## TODO

- [X] Code
- [X] Code review Docker for Mac/Windows
- [X] Code review minikube
- [ ] Code review kops
- [ ] Code review minishift
- [ ] Code review GKE
- [ ] Code review EKS
- [ ] Write
- [ ] The story
- [ ] Text review
- [ ] Diagrams
- [ ] Gist
- [ ] Review the title
- [ ] Proofread
- [ ] Add to slides
- [ ] Publish on TechnologyConversations.com
- [ ] Add to Book.txt
- [ ] Publish on LeanPub.com

# Creating A Continuous Deployment Pipeline With Jenkins

T> Having A Continuous Deployment pipeline capable of the fully automated application life-cycle is a true sign of maturity of an organization.

This is it. The time has come to put all the knowledge we obtained so far into a good use. We are about to define a "real" continuous deployment pipeline in Jenkins. Our goal is to move every commit through a set of steps until it is the application is installed (upgraded) and tested in production. We will surely face some new challenges but I am confident that we'll manage to overcome them. We already have all the ingredients, and the only thing left is to put them all together into a continuous deployment pipeline.

W> If you read the previous chapter before July 2018, you'll need to re-run the commands from it. While writing this chapter I realized that the previous one requires a few tweaks.

Before we move into a practical section, we might want to spend a few moments discussing our goals.

## Exploring The Continuous Deployment Process

Explaining continuous deployment (CDP) is easy. Implementing it is very hard, and the challenges are often hidden and unexpected. Depending on the maturity of your processes, architecture, and code, you might find out that the real problems do not lie in the code of a continuous deployment pipeline, but everywhere else. As a matter of fact, developing a pipeline is the easiest part. That being said, you might wonder whether you made a mistake by investing your time in reading this book since we are focused mostly on the pipeline, that will be executed inside a Kubernetes cluster.

We did not discuss the changes in your other processes. We did not explore what is a good architecture that will support CDP pipelines. Nor did we dive into how to code your application to be pipeline-friendly. I assumed that you already know all that. I hope that you do understand the basic concepts behind Agile and DevOps movements and that you already started dismantling the silos in your company. I assumed that you do know what it means for your software architecture to be cloud native and that you do implement some, if not all of the [12 factors](https://12factor.net/). I guessed that you are already practicing Test-Driven Development, Behavior-Driven Development, Acceptance-Driven Development, or any other technique that help you design your applications.

I might be wrong. To be more precise, I'm sure that I'm wrong. Most of you are not there yet. If you are one of those, please get informed. Read more books, do some courses, and convince your managers. It needs to be done. All those things, and many others, are what differentiates top performers (e.g., Google, Amazon, Netflix) and the rest of us. None of them is the same. Every high-performing company is different, and yet, they all share some things in common. They all need to ship features fast. They all need to have a high level of quality. And they all acknowledge that highly-available, fault-tolerant, and distributed systems require a very different approach that what most of the rest of us is used to.

If you got depressed by thinking that you are not yet ready and you are on the verge of quitting, my advice is to continue. Even though you might need to make a lot of changes before you are able to practice continuous deployment, knowing what the end result is will put you on the right path. We are about to design a fully operational continuous deployment pipeline. Once we're done, you'll know which other changes you'll need to make. You'll understand what the end-result is, and you will be able to go back to where you are and start moving into the right direction.

We already discussed what a continuous deployment pipeline looks like. In case you're forgetful (I know I am), here's the short version.

**Rule number one**: Every commit to the master branch is deployed to production if it passes all the steps of a fully automated pipeline. If you need to involve humans after the commit, it's not continuous deployment, nor it is continuous delivery. You're doing continuous integration, at best.

**Rule number two**: You commit directly to the master branch, or you're using short lived feature branches. The master branch is the only one that matters. Production releases are made from it. If we do use branches, they are taken from the master branch. It's the only one that truly matters. And when you do create a feature branch, you are merging back to master soon afterwards. You're not waiting for weeks to do so. If you are, you are not "continuously" validating whether your code integrates with the code of others. If that's the case, you're not even doing continuous integration. Unless, you have an elaborate branching strategy, in which case you are only making everyone's lives more complicated than they should be.

**Rule number three**: You trust your automation. When a test fails, there is a bug, and you fix it before anything else. You might belong to a big group of companies that have flaky tests that sometimes work, and sometimes fail for random reasons. The same can be said for builds, deployments, and just about any other step of the process. If you see yourself in that group, you'll have to fix your code first. Tests are code, just as builds, and deployments, and everything else is. When code produces inconsistent results, we fix it, we do not restart it. Unfortunately, I do see a lot of companies that rather re-run a build that failed because of flaky tests than fix the cause of that flakiness. Or, companies that solve half of production problems by restarting applications. Anyways, if you do not trust your automation, you cannot deploy to production automatically. You cannot even say that it is production ready.

Now that we established a very simple ground rules, we can move on and describe the pipeline we'll build. It'll be a simple one, and yet very close to what you might use in your "real" systems. We are going to build something. Since building without running unit and other types of static tests should be declared officially illegal and punishable with public shame, we'll include those in our **build stage**. Then we're going execute the steps of the **functional testing stage** that will execute all sort of tests that require a live application. Therefore, we'll need to deploy a test release during this stage. Once we're confident that our application behaves as expected, we're going to make a **production release**, followed with the **deployment stage** that will not only upgrade the production release but also run another round of tests to validate whether everything works as expected.

![Figure 7-TODO: The stages of a continuous deployment pipeline](images/ch07/cd-stages.png)

You might not agree with the names of the stages. That's OK. It does not matter much how you name things, nor how you group steps. What matters is that the pipeline has everything we need to feel confident that a release can be safely deployed to production. Steps matter, stages are only labels. However, we won't discuss the exact steps just yet. Instead, we'll break those stages apart and build one at the time. During the process, we'll discuss which steps are required.

It is almost certain that you'll need to add steps that I do not use. That's OK as well. It's all about principles and knowledge. Slight modifications should not be a problem.

Let's create a cluster and get going.

## Cluster

TODO: Write

TODO: Merge go-demo-3 and rename vfarcic

TODO: ChartMuseum

TODO: Increase Docker For Mac/Windows to 4GB and 4CPU

TODO: Docker For Mac/Windows needs a "real" IP

TODO: Increase minikube to 4GB and 4CPU

* [docker4mac-4gb.sh](https://gist.github.com/4b5487e707043c971989269883d20d28): **Docker for Mac** with 3 CPUs, 4 GB RAM, with **nginx Ingress**, with **tiller**, with `LB_IP` variable set to the IP of the cluster, and with **ChartMuseum**.

## Installing Jenkins

We already automated Jenkins installation so that it provides all the features we need out-of-the-box. Therefore, the exercises that follow should be very straightforward.

If you are a **Docker For Mac or Windows**, **minikube**, or **minishift** user, we'll need to bring back up the VM we created in the previous chapter. Feel free to skip the commands that follow if you did not `suspent` the VM at the end of the previous chapter, or if you are hosting your cluster in AWS or GCP.

```bash
cd cd/docker-build

vagrant up

cd ../../

export DOCKER_VM=true
```

If you prefer running your cluster in **AWS** with *kops* or **EKS**, we'll need to retrieve the AMI ID we stored in `docker-ami.log` in the previous chapter.

```bash
AMI_ID=$(grep 'artifact,0,id' \
    cluster/docker-ami.log \
    | cut -d: -f2)

echo $AMI_ID
```

Next, we'll need to create the Namespaces we'll need. Let's take a look at the definition we'll use.

```bash
cat ../go-demo-3/k8s/ns.yml
```

You'll notice that the definition is a combination of a few we used in the previous chapters. It contains three Namespaces.

The `go-demo-3-build` Namespace is where we'll run Pods from which we'll execute most of the steps of our pipeline. Those Pods will contain tools like kubectl, Helm, and Go compiler. We'll use the same Namespace to deploy our releases under test. All in all, the `go-demo-3-build` Namespace is for short lived Pods. The tools will be removed when a build is finished, just as installations of releases under test will be deleted when tests are finished executing. This Namespace will be like a trash can that needs to be emptied whenever it gets filled or start smelling.

The second Namespace is `go-demo-3`. That is the Namespace dedicated to the applications developed by the `go-demo-3` team. We'll work only on their main product, named after the team, but we can imagine that they might be in charge of other application. Therefore, do not think of this Namespace as dedicated to a single application, but dedicated to a team. They have full right to operate that Namespace, just as the others defined in `ns.yml`. They own them and `go-demo-3` is dedicated for production releases.

While we already used the two Namespaces, the third one is a bit new. The `go-demo-3-jenkins` is dedicated to Jenkins and you might wonder why we do not use the `jenkins` Namespace as we did so far. The answer lies in my belief that it is a good idea to give each team their own Jenkins. That way, we do not need to create an elaborate system with user permissions, we do not need to think whether a plugin desired by one team will break a job owned by another, and we do not need to worry about performance issues when Jenkins is stressed by hundreds or thousands of parallel builds. So, we're moving into **every team gets Jenkins** logic. *"It's your Jenkins, do whatever you want to do with it."* Now, if your organization has only twenty developers, there's probably no need for splitting Jenkins into multiple instances. Fifty should be OK as well. But, when that number rises to hundreds, or even thousands, having multiple Jenkins masters has clear benefits. Traditionally, that would not be practical due to increased operational costs. But, now that we are deep into Kubernetes, and we already saw that a fully operational and configured Jenkins is only a few commands away, monster instances do not make much sense any more. If you are small and that logic does not apply, the logic is still the same no matter whether you have one or a hundred Jenkins masters. Only the Namespace will be different (e.g., `jenkins`).

The rest of the definition is the same as what we used before. We have ServiceAccounts and RoleBindings that allow containers to interact with KubeAPI. We have LimitRanges and ResourceQuotas that protect the cluster from rogue Pods. The LimitRange defined for the `go-demo-3-build` Namespace is specially important. We can assume that many of the Pods created through CDP pipeline will not have memory and CPU requests and limits. That can be disastrous since it might produce undesired effects in the cluster. If nothing else, that would limit Kubernetes' capacity to schedule Pods. So, defining LimitRange entries `default` and `defaultRequest`is a crucial step.

Please go through the whole `ns.yml` definition to refresh your memory of the things we explored in the previous chapters. We'll `apply` it once you're back.

```bash
kubectl apply \
    -f ../go-demo-3/k8s/ns.yml \
    --record
```

```
namespace "go-demo-3-build" created
serviceaccount "build" created
rolebinding.rbac.authorization.k8s.io "build" created
limitrange "build" created
resourcequota "build" created
namespace "go-demo-3" created
rolebinding.rbac.authorization.k8s.io "build" created
limitrange "build" created
resourcequota "build" created
namespace "go-demo-3-jenkins" created
rolebinding.rbac.authorization.k8s.io "jenkins-role-binding" created
```

```bash
kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml
```

```
secret "jenkins-credentials" created
```

```bash
kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets
```

```
secret "jenkins-secrets" created
```

```bash
helm init --service-account build \
    --tiller-namespace go-demo-3-build
```

```
$HELM_HOME has been configured at /Users/vfarcic/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

```bash
JENKINS_ADDR="go-demo-3-jenkins.$LB_IP.nip.io"

helm dependency update helm/jenkins
```

```
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "local" chart repository (http://127.0.0.1:8879/charts):
        Get http://127.0.0.1:8879/charts/index.yaml: dial tcp 127.0.0.1:8879: connect: connection refused
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
helm install helm/jenkins \
    --name go-demo-3-jenkins \
    --namespace go-demo-3-jenkins \
    --set jenkins.Master.HostName=$JENKINS_ADDR \
    --set jenkins.Master.DockerVM=$DOCKER_VM \
    --set jenkins.Master.DockerAMI=$AMI_ID \
    --set jenkins.Master.GProject=$G_PROJECT \
    --set jenkins.Master.GlobalLibraries=true # TODO: Remove
```

```
NAME:   go-demo-3-jenkins
LAST DEPLOYED: Fri Jul 13 14:43:07 2018
NAMESPACE: go-demo-3-jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/ServiceAccount
NAME               SECRETS  AGE
go-demo-3-jenkins  1        1s

==> v1beta1/Ingress
NAME               HOSTS                                    ADDRESS  PORTS  AGE
go-demo-3-jenkins  go-demo-3-jenkins.18.219.143.208.nip.io  80       1s

==> v1/Pod(related)
NAME                                READY  STATUS    RESTARTS  AGE
go-demo-3-jenkins-7b5b4c94f9-rtg9j  0/1    Init:0/1  0         1s

==> v1/Secret
NAME               TYPE    DATA  AGE
go-demo-3-jenkins  Opaque  2     1s

==> v1/ConfigMap
NAME                     DATA  AGE
go-demo-3-jenkins        5     1s
go-demo-3-jenkins-tests  1     1s

==> v1/Service
NAME                     TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)    AGE
go-demo-3-jenkins-agent  ClusterIP  100.69.203.153  <none>       50000/TCP  1s
go-demo-3-jenkins        ClusterIP  100.65.129.59   <none>       8080/TCP   1s

==> v1beta1/Deployment
NAME               DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
go-demo-3-jenkins  1        1        1           0          1s

==> v1/PersistentVolumeClaim
NAME               STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
go-demo-3-jenkins  Bound   pvc-4ad602c1-869a-11e8-8d1b-067dc7747ba2  8Gi       RWO           gp2           1s

==> v1beta1/ClusterRoleBinding
NAME                            AGE
go-demo-3-jenkins-role-binding  1s
```

```bash
kubectl -n go-demo-3-jenkins \
    rollout status deployment \
    go-demo-3-jenkins
```

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "go-demo-3-jenkins" successfully rolled out
```

```bash
open "http://$JENKINS_ADDR/computer"

JENKINS_PASS=$(kubectl -n go-demo-3-jenkins \
    get secret go-demo-3-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

# Login with user *admin*

# TODO: docker-build: Docker For Mac/Windows, minikube

# TODO: Provision with docker-agents: kops

open "http://$JENKINS_ADDR"
```

W> ## A note to AWS EC2 users
W>
W> Unlike on-prem and GKE solutions, AWS requires a single manual step to complete the Jenkins setup.
W>
W> `cat cluster/devops24.pem`
W>
W> Copy the output.
W> 
W> `open "http://$JENKINS_ADDR/configure"`
W> Scroll to the *EC2 Key Pair's Private Key* field, and paste the key. Don't forget to click the *Apply* button to persist the change.

## Scripted vs Declarative Pipeline

TODO: Write

## Defining The Continuous Deployment Stages

TODO: Write

## Build Stage

TODO: Write

TODO: Discard old builds

```bash
# Click the *New Item* link from the left-hand menu

# Type *go-demo-3* as the *item name*

# Select *Pipeline* as the job type

# Click the *OK* button

# Select the *Discard old builds* checkbox

# Type *3* in the *Max # of builds to keep* field

# Click the *Pipeline* tab in the top of the screen

# Type the script that follows in the *Script* field
```

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.TAG_BETA = "${currentBuild.displayName}-${env.BRANCH_NAME}"

node("docker") {
  stage("build") {
    git "${env.REPO}"
    sh """sudo docker image build \
      -t ${env.IMAGE}:${env.TAG_BETA} ."""
    withCredentials([usernamePassword(
      credentialsId: "docker",
      usernameVariable: "USER",
      passwordVariable: "PASS"
    )]) {
      sh """sudo docker login \
        -u $USER -p $PASS"""
    }
    sh """sudo docker image push \
      ${env.IMAGE}:${env.TAG_BETA}"""
  }
}
```

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build

# Wait until the build is finished and green
```

![Figure 7-TODO: Jenkins build with a single stage](images/ch07/jenkins-build-build.png)

```bash
export DH_USER=[...]

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

# TODO: Comment on `null` as the branch name
```

## Functional Stage

TODO: Write

```bash
export ADDR=$LB_IP.nip.io

echo $ADDR

open "http://$JENKINS_ADDR/job/go-demo-3/configure"

# Replace the script with the one that follows
```

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.TAG_BETA = "${currentBuild.displayName}-${env.BRANCH_NAME}"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"
def label = "jenkins-slave-${UUID.randomUUID().toString()}"

podTemplate(
  label: label,
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.9.1
    command: ["cat"]
    tty: true
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.9
    command: ["cat"]
    tty: true
"""
) {
  node(label) {
    node("docker") {
      stage("build") {
        git "${env.REPO}"
        sh """sudo docker image build \
          -t ${env.IMAGE}:${env.TAG_BETA} ."""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG_BETA}"""
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3-build \
            rollout status deployment \
            ${env.CHART_NAME}"""
        }
        container("golang") { // Uses env ADDRESS
          sh "go get -d -v -t"
          sh """go test ./... -v \
            --run FunctionalTest"""
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          sh """helm delete \
            ${env.CHART_NAME} \
            --tiller-namespace go-demo-3-build \
            --purge"""
        }
      }
    }
  }
}
```

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build

# While in `func-test` stage

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3-build \
    get all

# Wait until the build is finished and green

# After the build is finished

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3-build \
    get all

# TODO: Explain shared workspace

# TODO: Sonar

# TODO: Performance

# TODO: parallel
```

## Release Stage

```bash
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/newCredentials"

# Username: admin
# Password: admin
# ID: chartmuseum
# Description: chartmuseum
# Click *OK*

JENKINS_POD=$(kubectl \
    -n go-demo-3-jenkins \
    get pods \
    -l component=go-demo-3-jenkins-jenkins-master \
    -o jsonpath='{.items[0].metadata.name}')

echo $JENKINS_POD

kubectl -n go-demo-3-jenkins cp \
    $JENKINS_POD:var/jenkins_home/credentials.xml \
    cluster/jenkins

open "http://$JENKINS_ADDR/job/go-demo-3/configure"

# Replace the script with the one that follows
```

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.CM_ADDR = "acme.com" // Replace `acme.com` with the $CM_ADDR retrieved earlier
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"
env.CHART_VER = "0.0.1"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.9.1
    command: ["cat"]
    tty: true
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.9
    command: ["cat"]
    tty: true
"""
) {
  node("kubernetes") {
    node("docker") {
      stage("build") {
        git "${env.REPO}"
        sh """sudo docker image build \
          -t ${env.IMAGE}:${env.TAG_BETA} ."""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG_BETA}"""
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3-build \
            rollout status deployment \
            ${env.CHART_NAME}"""
        }
        container("golang") { // Uses env ADDRESS
          sh "go get -d -v -t"
          sh """go test ./... -v \
            --run FunctionalTest"""
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          sh """helm delete \
            ${env.CHART_NAME} \
            --tiller-namespace go-demo-3-build \
            --purge"""
        }
      }
    }
    stage("release") {
      node("docker") {
        sh """sudo docker pull \
          ${env.IMAGE}:${env.TAG_BETA}"""
        sh """sudo docker image tag \
          ${env.IMAGE}:${env.TAG_BETA} \
          ${env.IMAGE}:${env.TAG}"""
        sh """sudo docker image tag \
          ${env.IMAGE}:${env.TAG_BETA} \
          ${env.IMAGE}:latest"""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG}"""
        sh """sudo docker image push \
          ${env.IMAGE}:latest"""
      }
      container("helm") {
        sh "helm package helm/go-demo-3"
        withCredentials([usernamePassword(
          credentialsId: "chartmuseum",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """curl -u $USER:$PASS \
            --data-binary "@go-demo-3-${CHART_VER}.tgz" \
            http://${env.CM_ADDR}/api/charts"""
        }
      }
    }
  }
}
```

```bash
xxx

# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build

# TODO: Release files to GH

# TODO: Manifest

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

curl -u admin:admin \
    "http://$CM_ADDR/index.yaml"
```

## Deploy Stage

```bash
open "http://$JENKINS_ADDR/job/go-demo-3/configure"

# Replace the script with the one that follows
```

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.PROD_ADDRESS = "go-demo-3.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.CM_ADDR = "acme.com" // Replace `acme.com` with the $CM_ADDR retrieved earlier
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"
env.CHART_VER = "0.0.1"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.9.1
    command: ["cat"]
    tty: true
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.9
    command: ["cat"]
    tty: true
"""
) {
  node("kubernetes") {
    node("docker") {
      stage("build") {
        git "${env.REPO}"
        sh """sudo docker image build \
          -t ${env.IMAGE}:${env.TAG_BETA} ."""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG_BETA}"""
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3-build \
            rollout status deployment \
            ${env.CHART_NAME}"""
        }
        container("golang") { // Uses env ADDRESS
          sh "go get -d -v -t"
          sh """go test ./... -v \
            --run FunctionalTest"""
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          sh """helm delete \
            ${env.CHART_NAME} \
            --tiller-namespace go-demo-3-build \
            --purge"""
        }
      }
    }
    stage("release") {
      node("docker") {
        sh """sudo docker pull \
          ${env.IMAGE}:${env.TAG_BETA}"""
        sh """sudo docker image tag \
          ${env.IMAGE}:${env.TAG_BETA} \
          ${env.IMAGE}:${env.TAG}"""
        sh """sudo docker image tag \
          ${env.IMAGE}:${env.TAG_BETA} \
          ${env.IMAGE}:latest"""
        withCredentials([usernamePassword(
          credentialsId: "docker",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """sudo docker login \
            -u $USER -p $PASS"""
        }
        sh """sudo docker image push \
          ${env.IMAGE}:${env.TAG}"""
        sh """sudo docker image push \
          ${env.IMAGE}:latest"""
      }
      container("helm") {
        sh "helm package helm/go-demo-3"
        withCredentials([usernamePassword(
          credentialsId: "chartmuseum",
          usernameVariable: "USER",
          passwordVariable: "PASS"
        )]) {
          sh """curl -u $USER:$PASS \
            --data-binary "@go-demo-3-${CHART_VER}.tgz" \
            http://${env.CM_ADDR}/api/charts"""
        }
      }
    }
    stage("deploy") {
      try {
        container("helm") {
          sh """helm upgrade \
            go-demo-3 \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --namespace go-demo-3 \
            --set image.tag=${env.TAG} \
            --set ingress.host=${env.PROD_ADDRESS}"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3 \
            rollout status deployment \
            go-demo-3"""
        }
        container("golang") {
          sh "go get -d -v -t"
          sh """DURATION=1 ADDRESS=${env.PROD_ADDRESS} \
            go test ./... -v \
            --run ProductionTest"""
        }
      } catch(e) {
        container("helm") {
          sh """helm rollback \
            go-demo-3 0 \
            --tiller-namespace go-demo-3-build"""
          error "Failed production tests"
        }
      }
    }
  }
}
```

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

helm ls \
    --tiller-namespace go-demo-3-build

helm history go-demo-3 \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3 get pods

curl "http://go-demo-3.$ADDR/demo/hello"

# TODO: Release files to GH

# TODO: Manifest

# TODO: Failure notifications
```

## Shared Libraries

```bash
open "http://$JENKINS_ADDR/configure"

# Search for *Global Pipeline Libraries*
# Click *Add*
# Name: *library*
# Default version: *master*
# Load implicitly: *true*
# Modern SCM: *true*
# Git: *true*
# Project Repository: *https://github.com/vfarcic/jenkins-shared-libraries.git*
# Click *Apply*

kubectl -n go-demo-3-jenkins cp \
    $JENKINS_POD:var/jenkins_home/org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml \
    cluster/jenkins/secrets

open "http://$JENKINS_ADDR/job/go-demo-3/configure"
```

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.PROJECT = "go-demo-3"
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.DOMAIN = "acme.com" // Replace me
env.ADDRESS = "go-demo-3.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.CM_ADDR = "acme.com" // Replace `acme.com` with the $CM_ADDR retrieved earlier
env.CHART_VER = "0.0.1"

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.9.1
    command: ["cat"]
    tty: true
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.9
    command: ["cat"]
    tty: true
"""
) {
  node("kubernetes") {
    node("docker") {
      stage("build") {
        git "${env.REPO}"
        k8sBuildImageBeta(env.IMAGE)
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          k8sUpgradeBeta(env.PROJECT, env.DOMAIN)
        }
        container("kubectl") {
          k8sRolloutBeta(env.PROJECT)
        }
        container("golang") {
          k8sFuncTestGolang(env.PROJECT, env.DOMAIN)
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          k8sDeleteBeta(env.PROJECT)
        }
      }
    }
    stage("release") {
      node("docker") {
        k8sPushImage(env.IMAGE)
      }
      container("helm") {
        k8sPushHelm(env.PROJECT, env.CHART_VER, env.CM_ADDR)
      }
    }
    stage("deploy") {
      try {
        container("helm") {
          k8sUpgrade(env.PROJECT, env.ADDRESS)
        }
        container("kubectl") {
          k8sRollout(env.PROJECT)
        }
        container("golang") {
          k8sProdTestGolang(env.ADDRESS)
        }
      } catch(e) {
        container("helm") {
          k8sRollback(env.PROJECT)
        }
      }
    }
  }
}
```

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

helm ls \
    --tiller-namespace go-demo-3-build

helm history go-demo-3 \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3 get pods

curl "http://go-demo-3.$ADDR/demo/hello"
```

## Jenkinsfile & Multistage Builds

```bash
cat ../go-demo-3/k8s/build-config.yml \
    | sed -e "s@acme.com@$ADDR@g" \
    | kubectl apply -f - --record

open "http://$JENKINS_ADDR/job/go-demo-3/"

# Click *Delete Pipeline*

open "http://$JENKINS_ADDR/blue/create-pipeline"

# Select *GitHub*

# Type *Your GitHub access token*

# Select the organization

# Type *go-demo-3* in the *Search...* field

# Select *go-demo-3*

# Click the *Create Pipeline* button

# TODO: Observe multiple jobs

# TODO: Click the *Branches* tab

# TODO: Click the *Pull Requests* tab

# TODO: Click the *Activity* tab

# TODO: Not enough capacity to run the builds in parallel

# Wait until *feature-1*, *feature-2*, or *PR-1* builds are finished

# Click on the build, wait until it's finished, and observe that it did not execute all the stages

# Wait until PR-1 build starts

export GH_USER=[...]

open "https://github.com/$GH_USER/go-demo-3/pull/1"

# Observe the status of the build

# Wait until *master* build is finished

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

# Observe that tag now have branch name instead of *null*

helm ls \
    --tiller-namespace go-demo-3-build

helm history go-demo-3 \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3 get pods

curl "http://go-demo-3.$ADDR/demo/hello"
```

## Webhooks

```bash
# TODO: No public IP for Docker for Mac/Windows and minikube
```

TODO: Code

## Manual Testing & The Attempt To Use The Same Artifacts

TODO: Write

TODO: Reference to the CI chapter

## Manual Testing & The Attempt To Use The Same Artifacts

TODO: Write

TODO: Reference to the CI chapter

## What Now?

```bash
cd cd/docker-build

vagrant suspend

cd ../../
```
