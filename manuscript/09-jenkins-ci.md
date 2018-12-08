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


# Continuous Integration With Jenkins And GitOps

T> Continuous Integration is a step down from continuous delivery. Instead of choosing which build should be promoted, we are waiting until pull requests are merged and the version is being captured and moved through environments until production. 

It might seem like we're moving backwards, from continuous deployment (CDP), to continuous delivery (CD), and now to continuous integration (CI). That doesn't seem like a logical order. However, from the pipeline perspective, CD is more complex than CDP, and CI is even more complicated than either of the two. That does not mean that CI is the most complex overal. It isn't. CDP and CD force us to adopt new processes, new culture, and new architecture. Changing those three is very hard, even though creating pipelines is easier. Since the chapters in this book are focused on pipelines, and assume certain maturity level of an organization, we ordered them by complexity of building those pipelines, not by the complexity of implementing the whole change (culture, processes, technology, architecture).

We call it continues integration as we need to wait until we merge work of different people (usually on the master or whatever is the name where everyone merges), and we don't know whether our code integrates with the code of others until all merges are done. Also, the merges are being collected and the product is considered releasable only after a certain set of features are ready. The reason behind that is based on the cost of the release process itself. It is relatively high because of the manual processes around the release. Things like manual testing, manual approvals, manual risk assessment, and sometimes manual unnecessary (some would say nonsensical) things done by people who are afraid to admit that whatever they do is useless or is a waste of human time and talent. Because of the cost, releases can't be done frequently. Therefore, they are being packaged and released when a certain set of features has been merged. The iteration of the release is different between teams, and it can vary from months to weeks. The longer the lifecycle of a release, the worse the development culture we have. We are not talking about NASA though, but regular software not putting people lives at danger.

So we will be solving problems in this chapter for teams which have some manual processes involved in their ways of working. We will show a CI implementation with some controls and with the assumption that manual steps are performed in between. You should be able to scale or descale the implementation to fit your needs, as we'll try to provide lego blocks type of examples.

Every team has different ways of working, with different cycles and methods to deploy. One example of such differencies is reflected in Git branching models. It is a known fact that more parallel branches you have, the harder it is to bring them together. Branches (especially those with long lifetime) introduce management complexity and, more importantly, delayed integration. It is always recomended to merge as soon as possible. However, as pointed in the [Continuous Delivery With Jenkins And GitOps](#cd) chapter, some organisational blockers may affect your ability to release the way you want to release. Blockers can be inside or outside of your organisation. Companies working in regulated environements an example of those facing such problems. In this chapter I will show yet another alternative of continuous integration (CI) implementation. Of course, you can mix those examples together to build your own pipeline, as everything is code.

We will continue using declarative pipeline and jenkins shared libraries. To avoid conflicts with existing libriaries, we'll use *ci* prefix for functions. The way we build docker image will remain the same, via mounting the socket. We will stick to GitOps as the main source of truth.

Before we dive into the pipeline, we'll explore individual topics that will influence the process as a whole.

## Exploring Branching Models

I am sure that at some point you thought how to organise your Git branches for your development and for releases. You found numerous articles on Internet describing the popular Git branching models where commits were landing on `develop` branch, and where branches were created for new releases. The same logic is often applied to *hotfix* branches. Those models focus on providing guarantee of work isolation, so that we have time to stabilise our release candidates on release branches, without stopping regular development happening on the *develop* branch. In such models, Git tags are often used to mark the point where the software has been released. 

Many build tools implemented the same technique for releases to comply with the suggested branching model. Maven, Gradle and others had (and still have) plugins which are generating release branches and tags, are opening and closing hotfix branches, and so on. Later on GitHub came up with a bit more relaxed branching model called [GitHub flow](https://guides.github.com/introduction/flow/). 

At the first glance, having variety of branches sounds correct, but if you think about it, it assumes that you need to stabilise your release, and that takes time. Therefore, you need a branch for it. And if you build your release process around that model, the process will force you to take time to stabilise the release. You'll need time for testing. After that, you can release it and merge back the stabilisation fixes to the *develop* branch. The process will force you to be slow. The more things we build around that branching model, the harder it is to change it later on. 

The examples of the branching model in the [Creating A Continuous Deployment Pipeline With Jenkins](#cdp) chapter were pretty simple. The assumption was that we do not need to stabilise software. We always roll forward, and everything is (or will be) automated. In the [Continuous Delivery With Jenkins And GitOps](#cd) chapter we saw a blend of those two assumptions, where it was possible to choose what version of software would go to production. However, there was no need to branch releases, nor to stabilise them. Master branch was treated as a stable branch. In this chapter, we will be taking a similar approach, where we do not have release branches. Instead, every merge will be treated as a release candidate, and we will assume that problems on the release candidate can be found early enough and that there is no need to branch out and wait. We will also introduce one more environment, typically called *UAT*, where things are being tested first before promotion to production. In my experience promoting service through different environements is pretty standard approach in most of the organisations. If you were following [The DevOps Toolkit Series](https://www.devopstoolkitseries.com/), you probably remember the recomendation to have exactly the same environements, and the same configuration. All that can be done, but in reality that's rarely the case. In typical organisations, you get different environments on the way to production. In those, we have different types of services, some dockerised and some not, but still forming part of the platform. Usually, that's one of the big blockers to have everything unified. If some parts of big systems are not agile enough, it's hard to deploy them (often due to administrative reasons), or they have not been conteinarised yet. Therefore, its hard to move them arround. Long story short, in most of the organisations the environements are different from each other, and more you move towards production, more production-like environement we are getting. 

We'll explore the correlations between Git tags, Docker image tags, and Helm Chart tags. We'll also show the ability to fixing issues on a specific release. We will be using `hotfix` branches. You can scale this model to have additional releasable branches. However make sure you dont build a process which assumes slow development. Aim for fast-paced processes.

Now that we have a clearer picture about branching models, we should make decisions how to version our releases.

TODO: Viktor: I feel that the "picture about the branching models" is somehow lost in the conversation. How about adding a short description (summary) before the previous sentence?

## Versioning Releases

Every software we use has a version. We need versions to know if we are missing any new features, and whether we are behind the latest version. But we also need versions to understand how hard is it to upgrade software. In this chapter we will use [semantic](https://semver.org/) versioning for our applications. We will make all our releases compliant with semantic versioning.

The rules of semantic versioning are pretty simple.

Given a version number *MAJOR.MINOR.PATCH*, increment each segment using the rules that follow.

* *MAJOR* version increases when we make incompatible API changes.
* *MINOR* version increases when we add functionality in a backwards-compatible manner.
* *PATCH* version increases when you make backwards-compatible bug fixes.

As we already talked about hotfix branches, you can guess that they will typically change the *PATCH* version. Changes on *MASTER* branch will change *MINOR* version, unless we know that we are introducing changes that will make API incompatible with previous releases. In that case, our pipeline should give us a chance to change the *MAJOR* version.

Now might be a good time to ask how would we know what version of we're building. What is going to be the next one? There are typically two ways of managing versions of an application; either in a file, or with Git tags. Both have their pros and cons. In case of having version in a file, every build needs to increment the version by changing that file. Since it is kept in Git, we need to push that change back to the repository. The problem with that approach is that we need to create some kind of a custom mechanism that will prevent those commits from triggering new builds. Otherwise, we'd run a risk of creating newer ending loops where a build commits a file, only to trigger another build that commits a file, and so on. We need a custom mechanism to avoid such loops.  One such solution could be to create rules in our pipelines that would skip builds if comments contain certain patterns. For example, skip the build if the comment says `[release commit ...]`. 

Another way to keep track of the versions is to leverage Git tags. That avoids having a file with version number inside and it avoids pushing that file to the repository. If you (or the process) need to know the version of the current source, you (or it) will read the latest tag. The drawback of this method is that you will need to perform a Git operation each time you want to read the release version.

Both approaches have their pros and cons. We explored the approach with files that contain versions in the [Continuous Delivery With Jenkins And GitOps](#cd) chapter. We avoided the problem with "build loops" by having a separate repository that defines all the information reqired for deploying applications. That, among other things, included versions. In this chapter, we'll explore the approach with Git tags. Git is pretty powerfull source control tool, and tags are its first-class citizens.

We will use the "Git tags" approach in the examples that follow. We will also automate generation of release notes, and attach them to our releases. At least, we will try to do so.

Finally, before we move into hands-on parts of our CI processes, we should define continuous integration pipeline.

## What Is The Continuous Integration Pipeline?

Before we proceed, we'll recap the definitions of continuous deployment, continuous delivery and continuous integration.

I> Continuous deployment (CDP) is a fully automated process that executes a set of steps with the goal of converting each commit to the master branch into a fully tested release deployed to production.

I> Continuous delivery (CD) is almost a fully automated process that executes a set of steps with the goal of converting each commit to the master branch into a fully tested release that is ready to be deployed to production. We (humans) retain the ability to choose which of the production-ready releases will be deployed to production and when is that deployment going to happen.

You knew what CDP and CD are. We just repeated the definitions from before, as a reminder, before we define continous integration.

I> Continuous integration is a slower process where developers are waiting until development on different branches is merged to master, and release is packaged when certain amount of features are ready. We (humans) decide when release will be packaged, and when will release be deployed to a certain environement. 

As with the previous chapter, my primary goal is to show a different approach that can be applied to any type of pipeline with small adjustments. 

The main difference would be applying CI on more than one releasable branches, also using semantic versioning for releases, and git tags as correlation between all artifacts. We will also deploy go-demo in *UAT* environment before releasing it to *production*.

That was the intro. Let's code a bit.

## Creating A Cluster

Just as before, we'll start the practical part by making sure that we have the latest version of the *k8s-specs* repository.

I> All the commands from this chapter are available in the [09-jenkins-ci.sh](TODO:) Gist.

TODO: Add the text explaining Gists once they are all verified.

* TODO: Validate whether this one is valid by rerunning all the commands [docker4mac-cd.sh](https://gist.github.com/d07bcbc7c88e8bd104fedde63aee8374): **Docker for Mac** with 3 CPUs, 4 GB RAM, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP of the cluster.
* TODO: Validate whether this one is valid by rerunning all the commands [minikube-cd.sh](https://gist.github.com/06bb38787932520906ede2d4c72c2bd8): **minikube** with 3 CPUs, 4 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, with **tiller**, and with `LB_IP` variable set to the VM created by minikube.
* TODO: Validate whether this one is valid by rerunning all the commands [kops-cd.sh](https://gist.github.com/d96c27204ff4b3ad3f4ae80ca3adb891): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP retrieved by pinging ELB's hostname. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).
* TODO: Validate whether this one is valid by rerunning all the commands [minishift-cd.sh](https://gist.github.com/94cfcb3f9e6df965ec233bbb5bf54110): **minishift** with 4 CPUs, 4 GB RAM, with version 1.16+, with **tiller**, and with `LB_IP` variable set to the VM created by minishift.
* TODO: Validate whether this one is valid by rerunning all the commands [gke-cd.sh](https://gist.github.com/1b126df156abc91d51286c603b8f8718): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-4 (4 CPUs, 3.6 GB RAM) nodes (one in each zone), with **nginx Ingress** controller running on top of the "standard" one that comes with GKE, with **tiller**, and with `LB_IP` variable set to the IP of the external load balancer created when installing nginx Ingress. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files and Helm Charts if you prefer NOT to install nginx Ingress.
* TODO: Validate whether this one is valid by rerunning all the commands [eks-cd.sh](https://gist.github.com/2af71594d5da3ca550de9dca0f23a2c5): **Elastic Kubernetes Service (EKS)** with 2 t2.medium nodes, with **nginx Ingress** controller, with a **default StorageClass**, with **tiller**, and with `LB_IP` variable set tot he IP retrieved by pinging ELB's hostname.

## Exploring Application's Repository And Preparing The Environment

This time, we'll use [vfarcic/go-demo-4](https://github.com/vfarcic/go-demo-4), instead of the [vfarcic/go-demo-3](https://github.com/vfarcic/go-demo-3) and [vfarcic/go-demo-5](https://github.com/vfarcic/go-demo-5) repositorories. By having a repo dedicated to continuous integration, we'll avoid conflicting issues between different approaches for creating a pipeline.

Since we'll need to change a few configuration files and push them back to the repository, this first thing you need to do is fork [vfarcic/go-demo-4](https://github.com/vfarcic/go-demo-4), just as you forked a few other repositories used in this book. You know what to do.

Next, we'll clone the repository before we explore the relevant files. Please make sure to replace `[...]` with your GitHub user.

```bash
cd ..

GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-4.git

cd go-demo-4
```

There is not much difference between that repository and those we used before, except in a couple of new files that we will be explore soon.

```bash
DH_USER=[...]

cat helm/go-demo-4/deployment-orig.yaml \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee helm/go-demo-4/templates/deployment.yaml
```

TODO: Most people will probably remember the previous command from other chapters, but I'd still repeat in a single sentence why we do that.

Just like before, lets create our build environment. 

```bash
kubectl apply -f k8s/build.yml --record
```

I have created new environment that we will be using for deployments to UAT. 

The extra step here would be to create the UAT environment defined in `k8s/uat.yml`. It is very similar to what we had for `k8s/build.yml`. There's nothing new there, apart from new namespace called `go-demo-4-uat` and a service account for it called `uat-build`.   

```bash
kubectl apply -f k8s/uat.yml --record
```

Finally, the only thing related to the setup of the environment we'll use for *go-demo-4* is to install Tiller. This time, we'll install two tillers, one in each new Namespace. You might be asking yourself, why two? Why not just make one Tiller to work with both namespaces through service accounts. The reason is internal security. Now when we have opened the pandora box lets talk about it.

There are many factors involved in security and it is hard to recommend a solution, because the magnitude of the problem is different. If you are a startup, most likely you are not bothered that much about internal security. Engineers might have access to all parts of the system, and if there are problems, they will likely be resolved by whomever is closest to the laptop. Taking away full access away from such teams would just add unnecessary complications to their startup life.
 
On the other hand, if you are working in a bank or some other regilated industry, you can end up in the prison by the local regulator just because just accidentally (or intentionally) brought down the payment system. Such a failure made a GDP of ASIA go down 10%. In such cases, you will appreciate some level of tighter control. Surely we are not going to solve that magnitude of a problem in this book, but we would like to open a door where you can start thinking about it, if you need higher level of security.

TODO: Do you have a reference (link?) to *GDP of ASIA go down 10%*?

Like we said before, `UAT` is going to be our production-like environment for testing stable releases. If we keep granting access to Tiller to all environments we will end up in a position where internal security is very much questionable as any Helm command which will reach tiller namespace can then make side effects on other environments accessible though the associated service account. Such a comment can be an human mistake, a code mistake, or a bad intention. That's where idea of control and security comes in. Jenkins has a way to do role base access control, where only certain people can invoke jobs which will be touching important environments. That approach will certainly help as well, but it needs to be implemented separately. We won't be going deep into possible and impossible security controls. Instead, I wanted to demonstrate that a bare minimum control can be implemented if Tiller in the build environment can't harm UAT and production environments. Important environments are isolated to some degree, and they require different service account for an access. That service account later on can be stored inside Jenkins under role based control. So, we'll run the commands below that will install two Tillers, one in each Namespace that represents different *go-demo-4* environment.

```bash
helm init --service-account build \
    --tiller-namespace go-demo-4-build

helm init --service-account uat-build \
    --tiller-namespace go-demo-4-uat
```

Now that we created two Tillers, one in each Namespace, we can turn our attention to *Jenkinsfile* and *DeploymentJenkinsfile* files as the key elements of our pipeline. We'll explore them next.

## Exploring Continous Integration Pipeline

Let's take a look at a *Jenkinsfile.orig* which we'll use as a base to generate *Jenkinsfile* that will contain the correct address of the cluster and the GitHub user.

```bash
cat Jenkinsfile.orig
```

We will now go block by block to comment the differences from the Jenkinsfile we used in the previous chapter.

The `agent` block from `Jenkinsfile.orig` is as follows.

```groovy
...
agent {
  kubernetes {
    label "builder-pod-${UUID.randomUUID().toString()}"
    cloud "go-demo-4-build"
    defaultContainer 'jnlp'
    serviceAccount "build"
    yamlFile "KubernetesPod.yaml"
  }
}
...
```

The `agent` block has a couple of differences when compared to what we used before. The `label` statement now has a random value. If two builds are running the same pipeline and at that time the build Pod is available with the same label, it will reuse the existing Pod, instead of creating a new one. That can result in race condition errors. Even if we disable concurrent builds with the method `disableConcurrentBuilds()`, parallel builds can still happen on different branches, and branches can effectively refer to the same Pod if they are labeled the same. Everything else remained equal, except the contents of the `KubernetesPod.yaml` file. We'll talk more about it soon.
 
Next section in the Jenkinsfile is `environment`. We added two new environment variables. 

```groovy
...
environment {
  project="go-demo-4"
  image="vfarcic/go-demo-4"
  domain = "acme.com"
  cmAddr = "cm.acme.com"
  rsaKey="go-demo-rsa-key"
  githubToken="github_token"
}
...
```

Two new variables are `rsaKey` and `githubToken`. Those are names of the two new secrets we will need to create together.

As part of our release process we will be creating and pushing release tags, and most likely your Git repo will require authentication. Therefore, we will use a private key saved with credential `go-demo-rsa-key` stored in Jenkins. 

`githubToken`, on the other hand, will be used to authenticate to GitHub so that we can publish our release notes. You can read the [Creating a personal access token for the command line](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) article if you need help generating a token.

Like before, we'll have to change `vfarcic` to your Docker Hub user and `acme.com` to the address of your cluster.

Next, the `option` block has remained the same as the one we used in *go-demo-5*, so we'll skip it.

We finally reached the execution of the pipeline. Just as in the previous chapter, we're having `build`, `func-test`, and `release` stages. However they behave a bit differently than before. Let us briefly go through each of the stages of the pipeline. The first one is the `build` stage.

```groovy
...
stage('build') {
    steps {
        ciPrettyBuildNumber()

        container('git') {
            ciBuildEnvVars()
        }

        container('docker') {
            ciK8sBuildImage(env.image, false, env.BUILD_TAG)
        }
    }
}
...
```

The first step is invocation of the function `ciPrettyBuildNumber`. It customizes the name of the build by changing the value of the `displayName`. We had that line in our previous chapter as well. The difference is that it is now moved to the Shared Pipeline Library, thus making the pipeline more declarative and easier to follow.

The second step execute the function `ciBuildEnvVars`. That's where the first important difference compared with the previous chapter comes in. The new method publishes few environment variables that will be used during our builds. In declarative pipeline there is no easy way of passing variables from one stage to another without breaking code readability, so we will be using environment variables for that. They will act as global or static variables in other programming languages. 

Lets have a look on the new method. 

```bash
curl "https://raw.githubusercontent.com\
/vfarcic/jenkins-shared-libraries\
/master/vars/ciBuildEnvVars.groovy"
```

The output is as follows.

```groovy
def call() {
    env.shortGitCommit = "${env.GIT_COMMIT[0..10]}"
    env.BUILD_TAG = ciBuildVersionRead()

    echo "build tag set to: ${env.BUILD_TAG}"
}
```

TODO: It might be confusing to use different naming conventions inside the same function. Shall we standardize all env. vars. to be upper case words separated with underscore (like `BUILD_TAG`)? In that case, it should be `SHORT_GIT_COMMIT`.

You can see that we are doing two things here.  

`shortGitCommit` is a short version of the Git commit SHA1. `GIT_COMMIT` environment variable is published by the Git plugin during pipeline run. We will be using `shortGitCommit` as an extra image tag.

TODO: discuss if we need `shortGitCommit` it at all.

The environment variable `BUILD_TAG` is important one. We will be using it to tag all our artifacts like Git source, Helm Charts, and Docker images. However build tags are going to be different depending on whether the build is running on a releasable branch. As we talked about it earlier, we consider only master and hotfix branches releasable.

You will also notice that there is another call to a function called `ciBuildVersionRead`. Lets have a look at the function. 

```bash
curl "https://raw.githubusercontent.com\
/vfarcic/jenkins-shared-libraries\
/master/vars/ciBuildVersionRead.groovy"
```

The output is as follows.

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

We have a bit of nested calls here. As most of those functions are reused, it made sense to capture them as separate functions. Lets check what `ciVersionRead` does on the first line.

```bash
curl "https://raw.githubusercontent.com\
/vfarcic/jenkins-shared-libraries\
/master/vars/ciVersionRead.groovy"
```

The output is as follows.

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

Finally we are getting to the core, where the whole magic happens.

We already talked about semantic versioning. You can see that function bumps the `minor` version if the current branch is `master`. If it is a `hotfix` branch, most likely it is a bug fix, therefore we're bumping up the `revision` version. Finally, if the current branch is not releasable, and it is a feature branch, we will use branch name as a version. Obviously we are not going to tag Git source with a branch name. In fact, we are not going to tag it at all when we are not working on one of the releasable branches. However we will be tagging our Docker images. Therefore, we will need a readable tag, even though we'll throw it away. 

What if it is the first run? Which version is going to be bumped up? If you look at the code inside [ciMasterVersionRead](https://github.com/vfarcic/jenkins-shared-libraries/blob/master/vars/ciMasterVersionRead.groovy), you will notice that it tries to find out what is the latest git tag and, if there isn't any, it will start from `1.0.0`. You can change it to any default tag you want, as long as it complies with the semantic versioning.

We're also using the function [ciBumpUpVersion](https://github.com/vfarcic/jenkins-shared-libraries/blob/master/vars/ciBumpUpVersion.groovy) which we did not explore. However, the name of the function suggests that it will run the logic of incrementing correct number in the version. We will not go into details of the method implementation. It applies some regexp logic, and increments numbers later on. Feel free to explore it on your own if you are curious.

Lets move forward. 

As a result of running the `ciBuildEnvVars` function inside the `build` stage, the `BUILD_TAG` environment variable will be exported, and we will know which tag to use.

It is time to build the docker image.

```groovy
...
  container('docker') {
    ciK8sBuildImage(params.image, false, env.BUILD_TAG)
  }
...
```

The `ciK8sBuildImage` function is almost the same as `k8sBuildImage` we used before. The only difference is that it can push extra tags if the fourth argument is specified.

TODO: Is the new functionality to push extra tags used anywhere?

We are approaching the `func-test` stage. It looks similar to what we had before.

```groovy
...
stage("func-test") {
  steps {
    container("helm") {
      ciK8sUpgradeBeta(env.project, env.domain, env.BUILD_TAG)
    }
    container("kubectl") {
      ciK8sRolloutBeta(env.project)
    }
    container("golang") {
      ciK8sFuncTestGolang(env.project, env.domain)
    }
  }
  post {
    failure {
      container("helm") {
        ciK8sDeleteBeta(env.project)
      }
    }
  }
}
...
```

This stage is almost stayed the same as in the previous chapter. `ciK8sUpgradeBeta` will deploy local Chart from a folder, which will point to the newly built image. Afterwards, we're waiting until Deployment is rolled out before we run our tests. If tests fail, the current Deployment is deleted. 

TODO: Continue review

It's time to move into the next stage which is `Release`. `Release` stage is a bit longer so we will break it down into pieces. 

```groovy
    ...
    stage("Release") {
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
        ciWithGitKey(env.rsaKey) {
            env.RELEASE_TAG = ciSuggestVersion(ciVersionRead())
        }
    }
    ...                
}
```

Here it comes more gitops way of working. As we have discussed before, our release versions are going to be stored as git tags inside our git repo. Intention of this step is to find the latest release number, autoincrement it, and suggest to the user. If user is happy, he/she can click continue or else suggest their own version. There is also a timeout for a decision, which is now set for 15 seconds, but can be changed to your prefer timing. When ttl expires, the suggested value would be taken and pipeline will continue.

So far it was down to jenkins to do git operations for us. Jenkins was checking out the code to the local workspace and was publishing some information via environment variables about git commits. However this is the first time we will need access to our git repo from the code. And because the git repo is going to be authenticated we will need to find a way to authenticate ourselves. There is genuinely two ways to interact with git repo. Either via `ssh` protocol which require ssh keys, or `http` with username and password. We will prefer ssh keys, to not pass username and password with every git command. The problem is, we do not have the private key available inside `git` container. And mounting our key there is an overhead, and also can introduce side effects. What we do is, we pass the private key from jenkins secrets to `ciWithGitKey` closure which will configure `GIT_SSH` environment variable to use the key, therefore every git call within the closure will be authenticated. Again, we will not go behind the scenes of `ciWithGitKey` and we hope you can read and understand it. 

So to summarize, `ciWithGitKey` will authenticate git commands. `ciVersionRead` will get the latest release number and will autoincrement it. `ciSuggestVersion` will suggest the new version to the user with a timeout of 15 seconds. User can change the release value or else continue with the suggestion. 

Lets move to the next new steps. You will notice that there are two outer functions around our main release steps. Lets understand why we need them first.


```groovy
    ...
    container("helm") {
        ciContinueAfterTimeout(5, 'MINUTES') {
            ciConditionalInputExecution(
                    id: "Release Gate",
                    message: "Release ${env.project} ?",
                    ok: "ok",
                    name: "release") {
                ...
            }
}

```

As unfortunately we are not doing CD, it means some decisions are back to humans to make. One decision will be, if indeed version has been tested. What we have done so far was, we have deployed our version to our build namespace, and we did run our tests. When we trust our tests its easy, we can release anytime. When we dont, we need to wait until someone will press the GO button. 


So, lets first define the intention of the stage. By release, we do not necessarily mean deployment. What we mean is, we want to capture everything under the same reference, so we can repeat the same installation of the software as many times as we want.  Our intention here is, 

1. Tag and push the docker image with new release number
1. Tag and push the git commit, with new release number
1. Tag and push helm chart with new release number
1. Generate release notes.


Lets start from the second method called `ciConditionalInputExecution(..)`. As you may have noticed its a closure which takes other functions and closures as arguments. What it does is simple, it will first ask the user if he/she is happy to continue, and then will simply execute the inner functions. Its a way of putting a gate, on a pipeline execution, to not do anything, unless instructed. Obviously if in your case you would prefer to do all release steps automatically, anytime there is a merge or a commit to a releasable branches without control then its easy to remove the outer function. In our case we will imagine we dont want to publish very short release notes with every new commit, but instead we will accomplish an iteration of work, and at some point we will hit the release button to capture everything as a release. 

Now, it would be naive to think, that we will be asking the user for an input for every build. That's where `ciContinueAfterTimeout(..)` can help us. That is yet another useful function, which will put a time out on the inner function. If inner function would take more time that it has been given, code will continue without errors. In our case, if build should not be marked and packaged into release, there will be nothing to do, after five minutes build will be marked as green.

Lets have a look, what will happen if someone would decide that build should be packaged into release. First thing to happen is 

```groovy
container('docker') {
    ciRetag(env.BUILD_TAG, false, ["latest", env.shortGitCommit, env.RELEASE_TAG])
}
```

Remember we have collected some information about the build before. Now we are going to tag the docker image with those values. `ciRetag(...)` function, will take current docker image as an argument, which is `env.BUILD_TAG` and will tag it will the provided list of tags. In our case the list will contain the semantic release version, the commit id, and the `latest` tag for development purposes only. 

Lets move forward, the next section will be tagging our source code.

```groovy
container('git') {
    ciWithGitKey(env.rsaKey) {
        ciTagGitRelease(tag: env.RELEASE_TAG)
    }
}
```

As we discussed before, release is going to be kept in github as a git tag. Therefor we will need to push back our tags. We will use same `ciWithGitKey()` closure. As a reminder, the closure will enable authenticated git operations within it. The nested function which will be called is `ciTagGitRelease(..)`. It is a simple function, which will `tag` the current commit, and will push it back. It will also create default git author called `jenkins` if one does not exist.

Lets continue. Next thing we want to automate are release notes. Lets have a look at the next step in the code.    

```groovy
container('gren') {
    withCredentials([string(credentialsId: env.githubToken, variable: 'TOKEN')]) {
        sh "gren release --token=${TOKEN}"
    }
}
```
Remember we have touched a topic about having a new container in `KubernetesPod.yaml`. [Gren](https://github.com/github-tools/github-release-notes) is a lightweight library to generate release notes from github issues. Obviously you might be using a different tool for tracking your requirements, we just want to demonstrate that the release notes are yet another thing which can be automated as it is part of a release process.

Github has its own issue tracker, and gren works pretty well with it. What it does is, it will collect all the `closed` issues between releases, and will publish them grouped by issue type, and with descriptions. For `gren` to work against authenticated repos, we will use the `githubtoken` credential that we have created before. As a result new shiny github style release notes are going to be published with the release, along with archived source code. 

Finally, we are approaching to a stage where we want to package and version our helm chart. 

```groovy
container("helm") {
    ciK8sPushHelm(params.project, env.RELEASE_TAG, params.cmAddr, true)
}
```

`ciK8sPushHelm(...)` does not contain much of a new information. Only one new thing, it will update `Chart.yaml` file with a new release version. So the chart version will have the same version as the docker image and the git tag. It will update `values.yaml` to point to the new image, will package and push the chart to chartmuseum.

There is nothing else under `release` stage. What is left is `post` actions.

Lets have a look at post action. 

```groovy
    post {
        always {
            ciWhenNotReleaseBranches {
                container("helm") {
                    ciK8sDeleteBeta(env.project)
                }
            }
        }
    }
```

I hope code is self descriptive, and it is clear what it does. The inner function passed to `ciWhenNotReleaseBranches(...)` will only work, if the current build is running on releasable branches. Idea behind is, if the build is running on the feature branch it will be deleted to not use resources from the cloud. Developer always can troubleshoot the version on his/her own laptop. However for release candidates we probably do not want to delete the version, as some manual testing could be in progress, and we do not want to interrupt it. 

At this point, we have, new semantically versioned release, and all artifacts referenced with the same release number, docker image, git source, helm chart. We also have automaticly generated release notes uploaded to github. 

However, we have decoupled deployment of the release, from the release operation itself. We will need a way to deploy our releases between environments. 

 

## Running the pipeline
TODO: Run the pipeline and guide the examples Things like
  - commit to master
  - commit to hotfix
  - commit to feature branch



## Deployment Job

We have explored the *Jenkinsfile* which  contains steps to package the release and make it repeatable to install to a desired environment. Lets have a look how we can choose a version to deploy. 

Lets have a look at the new file in our repo, called `DeploymentJenkinsFile`. It will look like a typical Jenkinsfile we saw many times already. But intention is going to be a little bit different. It wont be running on every commit, but will have instructions on how and where to deploy our software. We will be using jenkins as a UI to interact with, for humans who are making decisions at some point in the cycle. The job which will be running deployment pipeline is a simple example of controlled deployment. 


Lets have a look at the steps in the file.


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

As you would have guessed, when we run the job, as a first stage it will suggest us project list to choose from. We have only one microservice (go-demo-4) to deploy, however example is scalable to any number. Then depending on the selected project job will suggest the possible versions, and then finally the environment. Finally it will deploy the chosen combination to the requested environment and will run the tests. You may ask, how would it know the project list ? Well, we will need to somehow keep the project names that we would like to deploy, and as an example we will keep that information in a yml file called `platform_deployment.yml`. Its a simple `yml` listing microservices which can be deployed, and environments where they can be deployed to. If you have good automated environment, you can have those values coming from apis to be more dynamic. 

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

There is just one method call within the stage, called `showProject()`. `showProject()` is a private method written at the bottom of the same jenkinsfile. We have not done it before, but for argument sake we will show that it is possible to have local methods in declarative pipeline as well. Lets have a look at the method. 


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

What comes next is choosing a version. `Select Version` stage will be calling `showVersion()` in the same way we have done for the previous step. Local `showVersion()` method then will query github api for available releases for the project. The releases will be collected and will be shown in a new dropdown box just like we have done for the previous stage. 

Similar way the next stage will then read available environments for the service and will render them in the drop down. 

After collecting all the info, the deploy stage will execute the usual `helm upgrade ...` command and will pass the arguments collected from previous three stages. 

This approach will allow us to deploy any service to any new namespace. There are no restrictions to limit it to just microservices, but we can install the whole platform just like we did for prod helm. The difference is, the platform will have its own versioning, and it will be composition of multiple service. It will maintain its own release versions and release notes. We will leave that exercise to you to complete and hear your feedback about it. 


## Running Deployment job
> Run and guide through with images

## What Now?
?
