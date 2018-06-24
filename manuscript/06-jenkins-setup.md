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
- [ ] Publish on LeanPub.co

# Setting Up Jenkins

TODO: Write

## Creating A Cluster And Retrieving Its IP

You already know what are the first steps. Create a new cluster or reuse the one you dedicated to the exercises.

We'll start by going to the local copy of the *vfarcic/k8s-specs* repository and making sure that we have the latest revision.

I> All the commands from this chapter are available in the [05-chart-museum.sh](https://gist.github.com/e0657623045b43259fe258a146f05e1a) Gist.

```bash
cd k8s-specs

git pull
```

The requirements are the same as those from the previous chapter. The only difference is that I will assume that you'll store the IP of the cluster or the external load balancer as the environment variable `LB_IP`.

For your convenience, the Gists and the specs are available below. Please note that the are the same as those we used in the previous chapter with the addition of `export LB_IP` command.

* [docker4mac-ip.sh](https://gist.github.com/66842a54ef167219dc18b03991c26edb): **Docker for Mac** with 3 CPUs, 3 GB RAM, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to `127.0.0.1`.
* [minikube-ip.sh](https://gist.github.com/df5518b24bc39a8b8cca95cc37617221): **minikube** with 3 CPUs, 3 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, with **tiller**, and with `LB_IP` variable set to the VM created by minikube.
* [kops-ip.sh](https://gist.github.com/7ee11f4dd8a130b51407582505c817cb): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP retrieved by pinging ELB's hostname. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).
* [minishift-ip.sh](https://gist.github.com/fa902cc2e2f43dcbe88a60138dd20932): **minishift** with 3 CPUs, 3 GB RAM, with version 1.16+, with **tiller**, and with `LB_IP` variable set to the VM created by minishift.
* [gke-ip.sh](https://gist.github.com/3e53def041591f3c0f61569d49ffd879): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-2 (2 CPUs, 1.8 GB RAM) nodes (one in each zone), and with **nginx Ingress** controller running on top of the "standard" one that comes with GKE, with **tiller**, and with `LB_IP` variable set to the IP of the external load balancer created when installing nginx Ingress. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files and Helm Charts if you prefer NOT to install nginx Ingress.

Now we're ready to install Jenkins.

## Running Jenkins

We'll need a domain which we'll use to set Ingress' hostname and through which we'll be able to open Jenkins UI. We'll continue using *nip.io* service to generate domains. Just as before, remember that this is only a temporary solution and that you should configure "real" domains with the IP of your external load balancer.

```bash
JENKINS_ADDR="jenkins.$LB_IP.nip.io"

echo $JENKINS_ADDR
```

The output of the latter command should provide a visual confirmation that the address we'll use for Jenkins looks OK. In my case, it is `jenkins.52.15.140.221.nip.io`.

W> ## A note to minishift users
W>
W> Helm will try to install Jenkins Chart with the process in a container running as user 0. By default, that is not allowed in OpenShift. We'll skip discussing the best approach to correct the permissions in OpenShift. I'll assume you already know how to set the permissions on the per-Pod basis. Instead, we'll do the simplest fix. Please execute the command that follows to allow the creation of restricted Pods to run as any user.
W>
W> `oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'`

We'll start exploring the steps we'll need to run Jenkins in a Kubernetes cluster by executing the same `helm install` command we used in the previous chapters. It won't provide everything we need, but it will be a good start. We'll improve the process throughout the rest of the chapter with the goal of having a fully automated Jenkins installation process. We might not be able to accomplish our goal 100%. Or, we might reach the conclusion that full automation is not worth the trouble. Nevertheless, we'll use the installation from the [Packaging Kubernetes Applications](#chartmuseum) as the base and see how far we can go in our quest for full automation.

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$JENKINS_ADDR
```

Jenkins Helm Chart comes with one big drawback. It uses ClusterRoleBinding to binding with the ServiceAccount `jenkins`. As a result, we cannot fine-tune permissions. We cannot define that, for example, Jenkins can operate only in the `jenkins` Namespace. Instead, the permissions we bind will apply to all Namespaces. That, as you can imagine, is a huge security risk. Jenkins could, for example, remove all the Pods from `kube-system`. Even if we have full trust in all the people working in our company, and we're sure that no one will try to define any malicious Pipeline, having cluster-wide permissions introduces a possible risk of doing something wrong by accident.

I made a [PR](https://github.com/kubernetes/charts/pull/6190) that should allow us to switch from ClusterRoleBinding to RoleBinding. I'll update the book once the PR is merged. Until than, we'll remedy the issue with a workaround.

First, we'll remove the ClusterRoleBinding created through the Chart.

```bash
kubectl delete clusterrolebinding \
    jenkins-role-binding
```

Next, we'll create a RoleBinding. It'll be the same as the ClusterRoleBinding we just removed with only the `kind` being different.

```bash
cat helm/jenkins-patch.yml

kubectl apply -n jenkins \
    -f helm/jenkins-patch.yml
```

I am intentionally not providing more details since this is only a workaround until the PR is merged. Also, I assume that you already know how Roles, RoleBindings, and ServiceAccounts work and that you'll be able to deduce the logic just by exploring the definitions.

Finally, we'll confirm that Jenkins is rolled out.

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

The latter command will wit until `jenkins` Deployment rolls out. Its output is as follows.

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "jenkins" successfully rolled out
```

W> ## A note to minishift users
W>
W> OpenShift requires Routes to make services accessible outside the cluster. To make things more complicated, they are not part of "standard Kubernetes" so we'll need to create one using `oc`. Please execute the command that follows.
W> 
W> `oc -n jenkins create route edge --service jenkins --insecure-policy Allow --hostname $JENKINS_ADDR`
W> 
W> That command created an `edge` Router tied to the `jenkins` Service. Since we do not have SSL certificates for HTTPS communication, we also specified that it is OK to use insecure policy which will allow us to access Jenkins through plain HTTP. Finally, the last argument defined the address through which we'd like to access Jenkins UI.

Now that Jenkins is up-and-running, we can open it in your favourite browser.

```bash
open "http://$JENKINS_ADDR"
```

T> ## A note to Windows users
T> 
T> Git Bash might not be able to use the `open` command. If that's the case, replace the `open` command with `echo`. As a result, you'll get the full address that should be opened directly in your browser of choice.

Since this is the first time we're accessing this Jenkins instance, we need to login first. Just as before, the password is stored in the Secret `jenkins`, under `jenkins-admin-password`. So, we'll query the secret to find out the password.

```bash
JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS
```

The output of the latter command should be a random string. As an example, I got `Ucg2tab4FK`. Please copy it, return to the Jenkins login screen opened in your browser, and use it to authenticate. We did not retrieve the username since it is hard-coded to *admin*.

We'll leave this admin user as-is, since we won't explore authentication methods. When running Jenkins "for real", you should install a plugin that provides a "real" authentication mechanism and configure Jenkins to use it instead. That could be LDAP, Google or GitHub authentication, and many other providers. For now, we'll continue using *admin* as the only god-like user.

Now that we got Jenkins up-and-running, we'll create a Pipeline which we can use to test our setup.

## Using Pods to Run Tools

We won't explore how to write a continuous deployment pipeline in this chapter. That is reserved for the one that follows. Right now, we are only concerned whether our Jenkins setup is working as expected. We need to know whether Jenkins can interact with Kubernetes, whether we can run the tools we need as Pods, and whether they can be spun across different Namespaces. On top of those, we still need to solve the issue with building container images. Since we already established that it is not a good idea to mount a Docker socket, nor to run containers in privileged more, we need to find a valid alternative. In parallel to solving those and other challenges we'll encounter, we cannot loose focus from automation. Everything we do has to be converted into automated setup, unless we make a conscious decision that it is not worth the trouble.

I'm jumping ahead of myself by bombing you with too many things. So, we'll start with a simple requirement, and build on top of it. That requirement is to run different tools packaged as containers inside a Pod.

Please go back to Jenkins UI an dclick the *New Item* link in the left-hand menu. Type *my-k8s-job* in the *item name* field, select *Pipeline* as the job type, and click the *OK* button.

We created a new Pipeline job which does not yet do anything. Our next step is to write a very simple Pipeline that will validate that we can indeed use Jenkins to spin up a Pod with the containers we need.

Please click the *Pipeline* tab and you'll be presented with the *Pipeline Script* field. Write the script that follows.

```groovy
podTemplate(
    label: "kubernetes",
    containers: [
        containerTemplate(name: "maven", image: "maven:alpine", ttyEnabled: true, command: "cat"),
        containerTemplate(name: "golang", image: "golang:alpine", ttyEnabled: true, command: "cat")
    ]
) {
    node("kubernetes") {
        container("maven") {
            stage("build") {
                sh "mvn --version"
            }
            stage("unit-test") {
                sh "java -version"
            }
        }
        container("golang") {
            stage("deploy") {
                sh "go version"
            }
        }
    }
}
```

I> If you prefer to copy and paste, the job is available in the [my-k8s-job.groovy Gist](https://gist.github.com/2cf872c3a9acac51409fbd5a2789cb02).

As a reminder, the script defines a Pod template with two container. One is based on the `maven` and the other on the `golang` image. Further down, we defined that Jenkins should use that template as the `node`. Inside it, we are using the `maven` container to execute two stages. One will return Maven version and the other will output Java version. Further down, we switch to the `golang` container only to output Go version.

This job is very simple and does not do anything related to our continuous deployment processes. Nevertheless, it should be enough to provide a rudimentary validation that we can use Jenkins to create a Pod, that we can switch from one container to another, and that we can execute commands inside them.

Don't forget to click the *Save* button before proceeding.

If the job we created looks familiar, that's because it is the same as the one we used in the [Enabling Process Communication With Kube API Through Service Accounts](#sa) chapter. Since our goal is to confirm that our current Jenkins setup can create the Pods, that job is as good as any other to validate that claim.

Please click the *Open Blue Ocean* link from the left-hand menu. You'll see the *Run* button in the middle of the screen. Click it. As a result, a row will appear with a new build. Click it to see the details.

The build is running and we should go back to the terminal window to confirm that the Pod is indeed created.

```bash
kubectl -n jenkins get pods
```

The output is as follows.

```
NAME                      READY STATUS            RESTARTS AGE
jenkins-c7f7c77b4-cgxx8   1/1   Running           0        5m
jenkins-slave-6hssz-250tw 0/3   ContainerCreating 0        16s
```

We can see that there are two Pods in the `jenkins` Namespace. One is hosting Jenkins itself, while the other was created when we run the Jenkins build. You'll notice that even though we defined two containers, we are seeing three. The additional container was added automatically to the Pod and it's used to establish communication with Jenkins.

In your case, the status of the `jenkins-slave` Pod might be different. Besides `ContainerCreating`, it could be `Running`, `Terminating`, or you might not even see it. It all depends on how much time passed between initiating the build and retrieving the Pods in the `jenkins` Namespace.

What matters is the process. When we initiated a new build, Jenkins created the Pod in the same Namespace. Once all the containers are up-and-running, Jenkins will execute the steps we defined through the Pipeline script. When finished, the Pod will be removed, freeing resources for other processes.

Please go back to Jenkins UI and wait until the build is finished.

We proved that we can run a very simple job. We're yet to discover whether we can do more complicated operations.

On the first look, the script we wrote looks OK. However, I'm not happy with the way we defined `podTemplate`. Wouldn't it be better if we could use the same YAML format for defining the template as if we'd define a Pod in Kubernetes? Fortunatelly, [jenkins-kubernetes-plugin](https://github.com/jenkinsci/kubernetes-plugin) recently added that feature. So, we'll try to rewrite the script to better match Pod definitions.

We'll use the rewriting opportunity to replace `maven` with the tools we are more likely to use with a CD pipeline for the *go-demo-3* application. We still need `golang`. On top of it, we should be able to run `kubectl`, `helm`, and, `openshift-client`. The latter is required only if you're using OpenShift, and you are free to remove it if that's not your case.

Let's open `my-k8s-job` configuration screen and modify the job.

```bash
open "http://$JENKINS_ADDR/job/my-k8s-job/configure"
```

Please click the *Pipeline* tab and replace the script with the one that follows.

```groovy
podTemplate(label: "kubernetes", yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version"
            }
        }
    }
}
```

I> If you prefer to copy and paste, the job is available in the [my-k8s-job-yaml.groovy Gist](https://gist.github.com/a1b3b36c68323aea161d7364b1231de2).

This time, the format of the script is different. Instead of the `containers` argument inside `podTemplate`, now we have `yaml`. Inside it is Kubernetes Pod definition just as if we'd define a standard Kubernetes resource.

The rest of the script follow the same logic as before. The only difference is that, this time, we are using the tools were are more likely to need in our yet-to-be-define *go-demo-3* Pipeline. We'll output `kubectl`, `oc`, `go`, and `helm` versions.

Don't forget to click the *Save* button.

Next, we'll run a build of the job with the new script.

```bash
open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"
```

Please click the *Run* button, followed with a click on the row with the new build.

I have an assignment for you while the build is running. Try to find out what is wrong with our current setup without looking at the results of the build. You have approximately six minutes to complete the task. Proceed only if you know the answer or if you gave up.

Jenkins will create a Pod in the same Namespace. That Pod will have five containers, four of which will host the tools we specified in the `podTemplate`, and the fifth will be injected by Jenkins as a way to establish the communication between Jenkins and the Pod. We can confirm that by listing the Pods in the `jenkins` Namespace.

```bash
kubectl -n jenkins get pods
```

The output is as follows.

```
NAME                      READY STATUS            RESTARTS AGE
jenkins-c7f7c77b4-cgxx8   1/1   Running           0        16m
jenkins-slave-qnkwc-s6jfx 0/5   ContainerCreating 0        19s
```

So far, everything looks OK. Containers are being created. The `jenkins-slave-...` Pod will soon change its state to `Running`, and Jenkins will try to execute all the steps defined in the script.

Let's take a look at the build from Jenkins' UI.

After a while, the build will reach the `helm` stage. Click it and you'll see the output similar to the one that follows.

```
[my-k8s-job] Running shell script

+ helm version

Client: &version.Version{SemVer:"v2.8.2", GitCommit:"a80231648a1473929271764b920a8e346f6de844", GitTreeState:"clean"}
```

You'll notice that the build will hang at this point. After a few minutes, you might think that it will hang forever. It won't. Approximately five minutes later, the output of the step in the `helm` stage will change to the one that follows.

```
[my-k8s-job] Running shell script

+ helm version

Client: &version.Version{SemVer:"v2.8.2", GitCommit:"a80231648a1473929271764b920a8e346f6de844", GitTreeState:"clean"}

EXITCODE   0Error: cannot connect to Tiller

script returned exit code 1
```

W> ## A note to Docker For Mac/Windows users
W>
W> Even though Docker for Mac/Windows supports RBAC, it allows any internal process inside containers to communicate with Kube API. Unlike with other Kubernetes flavors, you will not see the same error. The build will complete successfully.

Our build could not connect to `Tiller`. Helm kept trying for five minutes. It reached it's pre-defined timeout and gave up.

If what we learned in the [Enabling Process Communication With Kube API Through Service Accounts](#sa) chapter is still fresh in your mind, that outcome should not be a surprise. We did not set ServiceAccount that would allow Helm running inside a container to communicate with Tiller. To make the situation more complicated, it is questionable whether we should allow Helm running in a container to communicate with Tiller running in `kube-system`. That would be a huge security risk that would allow anyone with access to Jenkins to gain access to any part of the cluster. It would defy one of the big reasoner why we're using Namespaces. We'll explore this, and a few other problems next. For now, we'll confirm that Jenkins removed the Pod created by the failed build.

```bash
kubectl -n jenkins get pods
```

The output is as follows.

```
NAME                    READY STATUS  RESTARTS AGE
jenkins-c7f7c77b4-cgxx8 1/1   Running 0        42m
```

The `jenkins-slave-...` Pod is gone and our system is restored to the state before the build started.

## Running Builds In Different Namespaces

One of the big disadvantages of the script we used inside the `my-k8s-job` is that it runs in the same Namespace as Jenkins. We should separate builds from Jenkins and thus ensure that they do not affect its stability.

We can create a system where each application has two namespaces; one for testing and the other for production. We can define quotas, limitations, and other things we are used to defining on the Namespace level. As a result, we can guarantee that testing an application will not affect the production release as well as to separate one application from another. At the same time, we'll reduce the chance that one team will accidentally mess up with the applications of the other. Our end-goal is to be secure without limiting the ability of our teams. By giving them freedom in their own Namespace, we can be secure without impacting team's performance and its ability to move forward without depending on other teams.

Let's go back to the job configuration screen.

```bash
open "http://$JENKINS_ADDR/job/my-k8s-job/configure"
```

Please click the *Pipeline* tab and replace the script with the one that follows.

```groovy
podTemplate(
    label: "kubernetes",
    namespace: "go-demo-3-build",
    serviceAccount: "build",
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version --tiller-namespace go-demo-3-build"
            }
        }
    }
}
```

I> Getting spoiled with Gist and still do not want to type? The job is available in the [my-k8s-job-ns.groovy Gist](https://gist.github.com/ced1806af8e092d202942a79e81d5ba9).

The only difference between that job and the one we used before is in `podTemplate` arguments `namespace` and `serviceAccount`. This time we specified that the Pod should be created in the `go-demo-3-build` Namespace and that it should use the ServiceAccount `build`. If everything works as expected, the instruction to run Pods in a different Namespace should provide the separation we crave and the ServiceAccount will provide the permissions the Pod might need when interacting with Kube API or other Pods.

Please click the *Save* button to persist the change of the Job definition.

Next, we'll open Jenkins' BlueOcean screen and check whether we can run builds based on the modified Job.

```bash
open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"
```

Please click the *Run* button, and select the row with the new build. You'll see the same `Waiting for next available executor` message we've already saw in the past. Jenkins needs to wait until a Pod is created and is fully operational. However, this time the wait will be longer since Jenkins will not be able to create the Pod.

The fact that we defined that the Job should operate in a different Namespace will do us no good if such a Namespace does not exist. Even if we create the Namespace, we specified that it should use the ServiceAccount `build`. So, we need to create both. However, that's not where our troubles stop. There are a few other problems we'll need to solve but, for now, we'll concentrate on the missing Namespace.

Please click the *Stop* button in the top-right corner or the build. That will abort the futile attempts and we can proceed and make the necessary changes that will allow us to run a build of that Job in the `go-demo-3-build` Namespace.

As a minimum, we'll have to make sure that the `go-demo-3-build` Namespace exists, and that it has the ServiceAccount `build` which is bound to a Role with sufficient permissions. While we're defining the Namespace, we should probably define a LimitRange and a ResourceQuota. Fortunately, we already did all that in the previous chapters and we already have a YAML file that does just that.

Let's take a quick look at the `build-ns.yml` file available in the *go-demo-3* repository.

```bash
cat ../go-demo-3/k8s/build-ns.yml
```

We won't go through the details behind that definition since we already explored it in the previous chapters. Instead, we'll imagine that we are cluster administrators and that the team in charge of *go-demo-3* asked us to `apply` that definition.

```bash
kubectl apply \
    -f ../go-demo-3/k8s/build-ns.yml \
    --record
```

The output shows the resources defined in that YAML were created.

Even though we won't build a continuous deployment pipeline just yet, we should be prepared for running our application in production. Since it should be separated from the testing Pods and releases under test, we'll create another Namespace that will be used exclusively for *go-demo-3* production releases. Just as before, we'll simply `apply` the definition stored in *go-demo-3* repository.

```bash
cat ../go-demo-3/k8s/prod-ns.yml

kubectl apply \
    -f ../go-demo-3/k8s/prod-ns.yml \
    --record
```

We're missing one more thing before the part of the setup related to Kubernetes resources is finished.

So far, we have a RoleBinding inside the `jenkins` Namespace that provide Jenkins with enough permissions to create Pods in the same Namespace. However, our latest Pipeline wants to create Pods in the `go-demo-3-build` Namespace. Since we are not using ClusterRoleBinding that would provide cluster-wide permissions, we'll need to create a RoleBinding in `go-demo-3-build` as well. Since that is specific to the application, the definition is in its repository and it should be executed by the administrator of the cluster, just as the previous two.

Let's take a quick look at the definition.

```bash
cat ../go-demo-3/k8s/jenkins.yml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-role-binding
  namespace: go-demo-3-build
  labels:
    app: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
```

The binding is relatively straight forward. It will bind the ServiceAccount in the `jenkins` Namespace with the ClusterRole `cluster-admin`. We will reduce those permissions in the next chapter. For now, just remember that we're creating a RoleBinding in the `go-demo-3-build` Namespace and that it'll give ServiceAccount `jenkins` in the `jenkins` Namespace full permissions in the `go-demo-3-build` Namespace.

Let's `apply` this last Kubernetes definition before we proceed with changes in Jenkins itself.

```bash
kubectl apply \
    -f ../go-demo-3/k8s/jenkins.yml \
    --record
```

The next issue we'll have to solve is communication between Jenkins and the Pods spun during builds. Let's take a quick look at the configuration screen.

```bash
open "http://$JENKINS_ADDR/configure"
```

If you scroll down to the *Jenkins URL* field of the *Kubernetes* section, you'll notice that it is set to *http://jenkins:8080*. Similarly, *Jenkins tunnel* is *jenkins-agent:50000*. The two values correspond to the names of the Services through which agent Pods will establish communication with the master and vice versa. As you hopefully already know, using only the name of a Service allows communication between Pods in the same Namespace. If we'd like to extend that communication across different Namespaces, we need to use the *[SERVICE_NAME].[NAMESPACE]* format. That way, agent Pods will know where to find the Jenkins Pod, no matter where they're running. That way, the communication will be successful even if Jenkins is in the `jenkins` Namespace and the agent Pods are in `go-demo-3-build`.

Let's change the config.

Please scroll to the *Kubernetes* section, and change the value of the *Jenkins URL* field to *http://jenkins.jenkins:8080*. Similarly, change the *Jenkins tunnel* field to *jenkins-agent.jenkins:50000*. Don't forget to click the *Save* button.

![Figure 6-TODO: Jenkins configuration screen with Kubernetes plugin configured for cross-Namespace usage](images/ch06/jenkins-configure-k8s-ns.png)

Our troubles are not yet over. We need to rethink our Helm strategy.

We have Tiller running in the `kube-system` Namespace. However, our agent Pods running in `go-demo-3-build` do not have permissions to access it. We could extend the permissions but that would allow the Pods in that Namespace to gain almost complete control over the whole cluster. Unless your organization is very small, that is often not acceptable. Instead, we'll deploy another Tiller instance in the `go-demo-3-build` Namespace and tie it to the ServiceAccount `build`. That will give the new tiller the same permissions in the `go-demo-3` and `go-demo-3-build` Namespaces. It'll be able to do anything in those, but nothing else.

That strategy has a downside. It is more expensive to run multiple Tillers than to run one. However, if we organize them per teams in our organization by giving each a separate Tiller instance, we can allow them full freedom within their Namespaces without affecting others. On top of that, remember that Tiller will be removed in Helm v3, so this it only a temporary fix.

```bash
helm init --service-account build \
    --tiller-namespace go-demo-3-build
```

The output ends with the `Happy Helming!` message letting us know that Tiller resources are installed. To be on the safe side, we'll wait until it rolls out.

```bash
kubectl -n go-demo-3-build \
    rollout status \
    deployment tiller-deploy
```

Now we are ready to re-run the job.

```bash
open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"
```

Please click the *Run* button followed with a click to the row of the new build.

While waiting for the build to start, we'll go back to the terminal and confirm that a new `jenkins-slave-...` Pod is created.

```bash
kubectl -n go-demo-3-build \
    get pods
```

The output should be as follows.

```
NAME              READY STATUS  RESTARTS AGE
jenkins-slave-... 5/5   Running 0        36s
tiller-deploy-... 1/1   Running 0        3m
```

If you do not see the `jenkins-slave` and `tiller-deploy` Pod, you might need to wait for a few moments, and retrieve the Pods again.

Once the state of the `jenkins-slave` Pod is `Running`, we can go back to Jenkins UI and observe that it progresses until the end and it turns to green.

![Figure 6-TODO: Jenkins job for testing tools](images/ch06/jenkins-tools-build.png)

We managed to run the tools in the separate Namespace. However, we still need to solve the issue of building container images.

## Creating Docker Nodes

We already discussed that mounting a Docker socket is a bad idea, due to security risks. Running Docker in Docker would require privileged access and is almost as unsafe and Docker socket. On top of that, both options have other downsides. Using Docker socket would introduce processes unknown to Kubernetes and could interfere with it's scheduling capabilities. Running Docker in Docker could mess up with networking. There are other reasons why both options are not good, so we need to look for an alternative.

Recently, new projects spun up attempting to help building container images. Good examples are [img](https://github.com/genuinetools/img), [orca-build](https://github.com/cyphar/orca-build), [umoci](https://github.com/openSUSE/umoci), [buildah](https://github.com/projectatomic/buildah), [FTL](https://github.com/GoogleCloudPlatform/runtimes-common/tree/master/ftl), and [Bazel rules_docker](https://github.com/bazelbuild/rules_docker). They all have serious downsides. While they might help, none of them is a truly good solution which I'd recommend as a replacement for building container images with Docker.

[kaniko](https://github.com/GoogleContainerTools/kaniko) has a potential to become a preferable way for building container images. It does not require Docker nor any other node dependency. It can run as a container and is likely to become a valid alternative one day. However, that day is not today (June 2018). It is still green, unstable, and unproven.

All in all, Docker is still our best option for building container images, but not inside a Kubernetes cluster. That means that we need to build our images in a VM outside Kubernetes.

How are we going to create a VM for building container images? Are we going to have a static VM potentially wasting our resources?

The answer to those questions depends on the hosting provider you're using. If it allows dynamic creation of VMs, we can create them when we need them, and destroy them when we don't. If that's not an option, we need to fall back to a dedicated machine for building images.

I could not explore all the methods for creating VMs, so I limited the scope to three combinations. We'll explore how to create a static VM in cases when dynamic provisioning is not an option. If you're using Docker For Mac or Windows, minikube, and minishift, that is your best bet. We'll use Vagrant but the same principles can be applied to any other, often on-prem, virtualization technology.

On the other hand, if you're using a hosting provider that does support dynamic provisioning of VMs, you should leverage that to your benefit to create them when needed, and destroy them when not. I'll show you the examples with AWS EC2 and Google Cloud Engine (GCE). If you use something else (e.g., Azure, DigitalOcean), the principle will be the same, even though the implementation might vary greatly. The major question is whether Jenkins supports your provider. If it does, you can use a plugin that will take care of creating and destroying nodes. Otherwise, you might need to extend your Pipeline script to use provider's API to spin up new nodes. In that case, you might want to evaluate whether such an option is worth the trouble. Remember, if everything else fails, having a static VM dedicated to building container images will always work.

Even if you choose to build your container images in a different way, it is still a good idea to master connecting external VMs to Jenkins. There's often a use-case that cannot (or shouldn't) be accomplished inside a Kubernetes cluster. You might need execute some of the steps in Windows nodes. Maybe there are processes that shouldn't run inside containers. Or, maybe you need to connect Android devices to your Pipelines. No matter the use-case, knowing how to connect external agents to Jenkins is important. So, building container images is not necessarily the only reason for having external agents (nodes), and I strongly suggest exploring the sections that follow, even if you don't think it's useful at this moment.

Choose the section that best fits your use case. Or, even better, try all three of them.

### Creating a Container Build VM with Vagrant and VirtualBox

I> This section is appropriate for those using **Docker for Mac or Windows**, **minikube**, **minishift**, or anyone else planning to use static nodes as agents.

We'll use [Vagrant](https://www.vagrantup.com/) to create a local VM. Please install it if you do not have it already.

The *Vagrantfile* we'll use is already available inside the [vfarcic/k8s-specs](https://github.com/vfarcic/k8s-specs). It's in the *cd/docker-build* directory, so let's go there and take a quick look at the definition.

```bash
cd cd/docker-build

cat Vagrantfile
```

The output of the latter command is as follows.

```ruby
# vi: set ft=ruby :
 
Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/xenial64"

    config.vm.define "docker-build" do |node|
      node.vm.hostname = "docker-build"
      node.vm.network :private_network, ip: "10.100.198.200"
      node.vm.provision :shell, inline: "apt update && apt install -y docker.io && apt install -y default-jre"
    end
end
```

That Vagrantfile is very simple. Even if you never used Vagrant, you should have no trouble understanding what it does.

We're defiing a VM called `docker-build` and we're assigning it a static IP `10.100.198.200`. The `node.vm.provision` will install Docker and JRE. The latter is required for establishing the connection between Jenkins and this soon-to-be VM.

Next, we'll create the VM based on that Vagrantfile definition.

```bash
vagrant up
```

Now that the VM is up and running, we can go back to Jenkins and add it as a new agent node.

```bash
open "http://$JENKINS_ADDR/computer/new"
```

Please type *docker-build* as the *Node name*, select *Permanent Agent*, and click the *OK* button.

![Figure 6-TODO: Jenkins screen for adding new nodes/agents](images/ch06/jenkins-new-node.png)

You are presented with a node configuration screen.

Please type *2* as *# of executors*. That will allow us to run up to two processes inside this agent. To put it differently, up to two builds will be able to use it in parallel. If there are more than two, the additional builds will wait in a queue until one of the executors is released. Depending on the size of your organization, you might want to increase the number of executors or add more nodes. As a rule of thumb, you should have one executor per CPU. In our case, we should be better of with one executor, but we'll roll with two mostly as a demonstration.

Next, we should set the *Remote root directory*. That's the place on the node's file system where Jenkins will store the state of the builds. Please set it to */tmp* or choose any other directory. Just remember that Jenkins will not create it so the folder must already exist on the system.

We should set labels that define the machine we're going to use as a Jenkins agent. It is always a good idea to be descriptive, even if we're sure that we will use only one of the labels. Since that node is based on Ubuntu Linux distribution and it has Docker, our labels will be *docker ubuntu linux*. Please type the three into the *Labels* field.

There are a couple of methods we can use to establish the communication between Jenkins and the newly created node. Since it's Linux, the easiest, and probably the best method is SSH. Please select *Launch slave agents via SSH* as the *Launch Method*.

The last piece of information we'll define, before jumping into credentials is the *Host*. Please type *10.100.198.200*.

We're almost finished. The only thing left is to create a set of credentials and assign them to this agent.

Please click *Add* dropdown next to *Credentials* and select *Jenkins*.

Once in the credentials popup screen, select *SSH Username with private key* as the *Kind*, type *vagrant* as the *Username*, and select *Enter directly* as the *Private Key*.

We'll have to go back to the terminal to retrieve the private key created by Vagrant when it generated the VM.

```bash
cat .vagrant/machines/docker-build/virtualbox/private_key
```

Please copy the output, go back to Jenkins UI, and paste it to the *Key* field. Type *docker-build* as the *ID*, and click the *Add* button.

The credentials are generated and we are back in the agent configuration screen. However, Jenkins did not pick the newly credentials automatically, we we'll need to select *vagrant* in the *Credentials* drop-down list. Finally, since we used a private key, we'll skip verification by selecting *Not verifying Verification Strategy* as the *Host Key Verification Strategy*.

![Figure 6-TODO: Jenkins node/agent configuration screen](images/ch06/jenkins-node-config.png)

Do not forget to click the *Save* button to persist the agent information.

You'll be redirected back to the Nodes screen. Please refresh the screen if the newly created agent is red.

![Figure 6-TODO: Jenkins nodes/agents screen](images/ch06/jenkins-nodes.png)

All that's left is to go back to the k8s-specs root directory.

```bash
cd ../../
```

We'll use the newly created agent soon. Feel free to skip the next two sections if this was the way you're planning to create agents.

### AWS

I> This section is appropriate for those using **AWS**.

We'll use [Jenkins EC2 plugin](https://plugins.jenkins.io/ec2) to create agent nodes when needed and destroy them after a period of inactivity. The plugin is already installed. However, we'll need to configure it to use a specific Amazon Machine Image (AMI), so creating one is our first order of business.

Before we proceed, please make sure that the environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` are set. If you followed the instructions for setting up the cluster with kops, the environment variables are already defined in `source cluster/kops`.

We'll build the image with [Packer](https://www.packer.io/), so please make sure that it is installed in your laptop.

Packer definition we'll explore soon will require a security group. Please execute the command that follows to create one.

```bash
aws ec2 create-security-group \
    --description "For building Docker images" \
    --group-name docker \
    | tee cluster/sg.json
```

For convenience, we'll parse the output to retrieve `GroupId` and store it in an environment variable. Please install [jq](https://stedolan.github.io/jq/) if you don't have it already.

```bash
SG_ID=$(cat cluster/sg.json \
    | jq -r ".GroupId")

echo $SG_ID
```

The output of the latter command should be similar to the one that follows.

```
sg-5fe96935
```

Next, we'll store the security group `export` in a file so that we can easily retrieve it in the next chapters.

```bash
echo "export SG_ID=$SG_ID" \
    | tee -a cluster/docker-ec2
```

The security group we created is useless in its current form. We'll need to authorize it to allow communicaation on port `22` so that Packer can access it and execute provisioning.

```bash
aws ec2 \
    authorize-security-group-ingress \
    --group-name docker \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
```

We're done with the preparation steps and we can proceed to create the AMI.

Let's take a quick look at the Package definition we'll use.

```basdh
cat jenkins/docker-ami.json
```

The output is as follows.

```json
{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-2",
    "source_ami_filter": {
      "filters": {
        "virtualization-type": "hvm",
        "name": "*ubuntu-xenial-16.04-amd64-server-*",
        "root-device-type": "ebs"
      },
      "most_recent": true
    },
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "docker",
    "force_deregister": true
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sleep 15",
      "sudo apt-get clean",
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates nfs-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo add-apt-repository -y ppa:openjdk-r/ppa",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install -y openjdk-8-jdk"
    ]
  }]
}
```

Most of the definition should be self-explanatory. We'll create an EBS image based on Ubuntu in the `us-east-2` region and use the `shell` provisioner to install Docker and JDK.

Let's create the AMI.

```bash
packer build -machine-readable \
    jenkins/docker-ami.json \
    | tee cluster/docker-ami.log
```

The last lines of the output are as follows.

```
...
1528917568,amazon-ebs,artifact,0,id,us-east-2:ami-ea053b8f
1528917568,amazon-ebs,artifact,0,string,AMIs were created:\nus-east-2: ami-ea053b8f\n
1528917568,amazon-ebs,artifact,0,files-count,0
1528917568,amazon-ebs,artifact,0,end
1528917568,,ui,say,--> amazon-ebs: AMIs were created:\nus-east-2: ami-ea053b8f\n
```

The important line is the one that contains `artifact,0,id`. The last column in that row container the ID we'll need to use to tell Jenkins about the new AMI. We'll store it in an environment variable for convenience.

```bash
AMI_ID=$(grep 'artifact,0,id' \
    cluster/docker-ami.log \
    | cut -d: -f2)

echo $AMI_ID
```

The output of the latter command should be similar to the one that follows.

```
ami-ea053b8f
```

Just as with the security group, we'll store the `AMI_ID` export in the `docker-ec2` file so that we can retrieve it easily in the next chapters.

```bash
echo "export AMI_ID=$AMI_ID" \
    | tee -a cluster/docker-ec2
```

Now that we have the AMI, we need to move to Jenkins and configure the *Amazon EC2* plugin.

```bash
open "http://$JENKINS_ADDR/configure"
```

Please scroll to the *Cloud* section and click the *Add a new cloud* drop-down list. Choose *Amazon EC2*.

In the new form, type *docker-agents* as the *Name*, and expand the *Add* drop-down list next to *Amazon EC2 Credentials*. Choose *Jenkins*.

From the credentials screen, please choose *AWS Credentials* as the *Kind*, and type *aws* as both the *ID* and the *Description*.

Next, wee need to return to the terminal to retrieve the AWS access key ID.

```bash
echo $AWS_ACCESS_KEY_ID
```

Please copy the output, return to Jenkins UI, and paste it into the *Access Key ID* field.

We'll repeat the same process for the AWS secrets access key.

```bash
echo $AWS_SECRET_ACCESS_KEY
```

Copy the output, return to Jenkins UI, and paste it into the *Secret Access Key* field.

Now with all the credentials information filled in, we need to press the *Add* button to store it and return to the EC2 configuration screen.

Please choose the newly created credentials and select *us-east-2* as the *Region*.

We need the private key next. It can be created through the `aws ec2` command `create-key-pair`.

```bash
aws ec2 create-key-pair \
    --key-name devops24 \
    | jq -r '.KeyMaterial' \
    >cluster/devops24.pem
```

We created a new key pair, filtered the output so that only the `KeyMaterial` is returned, and stored it in the `devops24.pem` file.

For security reasons, we should change the permissions of the `devops24.pem` file so that only the current user can read it.

```bash
chmod 400 cluster/devops24.pem
```

Finally, we'll output the content of the pem file.

```bash
cat cluster/devops24.pem
```

Please copy the output, return to Jenkins UI, and paste it into the *EC2 Key Pair's Private Key* field.

To be on the safe side, press the *Test Connection* button, and confirm that the output is *Success*.

We're finished with the general *Amazon EC2* configuration and we can proceed to add the first and the only AMI.

Please click the *Add* button next to *AMIs*, and type *docker* as the *Description*.

We need to return to the terminal one more time to retrieve the AMI ID.

```bash
echo $AMI_ID
```

Please copy the output, return to Jenkins UI, and paste it into the *AMI ID* field.

To be on the safe side, please click the *Check AMI* button, and confirm that that the output does not show any error.

We're almost done.

Select *T2Micro* as the *Instance Type*, type *docker* as the *Security group names*, and type *ubuntu* as the *Remote user*. The *Remote ssh port* should be set to *22*. Please write *docker ubuntu linux* as the labels, and change the *Idle termination time* to *1*.

Finally, click the *Save* button so preserve the changes.

We'll use the newly created EC2 template soon. Feel free to skip the next section if this was the way you're planning to create agents.

### GCE

I> This section is appropriate for those using **GKE**.

If you reached this far, it means that you prefer running your cluster in GKE, or that you are so curious that you prefer triing all three ways to create VMs that will be used to build container images. No matter the reason, we're about to create an GCE image and configure Jenkins to spin up VMs when needed, and destroy them when they're not in use.

Before we do anything related to GCE, we need to authenticate.

```bash
gcloud auth login
```

Next, we need to create a service account that can be used by Packer to to create GCE images.

```bash
gcloud iam service-accounts \
    create jenkins
```

The output is as follows.

```
Created service account [jenkins].
```

We'll also need to know the project you're planning to use. We'll assume that they one currently active and retrieve it with the `gcloud info` command.

```bash
export G_PROJECT=$(gcloud info \
    --format='value(config.project)')

echo $G_PROJECT
```

Please note that the output will differ from what I've got. In my case, the output is as follows.

```
devops24-book
```

The last information we need is the email that was generated when we created the service account.

```bash
export SA_EMAIL=$(gcloud iam \
    service-accounts list \
    --filter="name:jenkins" \
    --format='value(email)')

echo $SA_EMAIL
```

In my case, the output is as follows.

```
jenkins@devops24-book.iam.gserviceaccount.com
```

Now that we retrieved all the information we need, we can proceed and create a policy binding between the service account and the `compute.admin` role. That will give us more than sufficient privileges not only to create images, but also to instantiate VMs based on them.

```bash
gcloud projects add-iam-policy-binding \
    --member serviceAccount:$SA_EMAIL \
    --role roles/compute.admin \
    $G_PROJECT
```

The output shows all the information related to the binding we created. Instead of going into details, we'll create another one.

```bash
gcloud projects add-iam-policy-binding \
    --member serviceAccount:$SA_EMAIL \
    --role roles/iam.serviceAccountUser \
    $G_PROJECT
```

Now that our service account is bound both to `compute.admin` and `iam.serviceAccountUser` roles, the only thing left before we create an GCE image is to create a ser of keys.

```bash
gcloud iam service-accounts \
    keys create \
    --iam-account $SA_EMAIL \
    cluster/gce-jenkins.json
```

The output is as follows.

```
created key [...] of type [json] as [cluster/gce-jenkins.json] for [jenkins@devops24-book.iam.gserviceaccount.com]
```

We're finally ready to create an image. We'll build it with [Packer](https://www.packer.io/), so please make sure that it is installed in your laptop.

The definition of the image we're create is stored in the `docker-gce.json` file. Let's take a quick look.

```bash
cat jenkins/docker-gce.json
```

The output is as follows.

```json
{
  "variables": {
    "project_id": ""
  },
  "builders": [{
    "type": "googlecompute",
    "account_file": "cluster/gce-jenkins.json",
    "project_id": "{{user `project_id`}}",
    "source_image_project_id": "ubuntu-os-cloud",
    "source_image_family": "ubuntu-1604-lts",
    "ssh_username": "ubuntu",
    "zone": "us-east1-b",
    "image_name": "docker"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sleep 15",
      "sudo apt-get clean",
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates nfs-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo add-apt-repository -y ppa:openjdk-r/ppa",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install -y openjdk-8-jdk"
    ]
  }]
}
```

That Packer definition should be self-explanatory. It containers the `builders` section that defines the parameters required to build an image in GCE, and the `provisioners` contain the `shell` commands that install Docker and JDK. The latter is required for Jenkins to establish the communication with the agent VMs we'll create from that image.

Feel free to change the zone if you're running your cluster somewhere other than `us-east1`.

Next, we'll execute `packer build` command that will create the image.

```bash
packer build -machine-readable \
    --force \
    -var "project_id=$G_PROJECT" \
    jenkins/docker-gce.json \
    | tee cluster/docker-gce.log
```

The output, limited to the last few lines, is as follows.

```
...
1529242865,googlecompute,artifact,0,id,docker
1529242865,googlecompute,artifact,0,string,A disk image was created: docker
1529242865,googlecompute,artifact,0,files-count,0
1529242865,googlecompute,artifact,0,end
1529242865,,ui,say,--> googlecompute: A disk image was created: docker
```

Now that we have the image, we should turn our attention back to Jenkins and configure *Google Compute Engine Cloud*.

```bash
open "http://$JENKINS_ADDR/configure"
```

The chances are that your Jenkins session expired and that you'll need to log in again. If that's the case, please output the password we stored in the environment variable `JENKINS_PASS` and use it to authenticate.

```bash
echo $JENKINS_PASS
```

Once inside the Jenkins configuration screen, please expand the *Add a new cloud* drop-down list. It is located near the bottom of the screen. Select *Google Compute Engine*.

A new set of fields will appear. We'll need to fill them in so that Jenkins knows how to connect to GCE and what to do if we request a new node.

Type *docker* as the *Name*.

We'll need to go back to the terminal and retrieve the Project ID we stored in the environment variable `G_PROJECT`.

```bash
echo $G_PROJECT
```

Please copy the output, go back to Jenkins UI, and paste it to the *Project ID* field.

Next, we'll create the credentials.

Expand the *Add* drop-down list next to *Service Account Credentials* and select *Jenkins*.

You'll see a new popup with the form to create credentials.

Select *Google Service Account from private key* as the *Kind* and paste the name of the project to the *Project Name* field (the one you got from `G_PROJECT` variable).

Click *Choose File* button in the *JSON Key* field and select the *gce-jenkins.json* file we created earlier in the *cluster* directory.

Click the *Add* button and the new credential will be persisted.

![Figure 6-TODO: Jenkins Google credentials screen](images/ch06/jenkins-google-credentials.png)

We're back in the *Google Compute Engine* screen and we'll need to select the newly created credential.

Next, we'll add a definition of VMs we'd like to create through Jenkins.

Please click the *Add* button next to *Instance Configurations*, type *docker* as the *Name Prefix*, and type *Docker build instances* as the *Description*. Write *1* as the *Node Retention Time* and type *docker ubuntu linux* as the *Labels*.

If you're running your cluster in *us-east-1*, please select it as the *Region*. Otherwise, switch to whichever region your cluster is running in. Similarly, select one of the zones that match your region. If you're following the exact steps, it should be *us-east1-b*. The important part is that the zone must be the same as the one where we build the image.

We're almost done with *Google Compute Engine* Jenkins' configuration.

Select *n1-standard-2* as the *Machine Type*, and *default* as both the *Network* and the *Subnetwork*.

The *Image project* should be set to the same value as the one we stored in the environment variable `G_PROJECT`.

Finally, select *docker* as the *Image name* and click the *Save* button.

## Test Docker Builds

No matter whether you choose to use static VMs or to create them dynamically in AWS or GCE, the steps to test them out are the same. From Jenkins' perspective, all that matter is that there are agent nodes with the labels *docker*.

We'll modify our Pipeline to use the `node` labeled `docker`.

```bash
open "http://$JENKINS_ADDR/job/my-k8s-job/configure"
```

Please click the *Pipeline* tab and replace the script with the one that follows.

```groovy
podTemplate(
    label: "kubernetes",
    namespace: "go-demo-3-build",
    serviceAccount: "build",
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("docker") {
        stage("docker") {
            sh "sudo docker version"
        }
    }
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version --tiller-namespace go-demo-3-build"
            }
        }
    }
}
```

TODO: Continue

```bash
# Click the *Save* button

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

# Click the row with the new build

# Wait until all the stages are executed
```

![Figure 6-TODO: Jenkins job for testing tools](images/ch06/jenkins-tools-with-docker-build.png)

## Automate Setup

```bash
mkdir -p cluster/jenkins/secrets

kubectl -n jenkins \
    describe deployment jenkins
```

```
Name:                   jenkins
Namespace:              jenkins
CreationTimestamp:      Mon, 11 Jun 2018 19:13:37 +0200
Labels:                 chart=jenkins-0.16.1
                        component=jenkins-jenkins-master
                        heritage=Tiller
                        release=jenkins
Annotations:            deployment.kubernetes.io/revision=1
Selector:               component=jenkins-jenkins-master
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:           app=jenkins
                    chart=jenkins-0.16.1
                    component=jenkins-jenkins-master
                    heritage=Tiller
                    release=jenkins
  Annotations:      checksum/config=67ba4de5bdd4b6e03bc4256e9d73c9ede8ba5b0618af4be548ccfe93eb7d8498
  Service Account:  jenkins
  Init Containers:
   copy-default-config:
    Image:      jenkins/jenkins:2.116-alpine
    Port:       <none>
    Host Port:  <none>
    Command:
      sh
      /var/jenkins_config/apply_config.sh
    Environment:  <none>
    Mounts:
      /usr/share/jenkins/ref/secrets/ from secrets-dir (rw)
      /var/jenkins_config from jenkins-config (rw)
      /var/jenkins_home from jenkins-home (rw)
      /var/jenkins_plugins from plugin-dir (rw)
  Containers:
   jenkins:
    Image:       jenkins/jenkins:2.116-alpine
    Ports:       8080/TCP, 50000/TCP
    Host Ports:  0/TCP, 0/TCP
    Args:
      --argumentsRealm.passwd.$(ADMIN_USER)=$(ADMIN_PASSWORD)
      --argumentsRealm.roles.$(ADMIN_USER)=admin
    Requests:
      cpu:      500m
      memory:   500Mi
    Liveness:   http-get http://:http/login delay=60s timeout=5s period=10s #success=1 #failure=12
    Readiness:  http-get http://:http/login delay=60s timeout=1s period=10s #success=1 #failure=3
    Environment:
      JAVA_OPTS:       
      JENKINS_OPTS:    
      ADMIN_PASSWORD:  <set to the key 'jenkins-admin-password' in secret 'jenkins'>  Optional: false
      ADMIN_USER:      <set to the key 'jenkins-admin-user' in secret 'jenkins'>      Optional: false
    Mounts:
      /usr/share/jenkins/ref/plugins/ from plugin-dir (rw)
      /usr/share/jenkins/ref/secrets/ from secrets-dir (rw)
      /var/jenkins_config from jenkins-config (ro)
      /var/jenkins_home from jenkins-home (rw)
  Volumes:
   jenkins-config:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      jenkins
    Optional:  false
   plugin-dir:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  
   secrets-dir:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  
   jenkins-home:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  jenkins
    ReadOnly:   false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  jenkins-c7f7c77b4 (1/1 replicas created)
NewReplicaSet:   <none>
Events:          <none>
```

```bash
kubectl -n jenkins \
    get pods \
    -l component=jenkins-jenkins-master
```

```
NAME                      READY     STATUS    RESTARTS   AGE
jenkins-c7f7c77b4-cgxx8   1/1       Running   0          3h
```

```bash
JENKINS_POD=$(kubectl -n jenkins \
    get pods \
    -l component=jenkins-jenkins-master \
    -o jsonpath='{.items[0].metadata.name}')

echo $JENKINS_POD
```

```
jenkins-c7f7c77b4-cgxx8
```

```bash
kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/credentials.xml \
    cluster/jenkins

kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/secrets/hudson.util.Secret \
    cluster/jenkins/secrets

kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/secrets/master.key \
    cluster/jenkins/secrets

# If GKE
kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/gauth/ \
    cluster/jenkins/secrets

# If GKE
G_AUTH_FILE=$(ls \
    cluster/jenkins/secrets/key*json \
    | xargs -n 1 basename)

# If GKE
echo $G_AUTH_FILE
```

```
key7754885476942296969.json
```

```bash
helm delete jenkins --purge
```

```
release "jenkins" deleted
```

```bash
helm dependency update helm/jenkins
```

```
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "local" chart repository (http://127.0.0.1:8879/charts):
        Get http://127.0.0.1:8879/charts/index.yaml: dial tcp 127.0.0.1:8879: connect: connection refused
...Unable to get an update from the "chartmuseum" chart repository (http://cm.127.0.0.1.nip.io):
        Get http://cm.127.0.0.1.nip.io/index.yaml: dial tcp 127.0.0.1:80: connect: connection refused
...Successfully got an update from the "azure-samples" chart repository
...Successfully got an update from the "monocular" chart repository
...Successfully got an update from the "coreos" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "jenkins-x" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading jenkins from repo https://kubernetes-charts.storage.googleapis.com
Deleting outdated charts
```

```bash
helm inspect values helm/jenkins
```

```yaml
jenkins:
  Master:
    ImageTag: "2.121.1-alpine"
    Cpu: "500m"
    Memory: "500Mi"
    ServiceType: ClusterIP
    ServiceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    InstallPlugins:
      - blueocean:1.5.0
      - credentials:2.1.16
      - ec2:1.39
      - git:3.9.1
      - git-client:2.7.2
      - github:1.29.1
      - kubernetes:1.7.1
      - pipeline-utility-steps:2.1.0
      - script-security:1.44
      - slack:2.3
      - thinBackup:1.9
      - workflow-aggregator:2.5
      - ssh-slaves:1.26
      - ssh-agent:1.15
      - jdk-tool:1.1
      - command-launcher:1.2
      - github-oauth:0.29
    Ingress:
      Annotations:
        nginx.ingress.kubernetes.io/ssl-redirect: "false"
        nginx.ingress.kubernetes.io/proxy-body-size: 50m
        nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
        ingress.kubernetes.io/ssl-redirect: "false"
        ingress.kubernetes.io/proxy-body-size: 50m
        ingress.kubernetes.io/proxy-request-buffering: "off"
    HostName: jenkins.acme.com
    CustomConfigMap: true
    CredentialsXmlSecret: jenkins-credentials
    SecretsFilesSecret: jenkins-secrets
    # DockerAMI:
    # DockerEC2PrivateKey:
    # GProject:
    # GAuthFile:
  rbac:
    install: true
```

```bash
kubectl -n jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl -n jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets

helm install helm/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set jenkins.Master.HostName=$JENKINS_ADDR \
    --set jenkins.Master.DockerAMI=$AMI_ID \
    --set jenkins.Master.GProject=$G_PROJECT \
    --set jenkins.Master.GAuthFile=$G_AUTH_FILE

# TODO: Remove
kubectl delete clusterrolebinding \
    jenkins-role-binding

# TODO: Remove
kubectl apply -n jenkins \
    -f helm/jenkins-patch.yml

kubectl -n jenkins describe cm jenkins
```

```
Name:         jenkins
Namespace:    jenkins
Labels:       <none>
Annotations:  <none>

Data
====
docker-build:
----
<?xml version='1.1' encoding='UTF-8'?>
<slave>
  <name>docker-build</name>
  <description></description>
  <remoteFS>/tmp</remoteFS>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.26">
    <host>10.100.198.200</host>
    <port>22</port>
    <credentialsId>docker-build</credentialsId>
    <maxNumRetries>0</maxNumRetries>
    <retryWaitTime>0</retryWaitTime>
    <sshHostKeyVerificationStrategy class="hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy"/>
  </launcher>
  <label>docker ubuntu</label>
  <nodeProperties/>
</slave>
jenkins.CLI.xml:
----
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.CLI>
  <enabled>false</enabled>
</jenkins.CLI>
plugins.txt:
----
blueocean:1.5.0
credentials:2.1.16
ec2:1.39
git:3.9.1
git-client:2.7.2
github:1.29.1
kubernetes:1.7.1
pipeline-utility-steps:2.1.0
script-security:1.44
slack:2.3
thinBackup:1.9
workflow-aggregator:2.5
ssh-slaves:1.26
ssh-agent:1.15
jdk-tool:1.1
command-launcher:1.2
github-oauth:0.29
google-compute-engine:1.0.4
apply_config.sh:
----
mkdir -p /usr/share/jenkins/ref/secrets/;
echo "false" > /usr/share/jenkins/ref/secrets/slave-to-master-security-kill-switch;
cp -n /var/jenkins_config/config.xml /var/jenkins_home;
cp -n /var/jenkins_config/jenkins.CLI.xml /var/jenkins_home;
mkdir -p /var/jenkins_home/nodes/docker-build
cp /var/jenkins_config/docker-build /var/jenkins_home/nodes/docker-build/config.xml;
mkdir -p /var/jenkins_home/gauth
cp -n /var/jenkins_secrets/key7754885476942296969.json /var/jenkins_home/gauth;
# Install missing plugins
cp /var/jenkins_config/plugins.txt /var/jenkins_home;
rm -rf /usr/share/jenkins/ref/plugins/*.lock
/usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;
# Copy plugins to shared volume
cp -n /usr/share/jenkins/ref/plugins/* /var/jenkins_plugins;
cp -n /var/jenkins_credentials/credentials.xml /var/jenkins_home;
cp -n /var/jenkins_secrets/* /usr/share/jenkins/ref/secrets;
config.xml:
----
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <disabledAdministrativeMonitors/>
  <version>2.121.1-alpine</version>
  <numExecutors>0</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
    <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
  </authorizationStrategy>
  <securityRealm class="hudson.security.LegacySecurityRealm"/>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
  <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
  <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
  <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds>
    <org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud plugin="kubernetes@1.7.1">
      <name>kubernetes</name>
      <templates>
        <org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
          <inheritFrom></inheritFrom>
          <name>default</name>
          <instanceCap>2147483647</instanceCap>
          <idleMinutes>0</idleMinutes>
          <label>jenkins-jenkins-slave</label>
          <nodeSelector></nodeSelector>
            <nodeUsageMode>NORMAL</nodeUsageMode>
          <volumes>
          </volumes>
          <containers>
            <org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
              <name>jnlp</name>
              <image>jenkins/jnlp-slave:3.10-1</image>
              <privileged>false</privileged>
              <alwaysPullImage>false</alwaysPullImage>
              <workingDir>/home/jenkins</workingDir>
              <command></command>
              <args>${computer.jnlpmac} ${computer.name}</args>
              <ttyEnabled>false</ttyEnabled>
              <resourceRequestCpu>200m</resourceRequestCpu>
              <resourceRequestMemory>256Mi</resourceRequestMemory>
              <resourceLimitCpu>200m</resourceLimitCpu>
              <resourceLimitMemory>256Mi</resourceLimitMemory>
              <envVars>
                <org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                  <key>JENKINS_URL</key>
                  <value>http://jenkins.jenkins:8080</value>
                </org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
              </envVars>
            </org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
          </containers>
          <envVars/>
          <annotations/>
          <imagePullSecrets/>
          <nodeProperties/>
        </org.csanchez.jenkins.plugins.kubernetes.PodTemplate></templates>
      <serverUrl>https://kubernetes.default</serverUrl>
      <skipTlsVerify>false</skipTlsVerify>
      <namespace>jenkins</namespace>
      <jenkinsUrl>http://jenkins.jenkins:8080</jenkinsUrl>
      <jenkinsTunnel>jenkins-agent.jenkins:50000</jenkinsTunnel>
      <containerCap>10</containerCap>
      <retentionTimeout>5</retentionTimeout>
      <connectTimeout>0</connectTimeout>
      <readTimeout>0</readTimeout>
    </org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud>
    <com.google.jenkins.plugins.computeengine.ComputeEngineCloud plugin="google-compute-engine@1.0.4">
      <name>gce-docker</name>
      <instanceCap>2147483647</instanceCap>
      <projectId>devops24-book</projectId>
      <credentialsId>devops24-book</credentialsId>
      <configurations>
        <com.google.jenkins.plugins.computeengine.InstanceConfiguration>
          <description>Docker build instances</description>
          <namePrefix>docker</namePrefix>
          <region>https://www.googleapis.com/compute/v1/projects/devops24-book/regions/us-east1</region>
          <zone>https://www.googleapis.com/compute/v1/projects/devops24-book/zones/us-east1-b</zone>
          <machineType>https://www.googleapis.com/compute/v1/projects/devops24-book/zones/us-east1-b/machineTypes/n1-standard-2</machineType>
          <numExecutorsStr>1</numExecutorsStr>
          <startupScript></startupScript>
          <preemptible>false</preemptible>
          <labels>docker ubuntu linux</labels>
          <runAsUser>jenkins</runAsUser>
          <bootDiskType>https://www.googleapis.com/compute/v1/projects/devops24-book/zones/us-east1-b/diskTypes/pd-ssd</bootDiskType>
          <bootDiskAutoDelete>true</bootDiskAutoDelete>
          <bootDiskSourceImageName>https://www.googleapis.com/compute/v1/projects/devops24-book/global/images/docker</bootDiskSourceImageName>
          <bootDiskSourceImageProject>devops24-book</bootDiskSourceImageProject>
          <networkConfiguration class="com.google.jenkins.plugins.computeengine.AutofilledNetworkConfiguration">
            <network>https://www.googleapis.com/compute/v1/projects/devops24-book/global/networks/default</network>
            <subnetwork>default</subnetwork>
          </networkConfiguration>
          <externalAddress>false</externalAddress>
          <useInternalAddress>false</useInternalAddress>
          <networkTags></networkTags>
          <serviceAccountEmail></serviceAccountEmail>
          <mode>NORMAL</mode>
          <retentionTimeMinutesStr>6</retentionTimeMinutesStr>
          <launchTimeoutSecondsStr>300</launchTimeoutSecondsStr>
          <bootDiskSizeGbStr>10</bootDiskSizeGbStr>
          <googleLabels>
            <entry>
              <string>jenkins_cloud_id</string>
              <string>-1723728540</string>
            </entry>
            <entry>
              <string>jenkins_config_name</string>
              <string>docker</string>
            </entry>
          </googleLabels>
          <numExecutors>1</numExecutors>
          <retentionTimeMinutes>6</retentionTimeMinutes>
          <launchTimeoutSeconds>300</launchTimeoutSeconds>
          <bootDiskSizeGb>10</bootDiskSizeGb>
        </com.google.jenkins.plugins.computeengine.InstanceConfiguration>
      </configurations>
    </com.google.jenkins.plugins.computeengine.ComputeEngineCloud>
  </clouds>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>50000</slaveAgentPort>
  <disabledAgentProtocols>
    <string>JNLP-connect</string>
    <string>JNLP2-connect</string>
  </disabledAgentProtocols>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
  <noUsageStatistics>true</noUsageStatistics>
</hudson>
Events:  <none>
```

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "jenkins" successfully rolled out
```

```bash
open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS
```

```
Ucg2tab4FK
```

```bash
# Login with user `admin`

open "http://$JENKINS_ADDR/configure"

# Observe that the *Kubernetes* section fields *Jenkins URL* and *Jenkins tunnel* are correctly populated.

# Only if AWS
cat cluster/devops24.pem

# Only if AWS
# Copy the output

# Only if AWS
# Scroll to the *EC2 Key Pair's Private Key* field

# Only if AWS
# Paste the output

# Only if GKE
# Observe that the *Google Compute Section* section fields look OK and that there is the message *The credential successfully made an API request to Google Compute Engine* below the *Service Account Credentials* field.

# Only if Vagrant VM
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/docker-build/update"

# Only if AWS
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/aws/update"

# Only if GKE
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/$G_PROJECT/update"

# Observe that the credential is created

open "http://$JENKINS_ADDR/computer"

# Only if Vagrant VM
# Observe that the *docker-build* agent is created and available

# Only if NOT Vagrant VM
# Observe that the *docker-build* agent is created and but it is NOT available

# Only if AWS
# Observe that the *Provision via docker-agents* drop-down list is available

# Only if AWS
# Observe that the *Provision via docker* drop-down list is available

open "http://$JENKINS_ADDR/newJob"

# Type *my-k8s-job* as the job name

# Select *Pipeline* as the job type

# Click the *OK* button

# Click the *Pipeline* tab

# Copy the script that follows and paste it into the *Script* field.
```

```groovy
podTemplate(
    label: "kubernetes",
    namespace: "go-demo-3-build",
    serviceAccount: "build",
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("docker") {
        stage("docker") {
            sh "sudo docker version"
        }
    }
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version --tiller-namespace go-demo-3-build"
            }
        }
    }
}
```

```bash
# Click the *Save* button

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

# Click the row of the new build

# Wait until all the stages are finished and that it is green
```

## Destroying The Cluster

```bash
# TODO: Explain the need for one master per team strategy

# TODO: Explain the need for tiller for each team

# If AWS or GKE, make sure that Jenkins removed the nodes before proceeding.

helm delete $(helm ls -q) --purge

kubectl delete ns \
    go-demo-3 go-demo-3-build jenkins

# Only if Vagrant
cd cd/docker-build

# Only if Vagrant
vagrant suspend

# Only if Vagrant
cd ../../
```
