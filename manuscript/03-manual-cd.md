## TODO

- [X] Code
- [X] Write
- [X] Code review Docker for Mac/Windows
- [ ] Code review minikube
- [ ] Code review kops
- [ ] Code review minishift
- [ ] Code review GKE
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

# Defining Continuous Deployment

T> The work on defining Continuous Deployment (CDP) steps should not start in Jenkins or any other similar tool. Instead, we should focus on Shell and scripts. We should turn our attention to the tools only once we are confident that we can execute the full process with only a few commands.

We should be able to execute most, if not all, CDP steps from anywhere. Developers should be able to run them locally from a Shell. Others might want to integrate them into their favorite IDEs. The number of ways all or parts of the CDP steps are executed can be quite huge. Running them as part of every commit is only one of those permutations. The way we execute CDP steps should be agnostic to the way we defined them. If we add the need for very high (if not complete) automation, it is clear that the steps must be simple commands or Shell scripts. Adding anything else to the mix is likely to result in tight coupling which will limit our ability to be independent of the tools we're using to run those steps.

Our goal in this chapter is to define the minimum number of steps a continuous deployment process might need. From there on, it would be up to you to extend those steps to serve a particular use-case you might be facing in your project. Once we know what should be done, we'll proceed and define the commands that will get us there. We'll do our best to create the CDP steps in a way that they can be easily ported to Jenkins, CodeShip, or any other tool we might choose to use. We'll try to be tools agnostic. There will always be some specific steps that will be very specific to the tools we'll use but my hopes are that they will be limited to limited scaffolding, and not the CDP logic.

I> This chapter assumes that you are already familiar with LimitRanges and ResourceQuotas, besides the requirements from the previous chapters. If you're not, please refer to [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy) for more info.

Whether we'll manage to reach our goals fully is yet to be seen. For now, we'll ignore existence of Jenkins, CodeShip, and all the other tools that could be used to orchestrate our continuous deployment processes. Instead, we'll focus purely on Shell and the commands we need to execute. We might write a script or two.

## To Continuously Deliver Or To Continuously Deploy?

Everyone wants to implement continuous delivery or deployment. After all, the benefits are too big to be ignored. Increase the speed of delivery, increase the quality, decrease the costs, free people to dedicate time on what brings value, and so on and so forth. Those improvements are like music to any decision maker. Especially if that person has a business background. If a tech geek can articulate the benefits continuous delivery brings to the table, when he asks a business representative for a budget, the response is almost always “Yes! Do it.”

By now, you might be confused with the differences between continuous integration, delivery, and deployment, so I'll do my best to walk you through the main objectives behind each.

You are doing continuous integration (CI) if you have a set of automated processes that are executed every time you commit a change to a code repository. What we're trying to accomplish with CI is a state when every commit is validated shortly after a commit. We want to know not only whether what we did works, but also whether it integrates with the work our colleagues did. That's why it is important that everyone merges code to the master branch. Or, at least, to some other common branch. It does not matter much how we name it. What does matter is that not much time passes since the moment we fork code. That can be hours or maybe days. If we delay integration for more than that, we are risking spending too much time working on something that breaks work of others.

I> Continuous integration assumes that only a part of the process is automated and that human intervention is needed after machines are finished with their work. That intervention often consists of manual tests or even manual deployments to one or more environments.

The problem with continuous integration is that the level of automation is not high enough. We do not trust the process enough. We feel that it provides benefits, but we also require a second opinion. We need humans to confirm the result of the process executed by machines.

Continuous delivery (CD) is a superset of continuous integration. It features a fully automated process executed on every commit. If none of the steps in the process fail, we declare the commit as ready for production.

I> With continuous delivery, we do not deploy to production automatically because someone needs to make a business decision. The reason to postpone or skip deploying a release to production is anything but technical.

Finally, continuous deployment (CDP) is almost the same as delivery. All the steps in the process are in both cases fully automated. The only difference is that the button that says "deploy to production" is gone.

I> With continuous deployment (CDP), every commit that passed all the automated steps is deployed to production.

Even thought CD and CDP are almost the same from the process perspective, the latter might require change in the way we develop our applications. We might, for example, start using feature toggles that will allow us to disable partially finished features.

We won't go into all the cultural and development change one would need to employ before attempting to reach the stage where CDP is possible, or even desirable. That would be a subject for a different book and would require much more space than what we have. I am not even going to try to convince you to embrace continuous deployment. There are many valid cases when CDP is not a good option and even more of those when it is not even possible without substantial cultural and technical changes which are outside Kubernetes domain. It's likely that you are not ready to embrace continuous deployment.

At this point you might be wondering whether it makes sense for you to continue reading. Maybe you are indeed not ready for continuous deployment and maybe you are thinking that all this was a waste of time. If that's the case, my message to you is that it does not matter. The fact that you already have some experience with Kubernetes tells me that you are not a lagger. You choose to embrace a new way of working. You saw the benefits behind distributed systems and you are embracing what surely looked like madness when you made your first steps.

If you reached this far, you are ready to learn and practice the processes that follow. You might not be ready to do continuous deployment. That's OK. You can fall back to continuous delivery. If that is also too big of a scratch, you can start with continuous integration. The reason I'm saying that it does not matter lies in the fact that most of the steps are the same in all those cases. No matter whether you are planning to do CI, CD, or CDP, you will have to build something, you'll have to run some tests, and you'll have to deploy your applications somewhere.

I> The difference between continuous integration, delivery, and deployment is not in processes, but in the level of confidence we have in them.

From technical perspective, it does not matter whether we deploy to a local cluster, to the one dedicated to testing, or to production. A deployment to a Kubernetes cluster is (more or less) the same no matter what it's purpose is. You might choose to have a single cluster for everything. That's also OK. That's what Namespaces are for. You might not trust your tests. Still, that's not a problem from the start because the way we execute tests is the same no matter how much we trust them. I can continue for a while with statements like that. What trully matters is that the process is, more or less, the same, no matter how much you trust it. Trust is earned with time.

I> If you do want to read a very opinionated and politically incorrect thoughts on what you might be missing, please visit [The Ten Commandments Of Continuous Delivery](https://technologyconversations.com/2017/03/06/the-ten-commandments-of-continuous-delivery/).

The goal of this book is to teach you how to employ continuous deployment into a Kubernetes cluster. It's up to you to decide when is your expertise, culture, and code ready for it. The pipeline we'll build will be the same no matter whether you're planning to use CI, CD, or CDP. Only a few arguments might change.

All in all, the first objective is to define the base set of steps for our continuous deployment processes. We'll worry about executing those steps later.

## Defining Continuous Deployment Goals

Continuous deployment process is fairly easy to explain, even though implementation might get tricky. We'll split our requirements into two groups. We'll start with a discussion about the overall goals that should be applied to the whole process. To be more precise, we'll talk about what I consider a non-negotiable requirements.

A Pipeline needs to be secure. Normally, that would not be a problem. Before Kubernetes, we would run the pipeline steps on separate servers. We'd have one dedicated to building and another for testing. We might have had one for integration and another for performance tests. Once we adopt container schedulers and move into clusters, we loose control of the servers. Even though it is possible to run someting on a specific server, that is highly discouraged in Kubernetes. We should let it schedule Pods with as few restraints as possible. That means that our builds and tests might run in the production cluster and that might prove not to be secure. If we are not careful, a malicious user might exploit shared space. Even more likely, our tests might contain an unwanted side-effect that could put production applications at risk.

We could create separate clusters. One can be dedicated to production and the other to everything else. While that is certainly an option we should explore, Kubernetes already provides us with the tools we need to make a cluster secure. We have RBAC, ServiceAccounts, Namespaces, and a few other resources at our disposal. We can share the same cluster and be reasonably secure at the same time.

Security is not the only requirement. Even when everything is secured, we still need to make sure that our pipeline does not negatively affect other applications running inside the cluster. If we are not careful, tests might, for example, request or use too much resources and, as a result, we might be left with insufficient memory for the other applications and processes running inside our cluster. Fortunatelly, Kubernetes has a solution for those problems as well. We can combine Namespaces with LimitRanges and ResourceQuotas. While they do not provide complete guarantees that nothing will go wrong (nothing does), they do provide a set of tools that, when used properly, do provide a reasonable guarantees that the processes in a Namespace will not go "wild".

Finally, our pipeline should be fast. If it takes too much time for a pipeline to execute, we will be compelled to start working on a new feature before the execution of the pipeline is finished. If it fails, we will have to make a decision whether to stop working on the new feature and incur context switching penalty, or to ignore the problem until we are free to deal with it. While both scenarios are bad, the latter is definitely worst and should be avoided at all costs. A failed pipeline must have the highest priority. Otherwise, what's the point of having automated and continuous processes if dealing with issues is eventual.

I> Continuous deployment pipeline must be secured, it should produce no side-effects to the rest of the applications in the cluster, and it should be fast.

The problem is that we often cannot accomplish those goals independently. We might be forced to make tradeoffs. Security often clashes with speed and we might need to strike a balance between the two.

Finally, the main goal, that one that is above the others, is that our continuous deployment pipeline must be executed on every commit to the master branch. That will provide continuous feedback about the readiness of the system, and, in a way, forces people to merge to the master often. When we create a branch, it is non-existent until it gets back to master, or whatever is the name of the common and production-ready branch. The more time it passes until the merge, the bigger then chance that our code does not integrate with the work of our colleagues.

No that we have the high-level objectives straighten out, we should switch out focus to the particular steps a pipeline should contain.

## Defining Continuous Deployment Steps

We'll try to define a minimum set of steps any continuous deployment pipeline should execute. Do not take them literally. Every company is different and every project has something special. You will likely have to extend them to suit your particular needs. However, that should not be a problem. Once we get a grip on those that are mandatory, extending the process should be fairly simple. Except if you need to interact with tools that do not have a well defined API nor a good CLI. If that's the case, my recommendation is to drop those tools. They're not worthy of the suffering they often impose.

We can split the pipeline into several stages. We'll need to *build* the artifacts (after running static tests and analysis). We have to run *functional tests* because unit testing is not enough. We need to create a *release* and *deploy* it somewhere (hopefully to production). No matter how much we trust the earlier stages, we do have to run tests that will validate that the deployment (to production) was successfully. Finally, we need to do some cleanup at the end of the process and remove all the processes created for the Pipeline. It would be pointless to leave them running idle.

All in all, the stages are as follows.

* Build stage
* Functional testing stage
* Release stage
* Deploy stage
* Production testing stage
* Cleanup stage

In the build stage we'll build a Docker image and push it to a registry (in our case Docker Hub). However, since building untested artifacts should be illegal, we are going to run static tests before the actual build. Once our Docker image is pushed, we'll deploy the application and run tests against it. If everything works as expected. We'll make a new release and deploy it to production. To be on the safe side, we'll run another round of tests to validate that the deployment was indeed successful. Finally, we'll clean up the system by removing everything except the production release.

We'll discuss the steps of each of those stages later on. For now, we need a cluster we'll use for the hands-on exercises that'll help us get a better understanding of the pipeline we'll build later.

## Creating A Cluster

We'll start the hands-on part by going back to the local copy of the `vfarcic/k8s-specs` repository and pulling the latest version.

```bash
cd k8s-specs

git pull
```

Just as in the previous chapters, we'll need a cluster if we are to do some hands-on exercises. The rules are still the same. You can continue using the same cluster as before, or switch to a different Kubernetes flavor. You can continue using one of the Kubernetes distributions listed below, or be adventurous and try something different. If you go with the latter, please let me know how it went and I'll test it myself and incorporate it to the list.

W> Beware that for this chapter the minimum requirements for the cluster are 3 CPUs and 3 GB RAM. If you're using Docker For Mac or Windows, minikube, or minishift, the requirements are slightly higher. For everyone else, the specs are still the same.

* [docker4mac-3cpu.sh](https://gist.github.com/bf08bce43a26c7299b6bd365037eb074): **Docker for Mac** with 3 CPUs, 3 GB RAM, and with nginx Ingress.
* [minikube-3cpu.sh](https://gist.github.com/871b5d7742ea6c10469812018c308798): **minikube** with 3 CPUs, 3 GB RAM, and with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled.
* [kops.sh](https://gist.github.com/2a3e4ee9cb86d4a5a65cd3e4397f48fd): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, and with nginx Ingress (assumes that the prerequisites are set through [Appendix B](#appendix-b)).
* [minishift-3cpu.sh](https://gist.github.com/2074633688a85ef3f887769b726066df): **minishift** with 3 CPUs, 3 GB RAM, and version 1.16+.
* [gke.sh](https://gist.github.com/5c52c165bf9c5002fedb61f8a5d6a6d1): **Google Kubernetes Engine (GKE)** with 3 n1-standard-1 (1 CPU, 3.75GB RAM) nodes (one in each zone), and with nginx Ingress controller running on top of the "standard" one that comes with GKE. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files if you prefer NOT to install nginx Ingress.

Now that we have a cluster, we can move onto a more interesting part of this chapter. We'll start defining and executing stages and steps of a continuous deployment pipeline.

## Creating A Namespace Dedicated To Continuous Deployment Processes

If we are run accomplish a reasonable level of security of our pipelines, we need to run them in dedicated Namespaces. Our cluster already has RBAC enabled, so we'll need a ServiceAccount as well. Since security is not enough and we need to make sure that our pipeline does not affect other applications, we'll have to create a LimitRange and a ResourceQuota.

I believe that in most cases we should store everything an application needs in the same repository. That makes maintenance much simpler and enables the team in charge of that application to be in full control, even though that team might not have all the permissions to create the resources in a cluster.

Before we move on, you should fork the `go-demo-3` repository. We'll have to change a few things in the repo, so it's better if you apply the changes to your own fork and, maybe, push them back to GitHub.

```bash
open "https://github.com/vfarcic/go-demo-3"
```

If you're not familiar with GitHub, all you have to do is to login and click the *Fork* button located in the top-right corner of the screen.

Next, we'll remove the `go-demo-3` repository and clone the fork.

```bash
cd ..

rm -rf go-demo-3

export GH_USER=[...]

git clone https://github.com/$GH_USER/go-demo-3.git
```

Make sure that you replaced `[...]` with your GitHub username.

The only thing left is to edit a few files. Please open *k8s/build.yml*, *k8s/prod.yml*, and *k8s/functional.yml* files in your favorite editor and change all occurrences of `vfarcic` to your Docker Hub user.

The namespace dedicated for all building and testing activities of the `go-demo-3` project is defined in the `k8s/build-ns.yml` file stored in the project repository.

```bash
cd go-demo-3

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

We defined the `go-demo-3-build` Namespace which we'll use for all our CDP tasks. It'll contain the ServiceAccount `build` bound to the ClusterRole `ClusterRole`. As a result, we'll be able to do anything we want inside that Namespace. It'll be our playground.

We also defined the LimitRange named `build`. It'll make sure to give sensible defaults to the Pods that will run in the Namespace. That way we can define create Pods from which we'll build and test without worrying whether we forgot to specify resources those Pods need. After all, most of us to not really know how much memory and CPU a build needs. The same LimitRange also contains some minimum and maximum limits that should prevent users from specifying too small or too big resource reservations and limits.

Finally, since the capacity of our cluster is probably not unlimited, we defined a ResourceQuota that specifies the total amount of memory and CPU requests and limits we can have in that Namespace. We also defined that the maximum number of Pods running it that Namespace cannot be greater than fifteen. Since we do not expect Pods in that Namespace to live for long, those limits will not prevent those that go over the limits from running. If we do have more Pods than what we can place in that Namespace, some will be in the pending state until others finish their work and resources are liberated.

It is very likely that the team behind the project will not have sufficient permissions to create new Nemespaces. If that's the case, the team would need to let the cluster administrator know about the existence of that YAML. In turn, he (or she) would review the definition and, once it deduces that it is safe to create the resources. For the sake of simplicity, you are that person, so please execute the command that follows.

```bash
kubectl apply \
    -f k8s/build-ns.yml \
    --record
```

As you can see from the output, the `go-demo-3-build` Namespace was created together with a few other resources.

Now that we have a Namespace dedicated to the lifecycle of our application, we'll create another one that will host our production release.

```bash
cat k8s/prod-ns.yml
```

The `go-demo-3` Namespace is very similar to `go-demo-3-build`. The major difference is in the RoleBinding. Since we can assume that a processes running in the `go-demo-3-build` Namespace will, at some moment, want to deploy a release to production, we created the RoleBinding `build` in the which binds to the ServiceAccount `build` in the Namespace `go-demo-3-build`.

We'll `apply` this definition while still keeping our cluster administrator hat on.

```bash
kubectl apply \
    -f k8s/prod-ns.yml \
    --record
```

Now that we have two Namespaces dedicated to the `go-demo-3` application, we can start working on our continuous deployment steps.

## Executing Continuous Integration Inside Containers

The first stage in our continuous deployment pipeline will have quite a few steps. We'll need to checkout the code, run unit tests and any other static analysis, build a Docker image, and push it to the registry. If we define continuous integration (CI) as a set of automated steps followed with manual operations and validations, we can say that the steps we are about to execute can be qualified as CI.

The only thing we truly need to make all those steps work is Docker client which has access to Docker server. Fortunately, the `go-demo-3` repository already contains the definition we need.

```bash
cat k8s/docker-socket.yml
```

The output is as follows.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: docker
  namespace: go-demo-3-build
spec:
  containers:
  - name: docker
    image: docker:18.03-git
    command: ["sleep"]
    args: ["100000"]
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-socket
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
      type: Socket
```

There's nothing special about this Pod except maybe the volume. We are mounting Docker socket so that the Docker client inside a container can issue commands to Docker server running on the host. Otherwise, we would be running Docker-in-Docker and that is not a very good idea.

Let's `apply` the definition and see whether that Pod can provide everything we need for this stage of the pipeline.

```bash
kubectl apply \
    -f k8s/docker-socket.yml \
    --record
```

We should wait for a few moments until the image is pulled and the Pod is running.

```bash
kubectl -n go-demo-3-build \
    get pods
```

The output should show that the `Pod` is running. If that's not the case, please wait for a few moments more and repeat the previous command.

Now we can enter inside the container and check whether Docker client indeed communicated with the server.

```bash
kubectl -n go-demo-3-build \
    exec -it docker -- sh

docker container ls
```

Once inside the `docker` container, we executed `docker container ls` only as a proof that we are using a client inside the container which, in turn, uses Docker server running on the node. The output is the list of the containers running on top of one of our servers.

Let's get moving and execute the first step.

We cannot do much without the code of our application so the first step is to clone the code.

```bash
export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git

cd go-demo-3
```

Make sure that you replaced `[...]` with your GitHub username.

Please note that we cloned the whole repository and, as a result, we are having a local copy of the HEAD commit of the master branch. If this would be a "real" pipeline, such a strategy would be unacceptable. Instead, we should have checked out a specific branch and a commit that initiated the process. However, we'll ignore those details for now, and assume that we'll solve them when we move the pipeline steps into Jenkins and other tools.

Next, we'll build an image and push it to Docker Hub. To do that, we'll need to login first.

```bash
export DH_USER=[...]

docker login -u $DH_USER
```

Make sure that you replaced `[...]` with your Docker Hub username.

Once you enter your password, you should see the `Login Succeeded` message.

We are finally about to execute the most important step of this stage. We'll build an image.

At this moment you might be freaking out. You might be thinking that I went insane. A Pastafarian and a firm believer that nothing should be built without running tests first, just told you to build an image as the first step after cloning the code. Sacrilege!

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

Normally, we'd run a container, in this case based on the `golang` image, execute a few processes, store the binary into a directory that was mounted as a volume, exit the container, and build a new image using the binary created earlier. While that would work fairly well, multi-stage builds allow us to streamline the processes into a single `docker image build` command.

If you're not following closely Docker releases, you might be wondering what is a multi-stage build. It is a feature introduced in Docker 17.05 that allows us to specify multiple `FROM` statements in a Dockerfile. Each `FROM` instruction can use a different base, and each starts a new stage of the build process. Only the image created with the last `FROM` segment is kept. As a result, we can specify all the steps we need to execute prior to building the image without increasing its size.

In our example, we need to execute a few Go command that will download all the dependencies, run unit tests, and compile a binary. Therefore, we specified `golang` as the base image. The first `FROM` statement is named `build`.

Further down, we start over with a new `FROM` section that uses `alpine`. It is a very minimalistic linux distribution (a few MB in size) that guarantees that our final image will very small and will not be cluttered with unnecessary tools that are normally used in "traditional" linux distros like `ubuntu`, `debian`, and `centos`. The second `FROM` segment creates everything our application needs, like the `DB` environment variable used by the code to know where the database is, the command that should be executed when a container starts, and so on. The important part is the `COPY` statement. It will copy the binary we created in the `build` stage into the final image.

I> Please consult [Dockerfile reference](https://docs.docker.com/engine/reference/builder/) and [Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) for more information.

Let's build the image.

```bash
docker image build \
    -t $DH_USER/go-demo-3:1.0-beta .
```

We can see from the output that the steps of our multi-stage build we executed. We downloaded the dependencies, run unit tests, and built the `go-demo` binary. All those things were temporary and we do not need them in the final image. There's no need to have a Go compiler, nor to keep the code. Therefore, once the first stage was finished, we can see the message *Removing intermediate container*. Everything was discarded and we started over and built the production ready image with the binary generated in the previous stage.

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

The first two images are the result of our build. The final image (`vfarcic/go-demo-3`) is only 25 MB. It's that small because Docker discarded all but the last stage. If you'd like to know how big your image would be if everything was built in a single stage, combine the size of the `vfarcic/go-demo-3` image with the one below it. That's the temporary image used in the first stage.

The only thing missing is to push the image to the registry (e.g., Docker Hub).

```bash
docker image push \
    $DH_USER/go-demo-3:1.0-beta
```

The image is in the registry and ready for further deployments and testing. Missing accomplished. We're doing continuous integration. Or, to be more precise, if we'd place those few commands into a CI/CD tool, we would have the first part of the process up and running.

But, there are a few problems. Docker running in a Kubernetes cluster might be too old. It might not support all the features we need. As an example, most of the Kubernetes distributions before 1.10 supported Docker versions older than 17.05. Even though that might not be an issue, you might not even use Docker in a Kubernetes cluster. It is very likely that ContainerD will be the preferable container engine in the future, and that is only one of many choices we can select. The point is that container engine in a Kubernetes cluster should be in charge of running container, and not much more. There should be no need for the nodes in a Kubernetes cluster to be able to build images.

Another issue is security. If we allow containers to mount Docker socket, we are effectively allowing them to control all the containers running on that node. That by itself makes security departments freak out, and for a very good reason. Also, don't forget that we logged into the registry. Anyone on that node could not push images there. Even if we do log out, there was still a period when everyone could exploit the fact that Docker server is authenticated and authorized to push images. Trust be told, we are not preventing anyone from mounting a Docker socket. At the moment, our policy is based on trust. That should change with PodSecurityPolicy. However, security is not the focus of this book so I'll assume that you'll set up the policies yourself, if you deem they're worthy of your time.

I> We should further restrict what a Pod can and cannot do through [PodSecurityPolicy](https://v1-9.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.9/#podsecuritypolicy-v1beta1-extensions).

If that's not enough, there's also the issue of preventing Kubernetes to do it's job. The moment we adopted it, we accepted that it is in charge of scheduling all the processes happening inside the cluster. If we start doing things behind its back, we might end up messing up with it's scheduling capabilities. Everything we do without going through Kube API is unknown to Kubernetes.

On the other hand, developers love using Docker locally. It helps with a lot of tasks and it would be a bad idea changing it for something else. So, we are in a complicated position. We cannot run container that mounts Docker socket, and yet we want to reep benefits Docker provides for building images.

We could use Docker inside Docker. That would allow us to build images inside containers without reaching out to Docker socker on the nodes. However, that requires privileged access which poses as much of a security risk as mounting a Docker socket. Actually, it is even riskier. So, we need to discard that option as well.

Another solution might be use [kaniko](https://github.com/GoogleContainerTools/kaniko). It allows us to build Docker images from inside Pods. The process is done without Docker so there is no dependency on Docker socket nor there is a need to run containers in privileged mode. However, at the time of this writing (May 2018) kaniko is still not ready. It is complicated to use, it does not support everything Docker does (e.g., multi-stage builds), it's not easy to decipher it's logs (especially errors), and so on. The project will likely have a bright future, but it is still not ready for prime time.

Taking all this into consideration, the only viable option we have, for now, is to build our Docker images outside our cluster. You already know the steps you should execute, and the only thing missing is to figure out how to create a build server and hook it up into our CI/CD tool. We'll revisit this subject later on.

For now, we'll exit the container.

```bash
exit
```

Let's move onto the next stage of our pipeline.

## Running Functional Tests

Which steps do we need to execute in the functional testing phase? We need to deploy the new release of the application. Without it, there would be nothing to test. All the static tests were already executed when we built the image. Everything else needs a live application.

Deploying the application is not enough, we'll have to validate that, at least it rolled out successfully. Otherwise, we'll have to abort the process.

We'll have to be careful how we deploy the new release. Since we'll run the new release in the same cluster as production, we need to be careful that one does not affect the other. We already have a Namespace that provides some level of isolation. However, we'll have to be careful not to use the same path or domain in Ingress as the one used for production. The two need to be accessible separately from each other, until we are confident that the new release meets all the quality standards.

Finally, once the new release is running, we'll execute a set of tests that will validate it. Please note that we will run functional tests only. You should translate that into "in this stage I run all kind of tests that require live application". You might want to add performance and integration tests as well. From processes point of view, it does not matter which tests you run. What matters is that in this stage you run all those that could not be executed statically when we built the image.

If any step in this stage fails, we need to be prepared to destroy everything we did and leave the cluster in the same state as before we started this stage.

As you probably guessed, we'll need to add `kubectl` for at least some of the steps in this stage. Since we are committed not to install anything on the servers, we'll have to run `kubect` as yet another Pod.

```bash
cat k8s/kubectl.yml
```

We already used a similar definition so there's probably no need to go through it. Instead, we'll create the Pod and confirm that it is running.

```bash
kubectl apply \
    -f k8s/kubectl.yml

kubectl -n go-demo-3-build \
    get pods
```

We can continue once the output of the latter command confirms that the only container of the Pod is running.

The project contains separate definitions for deploying test and production releases. For now, we are interested only in prior which is defined in `k8s/build.yml`.

```bash
cat k8s/build.yml
```

We won't comment on all the resources defined in that YAML since they are very similar to those we used before. Instead, we'll take a quick look at the differences between a test and a production release.

```bash
diff k8s/build.yml k8s/prod.yml
```

The two are almost the same. One is using `go-demo-3-build` Namespace while the other works with `go-demo-3`. The `path` of the Ingress resource also differs. Non-production releases will be accessible through `/beta/demo` and thus provide a separation from the production release accessible through `/demo`. Everything else is the same.

It's a pity that we had to create two separate YAML files only because of a few differences (Namespace and Ingress). We'll discuss the challenges behind rapid deployments using standard YAML files later. For now, we'll just roll with what we have.

Since we'll execute `kubectl` commands from inside a container, we'll need to copy the `build.yml` file before we enter inside.

```bash
kubectl -n go-demo-3-build \
    cp k8s/build.yml \
    kubectl:/tmp/build.yml

kubectl -n go-demo-3-build \
    exec -it kubectl -- sh
```

Even though we separated production and non-production releases, we still need to modify the tag of the image on the fly. The alternative would be to change release numbers with each commit but that would represent a burden to developers and a likely source of errors. So, we'll go back to exercising "magic" with `sed`.

```bash
cat /tmp/build.yml | sed -e \
    "s@:latest@:1.0-beta@g" | \
    tee build.yml
```

We output the contents of the `/tmp/build.yml` file, modified it with `sed` so that the `1.0-beta` tag is used instead of `latest`, and stored the output in `build.yml`.

Now we can deploy the new and still not fully tested release.

```bash
kubectl apply -f build.yml --record

kubectl rollout status deployment api
```

We applied the new definition and waited until it rolled out.

Even though we know that the rollout was successful by reading the output, we cannot rely on such methods when we switch to full automation of the pipeline. Fortunately, the `rollout status` command will exit with `0` if everything is OK, and a different code if it's not.

Let's check the exit code of the last command.

```bash
echo $?

exit
```

The output is `0` thus confirming that the rollout was successful. If it was anything else, we'd need to roll back or, even better, quickly fix the problem and roll forward. Further on, we exited the container.

The only thing missing in this stage is to run the tests. But, before we do that, we need to find out the address through which the application can be accessed.

W> ## A note to minikube users
W>
W> Please change the command that follows to `DNS=$(minikube ip)`.

```bash
DNS=$(kubectl -n go-demo-3-build \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $DNS

curl "http://$DNS/beta/demo/hello"
```

We retrieved the `hostname` from Ingress and sent a `curl` request to confirm that the test release indeed responds. We got `hello, world!` as the response and we can proceed and execute our functional test suite. Since we we need Go to run our tests, we'll have to exit the `kubectl` and create another Pod.

```bash
kubectl -n go-demo-3-build \
    run golang \
    --quiet \
    --restart Never \
    --env GH_USER=$GH_USER \
    --env DNS=$DNS \
    --image golang:1.9 \
    sleep 1000000
```

Please note that we passed the DNS of our cluster as an environment variable. It might come in handy when running functional (and other) tests.

We should wait until the Pod is fully up and running. You can check the status by listing the Pods in the `go-demo-3-build` Namespace.

```bash
kubectl -n go-demo-3-build \
    get pods
```

The output, after a while, should show that `1/1` containers of the `golang` Pod are running.

Next, we'll go inside the `golang` container and clone the code.

```bash
kubectl -n go-demo-3-build \
    exec -it golang -- sh

git clone \
    https://github.com/$GH_USER/go-demo-3.git

cd go-demo-3
```

The tests require a few dependencies, so we'll download them using `go get` command. Don't worry if you're new to Go. This exercise is not aimed at teaching you how to work with it, but only to show you the principles that should be applicable to almost any language. In your head, you can replace the command that follows with `maven` this, `gradle` that, `npm` whatever.

```bash
go get -d -v -t
```

The tests expect the environment variable `ADDRESS` to tell them where to find the application under test, so our next step is to declare it.

```bash
export ADDRESS=api:8080
```

In this case, we choose to allow the tests to communicate with the application through the service called `api`.

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

We can see that the tests passed and we can conclude that the application is a step closer towards production. In a real-world situation, you'd run other types of tests or maybe bundle them all together. The logic is still the same. We deployed the application under test while leaving production intact, we validated that it behaves as expected, and we are ready to move on.

Testing an application through the service associated with is a good idea if for some reason we are not allowed to expose it to the outside world through Ingress. However, if there is no such restriction, executing the tests through a DNS which points to an external load balancer, which forwards to the Ingress service on one of the worker nodes, and from there load balances to one of the replicas is much closer to how our users will access the application. Using the "real" externally accessible address is a better option when that is possible, so we'll change our `ADDRESS` variable and execute the tests one more time.

```bash
export ADDRESS=$DNS/beta

go test ./... -v --run FunctionalTest
```

W> ## A note to Docker For Mac/Windows users
W>
W> DNS behind Docker for Mac or Windows is `localhost`. Since it has a different meaning depending on where it is invoked, the tests will fail since it'll try to access the application running inside the container from where we're running the tests. Please ignore the outcome and stick with using Service name (e.g., `api`) when running tests on Docker for Mac or Windows.

We're almost finished with this stage. The only thing left is to exit the `golang` container and remove the application under test.

```bash
exit

kubectl delete -f k8s/build.yml
```

Please note that we executed `kubectl` from your laptop. In the real world scenarios, we would need to go back to the `kubectl` container. But, since you already know how to run `kubectl` from inside a container, we took a shortcut and executed the command directly from the machine you used to create the cluster. We'll continue taking the same shortcut to speed things up. Later on, once we automate all the steps, everything will be running in containers.

Let's take a look at what's left in the Namespace.

```bash
kubectl -n go-demo-3-build get all
```

The output is as follows.

```
NAME       READY STATUS  RESTARTS AGE
po/docker  1/1   Running 0        11m
po/golang  1/1   Running 0        4m
po/kubectl 1/1   Running 0        5m
```

Our `golang` and `kubectl` containers are still running. We will remove them as well later on when we're certain that we don't need them any more.

## Creating The Production Release

We are ready to create our first production release. We trust our tests and they proved that it is relatively safe to deploy to production. Since we cannot deploy air, we need to create a release first.

Please make sure to replace `[...]` with your Docker Hub user in one of the commands that follow.

```bash
kubectl -n go-demo-3-build \
    exec -it docker -- sh

export DH_USER=[...]

docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:1.0

docker image push \
    $DH_USER/go-demo-3:1.0
```

We went back to the `docker` container, we tagged the `1.0-beta` release as `1.0`, and we pushed it to the registry (in this case Docker Hub). Both commands should take no time to execute since we already have all the layers cashed in the registry.

We'll repeat the same process, but this time with the `latests` tag.

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

The `1.0-beta` is a clear indication that the image might not have been tested and might not be ready for prime. That's why we intentionally postponed tagging until this point. It would be simpler if we tagged and pushed everything at once when we built the image. However, that would send a wrong message to those using our images. One of the steps could have failed indicating that the commit is not ready for production. As a result, if we pushed all at once, other might have decided to use `1.0` or `latest` without knowing that it is faulty.

The `1.0` tag is what we should deploy to production. We should always be explicit with versions. That will help us control what we have and debug problems when they occur. However, others might not want to use an explicit version. A developer might want to deploy the last stable version of an application by a different team. In those cases, developers might not care which version is production and deploying `latest` is probably a good idea, assuming that we take good care that it (almost) always works.

We're making great progress. Now that we have a new release, we can proceed and execute rolling updates against production.

## Deploy

We already saw the `prod.yml` is almost the same as `build.yml` we deployed earlier so there's probably no need to go through it in details. The only substantial difference is that we'll create the resources in the `go-demo-3` Namespace and we'll leave Ingress to its original path `/demo`.

```bash
cat k8s/prod.yml \
    | sed -e "s@:latest@:1.0@g" \
    | tee prod.yml

kubectl apply -f prod.yml --record
```

We used `sed` to convert `latest` to the tag we built shortwhile ago, and applied the definition. Since this is the first release, all the resources were created. Subsequent releases will follow the rolling update process. Since that is something Kubernetes does out-of-the-box, the command will always be the same.

Next, we'll wait until the release rolls out and check the exit code.

```bash
kubectl -n go-demo-3 \
    rollout status deployment api

echo $?
```

The exit code is `0`, so we can assume that the rollout was successful. There's no need even to look at the Pods. They are almost certainly running. Still, to be on the safe side, we'll run another round of tests. We'll call them "production tests".

## Production Testing

The process for running production tests is the same as functional testing we executed earlier. The difference is in the tests we execute, not how we do it.

The goal of production tests is not to validate all the units of our application. Unit tests did that. It is not going to validate anything on functional level. Functional tests did that. Instead, they are very light tests with a simple goal of validating whether the newly deployed application is correctly integrated with the rest of the system. Can we connect to the database? Can we access the application from outside the cluster (as our users will)? Those are a few of the questions we're concerned with when running this last round of tests.

The tests are written in Go, and we still have the `golang` container running. All we have to do it to go through the similar steps as before.

```bash
kubectl -n go-demo-3-build \
    exec -it golang -- sh

cd go-demo-3

export ADDRESS=$DNS
```

Now that we have the address required for the tests, we can go ahead and execute them.

W> ## A note to Docker For Mac/Windows users
W>
W> DNS behind Docker for Mac or Windows is `localhost`. Since it has a different meaning depending on where it is invoked, the tests will fail, just as they did with the functional stage. Please change the address to `api.go-demo-3:8080`. This time we need to specify not only the name of the Service but also the Namespace since we are executing tests from `go-demo-3-build` and the application is running in the Namespace `go-demo-3`. Please execute the command `export ADDRESS=api.go-demo-3:8080`.

```bash
go test ./... -v --run ProductionTest
```

The output of the latter command is as follows.

```
=== RUN   TestProductionTestSuite
=== RUN   TestProductionTestSuite/Test_Hello_ReturnsStatus200
--- PASS: TestProductionTestSuite (0.10s)
    --- PASS: TestProductionTestSuite/Test_Hello_ReturnsStatus200 (0.01s)
PASS
ok      _/go/go-demo-3  0.107s
```

Production tests were successfull and we can conclude that the deployment was successful as well.

All that's left is to exit the container before we clean up.

```bash
exit
```

## Cleaning Up

The last step in our manually-executed pipeline is to remove all the resources we created, except the production release. Since they are all Pods in the same Namespace, that should be fairly easy. We can simply remove all the Pods from `go-demo-3-build`.

```bash
kubectl -n go-demo-3-build \
    delete pods --all
```

The output is as follows.

```
pod "docker" deleted
pod "golang" deleted
pod "kubectl" deleted
```

That's it. Our continuous pipeline is finished. Or, to be more precise, we defined all the steps of the pipeline. We are yet to automate them.

## What Now?

We only partially succeeded in defining our continuous deployment stages. On one hand, we did manage to execute all the necessary steps. We cloned the code, we run unit tests, built the binary and the Docker image. We deployed our application under test without affecting the production release and we run functional tests. Once we confirmed that the application works as expected, we updated production with the new release. The new release was deployed through rolling updates but, since it was the first release, we did not see the affect of it. Finally, we run another round of tests to confirm that rolling updates were successful and that the new release is integrated with the rest of the system.

You might be wondering what I said that the "only partially succeeded". We did executed the full pipeline. Didn't we?

One of the problems we're facing is that our process can run only a single pipeline for an application. If another commit is pushed while our pipeline is in progress, it would need to wait in a queue. We cannot have a separate Namespace for each build since we'd need to have cluster wide permissions to create Namespaces and would defy the purpose of having RBAC. Having that limitation in mind, we still need to figure out how to deploy multiple revisions of an application in the same Namespace given to us by the cluster administrator.

Another problem is the horrifying usage of `sed` commands to modify the content of a YAML file. There must be a better way to parametrize definition of an application. We'll try to solve that issue in the next chapter.

Once we start running multiple builds of the same application, we'll need to figure out how to remove the tools we create during the process. Commands like `kubectl delete pods --all` will obviously not work since we need to restrict the removal only to the Pods spin up by the build we finished, not all those in a Namespace. CI/CD tools we'll use later on might be able to help with this problem.

We are missing quite a few steps in our pipeline. That is one of the issues we will not try to fix in this book. Those that we explored so far are common to almost all pipelines. We always run different types of tests, some of which are static (e.g., unit tests), while others need a live application (e.g., functional tests). We always need to build a binary or package our application. We need to build an image and deploy it to one or more locations. The rest of the steps differ from one case to another. You might want to send test results to SonarQube. Or, you might choose to make a GitHub release. If your images can be deployed to different operating systems (e.g., Linux, Windows, ARM), you might want to create a manifest file. You'll probably run some sort of security scanning as well. The list of the things you might do is almost unlimited, so I choose to stick with the steps that are very common and, in many cases, mandatory. Once you grasp the principles behind a well defined, fully automated, and container based pipeline executed on top of a scheduler, I'm sure you won't have a problem extending our examples to fit your particular needs.

How about building Docker images? That is also one of the items on our TODO list. We are yet to discover how to build images outside the cluster. However, I suspect that will be a very easy challenge.

Finally, the is one more thing we did that could be improved. We created a few different Pods to host the tools we need. There's no need for something like that in Kubernetes. We should try to improve that by defining the containers we need to execute a pipeline and spin them up as a single Pod. That will provide a few benefits we did not yet explore in this context. By having a single Pod with multiple containers, we can share the same file system and network. I have a feeling that will come in handy later on when we transfer our knowledge into CI/CD tools.

One message I tried to convey is that everything related to an application should be in the same repository. That applies not only to the source code and tests, but also to build scripts, Dockerfile, and Kubernetes definitions. Outside of that application-related repository should be only the code and configurations that transcend a single application (e.g., cluster setup). We'll continue using the same logic separation throughout the rest of the book. Everything required by `go-demo-3` will be in the [vfarcic/go-demo-3](https://github.com/vfarcic/go-demo-3) repository. Cluster wide code and configuration will continue living in [vfarcic/k8s-specs](https://github.com/vfarcic/k8s-specs).

The logic behind everything-an-application-needs-is-in-a-single-repo mantra is important if we want to empower the teams to be in charge of their applications. It's up to those teams to choose how to do something, and it's everyone elses job to teach them the skills they need. With some other tools, such an approach would pose a big security risk and could put other teams in danger. However, Kubernetes provides quite a lot of tools that can help us to avoid those risks without sacrificing autonomy of the teams in charge of application development. We have RBAC and Namespaces. We have ResourceQuotas and LimitRanges. There are quite a few other tools that we did not even explore yet.

I> We can provide autonomy to the teams without sacrificing security and stability. We have the tools and the only thing missing is to change our culture and processes.

We're done, for now. Please destroy the cluster if you're not planning to jump to the next chapter right away and if it is dedicated to the exercises in this book. Otherwise, execute the command that follows to remove everything we did.

```bash
kubectl delete ns \
    go-demo-3 go-demo-3-build
```