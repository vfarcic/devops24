## TODO
- [ ] Code
- [ ] Code review Docker for Mac/Windows
- [ ] Code review minikube
- [ ] Code review kops
- [ ] Code review minishift
- [ ] Code review GKE
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


# Continuous Delivery With Jenkins And GitOps

T> Continuous Delivery is a step down from Continuous Deployment. Instead of deploying every commit from the master branch to production, we are choosing which build should be promoted. Yet, many are not ready for Continuous Deployment and Continuous Delivery is the second best option.

In many companies, every team has different ways of working, with different cycles and methods to deploy. One example of such differentces is reflected in Git branching models. It is known fact that more parallel branches you have, the harder it is to bring them together later on. Branches (especially those with long lifetime), introduce management complexity and, more importantly, delayed integration. It is always recomended to merge as soon as possible. However, as pointed in the [Continuous Delivery With Jenkins And GitOps](#cd) chapter, some organisational blockers may affect your ability to release the way you want to release, blockers can be inside or outside of your organisations, companies which are working in regulated environements facing those problems. In this chapter I will show yet another alternative of Continuous Integration (CI) implementation, and of course you can mix those examples together, to build your own pipeline, as everything is a code.

We will continue using declarative pipeline and jenkins shared library. To avoid conflicts with existing shared libriaries, we'll use *ci* prefix for functions. The way we build docker image will remain the same, via mounting the socket. We will stick to GitOps as the main source of truth.

TODO: Is this chapter about CD or CI? If it's latter, we should probably change the title.

TODO: Add a note that when a merge to master is delayed, it is continuous integration, or not even that. We can continuous execute only some processes (e.g., testing), while we need to wait until merges are done for the rest. The reason I said "not even that" (CI), is that until we merge work of different people (usually on the master or whatever is the name where everyone merges), we don't know whether our code integrates with the code of others.

TODO: The paragraph that follows is new. Please let me know what you think.

It might seem like we're moving backwards, from Continuous Deployment (CDP), to Continuous Delivery (CD), and now to Continuous Integration (CI). That doesn't seem like a logical order. However, from the pipeline perspective, CD is more complex than CDP, and CI is even more complicated than either of the two. That does not mean that CI is the most complex overal. It isn't. CDP and CD force us to adopt new processes, new culture, and new architecture. Changing those three is very hard, even though creating pipelines is easier. Since the chapters in this book are focused on pipelines, and assume certain maturity level of an organization, we ordered them by complexity of building those pipelines, not by the complexity of implementing the whole change (culture, processes, technology, architecture).

Before we dive into the pipeline, we'll explore a individual topics that will influence the process as a whole.

## Branching Model

I am sure if at some point you thought how to organise git branches for your development and the release, you found numerues articles on Internet describing the popular Git branching model where commits were landing on `develop` branch, and for releases new *release* branches were created. Same were applying for *hotfix* branches. It was kind of bringing garuantee of work isolation, so that you can have time to stabilise your release candidate on release branches, without stopping regular development happening on *develop* branch. Git Tags obviously were used to mark the point where the software been released. 

Many build tools then have implemented the same technique for release to comply with the suggested branching model. Maven, Gradle and others had and still have plugins, which are generating release branches and tags, were opening and closing hotfix branches and so on. Later on github came up with a bit more relaxed branching model called [github flow](https://guides.github.com/introduction/flow/). 

At the first glance, having variety of branches sounds correct, but if you think about it, it kind of assumes that you need to stabilise your release, and that takes time. Therefore, you need a branch for it. And if you build your release process around that model, the process will force you to take time to stabilise the release. You'll need time for testing. After that, you can release it and merge back the stabilisation fixes to the *develop* branch.  The process will force you to be slow. The more things are being build around that branching model, harder it is to change later on. 

The examples of the branching model in the [Creating A Continuous Deployment Pipeline With Jenkins](#cdp) chapter were pretty simple. The assumption was that we do not need to stabilise software. We always roll forward, and everything is (or will be) automated. In the [Continuous Delivery With Jenkins And GitOps](#cd) chapter it was blend of those two assumptions, where it was possible to choose what version of software would go to production. However, there was no need to branch out releases, nor to stabilise them. Master branch was treated as a stable branch. In this chapter, we will be taking a similar approach, where we do not have release branches. Instead, every merge will be treated as a release candidate, and we will assume that problems on the release candidate can be found early enough and that there is no need to branch out and wait. We will also introduce one more environement, typically called *UAT*, where things are being tested first before promotion to production. In my experience promoting service through different environements is pretty standard approach in most of the organisations. If you were following devops toolkit series, you probably remember the recomendation to have exactly the same environements, and the same configuration. All that can be done, but in reality that's rarely the case. In typical organisations, you get different environments on the way to production, where you meet different type of services, dockerised and not dockerised, but still forming part of the platform. Usually thats one of the big blockers to have everything unified. If some parts of big systems are not agile enough, it's hard to deploy them or they have not been conteinarised yet. Therefore, its hard to move them arround. Long story short, in most of the organisations the environements are pretty different from each other, and more you move towards production more prodction like environement you are getting. 

We'll explore the correlations between Git tags, Docker image tags, and Helm Chart tags. We'll also show the ability of fixing issues on a specific release. We will be using `hotfix` branches. You can scale this model to have additional releasable branches. However make sure you dont build a process which assumes slow development. Aim for fast process.

Now that we have a clearer picture about branching models, we should make decisions how to version our releases.

## Versioning

Every software we use, has a version. We need versions to know if we are missing any new features, and whether we are behind the latest version. But we also need versions to understand how hard is it to upgrade software. In this chapter we will use [semantic](https://semver.org/) versioning for our applications. We will make all our releases complient with semantic versioning. The rules are pretty simple.

Given a version number *MAJOR.MINOR.PATCH*, increment each segment using the rules that follow.

* *MAJOR* version increases when we make incompatible API changes.
* *MINOR* version increases when we add functionality in a backwards-compatible manner.
* *PATCH* version increases when you make backwards-compatible bug fixes.

As we have already talked about hotfix branches, you can guess that they will typically change the *PATCH* version. Changes on *MASTER* branch will change *MINOR* version, unless we know that we are introducing changes that will make API incompatible with previous releases. in that case, our pipeline should give us a chance to change the *MAJOR* version.

Now might be a good time to ask how would we know what version of we're building. What is going to be the next version? There are typically two ways of managing versions of an application; either in a file, or with Git tags. Both have their pros and cons. In case of having version in a file, every build needs to increment the version by changing that file. Since it is kept in Git, we need to push that change back to the repository. The problem with that approach is that we need to create some kind of a custom mechanism that will prevent those commit from triggering builds. Otherwise, we'd run a risk of creating newer ending loops where a build commits a file, only to trigger another build that commit a file, and so on. We need a custom mechanism to avoid such loops. Some plugins are adding custom comments and you can include that rule in your pipeline. For example, if the comment says `[release commit ...]` then skip the build. 

Another way to keep track of the versions is to leverage Git tags. That avoids having a file with version number inside and avoid pushing that file to the repository. If you (or the process) needs to know the version of the current source, you (or it) will read the latest tag. The drawback of this method is, you will need git operation each time you want to read the release version. TODO: I'm not sure I understand the last sentence.

Both approaches have their pros and cons. We explored the approach with files that contain versions in the previous chapter. We avoided the problem with "build loops" by having a separate repository that defines everything we need to deploy applications. That, among other things, included versions. In this chapter, we'll explore the approach with Git tags. Git is pretty powerefull source control tool, and its tags are first class citizens.

We will use the "Git tags" approach in the examples that follow. We will also attach release notes to our releases, and we will automate release note generation. Release notes are yet another task involved in the release process which should be automated. At least we will try to do so.

That was the intro, and lets code a bit.

TODO: Continue review

## Creating A Cluster

We will setup the production environement with helm requirements like we did in the previous chapter. You will be very familiar with that part of the scripts.

Just as before, we'll start the practical part by making sure that we have the latest version of the *k8s-specs* repository.

I> All the commands from this chapter are available in the [09-jenkins-cd.sh](https://gist.github.com/cb0ececf6600745daeac8cc3ae400a86) Gist.

```bash
cd k8s-specs

git pull
```


For **GKE** we'll need to increase memory slightly so we'll use **n1-highcpu-4** instance types instead of *n1-highcpu-2* we used so far.

* [docker4mac-cd.sh](https://gist.github.com/d07bcbc7c88e8bd104fedde63aee8374): **Docker for Mac** with 3 CPUs, 4 GB RAM, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP of the cluster.
* [minikube-cd.sh](https://gist.github.com/06bb38787932520906ede2d4c72c2bd8): **minikube** with 3 CPUs, 4 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, with **tiller**, and with `LB_IP` variable set to the VM created by minikube.
* [kops-cd.sh](https://gist.github.com/d96c27204ff4b3ad3f4ae80ca3adb891): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP retrieved by pinging ELB's hostname. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).
* [minishift-cd.sh](https://gist.github.com/94cfcb3f9e6df965ec233bbb5bf54110): **minishift** with 4 CPUs, 4 GB RAM, with version 1.16+, with **tiller**, and with `LB_IP` variable set to the VM created by minishift.
* [gke-cd.sh](https://gist.github.com/1b126df156abc91d51286c603b8f8718): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-4 (4 CPUs, 3.6 GB RAM) nodes (one in each zone), with **nginx Ingress** controller running on top of the "standard" one that comes with GKE, with **tiller**, and with `LB_IP` variable set to the IP of the external load balancer created when installing nginx Ingress. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files and Helm Charts if you prefer NOT to install nginx Ingress.
* [eks-cd.sh](https://gist.github.com/2af71594d5da3ca550de9dca0f23a2c5): **Elastic Kubernetes Service (EKS)** with 2 t2.medium nodes, with **nginx Ingress** controller, with a **default StorageClass**, with **tiller**, and with `LB_IP` variable set tot he IP retrieved by pinging ELB's hostname.

Here we go.

## Defining The Whole Production Environment

Please refer to the previous chapter to bring your production environement up and running.

## What Is The Continuous Delivery Pipeline?

Now that we have a cluster and the third-party applications running in the production environment, we can turn our attention towards defining a continuous delivery pipeline.

Before we proceed, we'll recap the definitions of continuous deployment and continuous delivery.

I> Continuous deployment is a fully automated process that executes a set of steps with the goal of converting each commit to the master branch into a fully tested release deployed to production.

I> Continuous delivery is almost a fully automated process that executes a set of steps with the goal of converting each commit to the master branch into a fully tested release that is ready to be deployed to production. We (humans) retain the ability to choose which of the production-ready releases will be deployed to production and when is that deployment going to happen.

As with the previous chapter, My primary goal is to show a different approach that with small adjustments can be applied to any type of pipeline. 

The main difference would be applying CI on more than one releasable branches, also using semantic versioning for releases, and git tags as correlation between all artifacts. We will also deploy go-demo in `UAT` environement before `Production`.

## Exploring Application's Repository And Preparing The Environment


As in the previous chapter, I forked the [vfarcic/go-demo-3](https://github.com/vfarcic/go-demo-3) repository into [vfarcic/go-demo-4](https://github.com/vfarcic/go-demo-4). Reason is the same, to not have conflicting issues between different approaches for the pipeline. Obviously Viktor was faster than myself and his chapter pointing to go-demo-5 came out earlier. I hope i am not too late, but after writing this chapter I now appreciate more effort from Viktor. 

Since we'll need to change a few configuration files and push them back to the repository, you should fork [vfarcic/go-demo-4](https://github.com/vfarcic/go-demo-4), just as you forked [vfarcic/k8s-prod](https://github.com/vfarcic/k8s-prod).

Next, we'll clone the repository before we explore the relevant files.

```bash
cd ..

git clone \
    https://github.com/$GH_USER/go-demo-4.git

cd go-demo-4
```

There is not much difference between those repos, except

The Chart located in `helm` directory is the same as the one we used in *go-demo-5* so we'll skip commenting it. Instead, we'll replace GitHub user (`vfarcic`) with yours.

Before you execute the commands that follow, make sure you replace `[...]` with your Docker Hub user.

```bash
DH_USER=[...]

cat helm/go-demo-4/deployment-orig.yaml \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee helm/go-demo-4/templates/deployment.yaml
```

In *go-demo-3*, the resources that define the Namespace, ServiceAccount, RoleBinding, LimitRange, and ResourceQuota were split between `ns.yml` and `build-config.yml` files. I got tired of having them separated, so I joined them into a single file `build.yml`. Other than that, the resources are the same as those we used before so we'll skip commenting on them as well. The only difference is that the Namespace is now *go-demo-4*.

```bash
kubectl apply -f k8s/build.yml --record
```

The extra step here would be create `uat` environement. 

```bash
kubectl apply -f k8s/uat-ns.yml --record
```


Finally, the only thing related to the setup of the environment we'll use for *go-demo-4* is to install Tiller, just as we did before.

```bash
helm init --service-account build \
    --tiller-namespace go-demo-4-build
```

The  key elements of our pipeline will be *JCienkinsfile* and *DeploymentJenkinsfile* files. Let's explore them now.


## Demystifying Declarative Pipeline Through A Practical Example

Let's take a look at a *JCienkinsfile.orig* which we'll use as a base to generate *Jenkinsfile* that will contain the correct address of the cluster and the GitHub user.

```bash
cat CiJenkinsfile.orig
```

The `option` block has remiand the same. 

The `agent` block however has couple of differences. First the `label` block now has a random value. Reason for that is, if two build are running the same pipeline and at that time the buildpod is available with the same label, it will reuse existing pod, which can result into some race condition errors. Even if you disable concurrent builds with the method `disableConcurrentBuilds()`, parallel build can still happen on different branches, and branches can effectivly refer to the same labeled pod. 


```groovy
...
agent {
    kubernetes {
        label "builder-pod-${UUID.randomUUID().toString()}"
        defaultContainer 'jnlp'
        serviceAccount "build"
        yamlFile "CiKubernetesPod.yaml"
}
    }
...
```

You will also notice that `yamlFile` now refers to a differnt file called `CiKubernetesPod.yaml`. Lets have a look at the content of the file. 


```bash
cat CiKubernetesPod.yaml
```


The difference in the output is as follows.

```yaml
...
  - name: gren
    image: digitalinside/gren:latest //todo change to vfarcic
    command:
...
```
`Gren` is a lightweight library to generate release notes from github issues. Obviously you might be using a different tool for tracking your requirements, we just want to demonstrate that the release notes are is yet another thing which can be automated as it is part of a release. 


Next section which is differnt in the jenkinsfile is `environment`. We have added two new environement variables. 


```groovy
...
environment {
  rsaKey="go-demo-rsa-key"
  githubToken="GITHUB_TOKEN"
}
...
```

Two variables are `rsaKey` and `githubToken`. Those are names of the two new secrets we will need to create together. 

TODO: discuss automation of those secrets.

As part of our release process we will be creating and pushing back release tags, and most likely your git repo will require authentication, therefore we will use your private key saved with credential id `go-demo-rsa-key` in jenkins. 


`githubToken` on the other hand will be used to authenticate `gren`, to publish our release notes back to github. You can read [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) how to generate token.


Like before, we'll have to change `vfarcic` to your Docker Hub user and `acme.com` to the address of your cluster.


Now we reached the execution of the pipeline. Just as in the previous chapter, we're having `build`, `func-test`, and `release` stages. However they behave a bit different than before. Let us briefly go through each of the stages of the pipeline. The first one is the `build` stage.

```groovy
...
stage('build') {
    steps {
        ciPrettyBuildNumber()

        container('git') {
            ciWithGitKey(params.rsaKey) {                        
                ciBuildEnvVars() // publish env vars
            }
        }

        container('docker') {
            //for feature branch
            ciK8sBuildImage(params.image, false, env.BUILD_TAG)
        }
    }
}
...
```

 The first action is a method called `ciPrettyBuildNumber()` to customize the name of the build by changing the value of the `displayName`. We had that line in our previous chapter, the difference is, it is now moved to shared jenkins library.

 Second action is called `ciBuildEnvVars()`.


 ```groovy
...
stage('build') {
    steps {
        ...
        container('git') {
            ciWithGitKey(params.rsaKey) {                        
                ciBuildEnvVars() // publish env vars
            }
        }
        ...
    }
}
...
```

Thats where the first difference compared with the previous chapter comes in. The new method will be publishing few environement variables that we will be using during our build. In declarative pipeline there is no easy way of passing variables from one stage to another without breaking code readibility, so we will be using environement variables for that, almost like global or static variables in any other traditional programming languages. 

Lets have a look on the new method. 


 ```groovy
...
def call() {
    //https://issues.jenkins-ci.org/browse/JENKINS-52623 i found issue and waiting it to be fixed, i think carlos is on it now
    env.GIT_COMMIT = sh(script: """ git rev-parse HEAD """, returnStdout: true).trim()
    env.shortGitCommit = "${env.GIT_COMMIT[0..10]}"
    env.BUILD_TAG = ciBuildVersionRead()

    echo "build tag set to: ${env.BUILD_TAG}"
}
...
```

You would see we are doing three things here. First we are reading `GIT_COMMIT` sha1. Git plugin used to publish this environement variable explicitly, however during writing this chapter, we found a bug that those variables are not published in declarative pipeline. We will remove the line when bug fix is going to be merged. 

`shortGitCommit` is short version of the same sha1, we will be using it as an extra image tag. //TODO discuss if we need it at all ?

`BUILD_TAG`, is important one. We will be using `BUILD_TAG` to tag all our artifacts like git source, helm charts, docker images. However build tags are going to be different depending if the build is running on a `releasable` branche(s) or no. As we talked about it earlier, we consider master and hotifx branches releasable.

You will also notice that there is another call to a function called `ciBuildVersionRead()`. Lets have a look on the function. 

```groovy
def call() {

    def version = ciVersionRead()
    
    if(ciCheckReleaseBranches()) {
        version = "RC-" + version + "-b${env.BUILD_ID}"
    }

    echo "build version set to $version"
    return version
}

```

We will have a bit of nested calles here, as most of those functions are re-used, and it did make sense to capture them as separate functions. Lets check what `ciVersionRead()` does on the first line.

```groovy

def call() {
    
    escapedBranch = ciEscapeBranchName()

    tag = ""
    if(env.BRANCH_NAME == 'master') {
        echo "##### master branch detected"
        tag = ciBumpUpVersion(ciMasterVersionRead(), "minor")
    } else if (env.BRANCH_NAME.toString().startsWith("hotfix")) {
        echo "##### hotfix branch detected"
        tag = ciBumpUpVersion(ciMasterVersionRead(), "revision")
    } else  {
        echo "##### feature branch detected"
        tag = escapedBranch
    }

    echo "version set to $tag"
    return tag
}

```

Finally we are getting to the core, where the whole magic happens. Code in the above function will do the following. Remember we were talking about semantic versioning before, now, If the current branch is `master`, it will bump up the `Minor` version. If it is a hotfix branch, most likely it is a bug fix, therefore it will bump up the `patch` version. Finally, if the current branch is not releasable, and is a feature branch, we will use branch name as a version. Obviously we are not going to tag git source with a branch name, in fact we are not going to tag it at all when we are not working on one of the releasable branches. However we will be tagging our docker images, therefore we will need a readable but through away tag. 


You may ask a question, what if it is the first run, what version is going to be bumped up. If you look at the code inside method called `ciMasterVersionRead()` you will notice that it tries to find out what is the latest git tag, and if there isn't any, it will start from `1.0.0`. You can change to any default tag you want, as long as it complies with the semantic versioning. There is another method called `ciBumpUpVersion()` used which we have not talked about, but name of the method suggests that it will run the logic of incrementing correct number in the version. We would not go into details of the method implementation, mainly it applies some regexp logic, and increments numbers later on. 

Lets move forward. 

As a result of running `ciBuildEnvVars()` method inside `build` stage, `BUILD_TAG` invorenemnt variable will be exported, and we will know what tag to use during our build. Time to biuld the docker image.


```groovy
...
container('docker') {
        //for feature branch
        ciK8sBuildImage(params.image, false, env.BUILD_TAG)
    }
...
```

We will use equivalent of `k8sBuildImage` we have used before, only change in `ciK8sBuildImage` is, the method now can push extra tags on the same image. 


We are approaching `func-test` now, which looks similar to what we had before.


```groovy
...
stage("func-test") {
    steps {
        container("helm") {
            ciK8sUpgradeBeta(params.project, params.domain, env.BUILD_TAG)
        }

        container("kubectl") {
            ciK8sRolloutBeta(params.project)
        }

        container("golang") {
            ciK8sFuncTestGolang(params.project, params.domain)
        }
    }

    post {
        failure {
            container("helm") {
                ciK8sDeleteBeta(params.project)
            }
        }
    }
}
...
```

This section almost stayed the same, `ciK8sUpgradeBeta` will deploy local chart from a folder, which will point to the newly built image. We will wait until deployment is rolled out, and we will run our tests. If tests would fail, we will delete current deployment. 

It's time to move into the next stage which is `Release`. `Release` stage is a bit longer so we will break it down into pieces. 

```groovy
...
stage("Release") {
...
    when {
        anyOf {
            branch "master"
            branch "hotfix-*"
        }
    }

...    
}
...
```

As we have talked before, we have two types of releasable branches. We have used new function called `anyOf` which is self explanatory. We have also used wildcard for hotfix branch to match all the branches which are starting with `hotfix-` prefix. So if the build is running on those branches, release stage will run. 

Lets see what other new things we have in release stage. First thing which will run inside release stage is below. 

```groovy
stage("Release") {
...            
container("git") {
    ciWithGitKey(params.rsaKey) {
        env.RELEASE_TAG = ciSuggestVersion(ciVersionRead())
    }
}
...                
}
```

Here it comes more gitops way of working. As we have discussed before, our release versions are going to be stored as git tags inside our git repo. Intention of this step is to find the latest release number, autoincrement it, and suggest to the user. If user is happy, he/she can click continue or else suggest their own version. There is also a timeout for a decision, which is now set for 15 seconds, but can be changed to your prefer timing. When ttl expires, the suggested value would be taken and pipeline will continue.

Because git repo is going to be authenticated we will need to find a way to authenticate ourselves. There is geniuinly two ways to interract with git. Either via `ssh` protocol which require ssh keys, or `http` with username and password. We will prefer ssh keys, to not pass username and password with every git command. The problem is, we do not have the private key available inside `git` container. And mounting our key there is an overhead, and also can introduce side effects. What we do is, we pass the private key from jenkins secrets to `ciWithGitKey` closure which will configure `GIT_SSH` environement variable to use the key, therefore every git call within the closure will be authenticated. Again, we will not go behind the scenes of `ciWithGitKey` and we hope you can read and understand it. 

So to summarize, `ciWithGitKey` will authenticate git commands. `ciVersionRead` will get the latest release number and will autoincrement it. `ciSuggestVersion` will suggest the new version to the user with a timeout of 15 seconds. User can change the release value or else continue with the suggestion. 

Lets move to the next new steps. You will notice that there are two outer functions around our main release steps. Lets understand why we need them first.


```groovy
...
container("helm") {     
    ciContinueAfterTimeout(5, 'MINUTES') {
        ciConditionalInputExecution(
                id: "Release Gate",
                message: "Release ${params.project} ?",
                ok: "ok",
                name: "release") {
                }

                ...
            }
}

```

As unfortunatly we are not doing CD, it means some decisions are back to humans to make. One decision will be, if indeed version has been tested. What we have done so far was, we have deployed our version to our build namespace, and we did run our tests. When we trust our tests its easy, we can release anytime. When we dont, we need to wait until someone will press the GO button. 


So, lets first define the intention of the stage. By release, we do not necessurly mean deployment. What we mean is, we want to capture everything under the same reference, so we can repeat the same installation of the software as many times as we want.  So, our intention here is, 

1. Tag and push the docker image with new release number
1. Tag and push the git commit, with new release number
1. Tag and push helm chart with new release number
1. Generate release notes.


Lets start from the second method called `ciConditionalInputExecution(..)`. As you may have noticed its a closure which takes other functions and closures as arguments. What it does is simple, it will first ask the user if he/she is happy to continue, and then will simply execute the inner functions. Its a way of putting a gate, on a pipeline execution, to not do anything, unless instracted. Obviously if in your case you would prefer to do all release steps automatically, anytime there is a merge or a commit to a releasable branches without control then its easy to remove the outor function. In our case we will imagine we dont want to publish short release notes with every new commit, but instead we will accomplish an iteration of work, and at some point we will hit the release button to capture everything as a release. 

Now, it would be naive to think, that we will be asking the user for an input for every build. Thats where `ciContinueAfterTimeout(..)` can help us. That is yet another useful function, which will put a time out on the inner function. If inner function would take more time that it has been given, code will continue without errors. In our case, if build should not be marked and packaged into release, there will be nothing to do, after five minutes build will be marked as green.

Lets have a look, what will happen if someone would decide that build should be packaged into release. 
 
 First thing to happen is 
```groovy
container('docker') {
    ciRetag(env.BUILD_TAG, false, ["latest", env.shortGitCommit, env.RELEASE_TAG])
}
```
Remember we have collected some information about the build before. Now we are going to tag the docker image with those values. `ciRetag(...)` function, will take current docker image as an argument, which is `env.BUILD_TAG` and will tag it will the provided list of tags. In our case the list will contain the semantic release version, the commit id, and the `latest` tag for development purposes only. 

Lets move forward, the next section will be tagging our source code.

```groovy
container('git') {
    ciWithGitKey(params.rsaKey) {
        ciTagGitRelease(tag: env.RELEASE_TAG)
    }
}
```

As we discussed before, release is going to be kept in github as a git tag. Therefor we will need to push back our tags. We will use same `ciWithGitKey()` closure. As a reminder, the closure will enable authenticated git operations within it. The nested function which will be called is `ciTagGitRelease(..)`. It is a simple function, which will `tag` the current commit, and will push it back. It will also create default git author called `jenkins` if one does not exist.

Lets continue. Next thing we want to automate are release notes. Container `gren` is going to help us here. 

```groovy
container('gren') {
    //https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
    withCredentials([string(credentialsId: params.githubToken, variable: 'TOKEN')]) {
        sh "gren release --token=${TOKEN}"
    }
}
```

Github has its own issue tracker, and gren works pretty well with it. What it does is, it will collect all the `closed` issues between releases, and will publish them grouped by issue type, and with descriptions. For `gren` to work against authenticated repos, we will use the `githubtoken` credential that we have created before. As a result new shiny github style release notes are going to be published with the release. 

Finally, lets package and version our helm chart. 

```groovy
container("helm") {
    ciK8sPushHelm(params.project, env.RELEASE_TAG, params.cmAddr, true)
}
```

`ciK8sPushHelm(...)` does not contain new information. It will update `Chart.yaml` file with new release version, will update `values.yaml` to point to the new image, will package and push the chart to chartmuseum.

There is nothing else under `release` stage. What is left is `post` actions.

Lets have a look at post action. 

```groovy

post {
    always {
        ciWhenNotReleaseBranches {
            container("helm") {
                    ciK8sDeleteBeta(params.project)                        
            }
        }
    }
}
```

I hope code is self descriptive, and it is clear what it does. The inner function passed to `ciWhenNotReleaseBranches(...)` will only work, if the current build is running on releasable branches. Idea behind is, if the build is running on the feature branch it will be deleted to not use resources from the cloud. Developer always can troubleshoot the version on his/her own laptop. However for release candidates we probably do not want to delete the version, as some manual testing could be in progress, and we do not want to interrupt it. 

At this point, we have, new semanticly versioned release, and all artifacts referenced with the same release number, docker image, git source, helm chart. We also have automaticly generated release notes uploaded to github. 

However, we have decoupled deployment of the release, from the release operation itself. We will need a way to deploy our releases between environements. 


## Running a Deployment Job

We have explored the *Jenkinsfile* which that contains steps to package the release and make it repeatable to install to a desired environement. Lets have a look how we can choose a version to deploy. 

Lets have a look at the new file in our repo, called `DeploymentJenkinsFile`. It will look like a typical Jenkinsfile we saw many times already. Lets have a look at the steps.


```groovy
stages {

        stage('Select Project') {
            ...
        }

        stage("Select Version") {
            ...
        }

        stage("Select Environment") {
            ...
        }

        stage("Deploy") {
            ...
        }

        stage("Test") {
            ...
        }
    }
```

As you would have guessed, when we run the job, as a first stage it will suggest us project list to choose from. Then depending on the project it will suggest the possible versions, then the environement. Finally it will deploy the choosed combination to the requested environement and will run the test. You may ask, how would it know the project list ? Well, we will need to somehow keep the project names that we would like to deploy, and as an example we will keep that information in a yml file called `platform_deployment.yml`. Its a simple `yml` listing services which can be deployed, and environements where they can be deployed to. If you have good automated environement, you can have those values coming from third party services or api. 

Lets have a look at `Select Project` stage more closely. 

```groovy
...
stage('Select Project') {
    steps {
        showProject()
    }
}
...
```

There is just one method call within the stage, called `showProject()`. `showProject()` is a private method writtine at the bottom of the same jenkinsfile. We have not done it before, but for argument sake we will show that it is possible to have local methods in declarative pipeline as well. Lets have a look at the method. 


```groovy

def showProject() {
    def deployment = readYaml file: "platform_deployment.yml"
    def projectChoices = ''
    deployment.services.each {
        projectChoices += it.name + '\n'
    }

    env.project = input(id: 'projectInput',
            message: 'Choose properties file',
            parameters: [[$class     : 'ChoiceParameterDefinition',
                          choices    : projectChoices,
                          description: 'What service to deploy?',
                          name       : 'project']])
}

```

What happens here is not hard, first we read the "platform_deployment.yml" file and then we traverse over services to have the names appended to `projectChoices` property with a new line symbol as a delimiter. Later on the list of service names is passed as a data source to a `input` field. This will render a dropdown box, with service names inside. User will choose a service to deploy and will click next. 

What comes next is choosing a version. `Select Version` stage will be calling `showVersion()` in the same way we have done for the previous step. Local `showVersion()` method then will query github api for available releases for the project. The releases will be collected and will be shown in a new dropdown box just like we have done for the previos stage. 


Similar way the next stage will then read available environements for the service and will render them in the drop down. 

After collecting all the info, the deploy stage will execute the usual `helm install ...` command and will pass the arguments collected from previos three stages. 

This approach will allow us to deploy any service to any new namespace. There are no restrictions to limit it to just microservices, but we can install the whole platform just like we did in our previous chapter. The difference is, the platform will have its own versioning, and it will be composition of multiple service. However it will maintain its own release versions and release notes. We will leave that excersize to you to complete and hear your feedback about it. 


## Creating And Running A Continuous Delivery Job

There is nothing new in this chapter, and same scripts and ways of creating the job remained the same. Please follow isntractions from previos chapter. 



## What Now?

We are finished with the exploration of continuous delivery processes. Destroy the cluster if you created it only for the purpose of this chapter. Have a break. You deserve it.
