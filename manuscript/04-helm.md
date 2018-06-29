# Packaging Kubernetes Applications {#chartmuseum}

T> Using YAML files to install or upgrade applications in a Kubernetes cluster works well only for static definitions. The moment we need to change an aspect of an application we are bound to discover the need for templating and packaging mechanisms.

We faced quite a few challenges thus far. The good news is that we managed to solve most of them. The bad news is that, in some cases, our solutions felt sub-optimum (politically correct way to say *horrible*).

We spent a bit of time trying to define Jenkins resources while we were in the [Deploying Stateful Applications At Scale](#sts) chapter. That was a good exercise that can be characterized as a learning experience, but there's still some work in front of us to make it a truly useful definition. The primary issue with our Jenkins definition is that it is still not automated. We can spin up a master, but we still have to go through the setup wizard manually. Once we're done with the setup, we'd need to install some plugins, and we'd need to change its configuration. Before we go down that road, we might want to explore whether others already did that work for us. If we'd look for, let's say, a Java library that would help us solve a particular problem with our application, we'd probably look for a Maven repository. Maybe there is something similar for Kubernetes applications. Perhaps there is a community-maintained repository with installation solutions for commonly used tools. We'll make it our mission to find such a place.

Another problem we faced was customization of our YAML files. As a minimum, we'll need to specify different image tag every time we deploy a release. In the [Defining Continuous Deployment](#manual-cd) chapter, we had to use `sed` to modify definitions before sending them through `kubectl` to Kube API. While that worked, I'm sure that you'll agree that commands like `sed -e "s@:latest@:1.7@g"` are not very intuitive. They look and feel awkward. To make things more complicated, image tags are rarely the only things that change from one deployment to another. We might need to change domains or paths of our Ingress controllers to accommodate the needs of having our applications deployed to different environments (e.g., staging and production). The same can be said for the number of replicas and many other things that define what we want to install. Using concatenated `sed` command can quickly become complicated, and it is not very user-friendly. Sure, we could modify YAML every time we, for example, make a new release. We could also create different definitions for each environment we're planning to use. But, we won't do that. That would only result in duplication and maintenance nightmare. We already have two YAML files for the `go-demo-3` application (one for testing and the other for production). If we continue down that route, we might end up with ten, twenty, or even more variations of the same definitions. We might also be forced to change it with every commit of our code so that the tag is always up to date. That road is not the one we'll take. It leads towards a cliff. What we need is a templating mechanism that will allow us to modify definitions before sending them to Kube API.

The last issue we'll try to solve in this chapter is the need to describe our applications and the possible changes others might apply to them before installing them inside a cluster. Truth be told, that is already possible. Anyone can read our YAML files to deduce what constitutes the application. Anyone could take one of our YAML files and modify it to suit their own needs. In some cases that might be challenging even for someone experienced with Kubernetes. However, our primary concern is related to those who are not Kubernetes ninjas. We cannot expect everyone in our organization to spend a year learning Kubernetes only so that they can deploy applications. On the other hand, we do want to provide that ability to everyone. We want to empower everyone. When faced with the need for everyone to use Kubernetes and the fact that not everyone will be a Kubernetes expert, it becomes apparent that we need a more descriptive, easier to customize, and more user-friendly way to discover and deploy applications.

We'll try to tackle those and a few other issues in this chapter. We'll try to find a place where community contributes with definitions of commonly used applications (e.g., Jenkins). We'll seek for a templating mechanism that will allow us to customize our applications before installing them. Finally, we'll try to find a way to better document our definitions. We'll try to make it so simple that even those who don't know Kubernetes can safely deploy applications to a cluster. What we need is a Kubernetes equivalent of package managers like *apt*, *yum*, *apk*, [Homebrew](https://brew.sh/), or [Chocolatey](https://chocolatey.org/), combined with the ability to document our packages in a way that anyone can use them.

I'll save you from searching for a solution and reveal it right away. We'll explore [Helm](https://helm.sh/) as the missing piece that will make our deployments customizable and user-friendly. If we are lucky, it might even turn out to be the solution that will save us from reinventing the wheel with commonly used applications.

Before we proceed, we'll need a cluster. It's time to get our hands dirty.

## Creating A Cluster

It's hands-on time again. We'll need to go back to the local copy of the [vfarcic/k8s-specs](https://github.com/vfarcic/k8s-specs) repository and pull the latest version.

I> All the commands from this chapter are available in the [04-helm.sh](https://gist.github.com/84adc5ad977f5c1a682bed524b781e0c) Gist.

```bash
cd k8s-specs

git pull
```

Just as in the previous chapters, we'll need a cluster if we are to execute hands-on exercises. The rules are still the same. You can continue using the same cluster as before, or you can switch to a different Kubernetes flavor. You can keep using one of the Kubernetes distributions listed below, or be adventurous and try something different. If you go with the latter, please let me know how it went, and I'll test it myself and incorporate it into the list.

Cluster requirements in this chapter are the same as in the previous. We'll need at least 3 CPUs and 3 GB RAM if running a single-node cluster, and slightly more if those resources are spread across multiple nodes.

For your convenience, the Gists and the specs we used in the previous chapter are available here as well.

* [docker4mac-3cpu.sh](https://gist.github.com/bf08bce43a26c7299b6bd365037eb074): **Docker for Mac** with 3 CPUs, 3 GB RAM, and with nginx Ingress.
* [minikube-3cpu.sh](https://gist.github.com/871b5d7742ea6c10469812018c308798): **minikube** with 3 CPUs, 3 GB RAM, and with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled.
* [kops.sh](https://gist.github.com/2a3e4ee9cb86d4a5a65cd3e4397f48fd): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, and with nginx Ingress (assumes that the prerequisites are set through [Appendix B](#appendix-b)).
* [minishift-3cpu.sh](https://gist.github.com/2074633688a85ef3f887769b726066df): **minishift** with 3 CPUs, 3 GB RAM, and version 1.16+.
* [gke-2cpu.sh](https://gist.github.com/e3a2be59b0294438707b6b48adeb1a68): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-2 (2 CPUs, 1.8 GB RAM) nodes (one in each zone), and with nginx Ingress controller running on top of the "standard" one that comes with GKE. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files if you prefer NOT to install nginx Ingress.

With a cluster up-and-running, we can proceed with an introduction to Helm.

## What Is Helm?

I will not explain about Helm. I won't even give you the elevator pitch. I'll only say that it is a project with a big and healthy community, that it is a member of [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/), and that it has the backing of big guys like Google, Microsoft, and a few others. For everything else, you'll need to follow the exercises. They'll lead us towards an understanding of the project, and they will hopefully help us in our goal to refine our continuous deployment pipeline.

The first step is to install it.

## Installing Helm

Helm is a client/server type of application. We'll start with a client. Once we have it running, we'll use it to install the server (Tiller) inside our newly created cluster.

The Helm client is a command line utility responsible for the local development of Charts, managing repositories, and interaction with the Tiller. Tiller server, on the other hand, runs inside a Kubernetes cluster and interacts with Kube API. It listens for incoming requests from the Helm client, combines Charts and configuration values to build a release, installs Charts and tracks subsequent releases, and is in charge of upgrading and uninstalling Charts through interaction with Kube API.

I> Do not get too attached to Tiller. Helm v3 will remove the server component and operate fully from the client side. At the time of this writing (June 2018), it is still unknown when will v3 reach GA.

I'm sure that this brief explanation is more confusing than helpful. Worry not. Everything will be explained soon through examples. For now, we'll focus on installing Helm and Tiller.

If you are a **MacOS user**, please use [Homebrew](https://brew.sh/) to install Helm. The command is as follows.

```bash
brew install kubernetes-helm
```

If you are a **Windows user**, please use [Chocolatey](https://chocolatey.org/) to install Helm. The command is as follows.

```bash
choco install kubernetes-helm
```

Finally, if you are neither Windows nor MacOS user, you must be running **Linux**. Please go to the [releases](https://github.com/kubernetes/helm/releases) page, download `tar.gz` file, unpack it, and move the binary to `/usr/local/bin/`.

If you already have Helm installed, please make sure that it is newer than 2.8.2. That version, and probably a few versions before, was failing on Docker For Mac/Windows.

Once you're done installing (or upgrading) Helm, please execute `helm help` to verify that it is working.

We are about to install *Tiller*. It'll run inside our cluster. Just as `kubectl` is a client that communicates with Kube API, `helm` will propagate our wishes to `tiller` which, in turn, will issue requests to Kube API.

It should come as no surprise that Tiller will be yet another Pod in our cluster. As such, you should already know that we'll need a ServiceAccount that will allow it to establish communication with Kube API. Since we hope to use Helm for all our installation in Kubernetes, we should give that ServiceAccount very generous permissions across the whole cluster.

Let's take a look at the definition of a ServiceAccount we'll create for Tiller.

```bash
cat helm/tiller-rbac.yml
```

The output is as follows.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

Since by now you are an expert in ServiceAccounts, there should be no need for a detailed explanation of the definition. We're creating a ServiceAccount called `tiller` in the `kube-system` Namespace, and we are assigning it ClusterRole `cluster-admin`. In other words, the account will be able to execute any operation anywhere inside the cluster.

You might be thinking that having such broad permissions might seem dangerous, and you would be right. Only a handful of people should have the user permissions to operate inside `kube-system` Namespace. On the other hand, we can expect much wider circle of people being able to use Helm. We'll solve that problem later in one of the next chapters. For now, we'll focus only on how Helm works, and get back to the permissions issue later.

Let's create the ServiceAccount.

```bash
kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config
```

We can see from the output that both the ServiceAccount and the ClusterRoleBinding were created.

Now that we have the ServiceAccount that gives Helm full permissions to manage any Kubernetes resource, we can proceed and install Tiller.

```bash
helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy
```

We used `helm init` to create the server component called `tiller`. Since our cluster uses RBAC and all the processes require authentication and permissions to communicate with Kube API, we added `--service-account tiller` argument. It'll attach the ServiceAccount to the `tiller` Pod.

The latter command waits until the Deployment is rolled out.

We could have specified `--tiller-namespace` argument to deploy it to a specific Namespace. That ability will come in handy in one of the next chapters. For now, we omitted that argument, so Tiller was installed in the `kube-system` Namespace. To be on the safe side, we'll list the Pods to confirm that it is indeed running.

```bash
kubectl -n kube-system get pods
```

The output, limited to the relevant parts, is as follows.

```
NAME              READY STATUS  RESTARTS AGE
...
tiller-deploy-... 1/1   Running 0        59s
```

Helm already has a single repository pre-configured. For those of you who just installed Helm for the first time, the repository is up-to-date. On the other hand, if you happen to have Helm from before, you might want to update the repository references by executing the command that follows.

```bash
helm repo update
```

The only thing left is to search for our favorite application hoping that it is available in the Helm repository.

```bash
helm search
```

The output, limited to the last few entries, is as follows.

```
...
stable/weave-scope 0.9.2 1.6.5 A Helm chart for the Weave Scope cluster visual...
stable/wordpress   1.0.7 4.9.6 Web publishing platform for building blogs and ...
stable/zeppelin    1.0.1 0.7.2 Web-based notebook that enables data-driven, in...
stable/zetcd       0.1.9 0.0.3 CoreOS zetcd Helm chart for Kubernetes            
```

We can see that the default repository already contains quite a few commonly used applications. It is the repository that contains the official Kubernetes Charts which are carefully curated and well maintained. Later on, in one of the next chapters, we'll add more repositories to our local Helm installation. For now, we just need Jenkins, which happens to be one of the official Charts.

I already mentioned Charts a few times. You'll find out what they are soon. For now, all you should know is that a Chart defines everything an application needs to run in a Kubernetes cluster.

## Installing Helm Charts

The first thing we'll do is to confirm that Jenkins indeed exists in the official Helm repository. We could do that by executing `helm search` (again) and going through all the available Charts. However, the list is pretty big and growing by the day. We'll filter the search to narrow down the output.

```bash
helm search jenkins
```

The output is as follows.

```
NAME           CHART VERSION APP VERSION DESCRIPTION                                       
stable/jenkins 0.16.1        2.107       Open source continuous integration server. It s...
```

We can see that the repository contains `stable/jenkins` chart based on Jenkins version 2.107.

W> ## A note to minishift users
W>
W> Helm will try to install Jenkins Chart with the process in a container running as user 0. By default, that is not allowed in OpenShift. We'll skip discussing the best approach to correct the permissions in OpenShift. I'll assume you already know how to set the permissions on the per-Pod basis. Instead, we'll do the simplest fix. Please execute the command that follows to allow the creation of restricted Pods to run as any user.
W>
W> `oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'`

We'll install Jenkins with the default values first. If that works as expected, we'll try to adapt it to our needs later on.

Now that we know (through `search`) that the name of the Chart is `stable/jenkins`, all we need to do is execute `helm install`.

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins
```

We instructed Helm to install `stable/jenkins` with the name `jenkins`, and inside the Namespace also called `jenkins`.

The output is as follows.

```
NAME:   jenkins
LAST DEPLOYED: Sun May ...
NAMESPACE: jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME          TYPE         CLUSTER-IP     EXTERNAL-IP PORT(S)        AGE
jenkins-agent ClusterIP    10.111.123.174 <none>      50000/TCP      1s
jenkins       LoadBalancer 10.110.48.57   localhost   8080:31294/TCP 0s

==> v1beta1/Deployment
NAME    DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
jenkins 1       1       1          0         0s

==> v1/Pod(related)
NAME        READY STATUS   RESTARTS AGE
jenkins-... 0/1   Init:0/1 0        0s

==> v1/Secret
NAME    TYPE   DATA AGE
jenkins Opaque 2    1s

==> v1/ConfigMap
NAME          DATA AGE
jenkins       4    1s
jenkins-tests 1    1s

==> v1/PersistentVolumeClaim
NAME    STATUS VOLUME  CAPACITY ACCESS MODES STORAGECLASS AGE
jenkins Bound  pvc-... 8Gi      RWO          gp2          1s


NOTES:
1. Get your 'admin' user password by running:
  echo $(kubectl get secret --namespace jenkins jenkins -o go-template --template="{.data.jenkins-admin-password | base64decode}")
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
```

At the top of the output, we can see some general information like the name we gave to the installed Chart (`jenkins`), when it was deployed, what the Namespace is, and the status.

Below the general information is the list of the installed resources. We can see that the Chart installed two services; one for the master and the other for the agents. Below is the Deployment and the Pod. It also created a Secret that holds the administrative username and password. We'll use it soon. Further on, we can see that it created two ConfigMaps. One (`jenkins`) holds all the configurations Jenkins might need. Later on, when we customize it, the data in this ConfigMap will reflect those changes. The second ConfigMap (`jenkins-tests`) is, at the moment, used only to provide a command used for executing liveness and readiness probes. Finally, we can see that a PersistentVolumeClass was created as well, thus making our Jenkins fault tolerant without losing its state.

Don't worry if you feel overwhelmed. We'll do a couple of iterations of the Jenkins installation process, and that will give us plenty of opportunities to explore this Chart in more details. If you are impatient, please `describe` any of those resources to get more insight into what's installed.

One thing worthwhile commenting right away is the type of the `jenkins` Service. It is, by default, set to `LoadBalancer`. We did not explore that type in [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy), primarily because the book is, for the most part, based on minikube.

On cloud providers which support external load balancers, setting the type field to `LoadBalancer` will provision an external load balancer for the Service. The actual creation of the load balancer happens asynchronously, and information about the provisioned balancer is published in the Service’s `status.loadBalancer` field.

When a Service is of the `LoadBalancer` type, it publishes a random port just as if it is the `NodePort` type. The additional feature is that it also communicates that change to the external load balancer (LB) which, in turn, should open a port as well. In most cases, the port opened in the external LB will be the same as the Service's `TargetPort`. For example, if the `TargetPort` of a Service is `8080` and the published port is `32456`, the external LB will be configured to accept traffic on the port `8080`, and it will forward it to one of the healthy nodes on the port `32456`. From there on, requests will be picked up by the Service and the standard process of forwarding it further towards the replicas will be initiated. From user's perspective, it seems as if the published port is the same as the `TargetPort`.

The problem is that not all load balancers and hosting vendors support the `LoadBalancer` type, so we'll have to change it to `NodePort` in some of the cases. Those changes will be outlined as notes specific to the Kubernetes flavor.

Going back to the Helm output...

At the bottom of the output, we can see the post-installation instructions provided by the authors of the Chart. In our case, those instructions tell us how to retrieve the administrative password from the Secret, how to open Jenkins in a browser, and how to log in.

W> ## A note to minikube users
W>
W> If you go back to the output, you'll notice that the type of the `jenkins` Service is `LoadBalancer`. Since we do not have a load balancer in front of our minikube cluster, that type will not work, and we should change it to `NodePort`. Please execute the command that follows.
W>
W> `helm upgrade jenkins stable/jenkins --set Master.ServiceType=NodePort`
W>
W> We haven't explained the `upgrade` process just yet. For now, just note that we changed the Service type to `NodePort`.

W> ## A note to minishift users
W>
W> OpenShift requires Routes to make services accessible outside the cluster. To make things more complicated, they are not part of "standard Kubernetes" so we'll need to create one using `oc`. Please execute the command that follows.
W>
W> `oc -n jenkins create route edge --service jenkins --insecure-policy Allow`
W>
W> That command created an `edge` Router tied to the `jenkins` Service. Since we do not have SSL certificates for HTTPS communication, we also specified that it is OK to use insecure policy which will allow us to access Jenkins through plain HTTP.

Next, we'll wait until `jenkins` Deployment is rolled out.

```bash
kubectl -n jenkins \
    rollout status deploy jenkins
```

We are almost ready to open Jenkins in a browser. But, before we do that, we need to retrieve the hostname (or IP) through which we can access our first Helm install.

```bash
ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080
```

W> ## A note to minikube users
W>
W> Unlike some other Kubernetes flavors (e.g., AWS with kops), minikube does not have a hostname automatically assigned to us through an external load balancer. We'll have to retrieve the IP of our minikube cluster and the port published when we changed the `jenkins` service to `NodePort`. Please execute the command that follows.
W>
W> `ADDR=$(minikube ip):$(kubectl -n jenkins get svc jenkins -o jsonpath="{.spec.ports[0].nodePort}")`

W> ## A note to GKE users
W>
W> Unlike some other Kubernetes flavors (e.g., AWS with kops), GKE does not have a hostname automatically assigned to us through an external load balancer. Instead, we got the IP of Google's LB. We'll have to get that IP. Please execute the command that follows.
W>
W> `ADDR=$(kubectl -n jenkins get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080`

W> ## A note to minishift users
W>
W> Unlike all other Kubernetes flavors, OpenShift does not use Ingress. We'll have to retrieve the address from the `jenkins` Route we created previously. Please execute the command that follows.
W>
W> `ADDR=$(oc -n jenkins get route jenkins -o jsonpath="{.status.ingress[0].host}")`

To be on the safe side, we'll `echo` the address we retrieved and confirm that it looks valid.

```bash
echo $ADDR
```

The format of the output will differ from one Kubernetes flavor to another. In case of AWS with kops, it should be similar to the one that follows.

```
...us-east-2.elb.amazonaws.com
```

Now we can finally open Jenkins. We won't do much with it. Our goal, for now, is only to confirm that it is up-and-running.

```bash
open "http://$ADDR"
```

W> Remember that if you are a **Windows user**, you'll have to replace `open` with `echo`, copy the output, and paste it into a new tab of your browser of choice.

You should be presented with the login screen. There is no setup wizard indicating that this Helm chart already configured Jenkins with some sensible default values. That means that, among other things, the Chart created a user with a password during the automatic setup. We need to discover it.

Fortunately, we already saw from the `helm install` output that we should retrieve the password by retrieving the `jenkins-admin-password` entry from the `jenkins` secret. If you need to refresh your memory, please scroll back to the output, or ignore it all together and execute the command that follows.

```bash
echo $(kubectl -n jenkins \
    get secret jenkins \
    -o go-template --template="{.data.jenkins-admin-password | base64decode}")
```

The output should be a random set of characters similar to the one that follows.

```
shP7Fcsb9g
```

Please copy the output and return to Jenkins` login screen in your browser. Type *admin* into the *User* field, paste the copied output into the *Password* field and click the *log in* button.

Mission accomplished. Jenkins is up-and-running without us spending any time writing YAML file with all the resources. It was set up automatically with the administrative user and probably quite a few other goodies. We'll get to them later. For now, we'll "play" with a few other `helm` commands that might come in handy.

If you are ever unsure about the details behind one of the Helm Charts, you can execute `helm inspect`.

```bash
helm inspect stable/jenkins
```

The output of the `inspect` command is too big to be presented in a book. It contains all the information you might need before installing an application (in this case Jenkins).

If you prefer to go through the available Charts visually, you might want to visit [Kubeapps](https://kubeapps.com/) project hosted by [bitnami](https://bitnami.com/). Click on the *Explore Apps* button, and you'll be sent to the hub with the list of all the official Charts. If you search for Jenkins, you'll end up on the [page with the Chart's details](https://hub.kubeapps.com/charts/stable/jenkins). You'll notice that the info in that page is the same as the output of the `inspect` command.

We won't go back to [Kubeapps](https://kubeapps.com/) since I prefer command line over UIs. A firm grip on the command line helps a lot when it comes to automation, which happens to be the goal of this book.

With time, the number of the Charts running in your cluster will increase, and you might be in need to list them. You can do that with the `ls` command.

```bash
helm ls
```

The output is as follows.

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 1        Thu May ... DEPLOYED jenkins-0.16.1 jenkins
```

There is not much to look at right now since we have only one Chart. Just remember that the command exists. It'll come in handy later on.

If you need to see the details behind one of the installed Charts, please use the `status` command.

```bash
helm status jenkins
```

The output should be very similar to the one you saw when we installed the Chart. The only difference is that this time all the Pods are running.

Tiller obviously stores the information about the installed Charts somewhere. Unlike most other applications that tend to save their state on disk, or replicate data across multiple instances, tiller uses Kubernetes ConfgMaps to preserve its state.

Let's take a look at the ConfigMaps in the `kube-system` Namespace where tiller is running.

```bash
kubectl -n kube-system get cm
```

The output, limited to the relevant parts, is as follows.

```
NAME       DATA AGE
...
jenkins.v1 1    25m
...
```

We can see that there is a config named `jenkins.v1`. We did not explore revisions just yet. For now, only assume that each new installation of a Chart is version 1.

Let's take a look at the contents of the ConfigMap.

```bash
kubectl -n kube-system \
    describe cm jenkins.v1
```

The output is as follows.

```
Name:        jenkins.v1
Namespace:   kube-system
Labels:      MODIFIED_AT=1527424681
             NAME=jenkins
             OWNER=TILLER
             STATUS=DEPLOYED
             VERSION=1
Annotations: <none>

Data
====
release:
----
[ENCRYPTED RELEASE INFO]
Events:  <none>
```

I replaced the content of the release Data with `[ENCRYPTED RELEASE INFO]` since it is too big to be presented in the book. The release contains all the info tiller used to create the first `jenkins` release. It is encrypted as a security precaution.

We're finished exploring our Jenkins installation, so our next step is to remove it.

```bash
helm delete jenkins
```

The output shows that the `release "jenkins"` was `deleted`.

Since this is the first time we deleted a Helm Chart, we might just as well confirm that all the resources were indeed removed.

```bash
kubectl -n jenkins get all
```

The output is as follows.

```
NAME           READY STATUS      RESTARTS AGE
po/jenkins-... 0/1   Terminating 0        5m
```

Everything is gone except the Pod that is still `terminating`. Soon it will disappear as well, and there will be no trace of Jenkins anywhere in the cluster. At least, that's what we're hoping for.

Let's check the status of the `jenkins` Chart.

```bash
helm status jenkins
```

The relevant parts of the output are as follows.

```
LAST DEPLOYED: Thu May 24 11:46:38 2018
NAMESPACE: jenkins
STATUS: DELETED

...
```

If you expected an empty output or an error stating that `jenkins` does not exist, you were wrong. The Chart is still in the system, only this time its status is `DELETED`. You'll notice that all the resources are gone though.

When we execute `helm delete [THE_NAME_OF_A_CHART]`, we are only removing the Kubernetes resources. The Chart is still in the system. We could, for example, revert the `delete` action and return to the previous state with Jenkins up-and-running again.

If you want to delete not only the Kubernetes resources created by the Chart but also the Chart itself, please add `--purge` argument.

```bash
helm delete jenkins --purge
```

The output is still the same as before. It states that the `release "jenkins"` was `deleted`.

Let's check the status now after we purged the system.

```bash
helm status jenkins
```

The output is as follows.

```
Error: getting deployed release "jenkins": release: "jenkins" not found
```

This time, everything was removed, and `helm` cannot find the `jenkins` Chart anymore.

## Customizing Helm Installations

We'll almost never install a Chart as we did. Even though the default values do often make a lot of sense, there is always something we need to tweak to make an application behave as we desire.

What if we do not want the Jenkins tag predefined in the Chart? What if for some reason we want to deploy Jenkins `2.112-alpine`? There must be a sensible way to change the tag of the `stable/jenkins` Chart.

Helm allows us to modify installation through variables. All we need to do is to find out which variables are available.

Besides visiting project's documentation, we can retrieve the available values through the command that follows.

```bash
helm inspect values stable/jenkins
```

The output, limited to the relevant parts, is as follows.

```
...
Master:
  Name: jenkins-master
  Image: "jenkins/jenkins"
  ImageTag: "lts"
  ...
```

We can see that within the `Master` section there is a variable `ImageTag`. The name of the variable should be, in this case, sufficiently self-explanatory. If we need more information, we can always inspect the Chart.

```bash
helm inspect stable/jenkins
```

I encourage you to read the whole output at some later moment. For now, we care only about the `ImageTag`.

The output, limited to the relevant parts, is as follows.

```
...
| Parameter         | Description      | Default |
| ----------------- | ---------------- | ------- |
...
| `Master.ImageTag` | Master image tag | `lts`   |
...
```

That did not provide much more info. Still, we do not really need more than that. We can assume that `Master.ImageTag` will allow us to replace the default value `lts` with `2.112-alpine`.

If we go through the documentation, we'll discover that one of the ways to overwrite the default values is through the `--set` argument. Let's give it a try.

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.112-alpine
```

W> ## A note to minikube users
W>
W> We still need to change the `jenkins` Service type to `NodePort`. Since this is specific to minikube, I did not want to include it in the command we just executed. Instead, we'll run the same command as before. Please execute the command that follows.
W>
W> `helm upgrade jenkins stable/jenkins --set Master.ServiceType=NodePort --reuse-values`
W>
W> We still did not go through the `upgrade` process. For now, just note that we changed the Service type to `NodePort`.
W>
W> Alternatively, you can `delete` the chart and install it again but, this time, with the `--set Master.ServiceType=NodePort` argument added to `helm install`.

W> ## A note to minishift users
W>
W> The Route we created earlier still exists, so we do not need to create it again.

The output of the `helm install` command is almost the same as when we executed it the first time, so there's probably no need to go through it again. Instead, we'll wait until `jenkins` rolls out.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

Now that the Deployment rolled out, we are almost ready to test whether the change of the variable had any effect. First, we need to get the Jenkins address. We'll retrieve it in the same way as before, so there's no need to lengthy explanation.

```bash
ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080
```

W> ## A note to minikube users
W>
W> As a reminder, the command to retrieve the address from minikube is as follows.
W>
W> `ADDR=$(minikube ip):$(kubectl -n jenkins get svc jenkins -o jsonpath="{.spec.ports[0].nodePort}")`

W> ## A note to GKE users
W>
W> As a reminder, the command to retrieve the address from GKE is as follows.
W>
W> `ADDR=$(kubectl -n jenkins get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080`

W> ## A note to minishift users
W>
W> As a reminder, the command to retrieve the address from the OpenShift route is as follows.
W>
W> `ADDR=$(oc -n jenkins get route jenkins -o jsonpath="{.status.ingress[0].host}")`

As a precaution, please output the `ADDR` variable and check whether the address looks correct.

```bash
echo $ADDR
```

Now we can open Jenkins UI.

```bash
open "http://$ADDR"
```

This time there is no need even to log in. All we need to do is to check whether changing the tag worked. Please observe the version in the bottom-right corner of the screen. If should be *Jenkins ver. 2.112*.

Let's imagine that some time passed and we decided to upgrade our Jenkins from *2.112* to *2.116*. We go through the documentation and discover that there is the `upgrade` command we can leverage.

```bash
helm upgrade jenkins stable/jenkins \
    --set Master.ImageTag=2.116-alpine \
    --reuse-values
```

This time we did not specify the Namespace, but we did set the `--reuse-values` argument. With it, the upgrade will maintain all the values used the last time we installed or upgraded the Chart. The result is an upgrade of the Kubernetes resources so that they comply with our desire to change the tag, and leave everything else intact.

The output of the `upgrade` command, limited to the first few lines, is as follows.

```
Release "jenkins" has been upgraded. Happy Helming!
LAST DEPLOYED: Thu May 24 12:51:03 2018
NAMESPACE: jenkins
STATUS: DEPLOYED
...
```

We can see that the release was upgraded.

To be on the safe side, we'll describe the `jenkins` Deployment and confirm that the image is indeed `2.116-alpine`.

```bash
kubectl -n jenkins \
    describe deployment jenkins
```

The output, limited to the relevant parts, is as follows.

```
Name:              jenkins
Namespace:         jenkins
...
Pod Template:
  ...
  Containers:
   jenkins:
    Image: jenkins/jenkins:2.116-alpine
    ...
```

The image was indeed updated to the tag `2.116-alpine`.

To satisfy my paranoid nature, we'll also open Jenkins UI and confirm the version there. But, before we do that, we need to wait until the update rolls out.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

Now we can open Jenkins UI.

```bash
open "http://$ADDR"
```

Please note the version in the bottom-right corner of the screen. It should say *Jenkins ver. 2.116*.

## Rolling Back Helm Revisions

No matter how we deploy our applications and no matter how much we trust our validations, the truth is that sooner or later we'll have to roll back. That is especially true with third-party applications. While we could roll forward faulty applications we developed, the same is often not an option with those that are not in our control. If there is a problem and we cannot fix it fast, the only alternative is to roll back.

Fortunately, Helm provides a mechanism to roll back. Before we try it out, let's take a look at the list of the Charts we installed so far.

```bash
helm list
```

The output is as follows.

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 2        Thu May ... DEPLOYED jenkins-0.16.1 jenkins  
```

As expected, we have only one Chart running in our cluster. The critical piece of information is that it is the second revision. First, we installed the Chart with Jenkins version 2.112, and then we upgraded it to 2.116.

W> ## A note to minikube users
W>
W> You'll see `3` revisions in your output. We executed `helm upgrade` after the initial install to change the type of the `jenkins` Service to `NodePort`.

We can roll back to the previous version (`2.112`) by executing `helm rollback jenkins 1`. That would roll back from the revision `2` to whatever was defined as the revision `1`. However, in most cases that is unpractical. Most of our rollbacks are likely to be executed through our CD or CDP processes. In those cases, it might be too complicated for us to find out what was the previous release number.

Luckily, there is an undocumented feature that allows us to roll back to the previous version without explicitly setting up the revision number. By the time you read this, the feature might become documented. I was about to start working on it and submit a pull request. Luckily, while going through the code, I saw that it's already there.

Please execute the command that follows.

```bash
helm rollback jenkins 0
```

By specifying `0` as the revision number, Helm will roll back to the previous version. It's as easy as that.

We got the visual confirmation in the form of the "`Rollback was a success! Happy Helming!`" message.

Let's take a look at the current situation.

```bash
helm list
```

The output is as follows.

```
NAME   	REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins	3        Thu May ... DEPLOYED jenkins-0.16.1 jenkins  
```

We can see that even though we issued a rollback, Helm created a new revision `3`. There's no need to panic. Every change is a new revision, even when a change means re-applying definition from one of the previous releases.

To be on the safe side, we'll go back to Jenkins UI and confirm that we are using version `2.112` again.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$ADDR"
```

We waited until Jenkins rolled out, and opened it in our favorite browser. If we look at the version information located in the bottom-right corner of the screen, we are bound to discover that it is *Jenkins ver. 2.112* once again.

We are about to start over one more time, so our next step it to purge Jenkins.

```bash
helm delete jenkins --purge
```

## Using YAML Values To Customize Helm Installations

We managed to customize Jenkins by setting `ImageTag`. What if we'd like to set CPU and memory. We should also add Ingress, and that would require a few annotations. If we add Ingress, we might want to change the Service type to ClusterIP and set HostName to our domain. We should also make sure that RBAC is used. Finally, the plugins that come with the Chart are probably not all the plugins we need.

Applying all those changes through `--set` arguments would end up as a very long command and would constitute an undocumented installation. We'll have to change the tactic and switch to `--values`. But before we do all that, we need to generate a domain we'll use with our cluster.

We'll use [nip.io](http://nip.io) to generate valid domains. The service provides a wildcard DNS for any IP address. It extracts IP from the nip.io subdomain and sends it back in the response. For example, if we generate 192.168.99.100.nip.io, it'll be resolved to 192.168.99.100. We can even add sub-sub domains like something.192.168.99.100.nip.io, and it would still be resolved to 192.168.99.100. It's a simple and awesome service that quickly became an indispensable part of my toolbox.

The service will be handy with Ingress since it will allow us to generate separate domains for each application, instead of resorting to paths which, by the way, are not supported by many Charts. If our cluster is accessible through *192.168.99.100*, we can have *jenkins.192.168.99.100.nip.io* and *go-demo-3.192.168.99.100.nip.io*.

We could use [xip.ip](http://xip.io) instead. For the end-users, there is no significant difference between the two. The main reason why we'll use nip.io instead of xip.io is integration with some of the tool. Minishift, for example, comes with Routes pre-configured to use nip.io.

I> Do NOT use `nip.io`, `xip.io`, or similar services for production. They are not a substitute for "real" domains, but a convenient way to generate them for testing purposes when your corporate domains are not easily accessible.

First things first... We need to find out the IP of our cluster, or the external LB if it is available. The commands that follow will differ from one cluster type to another.

I> Feel free to skip the sections that follow if you already know how to get the IP of your cluster's entry point.

If your cluster is running in **AWS** and was created with **kops**, we'll need to retrieve the hostname from the Ingress Service, and extract the IP from it. Please execute the commands that follow.

```bash
LB_HOST=$(kubectl -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

LB_IP="$(dig +short $LB_HOST \
    | tail -n 1)"
```

If your cluster is running in **Docker For Mac/Windows**, the IP is `127.0.0.1` and all you have to do is assign it to the environment variable `LB_IP`. Please execute the command that follows.

```bash
LB_IP="127.0.0.1"
```

If your cluster is running in **minikube**, the IP can be retrieved using `minikube ip` command. Please execute the command that follows.

```bash
LB_IP="$(minikube ip)"
```

If your cluster is running in **GKE**, the IP can be retrieved from the Ingress Service. Please execute the command that follows.

```bash
LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
```

Next, we'll output the retrieved IP to confirm that the commands worked, and generate a sub-domain `jenkins`.

```bash
echo $LB_IP

HOST="jenkins.$LB_IP.nip.io"

echo $HOST
```

The output of the second `echo` command should be similar to the one that follows.

```
jenkins.192.168.99.100.nip.io
```

*nip.io* will resolve that address to `192.168.99.100`, and we'll have a unique domain for our Jenkins installation. That way we can stop using different paths to distinguish applications in Ingress config. Domains work much better. Many Helm charts do not even have the option to configure unique request paths and assume that Ingress will be configured with a unique domain.

W> ## A note to minishift users
W>
W> I did not forget about you. You already have a valid domain in the `ADDR` variable. All we have to do is assign it to the `HOST` variable. Please execute the command that follows.
W>
W> `HOST=$ADDR && echo $HOST`
W>
W> The output should be similar to `jenkins.192.168.99.100.nip.io`.

Now that we have a valid `jenkins.*` domain, we can try to figure out how to apply all the changes we discussed.

We already learned that we can inspect all the available values using `helm inspect` command. Let's take another look.

```bash
helm inspect values stable/jenkins
```

The output, limited to the relevant parts, is as follows.

```yaml
Master:
  Name: jenkins-master
  Image: "jenkins/jenkins"
  ImageTag: "lts"
  ...
  Cpu: "200m"
  Memory: "256Mi"
  ...
  ServiceType: LoadBalancer
  # Master Service annotations
  ServiceAnnotations: {}
  ...
  # HostName: jenkins.cluster.local
  ...
  InstallPlugins:
    - kubernetes:1.1
    - workflow-aggregator:2.5
    - workflow-job:2.15
    - credentials-binding:1.13
    - git:3.6.4
  ...
  Ingress:
    ApiVersion: extensions/v1beta1
    Annotations:
    ...
...
rbac:
  install: false
  ...
```

Everything we need to accomplish our new requirements is available through the values. Some of them are already filled with defaults, while others are commented. When we look at all those values, it becomes clear that it would be unpractical to try to re-define them all through `--set` arguments. We'll use `--values` instead. It will allow us to specify the values in a file.

I already prepared a YAML file with the values that will fulfill our requirements, so let's take a quick look at them.

```bash
cat helm/jenkins-values.yml
```

The output is as follows.

```yaml
Master:
  ImageTag: "2.116-alpine"
  Cpu: "500m"
  Memory: "500Mi"
  ServiceType: ClusterIP
  ServiceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
  InstallPlugins:
    - blueocean:1.5.0
    - credentials:2.1.16
    - ec2:1.39
    - git:3.8.0
    - git-client:2.7.1
    - github:1.29.0
    - kubernetes:1.5.2
    - pipeline-utility-steps:2.0.2
    - script-security:1.43
    - slack:2.3
    - thinBackup:1.9
    - workflow-aggregator:2.5
  Ingress:
    Annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      ingress.kubernetes.io/ssl-redirect: "false"
      ingress.kubernetes.io/proxy-body-size: 50m
      ingress.kubernetes.io/proxy-request-buffering: "off"
  HostName: jenkins.acme.com
rbac:
  install: true
```

As you can see, the variables in that file follow the same format as those we output through the `helm inspect values` command. The only difference is in values, and the fact that `helm/jenkins-values.yml` contains only those that we are planning to change.

We defined that the `ImageTag` should be fixed to `2.116-alpine`.

We specified that our Jenkins master will need half a CPU and 500 MB RAM. The default values of 0.2 CPU and 256 MB RAM are probably not enough. What we set is also low, but since we're not going to run any serious load (at least not yet), what we re-defined should be enough.

The service was changed to `ClusterIP` to better accommodate Ingress resource we're defining further down.

If you are not using AWS, you can ignore `ServiceAnnotations`. They're telling ELB to use HTTP protocol.

Further down, we are defining the plugins we'll use throughout the book. Their usefulness will become evident in the next chapters.

The values in the `Ingress` section are defining the annotations that tell Ingress not to redirect HTTP requests to HTTPS (we don't have SSL certificates), as well as a few other less important options. We set both the old style (`ingress.kubernetes.io`) and the new style (`nginx.ingress.kubernetes.io`) of defining NGINX Ingress. That way it'll work no matter which Ingress version you're using. The `HostName` is set to a value that apparently does not exist. I could not know in advance what will be your hostname, so we'll overwrite it later on.

Finally, we set `rbac.install` to `true` so that the Chart knows that it should set the proper permissions.

Having all those variables defined at once might be a bit overwhelming. You might want to go through the [Jenkins Chart documentation](https://hub.kubeapps.com/charts/stable/jenkins) for more info. In some cases, documentation alone is not enough, and I often end up going through the files that form the chart. You'll get a grip on them with time. For now, the important thing to observe is that we can re-define any number of variables through a YAML file.

Let's install the Chart with those variables.

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$HOST
```

We used the `--values` argument to pass the contents of the `helm/jenkins-values.yml`. Since we had to overwrite the `HostName`, we used `--set`. If the same value is defined through `--values` and `--set`, the latter always takes precedence.

W> ## A note to minishift users
W>
W> The values define Ingress which does not exist in your cluster. If we'd create a set of values specific to OpenShift, we would not define Ingress. However, since those values are supposed to work in any Kubernetes cluster, we left them intact. Given that Ingress controller does not exist, Ingress resources will have no effect, so it's safe to leave those values.

Next, we'll wait for `jenkins` Deployment to roll out and open its UI in a browser.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$HOST"
```

The fact that we opened Jenkins through a domain defined as Ingress (or Route in case of OpenShift) tells us that the values were indeed used. We can double check those currently defined for the installed Chart with the command that follows.

```bash
helm get values jenkins
```

The output is as follows.

```yaml
Master:
  Cpu: 500m
  HostName: jenkins.18.220.212.56.nip.io
  ImageTag: 2.116-alpine
  Ingress:
    Annotations:
      ingress.kubernetes.io/proxy-body-size: 50m
      ingress.kubernetes.io/proxy-request-buffering: "off"
      ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
  InstallPlugins:
  - blueocean:1.5.0
  - credentials:2.1.16
  - ec2:1.39
  - git:3.8.0
  - git-client:2.7.1
  - github:1.29.0
  - kubernetes:1.5.2
  - pipeline-utility-steps:2.0.2
  - script-security:1.43
  - slack:2.3
  - thinBackup:1.9
  - workflow-aggregator:2.5
  Memory: 500Mi
  ServiceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
  ServiceType: ClusterIP
rbac:
  install: true
```

Even though the order is slightly different, we can easily confirm that the values are the same as those we defined in `helm/jenkins-values.yml`. The exception is the `HostName` which was overwritten through the `--set` argument.

Now that we explored how to use Helm to deploy publicly available Charts, we'll turn our attention towards development. Can we leverage the power behind Charts for our applications?

Before we proceed, please delete the Chart we installed as well as the `jenkins` Namespace.

```bash
helm delete jenkins --purge

kubectl delete ns jenkins
```

## Creating Helm Charts

Our next goal is to create a Chart for the *go-demo-3* application. We'll use the fork you created in the previous chapter.

First, we'll move into the fork's directory.

```bash
cd ../go-demo-3
```

To be on the safe side, we'll push the changes you might have made in the previous chapter and then we'll sync your fork with the upstream repository. That way we'll guarantee that you have all the changes I might have made.

You probably already know how to push your changes and how to sync with the upstream repository. In case you don't, the commands are as follows.

```bash
git add .

git commit -m \
    "Defining Continuous Deployment chapter"

git push

git remote add upstream \
    https://github.com/vfarcic/go-demo-3.git

git fetch upstream

git checkout master

git merge upstream/master
```

We pushed the changes we made in the previous chapter, we fetched the upstream repository *vfarcic/go-demo-3*, and we merged the latest code from it. Now we are ready to create our first Chart.

Even though we could create a Chart from scratch by creating a specific folder structure and the required files, we'll take a shortcut and create a sample Chart that can be modified later to suit our needs.

We won't start with a Chart for the *go-demo-3* application. Instead, we'll create a creatively named Chart *my-app* that we'll use to get a basic understanding of the commands we can use to create and manage our Charts. Once we're familiar with the process, we'll switch to *go-demo-3*.

Here we go.

```bash
helm create my-app

ls -1 my-app
```

The first command created a Chart named *my-app*, and the second listed the files and the directories that form the new Chart.

The output of the latter command is as follows.

```
Chart.yaml
charts
templates
values.yaml
```

We will not go into the details behind each of those files and directories just yet. For now, just note that a Chart consists of files and directories that follow certain naming conventions.

If our Chart has dependencies, we could download them with the `dependency update` command.

```bash
helm dependency update my-app
```

The output shows that `no requirements` were `found in .../go-demo-3/my-app/charts`. That makes sense because we did not yet declare any dependencies. For now, just remember that they can be downloaded or updated.

Once we're done with defining the Chart of an application, we can package it.

```bash
helm package my-app
```

We can see from the output that Helm `successfully packaged chart and saved it to: .../go-demo-3/my-app-0.1.0.tgz`. We do not yet have a repository for our Charts. We'll work on that in the next chapter.

If we are unsure whether we made a mistake in our Chart, we can validate it by executing `lint` command.

```bash
helm lint my-app
```

The output is as follows.

```
==> Linting my-app
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

We can see that our Chart contains no failures, at least not those based on syntax. That should come as no surprise since we did not even modify the sample Chart Helm created for us.

Charts can be installed using a Chart repository (e.g., `stable/jenkins`), a local Chart archive (e.g., `my-app-0.1.0.tgz`), an unpacked Chart directory (e.g., `my-app`), or a full URL (e.g., `https://acme.com/charts/my-app-0.1.0.tgz`). So far we used Chart repository to install Jenkins. We'll switch to the local archive option to install `my-app`.

```bash
helm install ./my-app-0.1.0.tgz \
    --name my-app
```

The output is as follows.

```
NAME:   my-app
LAST DEPLOYED: Thu May 24 13:43:17 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME   TYPE      CLUSTER-IP     EXTERNAL-IP PORT(S) AGE
my-app ClusterIP 100.65.227.236 <none>      80/TCP  1s

==> v1beta2/Deployment
NAME   DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
my-app 1       1       1          0         1s

==> v1/Pod(related)
NAME                    READY STATUS            RESTARTS AGE
my-app-7f4d66bf86-dns28 0/1   ContainerCreating 0        1s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=my-app,release=my-app" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

The sample application is a straightforward one with a Service and a Deployment. There's not much to say about it. We used it only to explore the basic commands for creating and managing Charts. We'll delete everything we did and start over with a more serious example.

```bash
helm delete my-app --purge

rm -rf my-app

rm -rf my-app-0.1.0.tgz
```

We deleted the Chart from the cluster, as well as the local directory and the archive we created earlier. The time has come to apply the knowledge we obtained and explore the format of the files that constitute a Chart. We'll switch to the *go-demo-3* application next.

## Exploring Files That Constitute A Chart

I prepared a Chart that defines the *go-demo-3* application. We'll use it to get familiar with writing Charts. Even if we choose to use Helm only for third-party applications, familiarity with Chart files is a must since we might have to look at them to better understand the application we want to install.

The files are located in `helm/go-demo-3` directory inside the repository. Let's take a look at what we have.

```bash
ls -1 helm/go-demo-3
```

The output is as follows.

```
Chart.yaml
LICENSE
README.md
templates
values.yaml
```

A chart is organized as a collection of files inside a directory. The directory name is the name of the Chart (without versioning information). So, a Chart that describes *go-demo-3* is stored in the directory with the same name.

The first file we'll explore is *Chart.yml*. It is a mandatory file with a combination of compulsory and optional fields.

Let's take a closer look.

```bash
cat helm/go-demo-3/Chart.yaml
```

The output is as follows.

```yaml
name: go-demo-3
version: 0.0.1
apiVersion: v1
description: A silly demo based on API written in Go and MongoDB
keywords:
- api
- backend
- go
- database
- mongodb
home: http://www.devopstoolkitseries.com/
sources:
- https://github.com/vfarcic/go-demo-3
maintainers:
- name: Viktor Farcic
  email: viktor@farcic.com
```

The `name`, `version`, and `apiVersion` are mandatory fields. All the others are optional.

Even though most of the fields should be self-explanatory, we'll go through each of them just in case.

The `name` is the name of the Chart, and the `version` is the version. That's obvious, isn't it? The critical thing to note is that versions must follow [SemVer 2](http://semver.org/) standard. The full identification of a Chart package in a repository is always a combination of a name and a version. If we package this Chart, its name would be *go-demo-3-0.0.1.tgz*. The `apiVersion` is the version of the Helm API and, at this moment, the only supported value is `v1`.

The rest of the fields are mostly informational. You should be able to understand their meaning so I won't bother you with lengthy explanations.

The next in line is the LICENSE file.

```bash
cat helm/go-demo-3/LICENSE
```

The first few lines of the output are as follows.

```
The MIT License (MIT)

Copyright (c) 2018 Viktor Farcic

Permission is hereby granted, free ...
```

The *go-demo-3* application is licensed as MIT. It's up to you to decide which license you'll use, if any.

README.md is used to describe the application.

```bash
cat helm/go-demo-3/README.md
```

The output is as follows.

```
This is just a silly demo.
```

I was too lazy to write a proper description. You shouldn't be. As a rule of thumb, README.md should contain a description of the application, a list of the pre-requisites and the requirements, a description of the options available through values.yaml, and anything else you might deem important. As the extension suggests, it should be written in Markdown format.

Now we are getting to the critical part.

The values that can be used to customize the installation are defined in `values.yaml`.

```bash
cat helm/go-demo-3/values.yaml
```

The output is as follows.

```yaml
replicaCount: 3
dbReplicaCount: 3
image:
  tag: latest
  dbTag: 3.3
ingress:
  enabled: true
  host: acme.com
service:
  # Change to NodePort if ingress.enable=false
  type: ClusterIP
rbac:
  enabled: true
resources:
  limits:
   cpu: 0.2
   memory: 20Mi
  requests:
   cpu: 0.1
   memory: 10Mi
dbResources:
  limits:
    memory: "200Mi"
    cpu: 0.2
  requests:
    memory: "100Mi"
    cpu: 0.1
dbPersistence:
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 2Gi
```

As you can see, all the things that may vary from one *go-demo-3* installation to another are defined here. We can set how many replicas should be deployed for both the API and the DB. Tags of both can be changed as well. We can disable Ingress and change the host. We can change the type of the Service or disable RBAC. The resources are split into two groups, so that the API and the DB can be controlled separately. Finally, we can change database persistence by specifying the `storageClass`, the `accessMode`, or the `size`.

I should have described those values in more detail in `README.md`, but, as I already admitted, I was too lazy to do that. The alternative explanation of the lack of proper README is that we'll go through the YAML files where those values are used, and everything will become much more apparent.

The important thing to note is that the values defined in that file are defaults that are used only if we do not overwrite them during the installation through `--set` or `--values` arguments.

The files that define all the resources are in the `templates` directory.

```bash
ls -1 helm/go-demo-3/templates/
```

The output is as follows.

```
NOTES.txt
_helpers.tpl
deployment.yaml
ing.yaml
rbac.yaml
sts.yaml
svc.yaml
```

The templates are written in [Go template language](https://golang.org/pkg/text/template/) extended with add-on functions from [Sprig library](https://github.com/Masterminds/sprig) and a few others specific to Helm. Don't worry if you are new to Go. You will not need to learn it. For most use-cases, a few templating rules are more than enough for most of the use-cases. With time, you might decide to "go crazy" and learn everything templating offers. That time is not today.

When Helm renders the Chart, it'll pass all the files in the `templates` directory through its templating engine.

Let's take a look at the `NOTES.txt` file.

```bash
cat helm/go-demo-3/templates/NOTES.txt
```

The output is as follows.

```
1. Wait until the applicaiton is rolled out:
  kubectl -n {{ .Release.Namespace }} rollout status deployment {{ template "helm.fullname" . }}

2. Test the application by running these commands:
{{- if .Values.ingress.enabled }}
  curl http://{{ .Values.ingress.host }}/demo/hello
{{- else if contains "NodePort" .Values.service.type }}
  export PORT=$(kubectl -n {{ .Release.Namespace }} get svc {{ template "helm.fullname" . }} -o jsonpath="{.spec.ports[0].nodePort}")

  # If you are running Docker for Mac/Windows
  export ADDR=localhost

  # If you are running minikube
  export ADDR=$(minikube ip)

  # If you are running anything else
  export ADDR=$(kubectl -n {{ .Release.Namespace }} get nodes -o jsonpath="{.items[0].status.addresses[0].address}")

  curl http://$NODE_IP:$PORT/demo/hello
{{- else }}
  If the application is running in OpenShift, please create a Route to enable access.

  For everyone else, you set ingress.enabled=false and service.type is not set to NodePort. The application cannot be accessed from outside the cluster.
{{- end }}
```

The content of the NOTES.txt file will be printed after the installation or upgrade. You already saw a similar one in action when we installed Jenkins. The instructions we received how to open it and how to retrieve the password came from the NOTES.txt file stored in Jenkins Chart.

That file is our first direct contact with Helm templating. You'll notice that parts of it are inside `if/else` blocks. If we take a look at the second bullet, we can deduce that one set of instructions will be printed if `ingress` is `enabled`, another if the `type` of the Service is `NodePort`, and yet another if neither of the first two conditions is met.

Template snippets are always inside double curly braces (e.g., `{{` and `}}`). Inside them can be (often simple) logic like an `if` statement, as well as predefined and custom made function. An example of a custom made function is `{{ template "helm.fullname" . }}`. It is defined in `_helpers.tpl` file which we'll explore soon.

Variables always start with a dot (`.`). Those coming from the `values.yaml` file are always prefixed with `.Values`. An example is `.Values.ingress.host` that defines the `host` that will be configured in our Ingress resource.

Helm also provides a set of pre-defined variables prefixed with `.Release`, `.Chart`, `.Files`, and `.Capabilities`. As an example, near the top of the NOTES.txt file is `{{ .Release.Namespace }}` snippet that will get converted to the Namespace into which we decided to install our Chart.

The full list of the pre-defined values is as follows (a copy of the official documentation).

* `Release.Name`: The name of the release (not the Chart)
* `Release.Time`: The time the chart release was last updated. This will match the Last Released time on a Release object.
* `Release.Namespace`: The Namespace the Chart was released to.
* `Release.Service`: The service that conducted the release. Usually this is Tiller.
* `Release.IsUpgrade`: This is set to `true` if the current operation is an upgrade or rollback.
* `Release.IsInstall`: This is set to `true` if the current operation is an install.
* `Release.Revision`: The revision number. It begins at 1, and increments with each helm upgrade.
* `Chart`: The contents of the Chart.yaml. Thus, the Chart version is obtainable as Chart.Version and the maintainers are in Chart.Maintainers.
* `Files`: A map-like object containing all non-special files in the Chart. This will not give you access to templates, but will give you access to additional files that are present (unless they are excluded using .helmignore). Files can be accessed using `{{index .Files "file.name"}}` or using the `{{.Files.Get name}}` or `{{.Files.GetString name}}` functions. You can also access the contents of the file as `[]byte` using `{{.Files.GetBytes}}`
* `Capabilities`: A map-like object that contains information about the versions of Kubernetes (`{{.Capabilities.KubeVersion}}`, Tiller (`{{.Capabilities.TillerVersion}}`, and the supported Kubernetes API versions (`{{.Capabilities.APIVersions.Has "batch/v1"}}`)

You'll also notice that our `if`, `else if`, `else`, and `end` statements start with a dash (`-`). That's the Go template way of specifying that we want all empty space before the statement (when `-` is on the left) or after the statement (when `-` is on the right) to be removed.

There's much more to Go templating that what we just explored. I'll comment on other use-cases as they come. For now, this should be enough to get you going. You are free to consult [template package documentation](https://golang.org/pkg/text/template/) for more info. For now, the critical thing to note is that we have the `NOTES.txt` file that will provide useful post-installation information to those who will use our Chart.

I mentioned `_helpers.tpl` as the source of custom functions and variables. Let's take a look at it.

```bash
cat helm/go-demo-3/templates/_helpers.tpl
```

The output is as follows.

```
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
```

That file is the exact copy of the `_helpers.tpl` file that was created with the `helm create` command that generated a sample Chart. You can extend it with your own functions. I didn't. I kept it as-is. It consists of two functions with comments that describe them. The first (`helm.name`) returns the name of the chart trimmed to 63 characters which is the limitation for the size of some of the Kubernetes fields. The second function (`helm.fullname`) returns fully qualified name of the application. If you go back to the NOTES.txt file, you'll notice that we are using `helm.fullname` in a few occasions. Later on, you'll see that we'll use it in quite a few other places.

Now that NOTES.txt and _helpers.tpl are out of the way, we can take a look at the first template that defines one of the Kubernetes resources.

```bash
cat helm/go-demo-3/templates/deployment.yaml
```

The output is as follows.

```yaml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: {{ template "helm.fullname" . }}
  labels:
    app: {{ template "helm.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ template "helm.name" . }}
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ template "helm.name" . }}
        release: {{ .Release.Name }}
    spec:
      containers:
      - name: api
        image: "vfarcic/go-demo-3:{{ .Values.image.tag }}"
        env:
        - name: DB
          value: {{ template "helm.fullname" . }}-db
        readinessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
          periodSeconds: 1
        livenessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
        resources:
{{ toYaml .Values.resources | indent 10 }}
```

That file defines the Deployment of the *go-demo-3* API. The first thing I did was to copy the definition from the YAML file we used in the previous chapters. Afterwards, I replaced parts of it with functions and variables. The `name`, for example, is now `{{ template "helm.fullname" . }}`, which guarantees that this Deployment will have a unique name. The rest of the file follows the same logic. Some things are using pre-defined values like `{{ .Chart.Name }}` and `{{ .Release.Name }}`, while others are using those from the `values.yaml`. An example of the latter is `{{ .Values.replicaCount }}`.

The last line contains a syntax we haven't seen before. `{{ toYaml .Values.resources | indent 10 }}` will take all the entries from the `resources` field in the `values.yaml`, and convert them to YAML format. Since the final YAML needs to be correctly indented, we piped the output to `indent 10`. Since the `resources:` section of `deployment.yaml` is indented by eight spaces, indenting the entries from `resources` in `values.yaml` by ten will put them just two spaces inside it.

Let's take a look at one more template.

```bash
cat helm/go-demo-3/templates/ing.yaml
```

The output is as follows.

```yaml
{{- if .Values.ingress.enabled -}}
{{- $serviceName := include "helm.fullname" . -}}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ template "helm.fullname" . }}
  labels:
    app: {{ template "helm.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: {{ $serviceName }}
          servicePort: 8080
    host: {{ .Values.ingress.host }}
{{- end -}}
```

That YAML defines the Ingress resource that makes the API Deployment accessible through its Service. Most of the values are the same as in the Deployment. There's only one difference worthwhile commenting.

The whole YAML is enveloped in the `{{- if .Values.ingress.enabled -}}` statement. The resource will be installed only if `ingress.enabled` value is set to `true`. Since that is already the default value in `values.yaml`, we'll have to explicitly disable it if we do not want Ingress.

Feel free to explore the rest of the templates. They are following the same logic as the two we just described.

There's one potentially significant file we did not define. We have not created `requirements.yaml` for *go-demo-3*. We did not need any. We will use it though in one of the next chapters, so I'll save the explanation for later.

Now that we went through the files that constitute the *go-demo-3* Chart, we should `lint` it to confirm that the format does not contain any apparent issues.

```bash
helm lint helm/go-demo-3
```

The output is as follows.

```
==> Linting helm/go-demo-3
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

If we ignore the complaint that the icon is not defined, our Chart seems to be defined correctly, and we can create a package.

```bash
helm package helm/go-demo-3 -d helm
```

The output is as follows.

```
Successfully packaged chart and saved it to: helm/go-demo-3-0.0.1.tgz
```

The `-d` argument is new. It specified that we want to create a package in `helm` directory.

We will not use the package just yet. For now, I wanted to make sure that you remember that we can create it.

## Upgrading Charts

We are about to install the *go-demo-3* Chart. You should already be familiar with the commands, so you can consider this as an exercise that aims to solidify what you already learned. There will be one difference when compared to the commands we executed earlier. It'll prove to be a simple, and yet an important one for our continuous deployment processes.

We'll start by inspecting the values.

```bash
helm inspect values helm/go-demo-3
```

The output is as follows.

```yaml
replicaCount: 3
dbReplicaCount: 3
image:
  tag: latest
  dbTag: 3.3
ingress:
  enabled: true
  host: acme.com
route:
  enabled: true
service:
  # Change to NodePort if ingress.enable=false
  type: ClusterIP
rbac:
  enabled: true
resources:
  limits:
   cpu: 0.2
   memory: 20Mi
  requests:
   cpu: 0.1
   memory: 10Mi
dbResources:
  limits:
    memory: "200Mi"
    cpu: 0.2
  requests:
    memory: "100Mi"
    cpu: 0.1
dbPersistence:
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 2Gi
```

We are almost ready to install the application. The only thing we're missing is the host we'll use for the application.

You'll find two commands below. Please execute only one of those depending on your Kubernetes flavor.

If you are **NOT** using **minishift**, please execute the command that follows.

```bash
HOST="go-demo-3.$LB_IP.nip.io"
```

If you are using minishift, you can retrieve the host with the command that follows.

```bash
HOST="go-demo-3-go-demo-3.$(minishift ip).nip.io"
```

No matter how you retrieved the host, we'll output it so that we can confirm that it looks OK.

```bash
echo $HOST
```

In my case, the output is as follows.

```
go-demo-3.192.168.99.100.nip.io
```

Now we are finally ready to install the Chart. However, we won't use `helm install` as before. We'll use `upgrade` instead.

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0 \
    --set ingress.host=$HOST \
    --reuse-values
```

The reason we are using `helm upgrade` this time lies in the fact that we are practicing the commands we hope to use inside our CDP processes. Given that we want to use the same process no matter whether it's the first release (install) or those that follow (upgrade). It would be silly to have `if/else` statements that would determine whether it is the first release and thus execute the install, or to go with an upgrade. We are going with a much simpler solution. We will always upgrade the Chart. The trick is in the `-i` argument that can be translated to "install unless a release by the same name doesn't already exist."

The next two arguments are the name of the Chart (`go-demo-3`) and the path to the Chart (`helm/go-demo-3`). By using the path to the directory with the Chart, we are experiencing yet another way to supply the Chart files. In the next chapter will switch to using `tgz` packages.

The rest of the arguments are making sure that the correct tag is used (`1.0`), that Ingress is using the desired host, and that the values that might have been used in the previous upgrades are still the same (`--reuse-values`).

If this command is used in the continuous deployment processes, we would need to set the tag explicitly through the `--set` argument to ensure that the correct image is used. The host, on the other hand, is static and unlikely to change often (if ever). We would be better of defining it in `values.yaml`. However, since I could not predict what will be your host, we had to define it as the `--set` argument.

Please note that minishift does not support Ingress (at least not by default). So, it was created, but it has no effect. I thought that it is a better option than to use different commands for OpenShift than for the rest of the flavors. If minishift is your choice, feel free to add `--set ingress.enable=false` to the previous command.

The output of the `upgrade` is the same as if we executed `install` (resources are removed for brevity).

```
NAME:   go-demo-3
LAST DEPLOYED: Fri May 25 14:40:31 2018
NAMESPACE: go-demo-3
STATUS: DEPLOYED

...

NOTES:
1. Wait until the application is rolled out:
  kubectl -n go-demo-3 rollout status deployment go-demo-3

2. Test the application by running these commands:
  curl http://go-demo-3.18.222.53.124.nip.io/demo/hello
```

W> ## A note to minishift users
W>
W> We'll need to create a Route separately from the Helm Chart, just as we did with Jenkins. Please execute the command that follows.
W>
W> `oc -n go-demo-3 create route edge --service go-demo-3 --insecure-policy Allow`

We'll wait until the Deployment rolls out before proceeding.

```bash
kubectl -n go-demo-3 \
    rollout status deployment go-demo-3
```

The output is as follows.

```
Waiting for rollout to finish: 0 of 3 updated replicas are available...
Waiting for rollout to finish: 1 of 3 updated replicas are available...
Waiting for rollout to finish: 2 of 3 updated replicas are available...
deployment "go-demo-3" successfully rolled out
```

Now we can confirm that the application is indeed working by sending a `curl` request.

```bash
curl http://$HOST/demo/hello
```

The output should display the familiar `hello, world!` message, thus confirming that the application is indeed running and that it is accessible through the host we defined in Ingress (or Route in case of minishift).

Let's imagine that some time passed since we installed the first release, that someone pushed a change to the master branch, that we already run all our tests, that we built a new image, and that we pushed it to Docker Hub. In that hypothetical situation, our next step would be to execute another `helm upgrade`.

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=2.0 \
    --reuse-values
```

When compared with the previous command, the difference is in the tag. This time we set it to `2.0`. We also removed `--set ingress.host=$HOST` argument. Since we have `--reuse-values`, all those used in the previous release will be maintained.

There's probably no need to further validations (e.g., wait for it to roll out and send a `curl` request). All that's left is to remove the Chart and delete the Namespace. We're done with the hands-on exercises.

```bash
helm delete go-demo-3 --purge

kubectl delete ns go-demo-3
```

## Helm vs. OpenShift Templates

I could give you a lengthy comparison between Helm and OpenShift templates. I won't do that. The reason is simple. Helm is the de-facto standard for installing applications. It's the most widely used, and its adoption is going through the roof. Among the similar tools, it has the biggest community, it has the most applications available, and it is becoming adopted by more software vendors than any other solution. The exception is RedHat. They created OpenShift templates long before Helm came into being. Helm borrowed many of its concepts, improved them, and added a few additional features. When we add to that the fact that OpenShift templates work only on OpenShift, the decision which one to use is pretty straightforward. Helm wins, unless you chose OpenShift as your Kubernetes flavor. In that case, the choice is harder to make. On the one hand, Routes and a few other OpenShift-specific types of resources cannot be defined (easily) in Helm. On the other hand, it is likely that OpenShift will switch to Helm at some moment. So, you might just as well jump into Helm right away.

I must give a big thumbs up to RedHat for paving the way towards some of the Kubernetes resources that are in use today. They created Routes when Ingress did not exist. They developed OpenShift templates before Helm was created. Both Ingress and Helm were heavily influenced by their counterparts in OpenShift. There are quite a few other similar examples.

The problem is that RedHat does not want to let go of the things they pioneered. They stick with Routes, even though Ingress become standard. If Routes provide more features than, let's say, nginx Ingress controller, they could still maintain them as OpenShift Ingress (or whatever would be the name). Routes are not the only example. They continue forcing OpenShift templates, even though it's clear that Helm is the de-facto standard. By not switching to the standards that they pioneered, they are making their platform incompatible with others. In the previous chapters, we experienced the pain Routes cause when trying to define YAML files that should work on all other Kubernetes flavors. Now we experienced the same problem with Helm.

If you chose OpenShift, it's up to you to decide whether to use Helm or OpenShift templates. Both choices have pros and cons. Personally, one of the things that attract me the most with Kubernetes is the promise that our applications can run on any hosting solution and on any Kubernetes flavor. RedHat is breaking that promise. It's not that I don't expect different solutions to come up with new things that distinguish them from the competition. I do. OpenShift has quite a few of those. But, it also has features that have equally good or better equivalents that are part of Kubernetes core or widely accepted by the community. Helm is one of those that are better than their counterpart in OpenShift.

We'll continue using Helm throughout the rest of the book. If you do choose to stick with OpenShift templates, you'll have to do a few modifications to the examples. The good news is that those changes should be relatively easy to make. I believe that you won't have a problem adapting.

## What Now?

We have a couple of problems left to solve. We did not yet figure out how to store the Helm charts in a way that they can be easily retrieved and used by others. We'll tackle that issue in the next chapter.

I suggest you take a rest. You deserve it. If you do feel that way, please destroy the cluster. Otherwise, jump to the next chapter right away. The choice is yours.
