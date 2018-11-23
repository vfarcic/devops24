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

T> Continuous delivery is a step down from continuous deployment. Instead of deploying every commit from the master branch to production, we are choosing which build should be promoted. Yet, many are not ready for continuous deployment and continuous delivery is the second best option.

In many companies, every team has different ways of working, with different cycles and methods to deploy. One example of such differentces is reflected in Git branching models. It is known fact that more parallel branches you have, the harder it is to bring them together later on. Branches (especially those with long lifetime), introduce management complexity and, more importantly, delayed integration. It is always recomended to merge as soon as possible. However, as pointed in the [Continuous Delivery With Jenkins And GitOps](#cd) chapter, some organisational blockers may affect your ability to release the way you want to release, blockers can be inside or outside of your organisations, companies which are working in regulated environements facing those problems. In this chapter I will show yet another alternative of continuous integration (CI) implementation, and of course you can mix those examples together, to build your own pipeline, as everything is a code.

We will continue using declarative pipeline and jenkins shared library. To avoid conflicts with existing shared libriaries, we'll use *ci* prefix for functions. The way we build docker image will remain the same, via mounting the socket. We will stick to GitOps as the main source of truth.

TODO: Is this chapter about CD or CI? If it's latter, we should probably change the title.

TODO: Add a note that when a merge to master is delayed, it is continuous integration, or not even that. We can continuous execute only some processes (e.g., testing), while we need to wait until merges are done for the rest. The reason I said "not even that" (CI), is that until we merge work of different people (usually on the master or whatever is the name where everyone merges), we don't know whether our code integrates with the code of others.

TODO: The paragraph that follows is new. Please let me know what you think.

It might seem like we're moving backwards, from continuous deployment (CDP), to continuous delivery (CD), and now to continuous integration (CI). That doesn't seem like a logical order. However, from the pipeline perspective, CD is more complex than CDP, and CI is even more complicated than either of the two. That does not mean that CI is the most complex overal. It isn't. CDP and CD force us to adopt new processes, new culture, and new architecture. Changing those three is very hard, even though creating pipelines is easier. Since the chapters in this book are focused on pipelines, and assume certain maturity level of an organization, we ordered them by complexity of building those pipelines, not by the complexity of implementing the whole change (culture, processes, technology, architecture).

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

Just as before, we'll start the practical part by making sure that we have the latest version of the *k8s-specs* repository.

I> All the commands from this chapter are available in the [09-jenkins-ci.sh](TODO:) Gist.

```bash
cd k8s-specs

git pull
```

We will setup the cluster with Helm requirements just as we did in the previous chapter. You should familiar with that part of the scripts.

* [docker4mac-cd.sh](https://gist.github.com/d07bcbc7c88e8bd104fedde63aee8374): **Docker for Mac** with 3 CPUs, 4 GB RAM, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP of the cluster.
* [minikube-cd.sh](https://gist.github.com/06bb38787932520906ede2d4c72c2bd8): **minikube** with 3 CPUs, 4 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, with **tiller**, and with `LB_IP` variable set to the VM created by minikube.
* [kops-cd.sh](https://gist.github.com/d96c27204ff4b3ad3f4ae80ca3adb891): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, with **tiller**, and with `LB_IP` variable set to the IP retrieved by pinging ELB's hostname. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).
* [minishift-cd.sh](https://gist.github.com/94cfcb3f9e6df965ec233bbb5bf54110): **minishift** with 4 CPUs, 4 GB RAM, with version 1.16+, with **tiller**, and with `LB_IP` variable set to the VM created by minishift.
* [gke-cd.sh](https://gist.github.com/1b126df156abc91d51286c603b8f8718): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-4 (4 CPUs, 3.6 GB RAM) nodes (one in each zone), with **nginx Ingress** controller running on top of the "standard" one that comes with GKE, with **tiller**, and with `LB_IP` variable set to the IP of the external load balancer created when installing nginx Ingress. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files and Helm Charts if you prefer NOT to install nginx Ingress.
* [eks-cd.sh](https://gist.github.com/2af71594d5da3ca550de9dca0f23a2c5): **Elastic Kubernetes Service (EKS)** with 2 t2.medium nodes, with **nginx Ingress** controller, with a **default StorageClass**, with **tiller**, and with `LB_IP` variable set tot he IP retrieved by pinging ELB's hostname.

Here we go.

TODO: Continue test
