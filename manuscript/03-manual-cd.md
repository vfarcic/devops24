# Defining Continuous Deployment {#manual-cd}

T> The work on defining Continuous Deployment (CDP) steps should not start in Jenkins or any other similar tool. Instead, we should focus on Shell commands and scripts and turn our attention to the CI/CD tools only once we are confident that we can execute the full process with only a few commands.

We should be able to execute most of the CDP steps from anywhere. Developers should be able to run them locally from a Shell. Others might want to integrate them into their favorite IDEs. The number of ways all or parts of the CDP steps can be executed might be quite huge. Running them as part of every commit is only one of those permutations. The way we execute CDP steps should be agnostic to the way we define them. If we add the need for very high (if not complete) automation, it is clear that the steps must be simple commands or Shell scripts. Adding anything else to the mix is likely to result in tight coupling which limits our ability to be independent of the tools we're using to run those steps.

Our goal in this chapter is to define the minimum number of steps a continuous deployment process might need. From there on, it would be up to you to extend those steps to serve a particular use-case you might be facing in your project.

Once we know what should be done, we'll proceed and define the commands that will get us there. We'll do our best to create the CDP steps in a way that they can be easily ported to Jenkins, CodeShip, or any other tool we might choose to use. We'll try to be tools agnostic. There will always be some steps that are very specific to the tools we'll use, but I hope that they will be limited to scaffolding, and not the CDP logic.

I> This chapter assumes that you are already familiar with LimitRanges and ResourceQuotas, besides the requirements from the previous chapters. If you're not, please refer to [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy) for more info.

Whether we'll manage to reach our goals entirely is yet to be seen. For now, we'll ignore the existence of Jenkins, CodeShip, and all the other tools that could be used to orchestrate our continuous deployment processes. Instead, we'll focus purely on Shell and the commands we need to execute. We might write a script or two though.

## To Continuously Deliver Or To Continuously Deploy?

Everyone wants to implement continuous delivery or deployment. After all, the benefits are too significant to be ignored. Increase the speed of delivery, increase the quality, decrease the costs, free people to dedicate time to what brings value, and so on and so forth. Those improvements are like music to any decision maker, especially if that person has a business background. If a tech geek can articulate the benefits continuous delivery brings to the table, when he asks a business representative for a budget, the response is almost always "Yes! Do it."

By now, you might be confused with the differences between continuous integration, delivery, and deployment, so I'll do my best to walk you through the primary objectives behind each.

You are doing continuous integration (CI) if you have a set of automated processes that are executed every time you commit a change to a code repository. What we're trying to accomplish with CI is a state when every commit is validated shortly after a commit. We want to know not only whether what we did works, but also whether it integrates with the work our colleagues did. That's why it is crucial that everyone merges code to the master branch or, at least, to some other common branch. It does not matter much how we name it. What does matter is that not much time passes since the moment we fork the code. That can be hours or maybe days. If we delay integration for more than that, we are risking spending too much time working on something that breaks work of others.

I> Continuous integration assumes that only a part of the process is automated and that human intervention is needed after machines are finished with their work. That intervention often consists of manual tests or even manual deployments to one or more environments.

The problem with continuous integration is that the level of automation is not high enough. We do not trust the process enough. We feel that it provides benefits, but we also require a second opinion. We need humans to confirm the result of the process executed by machines.

Continuous delivery (CD) is a superset of continuous integration. It features a fully automated process executed on every commit. If none of the steps in the process fail, we declare the commit as ready for production.

I> With continuous delivery, we do not deploy to production automatically because someone needs to make a business decision. The reason to postpone or skip deploying a release to production is anything but technical.

Finally, continuous deployment (CDP) is almost the same as continuous delivery. All the steps in the process are in both cases fully automated. The only difference is that the button that says "deploy to production" is gone.

I> With continuous deployment (CDP), every commit that passed all the automated steps is deployed to production.

Even though CD and CDP are almost the same from the process perspective, the latter might require changes in the way we develop our applications. We might, for example, need to start using feature toggles that allow us to disable partially finished features. Most of the changes required for CDP are things that should be adopted anyways. However, with CDP that need is increased to an even higher level.

We won't go into all the cultural and development changes one would need to employ before attempting to reach the stage where CDP is desirable, or even possible. That would be a subject for a different book and would require much more space than what we have. I am not even going to try to convince you to embrace continuous deployment. There are many valid cases when CDP is not a good option and even more of those when it is not even possible without substantial cultural and technical changes which are outside Kubernetes domain. Statistically speaking, it is likely that you are not ready to embrace continuous deployment.

At this point, you might be wondering whether it makes sense for you to continue reading. Maybe you are indeed not ready for continuous deployment, and maybe thinking this is a waste of time. If that's the case, my message to you is that, it does not matter. The fact that you already have some experience with Kubernetes tells me that you are not a lagger. You chose to embrace a new way of working. You saw the benefits of distributed systems, and you are embracing what surely looked like madness when you made your first steps.

If you reached this far, you are ready to learn and practice the processes that follow. You might not be ready to do continuous deployment. That's OK. You can fall back to continuous delivery. If that is also too big of a scratch, you can start with continuous integration. The reason I'm saying that it does not matter lies in the fact that most of the steps are the same in all those cases. No matter whether you are planning to do CI, CD, or CDP, you have to build something, you have to run some tests, and you have to deploy your applications somewhere.

I> The difference between continuous integration, delivery, and deployment is not in processes, but in the level of confidence we have in them.

From the technical perspective, it does not matter whether we deploy to a local cluster, to the one dedicated to testing, or to production. A deployment to a Kubernetes cluster is (more or less) the same no matter what its purpose is. You might choose to have a single cluster for everything. That's also OK. That's why we have Namespaces. You might not trust your tests. Still, that's not a problem from the start because the way we execute tests is the same no matter how much we trust them. I can continue for a while with statements like that. What truly matters is that the process is, more or less, the same, no matter how much you trust it. Trust is earned with time.

I> If you do want to read very opinionated and politically incorrect thoughts on what you might be missing, please visit [The Ten Commandments Of Continuous Delivery](https://technologyconversations.com/2017/03/06/the-ten-commandments-of-continuous-delivery/).

The goal of this book is to teach you how to employ continuous deployment into a Kubernetes cluster. It's up to you to decide when are your expertise, culture, and code ready for it. The pipeline we'll build should be the same no matter whether you're planning to use CI, CD, or CDP. Only a few arguments might change.

All in all, the first objective is to define the base set of steps for our continuous deployment processes. We'll worry about executing those steps later.

## Defining Continuous Deployment Goals

The continuous deployment process is relatively easy to explain, even though implementation might get tricky. We'll split our requirements into two groups. We'll start with a discussion about the overall goals that should be applied to the whole process. To be more precise, we'll talk about what I consider non-negotiable requirements.

A Pipeline needs to be secure. Typically, that would not be a problem. In past before Kubernetes was born, we would run the pipeline steps on separate servers. We'd have one dedicated to building and another for testing. We might have one for integration and another for performance tests. Once we adopt container schedulers and move into clusters, we lose control of the servers. Even though it is possible to run something on a specific server, that is highly discouraged in Kubernetes. We should let Kubernetes schedule Pods with as few restraints as possible. That means that our builds and tests might run in the production cluster and that might prove not to be secure. If we are not careful, a malicious user might exploit shared space. Even more likely, our tests might contain an unwanted side-effect that could put production applications at risk.

We could create separate clusters. One can be dedicated to the production and the other to everything else. While that is indeed an option we should explore, Kubernetes already provides the tools we need to make a cluster secure. We have RBAC, ServiceAccounts, Namespaces, PodSecurityPolicies, NetworkPolicies, and a few other resources at our disposal.So we can share the same cluster and be reasonably secure at the same time.

Security is not the only requirement. Even when everything is secured, we still need to make sure that our pipelines do not affect negatively other applications running inside a cluster. If we are not careful, tests might, for example, request or use too many resources and, as a result, we might be left with insufficient memory for the other applications and processes running inside our cluster. Fortunately, Kubernetes has a solution for those problems as well. We can combine Namespaces with LimitRanges and ResourceQuotas. While they do not provide a complete guarantee that nothing will go wrong (nothing does), they do provide a set of tools that, when used correctly, do provide reasonable guarantees that the processes in a Namespace will not go "wild".

Our pipeline should be fast. If it takes too much time for it to execute, we might be compelled to start working on a new feature before the execution of the pipeline is finished. If it fails, we will have to decide whether to stop working on the new feature and incur context switching penalty or to ignore the problem until we are free to deal with it. While both scenarios are bad, the latter is worst and should be avoided at all costs. A failed pipeline must have the highest priority. Otherwise, what's the point of having automated and continuous processes if dealing with issues is eventual?

I> Continuous deployment pipeline must be secured, it should produce no side-effects to the rest of the applications in a cluster, and it should be fast.

The problem is that we often cannot accomplish those goals independently. We might be forced to make tradeoffs. Security often clashes with speed, and we might need to strike a balance between the two.

Finally, the primary goal, that one that is above all the others, is that our continuous deployment pipeline must be executed on every commit to the master branch. That will provide continuous feedback about the readiness of the system, and, in a way, it will force people to merge to the master often. When we create a branch, it is non-existent until it gets back to the master, or whatever is the name of the production-ready branch. The more time passes until the merge, the bigger the chance that our code does not integrate with the work of our colleagues.

Now that we have the high-level objectives straighten out, we should switch our focus to the particular steps a pipeline should contain.

## Defining Continuous Deployment Steps

We'll try to define a minimum set of steps any continuous deployment pipeline should execute. Do not take them literally. Every company is different, and every project has something special. You will likely have to extend them to suit your particular needs. However, that should not be a problem. Once we get a grip on those that are mandatory, extending the process should be relatively straightforward, except if you need to interact with tools that do not have a well-defined API nor a good CLI. If that's the case, my recommendation is to drop those tools. They're not worthy of the suffering they often impose.

We can split the pipeline into several stages. We'll need to *build* the artifacts (after running static tests and analysis). We have to run *functional tests* because unit testing is not enough. We need to create a *release* and *deploy* it somewhere (hopefully to production). No matter how much we trust the earlier stages, we do have to run tests to validate that the deployment (to production) was successful. Finally, we need to do some cleanup at the end of the process and remove all the processes created for the Pipeline. It would be pointless to leave them running idle.

All in all, the stages are as follows.

* Build stage
* Functional testing stage
* Release stage
* Deploy stage
* Production testing stage
* Cleanup stage

Here's the plan. In the build stage, we'll build a Docker image and push it to a registry (in our case Docker Hub). However, since building untested artifacts should be stopped, we are going to run static tests before the actual build. Once our Docker image is pushed, we'll deploy the application and run tests against it. If everything works as expected, we'll make a new release and deploy it to production. To be on the safe side, we'll run another round of tests to validate that the deployment was indeed successful in production. Finally, we'll clean up the system by removing everything except the production release.

![Figure 3-1: The stages of a continuous deployment pipeline](images/ch03/manual-cd-stages.png)

We'll discuss the steps of each of those stages later on. For now, we need a cluster we'll use for the hands-on exercises that'll help us get a better understanding of the pipeline we'll build later. If we are successful with the manually executed steps, writing pipeline script should be relatively simple.

## Creating A Cluster

We'll start the hands-on part by going back to the local copy of the `vfarcic/k8s-specs` repository and pulling the latest version.

I> All the commands from this chapter are available in the [03-manual-cd.sh](https://gist.github.com/bf33bf65299870b68b3de8dbe1b21c36) Gist.

```bash
cd k8s-specs

git pull
```

Just as in the previous chapters, we'll need a cluster if we are to do the hands-on exercises. The rules are still the same. You can continue using the same cluster as before, or you can switch to a different Kubernetes flavor. You can continue using one of the Kubernetes distributions listed below, or be adventurous and try something different. If you go with the latter, please let me know how it went, and I'll test it myself and incorporate it into the list.

W> **Beware!** The minimum requirements for the cluster are now slightly higher. We'll need at least 3 CPUs and 3 GB RAM if running a single-node cluster, and slightly more if those resources are spread across multiple nodes. If you're using Docker For Mac or Windows, minikube, or minishift, the specs are 1 CPU and 1 GB RAM higher. For GKE, we need at least 4 CPUs, so we changed the machine type to *n1-highcpu-2*. For everyone else, the requirements are still the same.

The Gists with the commands I used to create different variations of Kubernetes clusters are as follows.

* [docker4mac-3cpu.sh](https://gist.github.com/bf08bce43a26c7299b6bd365037eb074): **Docker for Mac** with 3 CPUs, 3 GB RAM, and with **nginx Ingress**.
* [minikube-3cpu.sh](https://gist.github.com/871b5d7742ea6c10469812018c308798): **minikube** with 3 CPUs, 3 GB RAM, and with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled.
* [kops.sh](https://gist.github.com/2a3e4ee9cb86d4a5a65cd3e4397f48fd): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, and with **nginx Ingress** (assumes that the prerequisites are set through [Appendix B](#appendix-b)).
* [minishift-3cpu.sh](https://gist.github.com/2074633688a85ef3f887769b726066df): **minishift** with 3 CPUs, 3 GB RAM, and version 1.16+.
* [gke-2cpu.sh](https://gist.github.com/e3a2be59b0294438707b6b48adeb1a68): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-2 (2 CPUs, 1.8 GB RAM) nodes (one in each zone), and with **nginx Ingress** controller running on top of the "standard" one that comes with GKE. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files if you prefer NOT to install nginx Ingress.
* [eks.sh](https://gist.github.com/5496f79a3886be794cc317c6f8dd7083): **Elastic Kubernetes Service (EKS)** with 2 t2.medium nodes, with **nginx Ingress** controller, and with a **default StorageClass**.

Now that we have a cluster, we can move into a more exciting part of this chapter. We'll start defining and executing stages and steps of a continuous deployment pipeline.

## Creating Namespaces Dedicated To Continuous Deployment Processes

If we are to accomplish a reasonable level of security of our pipelines, we need to run them in dedicated Namespaces. Our cluster already has RBAC enabled, so we'll need a ServiceAccount as well. Since security alone is not enough, we also need to make sure that our pipeline does not affect other applications. We'll accomplish that by creating a LimitRange and a ResourceQuota.

I believe that in most cases we should store everything an application needs in the same repository. That makes maintenance much simpler and enables the team in charge of that application to be in full control, even though that team might not have all the permissions to create the resources in a cluster.

We'll continue using `go-demo-3` repository but, since we'll have to change a few things, it is better if you apply the changes to your fork and, maybe, push them back to GitHub.

```bash
open "https://github.com/vfarcic/go-demo-3"
```

If you're not familiar with GitHub, all you have to do is to log in and click the *Fork* button located in the top-right corner of the screen.

Next, we'll remove the `go-demo-3` repository (if you happen to have it) and clone the fork.

Make sure that you replace `[...]` with your GitHub username.

```bash
cd ..

rm -rf go-demo-3

export GH_USER=[...]

git clone https://github.com/$GH_USER/go-demo-3.git

cd go-demo-3
```

The only thing left is to edit a few files. Please open *k8s/build.yml* and *k8s/prod.yml* files in your favorite editor and change all occurrences of `vfarcic` with your Docker Hub user.

The namespace dedicated for all building and testing activities of the `go-demo-3` project is defined in the `k8s/build-ns.yml` file stored in the project repository.

```bash
git pull

cat k8s/build-ns.yml
```

The output is as follows.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo-3-build

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: build
  namespace: go-demo-3-build

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: build
  namespace: go-demo-3-build
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: build

---

apiVersion: v1
kind: LimitRange
metadata:
  name: build
  namespace: go-demo-3-build
spec:
  limits:
  - default:
      memory: 200Mi
      cpu: 0.2
    defaultRequest:
      memory: 100Mi
      cpu: 0.1
    max:
      memory: 500Mi
      cpu: 0.5
    min:
      memory: 10Mi
      cpu: 0.05
    type: Container

---

apiVersion: v1
kind: ResourceQuota
metadata:
  name: build
  namespace: go-demo-3-build
spec:
  hard:
    requests.cpu: 2
    requests.memory: 3Gi
    limits.cpu: 3
    limits.memory: 4Gi
    pods: 15
```

If you are familiar with Namespaces, ServiceAccounts, LimitRanges, and ResourceQuotas, the definition should be fairly easy to understand.

We defined the `go-demo-3-build` Namespace which we'll use for all our CDP tasks. It'll contain the ServiceAccount `build` bound to the ClusterRole `admin`. As a result, containers running inside that Namespace will be able to do anything they want. It'll be their playground.

We also defined the LimitRange named `build`. It'll make sure to give sensible defaults to the Pods that running in the Namespace. That way we can create Pods from which we'll build and test without worrying whether we forgot to specify resources they need. After all, most of us do not know how much memory and CPU a build needs. The same LimitRange also contains some minimum and maximum limits that should prevent users from specifying too small or too big resource reservations and limits.

Finally, since the capacity of our cluster is probably not unlimited, we defined a ResourceQuota that specifies the total amount of memory and CPU for requests and limits in that Namespace. We also defined that the maximum number of Pods running in that Namespace cannot be higher than fifteen.

If we do have more Pods than what we can place in that Namespace, some will be pending until others finish their work and resources are liberated.

It is very likely that the team behind the project will not have sufficient permissions to create new Namespaces. If that's the case, the team would need to let cluster administrator know about the existence of that YAML. In turn, he (or she) would review the definition and create the resources, once he (or she) deduces that they are safe. For the sake of simplicity, you are that person, so please execute the command that follows.

```bash
kubectl apply \
    -f k8s/build-ns.yml \
    --record
```

As you can see from the output, the `go-demo-3-build` Namespace was created together with a few other resources.

Now that we have a Namespace dedicated to the lifecycle of our application, we'll create another one that to our production release.

```bash
cat k8s/prod-ns.yml
```

The `go-demo-3` Namespace is very similar to `go-demo-3-build`. The major difference is in the RoleBinding. Since we can assume that processes running in the `go-demo-3-build` Namespace will, at some moment, want to deploy a release to production, we created the RoleBinding `build` which binds to the ServiceAccount `build` in the Namespace `go-demo-3-build`.

We'll `apply` this definition while still keeping our cluster administrator's hat.

```bash
kubectl apply \
    -f k8s/prod-ns.yml \
    --record
```

Now we have two Namespaces dedicated to the `go-demo-3` application. We are yet to figure out which tools we'll need for our continuous deployment pipeline.

## Defining A Pod With The Tools

Every application is different, and the tools we need for a continuous deployment pipeline vary from one case to another. For now, we'll focus on those we'll need for our *go-demo-3* application.

Since the application is written in Go, we'll need `golang` image to download the dependencies and run the tests. We'll have to build Docker images, so we should probably add a `docker` container as well. Finally, we'll have to execute quite a few `kubectl` commands. For those of you using OpenShift, we'll need `oc` as well. All in all, we need a Pod with `golang`, `docker`, `kubectl`, and (for some of you) `oc`.

The *go-demo-3* repository already contains a definition of a Pod with all those containers, so let's take a closer look at it.

```bash
cat k8s/cd.yml
```

The output is as follows.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cd
  namespace: go-demo-3-build
spec:
  containers:
  - name: docker
    image: docker:18.03-git
    command: ["sleep"]
    args: ["100000"]
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: docker-socket
      mountPath: /var/run/docker.sock
    workingDir: /workspace
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    workingDir: /workspace
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    workingDir: /workspace
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    workingDir: /workspace
  serviceAccount: build
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
      type: Socket
  - name: workspace
    emptyDir: {}
```

Most of the YAML defines the containers based on images that contain the tools we need. What makes it special is that all the containers have the same mount called `workspace`. It maps to `/workspace` directory inside containers, and it uses `emptyDir` volume type.

We'll accomplish two things with those volumes. On the one hand, all the containers will have a shared space so the artifacts generated through the actions we will perform in one will be available in the other. On the other hand, since `emptyDir` volume type exists only just as long as the Pod is running, it'll be deleted when we remove the Pod. As a result, we won't be leaving unnecessary garbage on our nodes or external drives.

To simplify the things and save us from typing `cd /workspace`, we set `workingDir` to all the containers.

Unlike most of the other Pods we usually run in our clusters, those dedicated to CDP processes are short lived. They are not supposed to exist for a long time nor should they leave any trace of their existence once they finish executing the steps we are about to define.

The ability to run multiple containers on the same node and with a shared file system and networking will be invaluable in our quest to define continuous deployment processes. If you were ever wondering what the purpose of having Pods as entities that envelop multiple containers is, the steps we are about to explore will hopefully provide a perfect use-case.

Let's create the Pod.

```bash
kubectl apply -f k8s/cd.yml --record
```

Pleases confirm that all the containers of the Pod are up and running by executing `kubectl -n go-demo-3-build get pods`. You should see that `4/4` are `ready`.

Now we can start working on our continuous deployment pipeline steps.

## Executing Continuous Integration Inside Containers

The first stage in our continuous deployment pipeline will contain quite a few steps. We'll need to check out the code, to run unit tests and any other static analysis, to build a Docker image, and to push it to the registry. If we define continuous integration (CI) as a set of automated steps followed with manual operations and validations, we can say that the steps we are about to execute can be qualified as CI.

The only thing we truly need to make all those steps work is Docker client with the access to Docker server. One of the containers of the `cd` Pod already contains it. If you take another look at the definition, you'll see that we are mounting Docker socket so that the Docker client inside the container can issue commands to Docker server running on the host. Otherwise, we would be running Docker-in-Docker, and that is not a very good idea.

Now we can enter the `docker` container and check whether Docker client can indeed communicate with the server.

```bash
kubectl -n go-demo-3-build \
    exec -it cd -c docker -- sh

docker container ls
```

Once inside the `docker` container, we executed `docker container ls` only as a proof that we are using a client inside the container which, in turn, uses Docker server running on the node. The output is the list of the containers running on top of one of our servers.

Let's get moving and execute the first step.

We cannot do much without the code of our application, so the first step is to clone the repository.

Make sure that you replace `[...]` with your GitHub username in the command that follows.

```bash
export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git \
    .
```

W> It is easy to overlook that there is a dot (`.`) in the `git` command. It specifies the current directory as the destination.

We cloned the repository into the `workspace` directory. That is the same folder we mounted as an `emptyDir` volume and is, therefore, available in all the containers of the `cd` Pod. Since that folder is set as `workingDir` of the container, we did not need to `cd` into it.

Please note that we cloned the whole repository and, as a result, we are having a local copy of the HEAD commit of the master branch. If this were a "real" pipeline, such a strategy would be unacceptable. Instead, we should have checked out a specific branch and a commit that initiated the process. However, we'll ignore those details for now, and assume that we'll solve them when we move the pipeline steps into Jenkins and other tools.

Next, we'll build an image and push it to Docker Hub. To do that, we'll need to login first.

Make sure that you replace `[...]` with your Docker Hub username in the command that follows.

```bash
export DH_USER=[...]

docker login -u $DH_USER
```

Once you enter your password, you should see the `Login Succeeded` message.

We are about to execute the most critical step of this stage. We'll build an image.

At this moment you might be freaking out. You might be thinking that I went insane. A Pastafarian and a firm believer that nothing should be built without running tests first just told you to build an image as the first step after cloning the code. Sacrilege!

However, this Dockerfile is special, so let's take a look at it.

```bash
cat Dockerfile
```

The output is as follows.

```
FROM golang:1.9 AS build
ADD . /src
WORKDIR /src
RUN go get -d -v -t
RUN go test --cover -v ./... --run UnitTest
RUN go build -v -o go-demo


FROM alpine:3.4
MAINTAINER 	Viktor Farcic <viktor@farcic.com>
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
EXPOSE 8080
ENV DB db
CMD ["go-demo"]
COPY --from=build /src/go-demo /usr/local/bin/go-demo
RUN chmod +x /usr/local/bin/go-demo
```

Normally, we'd run a container, in this case, based on the `golang` image, execute a few processes, store the binary into a directory that was mounted as a volume, exit the container, and build a new image using the binary created earlier. While that would work fairly well, multi-stage builds allow us to streamline the processes into a single `docker image build` command.

If you're not following Docker releases closely, you might be wondering what a multi-stage build is. It is a feature introduced in Docker 17.05 that allows us to specify multiple `FROM` statements in a Dockerfile. Each `FROM` instruction can use a different base, and each starts a new stage of the build process. Only the image created with the last `FROM` segment is kept. As a result, we can specify all the steps we need to execute before building the image without increasing its size.

In our example, we need to execute a few Go commands that will download all the dependencies, run unit tests, and compile a binary. Therefore, we specified `golang` as the base image followed with the `RUN` instruction that does all the heavy lifting. Please note that the first `FROM` statement is named `build`. We'll see why that matters soon.

Further down, we start over with a new `FROM` section that uses `alpine`. It is a very minimalist linux distribution (a few MB in size) that guarantees that our final image is minimal and is not cluttered with unnecessary tools that are typically used in "traditional" Linux distros like `ubuntu`, `debian`, and `centos`. Further down we are creating everything our application needs, like the `DB` environment variable used by the code to know where the database is, the command that should be executed when a container starts, and so on. The critical part is the `COPY` statement. It copies the binary we created in the `build` stage into the final image.

I> Please consult [Dockerfile reference](https://docs.docker.com/engine/reference/builder/) and [Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) for more information.

Let's build the image.

```bash
docker image build \
    -t $DH_USER/go-demo-3:1.0-beta \
    .
```

W> On some clusters you might receive `error parsing reference: "golang:1.9 AS build" is not a valid repository/tag: invalid reference format` error message. That probably means that Docker server is older than v17.05. You can check it with `docker version` command.
W> If you are indeed unable to use multi-stage builds, you've stumbled into one of the problems with this approach. We'll solve this issue later (in one of the next chapters). For now, please execute the commands that follow as a workaround.
W>
W> `docker image pull vfarcic/go-demo-3:1.0-beta`
W>
W> `docker image tag vfarcic/go-demo-3:1.0-beta $DH_USER/go-demo-3:1.0-beta`
W>
W> Those commands pulled my image and tagged it as yours. Remember that this is only a workaround until we find a better solution.

We can see from the output that the steps of our multi-stage build were executed. We downloaded the dependencies, run unit tests, and built the `go-demo` binary. All those things were temporary, and we do not need them in the final image. There's no need to have a Go compiler, nor to keep the code. Therefore, once the first stage was finished, we can see the message *Removing intermediate container*. Everything was discarded. We started over, and we built the production-ready image with the binary generated in the previous stage.

We have the whole continuous integration process reduced to a single command. Developers can run it on their laptops, and CI/CD tools can use it as part of their extended processes. Isn't that neat?

Let's take a quick look at the images on the node.

```bash
docker image ls
```

The output, limited to the relevant parts, is as follows.

```
REPOSITORY        TAG      IMAGE ID CREATED            SIZE
vfarcic/go-demo-3 1.0-beta ...      54 seconds ago     25.8MB
<none>            <none>   ...      About a minute ago 779MB
...
```

The first two images are the result of our build. The final image (`vfarcic/go-demo-3`) is only 25 MB. It's that small because Docker discarded all but the last stage. If you'd like to know how big your image would be if everything was built in a single stage, please combine the size of the `vfarcic/go-demo-3` image with the size of the temporary image used in the first stage (it's just below `vfarcic/go-demo-3 1.0-beta`).


W> If you had to tag my image as yours as a workaround for build problems, you won't see the second image (the one that is ~780 MB), on the other hand, if you succeded to build your own image, image name will be prefixed with your docker hub username.


The only thing missing is to push the image to the registry (e.g., Docker Hub).

```bash
docker image push \
    $DH_USER/go-demo-3:1.0-beta
```

The image is in the registry and ready for further deployments and testing. Mission accomplished. We're doing continuous integration manually. If we'd place those few commands into a CI/CD tool, we would have the first part of the process up and running.

![Figure 3-2: The build stage of a continuous deployment pipeline](images/ch03/manual-cd-steps-build.png)

We are still facing a few problems. Docker running in a Kubernetes cluster might be too old. It might not support all the features we need. As an example, most of the Kubernetes distributions before 1.10 supported Docker versions older than 17.05. If that's not enough, consider the possibility that you might not even use Docker in a Kubernetes cluster. It is very likely that ContainerD will be the preferable container engine in the future, and that is only one of many choices we can select. The point is that container engine in a Kubernetes cluster should be in charge of running container, and not much more. There should be no need for the nodes in a Kubernetes cluster to be able to build images.

Another issue is security. If we allow containers to mount Docker socket, we are effectively allowing them to control all the containers running on that node. That by itself makes security departments freak out, and for a very good reason. Also, don't forget that we logged into the registry. Anyone on that node could push images to the same registry without the need for credentials. Even if we do log out, there was still a period when everyone could exploit the fact that Docker server is authenticated and authorized to push images.

Truth be told, **we are not preventing anyone from mounting a Docker socket**. At the moment, our policy is based on trust. That should change with PodSecurityPolicy. However, security is not the focus of this book, so I'll assume that you'll set up the policies yourself, if you deem them worthy of your time.

I> We should further restrict what a Pod can and cannot do through [PodSecurityPolicy](https://v1-9.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.9/#podsecuritypolicy-v1beta1-extensions).

If that's not enough, there's also the issue of preventing Kubernetes to do its job. The moment we adopt container schedulers, we accept that they are in charge of scheduling all the processes running inside the cluster. If we start doing things behind their backs, we might end up messing with their scheduling capabilities. Everything we do without going through Kube API is unknown to Kubernetes.

We could use Docker inside Docker. That would allow us to build images inside containers without reaching out to Docker socket on the nodes. However, that requires privileged access which poses as much of a security risk as mounting a Docker socket. Actually, it is even riskier. So, we need to discard that option as well.

Another solution might be to use [kaniko](https://github.com/GoogleContainerTools/kaniko). It allows us to build Docker images from inside Pods. The process is done without Docker so there is no dependency on Docker socket nor there is a need to run containers in privileged mode. However, at the time of this writing (May 2018) *kaniko* is still not ready. It is complicated to use, and it does not support everything Docker does (e.g., multi-stage builds), it's not easy to decipher its logs (especially errors), and so on. The project will likely have a bright future, but it is still not ready for prime time.

Taking all this into consideration, the only viable option we have, for now, is to build our Docker images outside our cluster. The steps we should execute are the same as those we already run. The only thing missing is to figure out how to create a build server and hook it up to our CI/CD tool. We'll revisit this subject later on.

For now, we'll exit the container.

```bash
exit
```

Let's move onto the next stage of our pipeline.

## Running Functional Tests

Which steps do we need to execute in the functional testing phase? We need to deploy the new release of the application. Without it, there would be nothing to test. All the static tests were already executed when we built the image, so everything we do from now on will need a live application.

Deploying the application is not enough, we'll have to validate that at least it rolled out successfully. Otherwise, we'll have to abort the process.

We'll have to be careful how we deploy the new release. Since we'll run it in the same cluster as production, we need to be careful that one does not affect the other. We already have a Namespace that provides some level of isolation. However, we'll have to be careful not to use the same path or domain in Ingress as the one used for production. The two need to be accessible separately from each other until we are confident that the new release meets all the quality standards.

Finally, once the new release is running, we'll execute a set of tests that will validate it. Please note that we will run functional tests only. You should translate that into "in this stage, I run all kinds of tests that require a live application." You might want to add performance and integration tests as well. From the process point of view, it does not matter which tests you run. What matters is that in this stage you run all those that could not be executed statically when we built the image.

If any step in this stage fails, we need to be prepared to destroy everything we did and leave the cluster in the same state as before we started this stage. We'll postpone exploration of rollback steps until one of the next chapters. I'm sure you know how to do it anyway. If you don't, I'll leave you feeling ashamed until the next chapter.

As you probably guessed, we'll need to go into the `kubectl` container for at least some of the steps in this stage. It is already running as part of the `cd` Pod.

Remember, we are performing a manual simulation of a CDP pipeline. We must assume that everything will be executed from inside the cluster, not from your laptop.

```bash
kubectl -n go-demo-3-build \
    exec -it cd -c kubectl -- sh
```

The project contains separate definitions for deploying test and production releases. For now, we are interested only in prior which is defined in `k8s/build.yml`.

```bash
cat k8s/build.yml
```

We won't comment on all the resources defined in that YAML since they are very similar to those we used before. Instead, we'll take a quick look at the differences between a test and a production release.

```bash
diff k8s/build.yml k8s/prod.yml
```

The two are almost the same. One is using `go-demo-3-build` Namespace while the other works with `go-demo-3`. The `path` of the Ingress resource also differs. Non-production releases will be accessible through `/beta/demo` and thus provide separation from the production release accessible through `/demo`. Everything else is the same.

It's a pity that we had to create two separate YAML files only because of a few differences (Namespace and Ingress). We'll discuss the challenges behind rapid deployments using standard YAML files later. For now, we'll roll with what we have.

Even though we separated production and non-production releases, we still need to modify the tag of the image on the fly. The alternative would be to change release numbers with each commit, but that would represent a burden to developers and a likely source of errors. So, we'll go back to exercising "magic" with `sed`.

```bash
cat k8s/build.yml | sed -e \
    "s@:latest@:1.0-beta@g" | \
    tee /tmp/build.yml
```

We output the contents of the `/k8s/build.yml` file, we modified it with `sed` so that the `1.0-beta` tag is used instead of the `latest`, and we stored the output in `/tmp/build.yml`.

Now we can deploy the new release.

```bash
kubectl apply \
    -f /tmp/build.yml --record

kubectl rollout status deployment api
```

We applied the new definition and waited until it rolled out.

Even though we know that the rollout was successful by reading the output, we cannot rely on such methods when we switch to full automation of the pipeline. Fortunately, the `rollout status` command will exit with `0` if everything is OK, and with a different code if it's not.

Let's check the exit code of the last command.

```bash
echo $?
```

The output is `0` thus confirming that the rollout was successful. If it was anything else, we'd need to roll back or, even better, quickly fix the problem and roll forward.

W> ## A note to GKE users
W>
W> GKE uses external load balancer as Ingress. To work properly, the `type` of the service related to Ingress needs to be `NodePort`. Since most of the other Kubernetes flavors do not need it, I kept it as `ClusterIP` (the default type). We'll have to patch the service. Please execute the command that follows.
W>
W> `kubectl -n go-demo-3-build patch svc api -p '{"spec":{"type": "NodePort"}}'`

W> ## A note to minishift users
W>
W> Since OpenShift does not support Ingress (at least not by default), we'll need to add a Route. Please execute the commands that follow.
W>
W> `exit`
W>
W> `kubectl -n go-demo-3-build exec -it cd -c oc -- sh`
W>
W> `oc apply -f k8s/build-oc.yml`
W>
W> We exited `kubectl` container, entered into `oc`, and deployed the route defined in `k8s/build-oc.yml`.

The only thing missing in this stage is to run the tests. However, before we do that, we need to find out the address through which the application can be accessed.

W> ## A note to GKE users
W>
W> Please change `hostname` to `ip` in the command that follows. The `jsonpath` should be `{.status.loadBalancer.ingress[0].ip}`.
W> GKE Ingress spins up an external load balancer, and it might take a while until the IP is generated. Therefore, you might need to repeat the modified command that follows until you get the IP.

W> ## A note to minikube users
W>
W> Please open a separate terminal session and execute `minikube ip`. Remember the output. Change the command that follows to `ADDR=[...]/beta` where `[...]` is the IP you just retrieved.

W> ## A note to minishift users
W>
W> Please change the command that follows to `ADDR=$(oc -n go-demo-3-build get routes -o jsonpath="{.items[0].spec.host}")`.

```bash
ADDR=$(kubectl -n go-demo-3-build \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")/beta

echo $ADDR | tee /workspace/addr

exit
```

We retrieved the `hostname` from Ingress with the appended path (`/beta`) dedicated to beta releases. Further on, we stored the result in the `/workspace/addr` file. That way we'll be able to retrieve it from other containers running in the same Pod. Finally, we exited the container since the next steps will require a different one.

I> Ingress is painful, and its definition varies from one Kubernetes platform to another. If you choose to stick with one Kubernetes flavor forever and ever, that is not a big deal. On the other hand, if you want to be compatible and be able to deploy your applications to any Kubernetes cluster, you'll have to change the strategy. We'll try to address this issue in the next chapter.

Let's go inside the `golang` container. We'll need it to execute functional tests.

```bash
kubectl -n go-demo-3-build \
    exec -it cd -c golang -- sh
```

Before we run the functional tests, we'll send a request to the application manually. That will give us confidence that everything we did so far works as expected.

```bash
curl "http://$(cat addr)/demo/hello"
```

W> In some cases (e.g., GKE), it might take a few minutes until the external load balancer is created. If you see 40x or 50x error message, please wait for a while and re-send the request.

We constructed the address using the information we stored in the `addr` file and sent a `curl` request. The output is `hello, world!`, thus confirming that the test release of application seems to be deployed correctly.

The tests require a few dependencies, so we'll download them using the `go get` command. Don't worry if you're new to Go. This exercise is not aimed at teaching you how to work with it, but only to show you the principles that apply to almost any language. In your head, you can replace the command that follows with `maven` this, `gradle` that, `npm` whatever.

```bash
go get -d -v -t
```

The tests expect the environment variable `ADDRESS` to tell them where to find the application under test, so our next step is to declare it.

```bash
export ADDRESS=api:8080
```

In this case, we chose to allow the tests to communicate with the application through the service called `api`.

Now we're ready to execute the tests.

```bash
go test ./... -v --run FunctionalTest
```

The output is as follows.

```
=== RUN   TestFunctionalTestSuite
=== RUN   TestFunctionalTestSuite/Test_Hello_ReturnsStatus200
2018/05/14 14:41:25 Sending a request to http://api:8080/demo/hello
=== RUN   TestFunctionalTestSuite/Test_Person_ReturnsStatus200
2018/05/14 14:41:25 Sending a request to http://api:8080/demo/person
--- PASS: TestFunctionalTestSuite (0.03s)
    --- PASS: TestFunctionalTestSuite/Test_Hello_ReturnsStatus200 (0.01s)
    --- PASS: TestFunctionalTestSuite/Test_Person_ReturnsStatus200 (0.01s)
PASS
ok      _/go/go-demo-3  0.129s
```

We can see that the tests passed and we can conclude that the application is a step closer towards production. In a real-world situation, you'd run other types of tests or maybe bundle them all together. The logic is still the same. We deployed the application under test while leaving production intact, and we validated that it behaves as expected. We are ready to move on.

Testing an application through the service associated with it is a good idea,if for some reason we are not allowed to expose it to the outside world through Ingress. If there is no such restriction, executing the tests through a DNS which points to an external load balancer, which forwards to the Ingress service on one of the worker nodes, and from there load balances to one of the replicas, is much closer to how our users access the application. Using the "real" externally accessible address is a better option when that is possible, so we'll change our `ADDRESS` variable and execute the tests one more time.

```bash
export ADDRESS=$(cat addr)

go test ./... -v --run FunctionalTest
```

W> ## A note to Docker For Mac/Windows users
W>
W> Docker for Mac or Windows cluster is accessible through `localhost`. Since `localhost` has a different meaning depending on where it is invoked, the tests will fail by trying to access the application running inside the container from where we're running the tests. Please ignore the outcome and stick with using Service names (e.g., `api`) when running tests on Docker for Mac or Windows.

We're almost finished with this stage. The only thing left is to exit the `golang` container, go back to `kubectl`, and remove the application under test.

```bash
exit

kubectl -n go-demo-3-build \
    exec -it cd -c kubectl -- sh

kubectl delete \
    -f /workspace/k8s/build.yml
```

W> ## A note to minishift users
W>
W> The Route we created through `build-oc.yml` is still not deleted. For the sake of simplicity, we'll ignore it (for now) since it does not occupy almost any resources.

We exited the `golang` container and entered into `kubectl` to delete the test release.

![Figure 3-3: The functional testing stage of a continuous deployment pipeline](images/ch03/manual-cd-steps-func.png)

Let's take a look at what's left in the Namespace.

```bash
kubectl -n go-demo-3-build get all
```

The output is as follows.

```
NAME  READY STATUS  RESTARTS AGE
po/cd 4/4   Running 0        11m
```

Our `cd` Pod is still running. We will remove it later when we're confident that we don't need any of the tools it contains.

There's no need for us to stay inside the `kubectl` container anymore, so we'll exit.

```bash
exit
```

## Creating Production Releases

We are ready to create our first production release. We trust our tests, and they proved that it is relatively safe to deploy to production. Since we cannot deploy to air, we need to create a production release first.

Please make sure to replace `[...]` with your Docker Hub user in one of the commands that follow.

```bash
kubectl -n go-demo-3-build \
    exec -it cd -c docker -- sh

export DH_USER=[...]

docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:1.0

docker image push \
    $DH_USER/go-demo-3:1.0
```

We went back to the `docker` container, we tagged the `1.0-beta` release as `1.0`, and we pushed it to the registry (in this case Docker Hub). Both commands should take no time to execute since we already have all the layers cashed in the registry.

We'll repeat the same process, but this time with the `latest` tag.

```bash
docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:latest

docker image push \
    $DH_USER/go-demo-3:latest

exit
```

Now we have the same image tagged and pushed to the registry as `1.0-beta`, `1.0`, and `latest`.

You might be wondering why we have three tags. They are all pointing to the same image, but they serve different purposes.

The `1.0-beta` is a clear indication that the image might not have been tested and might not be ready for prime. That's why we intentionally postponed tagging until this point. It would be simpler if we tagged and pushed everything at once when we built the image. However, that would send a wrong message to those using our images. If one of the steps failed during the pipeline, it would be an indication that the commit is not ready for production. As a result, if we pushed all tags at once, others might have decided to use `1.0` or `latest` without knowing that it is faulty.

We should always be explicit with versions we are deploying to production, so the `1.0` tag is what we'll use. That will help us control what we have and debug problems if they occur. However, others might not want to use explicit versions. A developer might want to deploy the last stable version of an application created by a different team. In those cases, developers might not care which version is in production. In such a case, deploying `latest` is probably a good idea, assuming that we take good care that it (almost) always works.

![Figure 3-4: The release stage of a continuous deployment pipeline](images/ch03/manual-cd-steps-release.png)

We're making significant progress. Now that we have a new release, we can proceed and execute rolling updates against production.

## Deploying To Production

We already saw that `prod.yml` is almost the same as `build.yml` we deployed earlier, so there's probably no need to go through it in details. The only substantial difference is that we'll create the resources in the `go-demo-3` Namespace, and that we'll leave Ingress to its original path `/demo`.

```bash
kubectl -n go-demo-3-build \
    exec -it cd -c kubectl -- sh

cat k8s/prod.yml \
    | sed -e "s@:latest@:1.0@g" \
    | tee /tmp/prod.yml

kubectl apply -f /tmp/prod.yml --record
```

We used `sed` to convert `latest` to the tag we built a short while ago, and we applied the definition. This was the first release, so all the resources were created. Subsequent releases will follow the rolling update process. Since that is something Kubernetes does out-of-the-box, the command will always be the same.

Next, we'll wait until the release rolls out before we check the exit code.

```bash
kubectl -n go-demo-3 \
    rollout status deployment api

echo $?
```

The exit code is `0`, so we can assume that the rollout was successful. There's no need even to look at the Pods. They are almost certainly running.

W> ## A note to GKE users
W>
W> GKE uses external load balancer as Ingress. To work properly, the `type` of the service related to Ingress needs to be `NodePort`. We'll have to patch the service to change its type. Please execute the command that follows.
W>
W> `kubectl -n go-demo-3 patch svc api -p '{"spec":{"type": "NodePort"}}'`

W> ## A note to minishift users
W>
W> Since OpenShift does not support Ingress (at least not by default), we'll need to add a Route. Please execute the commands that follow.
W>
W> `exit`
W>
W> `kubectl -n go-demo-3-build exec -it cd -c oc -- sh`
W>
W> `oc apply -f k8s/prod-oc.yml`
W>
W> We exited `kubectl` container, entered into `oc`, and deployed the route defined in `k8s/build-oc.yml`.

Now that the production release is up-and-running, we should find the address through which we can access it. Excluding the difference in the Namespace, the command for retrieving the hostname is the same.

W> ## A note to GKE users
W>
W> Please change `hostname` to `ip` in the command that follows. The `jsonpath` should be `{.status.loadBalancer.ingress[0].ip}`.
W> Please note that GKE Ingress spins up an external load balancer and it might take a while until the IP is generated. Therefore, you might need to repeat the command that follows until you get the IP.

W> ## A note to minikube users
W>
W> Change the command that follows to `ADDR=[...]` where `[...]` is the minikube IP you retrieved earlier.

W> ## A note to minishift users
W>
W> Please change the command that follows to `ADDR=$(oc -n go-demo-3 get routes -o jsonpath="{.items[0].spec.host}")`.

```bash
ADDR=$(kubectl -n go-demo-3 \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $ADDR | tee /workspace/prod-addr
```

![Figure 3-5: The deploy stage of a continuous deployment pipeline](images/ch03/manual-cd-steps-deploy.png)

To be on the safe side, we'll run another round of validation, which we'll call *production tests*. We don't need to be in the `kubectl` container for that, so let's exit.

```bash
exit
```

## Running Production Tests

The process for running production tests is the same as functional testing we executed earlier. The difference is in the tests we execute, not how we do it.

The goal of production tests is not to validate all the units of our application. Unit tests did that. It is not going to validate anything on the functional level. Functional tests did that. Instead, they are very light tests with a simple goal of validating whether the newly deployed application is correctly integrated with the rest of the system. Can we connect to the database? Can we access the application from outside the cluster (as our users will)? Those are a few of the questions we're concerned with when running this last round of tests.

The tests are written in Go, and we still have the `golang` container running. All we have to do it to go through the similar steps as before.

```bash
kubectl -n go-demo-3-build \
    exec -it cd -c golang -- sh

export ADDRESS=$(cat prod-addr)
```

Now that we have the address required for the tests, we can go ahead and execute them.

W> ## A note to Docker For Mac/Windows users
W>
W> DNS behind Docker for Mac or Windows is `localhost`. Since it has a different meaning depending on where it is invoked, the tests will fail, just as they did with the functional stage. Please change the address to `api.go-demo-3:8080`. This time we need to specify not only the name of the Service but also the Namespace since we are executing tests from `go-demo-3-build` and the application is running in the Namespace `go-demo-3`.
W> Please execute the command `export ADDRESS=api.go-demo-3:8080`.

```bash
go test ./... -v --run ProductionTest
```

The output of the command is as follows.

```
=== RUN   TestProductionTestSuite
=== RUN   TestProductionTestSuite/Test_Hello_ReturnsStatus200
--- PASS: TestProductionTestSuite (0.10s)
    --- PASS: TestProductionTestSuite/Test_Hello_ReturnsStatus200 (0.01s)
PASS
ok      _/go/go-demo-3  0.107s
```

W> ## A note to GKE users
W>
W> If your tests failed, the cause is probably due to a long time GKE needs to create a load balancer. Please wait for a few minutes and re-execute them.

![Figure 3-6: The production testing stage of a continuous deployment pipeline](images/ch03/manual-cd-steps-prod.png)

Production tests were successful, and we can conclude that the deployment was successful as well.

All that's left is to exit the container before we clean up.

```bash
exit
```

## Cleaning Up Pipeline Leftovers

The last step in our manually-executed pipeline is to remove all the resources we created, except the production release. Since they are all Pods in the same Namespace, that should be reasonably easy. We can remove them all from `go-demo-3-build`.

```bash
kubectl -n go-demo-3-build \
    delete pods --all
```

The output is as follows.

```
pod "cd" deleted
```

![Figure 3-7: The cleanup stage of a continuous deployment pipeline](images/ch03/manual-cd-steps-cleanup.png)

That's it. Our continuous pipeline is finished. Or, to be more precise, we defined all the steps of the pipeline. We are yet to automate everything.

## Did We Do It?

We only partially succeeded in defining our continuous deployment stages. We did manage to execute all the necessary steps. We cloned the code, we run unit tests, and we built the binary and the Docker image. We deployed the application under test without affecting the production release, and we run functional tests. Once we confirmed that the application works as expected, we updated production with the new release. The new release was deployed through rolling updates but, since it was the first release, we did not see the effect of it. Finally, we run another round of tests to confirm that rolling updates were successful and that the new release is integrated with the rest of the system.

You might be wondering why I said that "we only partially succeeded." We executed the full pipeline. Didn't we?

One of the problems we're facing is that our process can run only a single pipeline for an application. If another commit is pushed while our pipeline is in progress, it would need to wait in a queue. We cannot have a separate Namespace for each build since we'd need to have cluster-wide permissions to create Namespaces and that would defy the purpose of having RBAC. So, the Namespaces need to be created in advance. We might create a few Namespaces for building and testing, but that would still be sub-optimal. We'll stick with a single Namespace with the pending task to figure out how to deploy multiple revisions of an application in the same Namespace given to us by the cluster administrator.

Another problem is the horrifying usage of `sed` commands to modify the content of a YAML file. There must be a better way to parametrize definition of an application. We'll try to solve that problem in the next chapter.

Once we start running multiple builds of the same application, we'll need to figure out how to remove the tools we create as part of our pipeline. Commands like `kubectl delete pods --all` will obviously not work if we plan to run multiple pipelines in parallel. We'll need to restrict the removal only to the Pods spin up by the build we finished, not all those in a Namespace. CI/CD tools we'll use later might be able to help with this problem.

We are missing quite a few steps in our pipeline. Those are the issues we will not try to fix in this book. Those that we explored so far are common to almost all pipelines. We always run different types of tests, some of which are static (e.g., unit tests), while others need a live application (e.g., functional tests). We always need to build a binary or package our application. We need to build an image and deploy it to one or more locations. The rest of the steps differs from one case to another. You might want to send test results to SonarQube, or you might choose to make a GitHub release. If your images can be deployed to different operating systems (e.g., Linux, Windows, ARM), you might want to create a manifest file. You'll probably run some security scanning as well. The list of the things you might do is almost unlimited, so I chose to stick with the steps that are very common and, in many cases, mandatory. Once you grasp the principles behind a well defined, fully automated, and container-based pipeline executed on top of a scheduler, I'm sure you won't have a problem extending our examples to fit your particular needs.

How about building Docker images? That is also one of the items on our TODO list. We shouldn't build them inside Kubernetes cluster because mounting Docker socket is a huge security risk and because we should not run anything without going through Kube API. Our best bet, for now, is to build them outside the cluster. We are yet to discover how to do that effectively. I suspect that will be a very easy challenge.

One message I tried to convey is that everything related to an application should be in the same repository. That applies not only to the source code and tests, but also to build scripts, Dockerfile, and Kubernetes definitions. Outside of that application-related repository should be only the code and configurations that transcends a single application (e.g., cluster setup). We'll continue using the same separation throughout the rest of the book. Everything required by `go-demo-3` will be in the [vfarcic/go-demo-3](https://github.com/vfarcic/go-demo-3) repository. Cluster-wide code and configuration will continue living in [vfarcic/k8s-specs](https://github.com/vfarcic/k8s-specs).

The logic behind everything-an-application-needs-is-in-a-single-repository mantra is vital if we want to empower the teams to be in charge of their applications. It's up to those teams to choose how to do something, and it's everyone else's job to teach them the skills they need. With some other tools, such approach would pose a big security risk and could put other teams in danger. However, Kubernetes provides quite a lot of tools that can help us to avoid those risks without sacrificing autonomy of the teams in charge of application development. We have RBAC and Namespaces. We have ResourceQuotas, LimitRanges, PodSecurityPolicies, NetworkPolicies, and quite a few other tools at our disposal.

I> We can provide autonomy to the teams without sacrificing security and stability. We have the tools and the only thing missing is to change our culture and processes.

## What Now?

We're done, for now. Please destroy the cluster if you're not planning to jump to the next chapter right away and if it is dedicated to the exercises in this book. Otherwise, execute the command that follows to remove everything we did.

```bash
kubectl delete ns \
    go-demo-3 go-demo-3-build
```
