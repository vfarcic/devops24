## TODO

- [X] Code
- [X] Code review Docker for Mac/Windows
- [X] Code review minikube
- [X] Code review kops
- [X] Code review minishift
- [X] Code review GKE
- [ ] Write
- [ ] Text review
- [ ] Diagrams
- [ ] Gist
- [ ] Review the title
- [ ] Proofread
- [ ] Add to slides
- [ ] Publish on TechnologyConversations.com
- [ ] Add to Book.txt
- [ ] Publish on LeanPub.com

# Packaging Kubernetes Applications

T> Using YAML files to deploy applications to a Kubernetes cluster work well only for static definitions. The moment we need to change an aspect of an application we are bound to discover the need for a templating and packaging mechanism.

We faced quite a few challenges thus far. The good news is that we managed to solve most of them. The bad news is that, in some cases, our solutions felt sub-optimum (politically correct way to say *horrible*).

We spent a bit of time trying to define Jenkins. While that was a good exercise that can be characterized as a learning experience, there's still some work in front of us to make it a truly useful definition. The major issue with our Jenkins definition is that it is still not automated. We can spin up a master, but we still have to go through the setup wizard manually. Once we're done with the setup, we'll need to install some plugins, and change the configuration. Before we go down that road, we might want to explore whether others already did that work for us. If we'd look for, let's say, a Java library that would help us solve a particular problem with our application, we'd probably look for a Maven repository. Maybe there is something similar for Kubernetes applications. Maybe there is a community maintained repository with deployment solutions for commonly used tools. We'll make it our mission to find such a place.

Another problem we faced was customization of our YAML files. As a minimum, we'll need to specify different image tag every time we deploy a release. Our solution, so far, was to use `sed` to modify definitions before sending them through `kubectl` to Kube API. While that worked, I'm sure that you'll agree that commands like `sed -e "s@:latest@:1.7@g"` are not very intuitive and feel awkward. To make things more complicated, image tags are rarely the only things that change from one deployment to another. We might need to change domains or paths of our Ingress controllers to acomodate the needs of having our applications deployed to different environments (e.g., staging and production). Using concatenated `sed` can quickly become complicated and is not very user-friendly. Sure, we could modify YAML every time we, for example, make a new release. We could also created different definitions for each environment we're planning to use. But, we won't do that. That would only result in duplication. We already have two YAML files for the `go-demo-3` application (one for testing and the other for production). If we continue down that route, we might end up with ten, twenty, or even more variations of the same definitions. We might even be forced to change it with every commit of our code so that the tag is always up to date. That road is not the one we'll take. It leads towards a cliff. What we need is a templating mechanism that will allow us to modify definitions before sending them to Kube API.

The last issue we'll try to solve in this chapter is the need to describe our applications and the possible changes others might apply to them before deploying them to a cluster. Truth be told, that is already possible. Anyone can read our YAML files to deduce what an application consist of. Anyone could take one of our YAML files and modify it to suit their own needs. In some cases that might be challenging even for someone experienced with Kubernetes. However, our main concern might be those who are not Kubernetes ninjas. We cannot expect everyone in our organization to spend a year learning Kubernetes only so that they can deploy applications. On the other hand, we do want to provide that ability to everyone. When faced with the need for everyone to use Kubernetes and the fact that not everyone will be a Kubernetes expert, it become obvious that we need a more descriptive, easier to customize, and more user friendly way to discover and deploy applications.

We'll try to tackle those and a few other issues in this chapter. We'll try to find a place where community contributes with definitions of commonly used applications (e.g., Jenkins). We'll seek for a templating mechanism that will allow us to customize our applications before deploying them. Finally, we'll try to find a way to better document our definitions. We'll try to make it so simple that even those who don't know Kubernetes can safely deploy applications to a cluster. What we need is a Kubernetes equivalent of package managers like *apt*, *yum*, *apk*, [Homebrew](https://brew.sh/), or [Chocolatey](https://chocolatey.org/), combined with the ability to document our packages in a way that anyone can use them.

I'll save you from searching for a solution and reveal it right away. We'll explore [Helm](https://helm.sh/) as the missing piece that will make our deployments customizable and user friendly. If we are lucky, it might even turn out to be the solution that will save us from reinventing the wheel with commonly used applications.

Before we proceed, we'll need a cluster. It's time to get our hands dirty.

## Creating A Cluster

It's hand-on time again. We'll need to go back to the local copy of the `vfarcic/k8s-specs` repository and pull the latest version.

I> All the commands from this chapter are available in the [04-helm.sh](TODO) Gist.

```bash
cd k8s-specs

git pull
```

Just as in the previous chapters, we'll need a cluster if we are to do the hands-on exercises. The rules are still the same. You can continue using the same cluster as before, or you can switch to a different Kubernetes flavor. You can continue using one of the Kubernetes distributions listed below, or be adventurous and try something different. If you go with the latter, please let me know how it went, and I'll test it myself and incorporate it into the list.

The cluster requirement in this chapter are the same as in the previous. We'll need at least 3 CPUs and 3 GB RAM if running a single-node cluster, and slightly more if those resources are spread across multiple nodes.

For your convenience, the Gists and the specs we used in the previous chapter are available here as well.

* [docker4mac-3cpu.sh](https://gist.github.com/bf08bce43a26c7299b6bd365037eb074): **Docker for Mac** with 3 CPUs, 3 GB RAM, and with nginx Ingress.
* [minikube-3cpu.sh](https://gist.github.com/871b5d7742ea6c10469812018c308798): **minikube** with 3 CPUs, 3 GB RAM, and with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled.
* [kops.sh](https://gist.github.com/2a3e4ee9cb86d4a5a65cd3e4397f48fd): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, and with nginx Ingress (assumes that the prerequisites are set through [Appendix B](#appendix-b)).
* [minishift-3cpu.sh](https://gist.github.com/2074633688a85ef3f887769b726066df): **minishift** with 3 CPUs, 3 GB RAM, and version 1.16+.
* [gke-2cpu.sh](https://gist.github.com/e3a2be59b0294438707b6b48adeb1a68): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-2 (2 CPUs, 1.8 GB RAM) nodes (one in each zone), and with nginx Ingress controller running on top of the "standard" one that comes with GKE. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files if you prefer NOT to install nginx Ingress.

With a cluster up-and-running, we can proceed with an introduction to Helm.

## What Is Helm?

I will not provide an explanation about Helm. I won't even give you the elevator pitch. I'll only say that it is a project with a big and healthy community, that it is a member of [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/), and that it has backing of big guys like Google, Microsoft, and a few others. For everything else, you'll need to follow the exercises. They'll lead us towards an understanding of the project and will hopefully helps us in our goal to refine our continuous deployment pipeline.

The first step is to install it.

## Installing Helm

Helm is a client/server type of application. We'll start with a client. Once we have it running, we'll use it to install the server (Tiller) inside our newly created cluster.

The Helm client is a command line utility responsible for local development of Charts, managing repositories, and interaction with the Tiller. Tiller server, on the other hand, runs inside a Kubernetes cluster and interacts with Kube API. It listens for incoming requests from the Helm client, combines Charts and configuration values to build a release, installs Charts and tracks subsequent releases, and is in charge of upgrading and uninstalling Charts through interaction with Kube API.

I'm sure that this brief explanation made is more confusing than helpful. Worry not. Everything will be explained soon through examples. For now, we'll focus on installing Helm and Tiller.

If you are a **MacOS user**, please use [Homebrew](https://brew.sh/) to install Helm. The command is as follows.

```bash
brew install kubernetes-helm
```

If you are a **Windows user**, please use [Chocolatey](https://chocolatey.org/) to install Helm. The command is as follows.

```bash
choco install kubernetes-helm
```

Finally, if you are neither Windows or MacOS user, you must be running **Linux**. Please go to the [releases](https://github.com/kubernetes/helm/releases) page, download `tar.gz` file, unpack it, and move the binary to `/usr/local/bin/`.

If you already have Helm installed, please make sure that it is newer than 2.8.2. That version, and probably a few versions before it, was failing on Docker For Mac/Windows.

Once you're done installing (or upgrading) Helm, please verify that it is working by executing `helm help`.

We are about to install *tiller*. It'll run inside our cluster. Just as `kubectl` is a client that communicates with Kube API, `helm` will propagate our wisher to `tiller` which, in turn, will issue requests to Kube API.

It should come as no surprise that *tiller* will be yet another Pod in our cluster. As such, you should already know that we'll need a ServiceAccount that will allow it to establish communication with Kube API. Since we hope to use Helm for potentially, all our Kubernetes deployments, we should give that ServiceAccount very generous permissions across the whole cluster.

Let's take a look at the definition of a ServiceAccount we'll use for *tiller*.

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

Since you are by now an expert in ServiceAccounts, there should be no need for a detailed explanation of the definition. We're creating a ServiceAccount called `tiller`in the `kube-system` Namespace and giving it `cluster-admin` ClusterRole. In other words, the account will be able to execute any operation anywhere inside the cluster.

You might be thinking that having such wide permissions might seem dangerous, and you would be right. Only a handful of people should have the user permissions to operate inside `kube-system` Namespace. On the other hand, we can expect much wider circle of people being able to use Helm. We'll solve that problem later in one of the next chapters. For now, we'll focus only on how Helm works, and get back to the permissions issue later.

Let's create the ServiceAccount.

```bash
kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config
```

We can see from the output that both the ServiceAccount and the ClusterRoleBinding were created.

Now that we have a ServiceAccount that will allow Helm full permissions to manage any Kubernetes resource, we can proceed and install *tiller*.

```bash
helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy
```

We used `helm init` to create the server component called *tiller*. Since our cluster uses RBAC and all the processes require authentication and permissions to communicate with Kube API, we added `--service-account tiller` argument. It'll attach the ServiceAccount the the *tiller* Pod.

The latter command waits until the Deployment is rolled out.

We could have specified `--tiller-namespace` argument to deploy it to a specific Namespace. That ability will come in handy in one of the next chapters. For now, we omitted that argument to *tiller* was deployed by default to the `kube-system` Namespace. To be on the safe side, we'll list the Pods to confirm that it is indeed running.

```bash
kubectl -n kube-system get pods
```

The output, limited to the relevant parts, is as follows.

```
NAME              READY STATUS  RESTARTS AGE
...
tiller-deploy-... 1/1   Running 0        59s
```

Helm we installed already has a single repository pre-configured. For those of you who just installed Helm for the first time, the repository is up-to-date. On the other hand, if you happen to have Helm from before, you might want to update the repository references by executing the command that follows.

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

I already mentioned Charts a few times. You'll find out what they are soon. For now, all you should know that a Chart defines everything an application needs to run in a Kubernetes cluster.

## Installing Helm Charts

The first thing we'll do is to confirm that Jenkins indeed exists in the official Helm repository. We could do that by executing `helm search` and going through all the available Charts. However, the list is pretty big and growing by the day. We'll filter the search to narrow down the output.

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
W> Helm will try to install Jenkins Chart with the process in a container running as user 0. By default, that is not allowed in OpenShift. We'll skip discussing the best approach to correct the permissions in OpenShift. I'll assume you already know how to set the permissions on per-Pod basis. Instead, we'll do the simplest fix. Please execute the command that follows to allow creation of restricted Pods to run as any user.
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
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
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

Below the general information is the list of the installed resources. We can see that the Chart installed two services; one for the master and the other for the agents. Below it is the Deployment and the Pod. It also created a Secret that holds the administrative username and password. We'll use it soon. Further on, we can see that it created two ConfigMaps. One (`jenkins`) holds all the configurations Jenkins might need. Later on, when we customize it, the data in this ConfigMap will reflect those changes. The second ConfigMap (`jenkins-tests`) is, at the moment, used only to provide a command used for executing liveness and readiness probes. Finally, we can see that a PersistentVolumeClass was created as well, thus making our Jenkins fault tolerant without loosing its state.

Don't worry if you feel overwhelmed. We'll do a couple of iterations of the Jenkins installation process and that will give us plenty of opportunity to explore Helm in more details. If you are impatient, please `describe` any of those resources to get more insight into what's installed.

At the bottom of the output we can see the post-installation instructions provided by the authors of the Chart. In our case, those instructions tell us how to retrieve the administrative password from the Secret, how to open Jenkins in browser, and how to login.

W> ## A note to minikube users
W>
W> If you go back to the output, you'll notice that the type of the `jenkins` Service is `LoadBalancer`. Since we do not have a load balancer in front of our minikube cluster, that type will not work and we should change it to `NodePort`. Please execute the command that follows.
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
W> Unlike some other Kubernetes flavors (e.g., AWS with kops), minikube does not have a hostname automatically assigned to us through an external load balancer. We'll have to retrieve the IP of our minikube cluster and the port published when we change the `jenkins` service to `NodePort`. Please execute the command that follows.
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

The format of the output will differ from one Kubernetes flavor. In case of AWS with kops, it should be similar to the one that follows.

```
...us-east-2.elb.amazonaws.com
```

Now we can, finally, open Jenkins. We won't do much with it. Our goal, for now, is only to confirm that it is up-and-running.

```bash
open "http://$ADDR"
```

W> Remember that if you are a Windows user, you'll have to replace `open` with `echo`, copy the output, and paste it into a new tab of your browser of choice.

You should be presented with the login screen. There is no setup wizard indicating that this Helm chart already configured Jenkins with some sensible default values. That means that, among other things, the Chart created a user with a password during the automated setup. We need to discover it.

Fortunatelly, we already from the `helm install` output that we should retrieve the password by retrieving the `jenkins-admin-password` entry from the `jenkins` secret. If you need to refresh your memory, please scroll back to the output or ignore it all together and execute the command that follows.

```bash
kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo
```

The output should be a random set of characters similar to the one that follows.

```
shP7Fcsb9g
```

Please copy the output and return to Jenkins` login screen in your browser. Type *admin* into the *User* field, paste the copied output into the *Password* field, and click the *log in* button.

Mission accomplished. Jenkins is up-and-running without us spending any time writing YAML file with all the resources. It was set up automatically with the administrative user and probably quite a few other goodies. We'll get to them later. For now, we'll "play" with a few other `helm` commands that might come in handy.

If you are ever unsure about the details behind one of the Helm Charts, you can execute `helm inspect`.

```bash
helm inspect stable/jenkins
```

The output of the `inspect` command is too big to be presented in a book. It contains all the information you might need before installing an application (in this case Jenkins).

If you prefer to go through the available Charts visualy, you might want to visit [Kubeapps](https://kubeapps.com/) project hosted by [bitnami](https://bitnami.com/). Click on the *Explore Apps* button and you'll be sent to the hub with the list of all the official Charts. If you search for Jenkins, you'll end up on the [page with the Chart's details](https://hub.kubeapps.com/charts/stable/jenkins). You'll notice that the info in that page is the same as the output of the `inspect` command.

We won't go back to [Kubeapps](https://kubeapps.com/) since I prefer command line over UIs. A strong grip on a command line helps a lot when it comes to automation, which happens to be the goal of this book.

With time the number of the Charts running in your cluster with increase and you might be in need to list them. You can do that with the `ls` command.

```bash
helm ls
```

The output is as follows.

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 1        Thu May ... DEPLOYED jenkins-0.16.1 jenkins
```

There is not much to look at now since we have only one Chart. Just remember that the command exist. It'll come in handy later on.

If you need to see the details behind on of the installed Charts, please use the `status` command.

```bash
helm status jenkins
```

The output should be very similar to the one you saw when we installed the Chart. The only difference is that, this time, all the Pods are running.

Tiller obviously stores the information about the installed Charts somewhere. Unlike most other applications that tend to store their state on disk, or replicate data across multiple instances, tiller uses Kubernetes ConfgMaps to preserve its state.

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

We can see that there is a config named `jenkins.v1`. We did not explore revisions just yet. For now, just assume that each new installation of a Chart is version 1.

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

I replaced the content of the release Data with `[ENCRYPTED RELEASE INFO]`, since it is too big to be presented in the book. The release contains all the info tiller used to create the first `jenkins` release. It is encrypted as a security precaution.

We're finished exploring our Jenkins installation so our next step is to remove it.

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

Everything is gone except the Pod that is still `terminating`. Soon it will dissapear as well and there will be no trace of Jenkins anywhere in the cluster. At least, that's what we're hoping for.

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

If you expected an empty output or an error stating that `jenkins` does not exist, you were wrong. The Chart is still in the system, only this time it's status is `DELETED`. You'll notice that all the resources are gone though.

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

This time, everything was removed and `helm` cannot find the `jenkins` Chart any more.

## Customizing Helm Installations

We'll almost never install a Chart as we did. Even though the default values do often make a lot of sense, there is always something we need to tweak.

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

We can see that within the `Master` section there is a variable `ImageTag`. The name of the variable should be, in this case, sufficiently sefl-explanatory. If we need more information, we can always inspect the Chart.

```bash
helm inspect stable/jenkins
```

I encourage you to read the whole output as some later moment. For now, we care only about the `ImageTag`.

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
W> We still need to change the `jenkins` Service type to `NodePort`. Since this is specific to minikube, I did not want to include it in the command we just executed. Instead, we'll run the same command we execute before. Please execute the command that follows.
W>
W> `helm upgrade jenkins stable/jenkins --set Master.ServiceType=NodePort`
W>
W> We still did not go through the `upgrade` process. For now, just note that we changed the Service type to `NodePort`.
W> 
W> Alternatively, you can add `delete` the chart and install it again but, this time, with the `--set Master.ServiceType=NodePort` argument added to `helm install`.

W> ## A note to minishift users
W>
W> The Route we created earlier still exists so we do not need to create it again.

The output of the `helm install` command is almost the same as when we executed it the first time, so there's probably no need to go through it again. Instead, we'll wait until `jenkins` rolls out.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

Now that the Deployment rolled out, we are almost ready to test whether the change of the variable had any effect. First we need to get the Jenkins address. We'll retrieve it in the same way as before, so there's no need to lengthy explanation.

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

As a precaution, please output the `ADDR` and check whether the address looks correct.

```bash
echo $ADDR
```

Now we can open Jenkins UI.

```bash
open "http://$ADDR"
```

This time there is no need even to login. All we need to do is to check whether changing the tag did really work. Please observe the version in the bottom-right corner of the screen. If should be *Jenkins ver. 2.112*.

## Upgrading Helm Installations

Let's imagine that some time passed and we decide to upgrade our Jenkins from *2.112* to *2.116*. We go through the documentation and discover that there is the `upgrade` command we can leverage.

```bash
helm upgrade jenkins stable/jenkins \
    --set Master.ImageTag=2.116-alpine \
    --reuse-values
```

This time we did not specify the Namespace but we did set the `--reuse-values` argument. With it, the upgrade will maintain all the values used the last time we installed or upgraded the Chart. The result is an upgrade of the Kubernetes resources so that they comply with our desire to change the tag, and leave everything else intact.

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

## Rolling Back A Helm Revision

No matter how we deploy our applications and how much we trust our validations, the truth is that sooner or later we'll have to roll back. That is especially true with third-party applications. While we could roll forward faulty applications we develop, the same is often not an option with those that are not in our control. If there is a problem and we cannot fix it fast, the only alternative it to roll back.

Fortunatelly, Helm provides a mechanism to roll back. Before we try it out, let's take a look at the list of the Charts we installed so far.

```bash
helm list
```

The output is as follows.

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 2        Thu May ... DEPLOYED jenkins-0.16.1 jenkins  
```

As expected, we have only one Chart running in our cluster. The important piece of information is that it is the second revision. First we installed the Chart with Jenkins version 2.112. Then we upgraded it to 2.116.

W> ## A note to minikube users
W>
W> You'll see `3` revisions in your output. We executed `helm upgrade` after the initial install to change the type of the `jenkins` Service to `NodePort`.

We can roll back to the the previous version (`2.112`) by executing `helm rollback jenkins 1`. That would roll back from the revision `2` to whatever was defined as the revision `1`. However, in most cases that is unpractical. Most of our rollback are likely to be executed through our CD or CDP processes. In those cases, it might be too complicated for us to find out what was the previous release number.

Luckily, there is an undocumented feature that allows us to roll back to the previous version without explicitly setting up the revision number. By the time you read this, the feature might become documented. I was about to start working on it and submit a pull request. Luckily, while going through the code I saw that it's already there.

Please execute the command that follows.

```bash
helm rollback jenkins 0
```

By specifying `0` as the revision number, Helm will roll back to the previous version. It's as easy as that.

The got the visual confirmation in form of the "`Rollback was a success! Happy Helming!`" message.

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

We are about to start over one more time so our next step it to purge Jenkins.

```bash
helm delete jenkins --purge
```

## Using YAML Values To Customize Helm Installations

We managed to customize Jenkins by setting `ImageTag`. What if we'd like to set CPU and memory as well. We should also add Ingress as well and that would require a few annotations. If we add Ingress, we might want to change the Service type to ClusterIP and set HostName to our domain. We should also make sure that RBAC is used. Finally, the plugins that come with the Chart are probably not all the plugins we need. Applying all those changes through `--set` arguments would end up as a very long command and would constitute an undocumented installation. We'll have to change the tactic and switch to `--values`. But before we do all that, we need to generate a domain we'll use with our cluster.

We'll use [xip.io](http://xip.io/) to generate valid domains. The service provides a wildcard DNS for any IP address. It extracts IP from the xip.io subdomain and sends it back in the response. For example, if we generate 192.168.99.100.xip.io, it'll be resolved to 192.168.99.100. We can even add sub-sub domains like something.192.168.99.100.xip.io and it would still be resolved to 192.168.99.100. It's a simple and awesome sesrvice that quickly become indispensable part of my toolbox.

First things first... We need to find out the IP of our cluster or external LB if available. The commands that follow will differ from one cluster type to another.

I> If you already know how to get the IP of your cluster's entry point, feel free to skip the sections that follow.

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

If your cluster is running in **minikube**, the IP is can be retrieved using `minikube ip` command. Please execute the command that follows.

```bash
LB_IP="$(minikube ip)"
```

If your cluster is running in **GKE**, the IP is can be retrieved from the Ingress Service. Please execute the command that follows.

```bash
LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
```

Next we'll output the retrieved IP to confirm that the commands worked, and generate a sub-sub domain `jenkins`.

```bash
echo $LB_IP

HOST="jenkins.$LB_IP.xip.io"

echo $HOST
```

The output of the `echo` command should be similar to the one that follows.

```
jenkins.192.168.99.100.xip.io
```

*xip.io* will resolve that domain to `192.168.99.100` and we'll have a unique domain for our Jenkins installation. That way we can stop using different paths to distinguish applications in Ingress config. Domains work much better. Many Helm charts do not even have the option to configure unique request paths and assume that Ingress will be configured through a unique domain.

W> ## A note to minishift users
W>
W> I did not forget about you. You already have a valid domain in the `ADDR` variable. It is based on `nip.io` which serves the same purpose as *xip.io*. All we have to do is assign it to the `HOST` variable. Please execute the command that follows.
W> 
W> `HOST=$ADDR && echo $HOST`.
W> 
W> The output should be similar to `jenkins.192.168.99.100.nip.io`.

Now that we have a valid `jenkins.*` domain, we can try to figure out how to apply all the changes we discussed.

We already learned that we can inspect all the available values using `helm inspect` command. Take take another look.

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

Everything we need to accomplish our new requirements is available through the values. Some of them are already filled with defaults, while others are commented. When we look at all those values, it becomes clear that it would be unpractical to try to re-define them all through `--set` arguments. We'll use `--values` instead.

I already prepared a YAML file with the values that will fullfil our requirements, so let's take a quick look at them.

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

As you can see, the variables in this file follow the same format as those we output through the `helm inspect values` command. The only difference is in values, and the fact that `helm/jenkins-values.yml` only contains those that we are hoping to change.

We defined that the `ImageTag` should be fixed to `2.116-alpine`.

We specified that our Jenkins master will need half a CPU and 500 MB RAM. The default values of 0.2 CPU and 256 MB RAM are probably not enough. Even what we set is low but since we're not going to run any serious load (at least not yet), what we set should be enough.

The service was changed to `ClusterIP` to better acomodate the Ingress we're defining further down.

If you are not using AWS, you can ignore `ServiceAnnotations`. They're telling ELB to use HTTP protocol.

Further down, we are defining the plugins we'll use throughout the book. Their usefulness will become evident in the next chapters.

`Ingress` set of values are defining the annotations that tell Ingress not to redirect HTTP requests to HTTPS (we don't have SSL certificates), as well as a few other less important options. We set both the old style (`ingress.kubernetes.io`) and the new style (`nginx.ingress.kubernetes.io`) of defining NGINX Ingress. That way, it'll work no matter which version you're using. The `HostName` is set to a value that obviously does not exist. I could not know in advance what will be your hostname, so we'll overwrite it later on.

Finally, we set `rbac.install` to `true` so that the Chart knows that it should set the proper permissions.

Having all those variables defined at once might be a bit overwhelming. You might want to go through the [Jenkins Chart documentation](https://hub.kubeapps.com/charts/stable/jenkins) for more info. In some cases that is not enough and I often end up going through the files that form the chart. You'll get a grip on it with time. For now, the important thing to observe is that we can re-define any number of variables through a YAML file.

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
W> The values define Ingress which does not exist in our cluster. If we'd create a set of values specific for OpenShift, we would not define Ingress. However, since those values are supposed to work in any Kubernetes cluster, we left them intact. Given that Ingress controller does not exist, Ingress resources will have no effect so it's safe to leave those values.

Next, we'll wait for `jenkins` Deployment to roll out and open UI in a browser.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$HOST"
```

The fact that we opened Jenkins through a domain defined as Ingress tells us that the values were indeed used. We can double check the values currently defined for the installed Chart with the command that follows.

```bash
helm get values jenkins
```

The output is as follows.

```yaml
Master:
  Cpu: 500m
  HostName: jenkins.18.220.212.56.xip.io
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

Even though the order is slightly different, we can easily confirm that the values are the same as those we defined in `helm/jenkins-values.yml`, with the exception of the `HostName` which was overwritten through the `--set` install argument.

Now that we explored how to use Helm to deploy publicly available Charts, we'll turn our attention towards development. Can we leverage the power behind Charts for our applications?

Before we proceed, please delete the Chart we installed as well as the `jenkins` Namespace.

```bash
helm delete jenkins --purge

kubectl delete ns jenkins
```

## Creating Helm Charts

Our next goal is to create a Chart for the *go-demo-3* application. We'll use the fork you created in the previous chapter. First we'll move into the fork's directory.

```bash
cd ../go-demo-3
```

To be on the safe side, we'll push the changes you might have made in the previous chapter, and than we'll sync your fork with the upstream repository. That way we'll guarantee that you have all the changes I might have made.

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

We pushed the changes we made in the previous chapter, fetched the upstream repository *vfarcic/go-demo-3*, and merged the latest code from it. Now we are ready to create our first Chart.

Even though we could create a Chart from scratch by creating a specific folder structure and the required files, we'll take a shortcut and create a sample Chart that can be modified later to suit our needs.

We won't start with a Chart for the *go-demo-3* application. Instead, we'll create a creatively named Chart *my-app* that we'll use to get a basic understanding of the commands we can use to create and manage our Charts. Once we're familiar with the process, we'll switch to *go-demo-3*.

Here we go.

```bash
helm create my-app

ls -1 my-app
```

The first command created a Chart named *my-app* and the second listed the files and the directories Helm created for us.

TODO: Continue

```
Chart.yaml
charts
templates
values.yaml
```

TODO: dev-charts

TODO: dev-templates

TODO: best-practices

```bash
helm dependency update my-app
```

```
No requirements found in /Users/vfarcic/IdeaProjects/go-demo-3/my-app/charts.
```

```bash
helm package my-app
```

```
Successfully packaged chart and saved it to: /Users/vfarcic/IdeaProjects/go-demo-3/my-app-0.1.0.tgz
```

```bash
helm lint my-app
```

```
==> Linting my-app
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

<!-- The helm install command can install from several sources:

A chart repository (as we’ve seen above)
A local chart archive (helm install foo-0.1.1.tgz)
An unpacked chart directory (helm install path/to/foo)
A full URL (helm install https://example.com/charts/foo-1.2.3.tgz) -->

```bash
helm install ./my-app-0.1.0.tgz \
    --name my-app
```

```
NAME:   my-app
LAST DEPLOYED: Thu May 24 13:43:17 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
my-app  ClusterIP  100.65.227.236  <none>       80/TCP   1s

==> v1beta2/Deployment
NAME    DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
my-app  1        1        1           0          1s

==> v1/Pod(related)
NAME                     READY  STATUS             RESTARTS  AGE
my-app-7f4d66bf86-dns28  0/1    ContainerCreating  0         1s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=my-app,release=my-app" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

```bash
helm delete my-app --purge
```

```
release "my-app" deleted
```

```bash
rm -rf my-app

rm -rf my-app-0.1.0.tgz
```

```bash
ls -1 helm/go-demo-3
```

```
Chart.yaml
LICENSE
README.md
templates
values.yamls
```

```bash
cat helm/go-demo-3/Chart.yaml
```

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

```bash
cat helm/go-demo-3/LICENSE
```

```
The MIT License (MIT)

Copyright (c) 2018 Viktor Farcic

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

```bash
cat helm/go-demo-3/README.md
```

```
This is just a silly demo.
```

```bash
cat helm/go-demo-3/values.yaml
```

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

```bash
ls -1 helm/go-demo-3/templates/
```

```
NOTES.txt
_helpers.tpl
deployment.yaml
ing.yaml
rbac.yaml
sts.yaml
svc.yaml
```

```bash
cat helm/go-demo-3/templates/NOTES.txt
```

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

```bash
cat helm/go-demo-3/templates/_helpers.tpl
```

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

```bash
cat helm/go-demo-3/templates/deployment.yaml
```

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

```bash
cat helm/go-demo-3/templates/ing.yaml
```

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

```bash
# The rest of the files are following the same logic

helm lint helm/go-demo-3
```

```
==> Linting helm/go-demo-3
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

```bash
helm package helm/go-demo-3 -d helm

# Useful if publishing
```

```
Successfully packaged chart and saved it to: helm/go-demo-3-0.0.1.tgz
```

## Installing

```bash
helm inspect values helm/go-demo-3
```

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

```bash
# If NOT minishift
HOST="go-demo-3.$LB_IP.xip.io"

# If minishift
HOST="go-demo-3-go-demo-3.$(minishift ip).nip.io"

echo $HOST
```

```
jenkins.192.168.99.100.xip.io
```

```bash
# If NOT minishift
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set ingress.host=$HOST

# No Ingress with minishift
```

```
NAME:   go-demo-3
LAST DEPLOYED: Fri May 25 14:40:31 2018
NAMESPACE: go-demo-3
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)    AGE
go-demo-3-db  ClusterIP  None            <none>       27017/TCP  1s
go-demo-3     ClusterIP  100.68.193.213  <none>       8080/TCP   1s

==> v1beta2/Deployment
NAME       DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
go-demo-3  3        3        3           0          1s

==> v1beta2/StatefulSet
NAME          DESIRED  CURRENT  AGE
go-demo-3-db  3        0        1s

==> v1beta1/Ingress
NAME       HOSTS                           ADDRESS  PORTS  AGE
go-demo-3  go-demo-3.18.222.53.124.xip.io  80       1s

==> v1/Pod(related)
NAME                        READY  STATUS             RESTARTS  AGE
go-demo-3-6f9bf6687c-77wgf  0/1    ContainerCreating  0         1s
go-demo-3-6f9bf6687c-97qdh  0/1    ContainerCreating  0         1s
go-demo-3-6f9bf6687c-sshbc  0/1    ContainerCreating  0         1s

==> v1/ServiceAccount
NAME          SECRETS  AGE
go-demo-3-db  1        1s

==> v1beta1/Role
NAME          AGE
go-demo-3-db  1s

==> v1beta1/RoleBinding
NAME          AGE
go-demo-3-db  1s


NOTES:
1. Wait until the applicaiton is rolled out:
  kubectl -n go-demo-3 rollout status deployment go-demo-3

2. Test the application by running these commands:
  curl http://go-demo-3.18.222.53.124.xip.io/demo/hello
```

```bash
# If minishift
oc -n go-demo-3 create route edge \
    --service go-demo-3 \
    --insecure-policy Allow

kubectl -n go-demo-3 \
    rollout status deployment go-demo-3
```

```
Waiting for rollout to finish: 0 of 3 updated replicas are available...
Waiting for rollout to finish: 1 of 3 updated replicas are available...
Waiting for rollout to finish: 2 of 3 updated replicas are available...
deployment "go-demo-3" successfully rolled out
```

```bash    
curl http://$HOST/demo/hello
```

```
hello, world!
```

```bash
kubectl -n go-demo-3 \
    describe deployment go-demo-3
```

```
Name:                   go-demo-3
Namespace:              go-demo-3
CreationTimestamp:      Fri, 25 May 2018 03:18:18 +0200
Labels:                 app=go-demo-3
                        chart=go-demo-3-0.0.1
                        heritage=Tiller
                        release=go-demo-3
Annotations:            deployment.kubernetes.io/revision=1
Selector:               app=go-demo-3,release=go-demo-3
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=go-demo-3
           release=go-demo-3
  Containers:
   api:
    Image:  vfarcic/go-demo-3:latest
    Port:   <none>
    Limits:
      cpu:     200m
      memory:  20Mi
    Requests:
      cpu:      100m
      memory:   10Mi
    Liveness:   http-get http://:8080/demo/hello delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/demo/hello delay=0s timeout=1s period=1s #success=1 #failure=3
    Environment:
      DB:    go-demo-3-db
    Mounts:  <none>
  Volumes:   <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   go-demo-3-5764f6465c (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set go-demo-3-5764f6465c to 3
```

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0 \
    --reuse-values
```

```
Release "go-demo-3" has been upgraded. Happy Helming!
LAST DEPLOYED: Fri May 25 14:42:53 2018
NAMESPACE: go-demo-3
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/Ingress
NAME       HOSTS                           ADDRESS           PORTS  AGE
go-demo-3  go-demo-3.18.222.53.124.xip.io  a2aa563a6600a...  80     2m

==> v1/Pod(related)
NAME                        READY  STATUS             RESTARTS  AGE
go-demo-3-6f9bf6687c-77wgf  1/1    Running            2         2m
go-demo-3-6f9bf6687c-97qdh  1/1    Running            2         2m
go-demo-3-6f9bf6687c-sshbc  1/1    Running            2         2m
go-demo-3-7bccf8b78f-slrdk  0/1    ContainerCreating  0         1s
go-demo-3-db-0              2/2    Running            0         2m
go-demo-3-db-1              2/2    Running            0         1m
go-demo-3-db-2              2/2    Running            0         1m

==> v1/ServiceAccount
NAME          SECRETS  AGE
go-demo-3-db  1        2m

==> v1beta1/Role
NAME          AGE
go-demo-3-db  2m

==> v1beta1/RoleBinding
NAME          AGE
go-demo-3-db  2m

==> v1/Service
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)    AGE
go-demo-3-db  ClusterIP  None            <none>       27017/TCP  2m
go-demo-3     ClusterIP  100.68.193.213  <none>       8080/TCP   2m

==> v1beta2/Deployment
NAME       DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
go-demo-3  3        4        1           3          2m

==> v1beta2/StatefulSet
NAME          DESIRED  CURRENT  AGE
go-demo-3-db  3        3        2m


NOTES:
1. Wait until the applicaiton is rolled out:
  kubectl -n go-demo-3 rollout status deployment go-demo-3

2. Test the application by running these commands:
  curl http://go-demo-3.18.222.53.124.xip.io/demo/hello
```

```bash
kubectl -n go-demo-3 \
    describe deployment go-demo-3
```

```
Name:                   go-demo-3
Namespace:              go-demo-3
CreationTimestamp:      Thu, 24 May 2018 13:58:46 +0200
Labels:                 app=go-demo-3
                        chart=go-demo-3-0.0.1
                        heritage=Tiller
                        release=go-demo-3
Annotations:            deployment.kubernetes.io/revision=2
Selector:               app=go-demo-3,release=go-demo-3
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=go-demo-3
           release=go-demo-3
  Containers:
   api:
    Image:  vfarcic/go-demo-3:1.0
    Port:   <none>
    Limits:
      cpu:     200m
      memory:  20Mi
    Requests:
      cpu:      100m
      memory:   10Mi
    Liveness:   http-get http://:8080/demo/hello delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/demo/hello delay=0s timeout=1s period=1s #success=1 #failure=3
    Environment:
      DB:    go-demo-3-db
    Mounts:  <none>
  Volumes:   <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   go-demo-3-7bccf8b78f (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled up replica set go-demo-3-6f9bf6687c to 3
  Normal  ScalingReplicaSet  28s   deployment-controller  Scaled up replica set go-demo-3-7bccf8b78f to 1
  Normal  ScalingReplicaSet  25s   deployment-controller  Scaled down replica set go-demo-3-6f9bf6687c to 2
  Normal  ScalingReplicaSet  25s   deployment-controller  Scaled up replica set go-demo-3-7bccf8b78f to 2
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled down replica set go-demo-3-6f9bf6687c to 1
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled up replica set go-demo-3-7bccf8b78f to 3
  Normal  ScalingReplicaSet  20s   deployment-controller  Scaled down replica set go-demo-3-6f9bf6687c to 0
```

```bash
kubectl -n go-demo-3 \
    rollout status deployment go-demo-3
```

```
deployment "go-demo-3" successfully rolled out
```

```bash
curl http://$HOST/demo/hello
```

```
hello, world!
```

```bash
helm delete go-demo-3 --purge

kubectl delete ns go-demo-3
```

## Helm vs OpenShift Templates

TODO: Write

## What Now?

TODO: Write

* Need to store Helm charts somewhere
* Need to solve the permissions