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

TODO: ChartMuseum, CM_ADDR, and CM_ADDR_ESC

TODO: Increase Docker For Mac/Windows to 4GB and 4CPU

TODO: Docker For Mac/Windows needs a "real" IP

TODO: Increase minikube to 4GB and 4CPU

* [docker4mac-4gb.sh](https://gist.github.com/4b5487e707043c971989269883d20d28): **Docker for Mac** with 3 CPUs, 4 GB RAM, with **nginx Ingress**, with **tiller**, with `LB_IP` variable set to the IP of the cluster, and with **ChartMuseum**.
* [minikube-4gb.sh](https://gist.github.com/0a29803842b62c5c033e4c75cd37f3d4): **minikube** with 3 CPUs, 4 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, with **tiller**, with `LB_IP` variable set to the VM created by minikube, and with **ChartMuseum**.
* [kops-cm.sh](https://gist.github.com/603e2dca21b4475985a078b0f78db88c): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP retrieved by pinging ELB's hostname, and with **ChartMuseum**. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).

## Installing Jenkins

We already automated Jenkins installation so that it provides all the features we need out-of-the-box. Therefore, the exercises that follow should be very straightforward.

If you are a **Docker For Mac or Windows**, **minikube**, or **minishift** user, we'll need to bring back up the VM we created in the previous chapter. Feel free to skip the commands that follow if you did not `suspend` the VM at the end of the previous chapter, or if you are hosting your cluster in AWS or GCP.

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

Now that we have the Namespaces, ServiceAccounts, RoleBindings, LimitRanges, and ResourceQuotas, we can proceed and create the secrets and credentails required by Jenkins.

```bash
kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets
```

Only one more thing is missing before we install Jenkins. We need to install Tiller in the `go-demo-3-build` Namespace.

```bash
helm init --service-account build \
    --tiller-namespace go-demo-3-build
```

Now we are ready to install Jenkins.

```bash
JENKINS_ADDR="go-demo-3-jenkins.$LB_IP.nip.io"

helm install helm/jenkins \
    --name go-demo-3-jenkins \
    --namespace go-demo-3-jenkins \
    --set jenkins.Master.HostName=$JENKINS_ADDR \
    --set jenkins.Master.DockerVM=$DOCKER_VM \
    --set jenkins.Master.DockerAMI=$AMI_ID \
    --set jenkins.Master.GProject=$G_PROJECT \
    --set jenkins.Master.GAuthFile=$G_AUTH_FILE \
    --set jenkins.Master.GlobalLibraries=true # TODO: Remove
```

We generated a `nip.io` address and installed Jenkins in the `go-demo-3-jenkins` Namespace. Remember, this Jenkins is dedicated to the *go-demo-3* team, and we might have many other instances serving the needs of other teams.

So far, everything we did is almost the same as what we did in the previous chapters. The only difference is that we changed the Namespace where we deployed Jenkins. Now, the only thing left, before we jump into experiences, is to wait until Jenkins is rolled out and confirm a few things.

```bash
kubectl -n go-demo-3-jenkins \
    rollout status deployment \
    go-demo-3-jenkins
```

The only thing we'll validate, right now, is whether the node that we'll use to build and push Docker images, is indeed connected to Jenkins.

```bash
open "http://$JENKINS_ADDR/computer"
```

Just as before, we'll need the auto-generated password.

```bash
JENKINS_PASS=$(kubectl -n go-demo-3-jenkins \
    get secret go-demo-3-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS
```

Please copy the output of the `echo` command, go back to the browser, and use it to log in as the `admin` user.

Once inside the nodes screen, you'll see different results depending on how you set up the node for building and pushing Docker images.

If you are a **Docker For Mac or Windows** or a **minikube** user, you'll see a node called `docker-build`. That confirms that we successfully connected Jenkins with the VM we created with Vagrant.

If you created a cluster in **AWS** using **kops**, you should see a drop-down list called **docker-agents**.

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

Now that we confirmed that a node (static or dynamic) is available for building and pushing Docker images, we can start designing our first stage of the continuous deployment pipeline.

## Build Stage

The primary function of the **build stage** of the continuous deployment pipeline is to build artifacts and a container image and push it to a registry from which it can be deployed and tested. Ofcourse, we cannot build anything without code, so we'll have to checkout the repository.

Since building things without running static analysis, unit tests, and other types of validation against static code should be illegal and punishable by public shame, we'll include those steps as well.

We won't deal with building artifacts nor we are going to run static testing and analysis from inside the pipeline. Instead, we'll continue relying on Docker's multi-stage builds for all those things, just as we did in the previous chapters.

We couldn't push to a registry without authentication, so we'll have to login to Docker Hub just before we push a new image.

There are a few things that we are NOT going to do, even though you probably should when applying the lessons learned your "real" projects. We do not have static analysis. We are NOT generating code coverage, we are NOT creating reports, and we are not sending the result to analysis tools like [SonarQube](https://www.sonarqube.org/). More importantly, we are NOT running any security scanning. There are many other things we could do in this chapter, but we are not. The reason is simple. There is an almost infinite number of tools and steps we could do. They depend on programming languages, internal processes, and what so not. The goal is to understand the logic, and adapt the examples to your own needs. With that in mind, we'll stick only to the bare minimum, not only in this stage, but also in those that follow. It is up to you to extend them to fit your specific needs.

![Figure 7-TODO: The essential steps of the build stage](images/ch07/cd-stages-build.png)

Let's define the steps of the build stage as a Jenkins job.

```bash
open "http://$JENKINS_ADDR"
```

From the Jenkins home screen, please click the *New Item* link from the left-hand menu. The script for creating new jobs will appear.

Type *go-demo-3* as the *item name*, select *Pipeline* as the job type, and click the *OK* button.

I> As a rule of thumb, name your pipeline job after the application/repository you're building.

Once inside job's configuration screen, click the *Pipeline* tab in the top of the screen, and type the script that follows inside the *Script* field.

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
env.REPO = "https://github.com/vfarcic/go-demo-3.git"
env.IMAGE = "vfarcic/go-demo-3"
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

I> If you prefer to copy and paste, the job is available in the [cdp-jenkins-build.groovy Gist](https://gist.github.com/f990482b94e1c292d36da4526a4fa536).

Since we already went through all those steps manually, the same steps inside a Jenkins job should be self-explanatory. However, this might be your first contact with Jenkins pipeline, so we'll briefly explain what's going on.

First of all, the job is written using the **scripted pipeline**. The alternative would be to use **declarative pipeline** which forces a certain structure and naming convention. Personally, I prefer the latter. Declarative pipeline is easier to write and read, and it provides structure that makes implementation of some patterns much easier. However, it also comes with a few limitations. In our case, those limitations are enough to make declarative pipeline a bad choice. Namely, it does not allow us to mix different types of agents and it does not support all the options available in `podTemplate`. Since scripted pipeline has no limitations, we opted for that flavour, even though it makes the code often harder to maintain.

I> Visit [jenkins.io](https://jenkins.io/doc/book/pipeline/) if you're somewhat new to Jenkins pipeline and want to learn more.

What did we do so far?

We imported `SimpleDateFormat` library that allows us to retrieve dates. The reason for the `import` becomes obvious in the next line where we are changing the name of the build. By default, each build is named sequentially. The first build is named `1`, the second `2`, and so on. We changed the naming pattern so that it contains the date in `yy.MM.dd` format, followed with the sequential number.

Next, we're defining a few environment variables that contain the information we'll need in the pipeline steps. `REPO` hold the GitHub repository we're using, `IMAGE` is the name of the Docker image we'll build, and `TAG_BETA` has the format we'll use to tag the images. The latter is a combination of the build and the branch name.

Before we proceed, please change the `REPO` and the `IMAGE` variables to match the address of the repository you forked and the name of the image. In most cases, changing `vfarcic` to your GitHub and Docker Hub user should be enough.

The `node` block is where the "real" action is happening.

By setting the `node` to `docker`, we're telling Jenkins to use the agent with the matching name or label for all the steps within that block. The mechanism will differ from one case to another. It could match the VM we created with Vagrant, or it could be a dynamically created node in AWS or GCP.

Inside the `node` is the `stage` block. It is used to group steps and has not practical purpose. It is purely cosmetic and used to visualize the pipeline.

Inside the `stage` are the steps. The full list of available steps depends on the available plugins. The most commonly used ones are documented in the [Pipeline Steps Reference](https://jenkins.io/doc/pipeline/steps/). As you'll see, most of the pipeline we'll define will be based on the [sh: Shell Script](https://jenkins.io/doc/pipeline/steps/workflow-durable-task-step/#sh-shell-script) step. Since in the previous chapters we defined almost everything we need through commands executed in a terminal, using `sh` allows us to copy and paste those same commands. That way, we'll have very little dependency on Jenkins-specific way of working, and we'll have parity between command line used by developers on their laptops, and Jenkins pipelines.

Inside the `build` stage, we're using `git` to retrieve the repository. Further on, we're using `sh` to execute Docker commands to `build` an image, `login` to Docker Hub, and `push` the image.

The only "special" part of the pipeline is the `withCredentials` block. Since it would be very insecure to hard-code Docker Hub's username and password into our jobs, we're retrieving the information from Jenkins. The credentials with the ID `docker` will be converted into variables `USER` and `PASS`, which are used with the `docker login` command. Besides the obvious do-not-hard-code-secrets reason, the main motivation for using the `withCredentials` block lies in Jenkins' ability to obfuscate confidential information. As you'll see later on, the credentials will be removed from logs making them hidden to anyone poking around our builds.

I> I split some of the instructions into multiple-lines to avoid potential problems with the width limitations in books. You won't have those limitations in your pipelines and might want to refactor examples into single-line steps thus making them easier to read and maintain.

Now that we had a brief exploration about our first draft of the pipeline, the time has come to try it out.

Please click the *Save* button to persist the job.

We'll use the new UI to run the builds and visualize them.

Click the *Open Blue Ocean* link from the left-hand menu, followed with a click on the *Run* button.

Once the build starts, a new row will appear. Click it to enter into the details of the build, and observe the progress until it's finished and everything is green.

![Figure 7-TODO: Jenkins build with a single stage](images/ch07/jenkins-build-build.png)

Let's check whether Jenkins executed the steps correctly. If it did, we should have a new image pushed to our Docker Hub account.

```bash
export DH_USER=[...]

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"
```

Please replace `[...]` with your Docker Hub username.

You should see a new image tagged as a combination of the date, build number (`1`), and the branch. Except, that the branch is set to `null`. That is the expected behavior since we did not tell Jenkins which branch to retrieve. As a result, the environment variable `BRANCH_NAME` is set to `null` and, with it, our image tag as well. We'll fix that problem later on. For now, we'll have to live with `null`.

Now that we finished defining and verifying the `build` stage, we can proceed to *functional testing*.

## Functional Stage

For the *functional testing* stage install the application under test. To avoid the potential error of installing the same release twice, we'll use `helm upgrade` instead of `install`.

As you already know, Helm only acknowledges that the resources are created, not that all the Pods are running. To mitigate that, we'll wait for `rollout status` before proceeding with tests.

Once the application is rolled out, we'll run functional tests. Please note that in this case we will run only one set of tests. In the "real" world scenario, there would probably be others. Among others, we might need to run performance tests or we might run tests in different browsers.

I> When running multiple sets of different tests, consider using `parallel` construct. More information can be found in the [Parallelism and Distributed Builds with Jenkins](https://www.cloudbees.com/blog/parallelism-and-distributed-builds-jenkins) article.

Finally, we'll have to `delete` the Chart we installed. After all, there's no point wasting resources by running an application longer than we need. In our scenario, as soon as the execution of the tests is finished, we'll remove the application under test. However, there is a twist. Jenkins, like most other CI/CD tools, will stop the execution of the first error. So, we'll have to envelop all the steps in this stage inside a big `try`/`catch`/`finally` statement.

![Figure 7-TODO: The essential steps of the functional stage](images/ch07/cd-stages-func.png)

Before we move on and write the new version of the pipeline, we'll need an address that we'll use as Ingress host of our application under tests.

```bash
export ADDR=$LB_IP.nip.io

echo $ADDR
```

Please copy the output of the `echo`. We'll need it soon.

Next, we'll open the job's configuration screen.

```bash
open "http://$JENKINS_ADDR/job/go-demo-3/configure"
```

Please replace the existing code with the contents of the [cdp-jenkins-func.groovy Gist](https://gist.github.com/4edc53d5dd11814651485c9ff3672fb7).

We'll explore only the differences between the two revisions of the pipeline. They are as follows.

```groovy
...
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com"
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
        ...
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
            --set ingress.host=${env.ADDRESS} \
            --set replicaCount=2 \
            --set dbReplicaCount=1"""
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

We added a few new environment variables that will simplify the steps that follow. The `ADDRESS` will be used to provide a unique host for the Ingress of the application under test. The uniqueness is accomplished by combining the name of the project (`go-demo-3`), the build number, and the name of the branch. We used a similar pattern to generate the name of the Chart that will be installed. All in all, both the address and the Chart are unique for each release of each application, no matter the branch.

We also defined `label` with a unique value by adding a suffix based on random UUID. Further down, when we define `podTemplate`, we'll use the `label` to ensure that each build uses its own Pod.

The `podTemplate` itself is very similar to those we used in quite a few occasions. It'll be created in the `go-demo-3-build` Namespace dedicated to building and testing applications owned by the `go-demo-3` team. The `yaml` contains definitions of the Pod that contains containers with `helm`, `kubectl`, and `golang`. Those are the tools we'll need to execute the steps of the *functional testing* stage.

The curious part is the way nodes (agents) are organized in this iteration of the pipeline. Everything is inside one big block of `node(label)`. As a result, all the steps will be executed in one of the containers of the `podTemplate`. However, since we do not want every part of the build to run inside the cluster, inside the node based on the `podTemplate`, is the same `node("docker")` block we are using for building and pushing Docker images.

The reason for using nested `node` blocks lies in Jenkins' ability to delete unused Pods. The moment `podTemplate` node block is closed, Jenkins would remove the associated Pod. To preserve the state we'll generate inside that Pod, we're making sure that it is alive through the whole build by enveloping all the steps (even thouse running somewhere else) inside one huge `node(label)` block.

Inside the `func-test` stage is a `try` block that contains all the steps (except cleanup). Each of the steps is executed inside a different container. We enter `helm` to clone the code and execute `helm upgrade` that installs the release under test. Next, we jump into the `kubectl` container to wait for the `rollout status` that confirms that the application is rolled out completely. Finally, we switch into the `golang` container to run our tests since they require Go.

Please note that we are installing only two replicas of the application under test and one replica of the DB. That's more than enough to validate whether it works as expected from the functional point of view. There's no need to have the same number of replicas as what we'll run in the production Namespace.

You might be wondering why we checked out the code for the second time. The reason is simple. In the first stage, we cloned the code inside the VM dedicated (or dynamically created) for building Docker images. The Pod created through `podTemplate` does not have that code so we had to clone it again. We did that inside the `helm` container since that's the first one we're using.

Now, you might be wondering why we didn't clone the code to all the containers of the Pod. After all, almost everything we do needs the code of the application. While that might not be true for the `kubectl` container (it only waits for the installation to roll out), it is certainly true for `golang`. The answer lies in Jenkins `podTemplate` hidden features. Among others, it creates a volume and mounts it to all the containers of the Pod as the directory `/workspace`. That directory happens to be the default directory in which it operates when inside those containers. So, the state created inside one container, exists in all others, as long as we do not switch to a different folder.

The `try` block is followed with `catch` that is executed only if one of the steps throws an error. The only purpose for having the `catch` block is to re-throw the error, if there is any.

The sole purpose for using `try`/`catch` blocks is in `finally`. In it, we are deleting the application we deployed. Since it executes no matter whether there was an error, we have reasonable guarantee that we'll have a clean system no matter the outcome of the pipeline.

To summarize, `try` block ensures that errors are caught. Without it, pipeline would stop executing on the first sign of error, and the release under test would never be removed. The `catch` block re-throws the error, and the `finally` block deletes the release no matter what happens.

Before we test the new iteration of the pipeline, please replace the values of the environment variables to fit your situation. As a minimum, you'll need to replace `vfarcic` with your GitHub user and Docker Hub user as before, and `acme.com` with the value stored in the environment variable `ADDR` in your terminal session.

Once finished with the changes, please click the *Save* button. Use the *Open Blue Ocean* link from the left-hand menu to switch to the new UI, click the *Run* button, followed by a click on the row of the new build.

I> If you configured Jenkins to spin up new Docker nodes in AWS or GCP, it'll take around a minute until the VM is created and operational.

Please wait until the build reaches the `func-test` stage and finishes executing the second step that executes `helm upgrade`. Once the release under test is installed, switch to the terminal session to confirm that the new release is indeed installed.

```bash
helm ls \
    --tiller-namespace go-demo-3-build
```

The output is as follows.

```
NAME             REVISION UPDATED        STATUS   CHART           NAMESPACE
go-demo-3-2-null 1        Tue Jul 17 ... DEPLOYED go-demo-3-0.0.1 go-demo-3-build
```

As we can see, Jenkins did initiate the process that resulted in the new Helm Chart being installed in the `go-demo-3-build` Namespace.

To be on the safe side, we'll confirm that the Pods are running as well.

```bash
kubectl -n go-demo-3-build \
    get pods
```

The output is as follows

```
NAME                  READY STATUS  RESTARTS AGE
go-demo-3-2-null-...  1/1   Running 4        2m
go-demo-3-2-null-...  1/1   Running 4        2m
go-demo-3-2-null-db-0 2/2   Running 0        2m
jenkins-slave-...     4/4   Running 0        6m
tiller-deploy-...     1/1   Running 0        14m
```

As we can see, the two Pods of the API and one of the DB are running together with `jenkins-slave` Pod created by Jenkins as well as `tiller`.

Please return to Jenkins UI and wait until the build is finished.

![Figure 7-TODO: Jenkins build with the build and the functional testing stage](images/ch07/jenkins-build-func.png)

If everything works as we designed, the release under test should have been removed once the testing was finished. Let's confirm that.

```bash
helm ls \
    --tiller-namespace go-demo-3-build
```

This time, the output is empty, clearly indicating that the Chart was removed.

Let's check the Pods one more time.

```bash
kubectl -n go-demo-3-build \
    get pods
```

The output is as follows

```
NAME              READY STATUS  RESTARTS AGE
tiller-deploy-... 1/1   Running 0        31m
```

Both the Pods of the release under tests as well as Jenkins agent are gone, leaving us only with Tiller. We defined the steps that remove the former, and the latter is done by Jenkins automatically.

Let's move onto the *release stage*.

## Release Stage

In the *release stage* we'll push correctly tagged Docker images to the registry as well as the project's Helm Chart.

In the *build stage*, we're tagging images by including the branch name. That way, we made it clear that an image is not yet fully tested. Now that we executed all sorts of tests that validated that the release is indeed working as expected, we can re-tag the images so that they do not include branch names. That way, everyone in our organization can easily distinguish yet-to-be-tested from production ready releases.

Since we cannot know (easily) whether the Chart included in the project's repository changed or not, during this stage we'll push it to ChartMuseum. If the Chart's release number is unchanged, the push will simply overwrite the existing Chart. Otherwise, we'll have a new Chart release as well.

The major difference between Docker images and Charts is in the way how we're generating releases. Each build will result in a new Docker image tag. Each commit to the repository probably results in changes to the code, so building new images on each build makes perfect sense. Helm Charts, on the other hand, do not change that often.

One thing worth noting is that we will not use ChartMuseum for deploying applications through Jenkins' pipelines. We already have the Chart inside the repository that we're cloning. We'll store them in ChartMuseum only for those that want to deploy Charts manually without Jenkins. A typical user of the Charts in ChartMuseum are developers that want to spin up applications inside local clusters that are outside Jenkins' control.

Just as with the previous stages, we are focused only on the essential steps which you should extend to suit your specific needs. An example that might serve as inspiration for the missing steps are those that would create a release in GitHub, GitLab, or Bitbucket. Also, it might be useful to build Docker images with manifest files in case you're planning on deploying them to different operating system families (e.g., ARM, Windows, etc). We'll skip those, as quite a few others, in an attempt to keep the pipeline simple, and yet fully functional.

![Figure 7-TODO: The essential steps of the release stage](images/ch07/cd-stages-release.png)

Before we move on, we'll need to create a new set of credentials in Jenkins to store ChartMuseum's username and password.

```bash
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/newCredentials"
```

Please type *admin* and both the *Username* and the *Password*.  The *ID* and the *Description* should be set to *chartmuseum*. Once finished, please click the *OK* button to persist the credentials.

![Figure 7-TODO: ChartMuseum Jenkins credentials](images/ch07/jenkins-credentials-cm.png)

Next, we'll retrieve the updated `credentials.xml` file and store it in the `cluster/jenkins` directory. That way, if we want to create a new Jenkins instance, the new credentials will be available just as those that we created in the previous chapter.

```bash
JENKINS_POD=$(kubectl \
    -n go-demo-3-jenkins \
    get pods \
    -l component=go-demo-3-jenkins-jenkins-master \
    -o jsonpath='{.items[0].metadata.name}')

echo $JENKINS_POD

kubectl -n go-demo-3-jenkins cp \
    $JENKINS_POD:var/jenkins_home/credentials.xml \
    cluster/jenkins
```

We retrieved the name of the Pod hosting Jenkins, and used it to copy the `credentials.xml` file.

Now we can update the job.

```bash
open "http://$JENKINS_ADDR/job/go-demo-3/configure"
```

Please replace the existing code with the contents of the [cdp-jenkins-release.groovy Gist](https://gist.github.com/2e89eec6ca991ab676d740733c409d35).

Just as before, we'll explore only the differences between the two pipeline iterations.

```groovy
...
env.CM_ADDR = "cm.acme.com"
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"
env.CHART_VER = "0.0.1"
...
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

We declared a few new environment variables that should be self-explanatory.

We start the steps of the *release stage* inside the `docker` node. Since the nodes in AWS and GCP are dynamic, there is no guarantee that it'll be the same agent as used in the *build stage*. We set retention to ten minutes which is more than enough time between the two requests for the node. However, some other build might have requested the node in between and, in that case, a new one would be created. Therefore, we cannot be certain that it's the same physical VM. To mitigate that, the first step is pulling the image we build previously, thus ensuring that the cache is used in subsequent steps.

Next, we're creating two tags. One is based on the release (build display name), and the other on `latest`. We'll use the more specific tag, while leaving the option to others to use the `latest`.

Further on, we're logging to Docker Hub and pushing the new tags.

Finally, we switched to the `helm` container of the `podTemplate`. Once inside, we packaged the Chart and pushed it to ChartMuseum with `curl`. The important element is the environment variable `CHART_VER`. It contains the version of the Chart that **must** correspond to the version in `Chart.yaml` file. We're using it to know which file to push. Truth be told, we could have parsed the output of the `helm package` command. However, since Charts do not change that often, it might be less work to update the version in two places, than to add the parsing to the code. It is true that having the same thing in two places increases the chances of an error by omission. Later on, we'll switch to Shared Libraries and the code will be moved to a different repository. I invite you to a challenge to to make a PR that will improve that.

Before we move on, you'll need to make the necessary changes to the values of the environment variables. Most likely, all you need to do is change `vfarcic` to your Docker Hub and GitHub users as well as `acme.com` in addresses to the value of the environment variable `ADDR` available in your terminal session.

Don't forget to click the *Save* button to persist the change and follow the same processes as before to run a new build by clicking the *Open Blue Ocean* link from the left-hand menu, followed with the *Run* button, and a click on the row of the new build. Please wait until the build is finished.

![Figure 7-TODO: Jenkins build with the build, the functional testing, and the release stages](images/ch07/jenkins-build-release.png)

TODO: Continue

```bash
open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"
```

![Figure 7-TODO: Images pushed to Docker Hub](images/ch07/docker-hub-go-demo-3.png)

```bash
curl -u admin:admin \
    "http://$CM_ADDR/index.yaml"
```

```yaml
apiVersion: v1
entries:
  go-demo-3:
  - apiVersion: v1
    created: "2018-07-17T21:53:30.760065856Z"
    description: A silly demo based on API written in Go and MongoDB
    digest: d73134fc9ff594e9923265476bac801b1bd38d40548799afd66328158f0617d8
    home: http://www.devopstoolkitseries.com/
    keywords:
    - api
    - backend
    - go
    - database
    - mongodb
    maintainers:
    - email: viktor@farcic.com
      name: Viktor Farcic
    name: go-demo-3
    sources:
    - https://github.com/vfarcic/go-demo-3
    urls:
    - charts/go-demo-3-0.0.1.tgz
    version: 0.0.1
generated: "2018-07-17T21:56:28Z"
```

## Deploy Stage

TODO: Explanation

TODO: Diagram

```bash
open "http://$JENKINS_ADDR/job/go-demo-3/configure"

# Replace the script with the one that follows
```

Please replace the existing code with the contents of the [cdp-jenkins-deploy.groovy Gist](https://gist.github.com/3657e7262b65749f29ddd618cf511d72).

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build
```

![Figure 7-TODO: Jenkins build with all the continuous deployment stages](images/ch07/jenkins-build-deploy.png)

```bash
helm ls \
    --tiller-namespace go-demo-3-build
```

```
NAME      REVISION UPDATED        STATUS   CHART           NAMESPACE
go-demo-3 1        Wed Jul 18 ... DEPLOYED go-demo-3-0.0.1 go-demo-3
```

```bash
helm history go-demo-3 \
    --tiller-namespace go-demo-3-build
```

```
REVISION UPDATED        STATUS   CHART           DESCRIPTION     
1        Wed Jul 18 ... DEPLOYED go-demo-3-0.0.1 Install complete
```

```bash
kubectl -n go-demo-3 get pods
```

```
NAME           READY STATUS  RESTARTS AGE
go-demo-3-...  1/1   Running 2        6m
go-demo-3-...  1/1   Running 2        6m
go-demo-3-...  1/1   Running 2        6m
go-demo-3-db-0 2/2   Running 0        6m
go-demo-3-db-1 2/2   Running 0        6m
go-demo-3-db-2 2/2   Running 0        5m
```

```bash
curl "http://go-demo-3.$ADDR/demo/hello"
```

```
hello, world!
```

```bash
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
```

![Figure 7-TODO: Jenkins Global Pipeline Libraries configuration screen](images/ch07/jenkins-global-pipeline-libraries.png)

```bash
kubectl -n go-demo-3-jenkins cp \
    $JENKINS_POD:var/jenkins_home/org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml \
    cluster/jenkins/secrets

open "http://$JENKINS_ADDR/job/go-demo-3/configure"
```

Please replace the existing code with the contents of the [cdp-jenkins-lib.groovy Gist](https://gist.github.com/e9821d0430ca909d68eecc7ccbb1825d).

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click on the row of the new build

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

helm ls \
    --tiller-namespace go-demo-3-build
```

```
NAME      REVISION UPDATED        STATUS   CHART           NAMESPACE
go-demo-3 2        Wed Jul 18 ... DEPLOYED go-demo-3-0.0.1 go-demo-3
```

```bash
helm history go-demo-3 \
    --tiller-namespace go-demo-3-build
```

```
REVISION UPDATED        STATUS     CHART           DESCRIPTION
1        Wed Jul 18 ... SUPERSEDED go-demo-3-0.0.1 Install complete
2        Wed Jul 18 ... DEPLOYED   go-demo-3-0.0.1 Upgrade complete
```

```bash
kubectl -n go-demo-3 get pods
```

```
NAME           READY STATUS  RESTARTS AGE
go-demo-3-db-0 2/2   Running 0        28m
go-demo-3-db-1 2/2   Running 0        27m
go-demo-3-db-2 2/2   Running 0        27m
go-demo-3-...  1/1   Running 0        4m
go-demo-3-...  1/1   Running 0        4m
go-demo-3-...  1/1   Running 0        4m
```

```bash
curl "http://go-demo-3.$ADDR/demo/hello"
```

```
hello, world!
```

## Jenkinsfile & Multistage Builds

```bash
cat ../go-demo-3/Jenkinsfile
```

```groovy
import java.text.SimpleDateFormat

def props
def label = "jenkins-slave-${UUID.randomUUID().toString()}"
currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER

podTemplate(
  label: label,
  namespace: "go-demo-3-build", // Not allowed with declarative
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
    volumeMounts:
    - name: build-config
      mountPath: /etc/config
  - name: kubectl
    image: vfarcic/kubectl
    command: ["cat"]
    tty: true
  - name: golang
    image: golang:1.9
    command: ["cat"]
    tty: true
  volumes:
  - name: build-config
    configMap:
      name: build-config
"""
) {
  node(label) {
    stage("build") {
      container("helm") {
        sh "cp /etc/config/build-config.properties ."
        props = readProperties interpolate: true, file: "build-config.properties"
      }
      node("docker") { // Not allowed with declarative
        checkout scm
        k8sBuildImageBeta(props.image)
      }
    }
    stage("func-test") {
      try {
        container("helm") {
          checkout scm
          k8sUpgradeBeta(props.project, props.domain)
        }
        container("kubectl") {
          k8sRolloutBeta(props.project)
        }
        container("golang") {
          k8sFuncTestGolang(props.project, props.domain)
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          k8sDeleteBeta(props.project)
        }
      }
    }
    if ("${BRANCH_NAME}" == "master") {
      stage("release") {
        node("docker") {
          k8sPushImage(props.image)
        }
        container("helm") {
          k8sPushHelm(props.project, props.chartVer, props.cmAddr)
        }
      }
      stage("deploy") {
        try {
          container("helm") {
            k8sUpgrade(props.project, props.addr)
          }
          container("kubectl") {
            k8sRollout(props.project)
          }
          container("golang") {
            k8sProdTestGolang(props.addr)
          }
        } catch(e) {
          container("helm") {
            k8sRollback(props.project)
          }
        }
      }
    }
  }
}
```

```bash
cat ../go-demo-3/k8s/build-config.yml
```

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  creationTimestamp: 2016-02-18T19:14:38Z
  name: build-config
  namespace: go-demo-3-build
data:
  build-config.properties: |
    project=go-demo-3
    image=vfarcic/go-demo-3
    domain=acme.com
    addr=go-demo-3.acme.com
    cmAddr=cm.acme.com
    chartVer=0.0.1
```

```bash
cat ../go-demo-3/k8s/build-config.yml \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | kubectl apply -f - --record

open "http://$JENKINS_ADDR/job/go-demo-3/"

# Click *Delete Pipeline*

open "http://$JENKINS_ADDR/blue/create-pipeline"

# Select *GitHub*

# Type *Your GitHub access token*

# TODO: Instructions for creating the token

# Select the organization

# Type *go-demo-3* in the *Search...* field

# Select *go-demo-3*

# Click the *Create Pipeline* button

# TODO: Observe multiple jobs

# TODO: Click the *Branches* tab (master, feature-1, feature-2)

# TODO: Click the *Pull Requests* tab

# TODO: Click the *Activity* tab

# TODO: Not enough capacity to run the builds in parallel

# Wait until *feature-1*, *feature-2*, or *PR-1* builds are finished (*PR-2* will fail)

# Click on the build and observe that it did not execute all the stages (only *build* and *func-test*)

# Wait until PR-1 build starts

export GH_USER=[...]

open "https://github.com/$GH_USER/go-demo-3/pull/1"

# Observe the status of the build
```

![Figure 7-TODO: Jenkins integration with GitHub pull requests](images/ch07/jenkins-github-pr.png)

```bash
# Wait until *master* build is finished

helm ls \
    --tiller-namespace go-demo-3-build
```

```
NAME      REVISION UPDATED        STATUS   CHART           NAMESPACE
go-demo-3 3        Wed Jul 18 ... DEPLOYED go-demo-3-0.0.1 go-demo-3
```

```bash
helm history go-demo-3 \
    --tiller-namespace go-demo-3-build
```

```
REVISION UPDATED        STATUS     CHART           DESCRIPTION
1        Wed Jul 18 ... SUPERSEDED go-demo-3-0.0.1 Install complete
2        Wed Jul 18 ... SUPERSEDED go-demo-3-0.0.1 Upgrade complete
3        Wed Jul 18 ... DEPLOYED   go-demo-3-0.0.1 Upgrade complete
```

```bash
kubectl -n go-demo-3 get pods
```

```
NAME           READY STATUS  RESTARTS AGE
go-demo-3-...  1/1   Running 0        5m
go-demo-3-...  1/1   Running 0        5m
go-demo-3-...  1/1   Running 0        5m
go-demo-3-db-0 2/2   Running 0        53m
go-demo-3-db-1 2/2   Running 0        53m
go-demo-3-db-2 2/2   Running 0        52m
```

```bash
curl "http://go-demo-3.$ADDR/demo/hello"
```

```
hello, world!
```

```bash
open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

# Observe that tags now have branch names instead of *null*
```

## Scripted vs Declarative Pipeline

TODO: Write

## Webhooks

```bash
# TODO: No public IP for Docker for Mac/Windows and minikube
```

TODO: Code

## Manual Testing & The Attempt To Use The Same Artifacts

TODO: Write

TODO: Reference to the CI chapter

## What Now?

```bash
# TODO: Builds were slow due to low resources

# TODO: Make sure that at least 10 minutes passed since the last build or the VM will stay in AWS

cd cd/docker-build

vagrant suspend

cd ../../
```
