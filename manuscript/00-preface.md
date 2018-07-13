# Preface

Soon after I started working on [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy), I realized that a single book could only scratch the surface. Kubernetes is vast, and no single book can envelop even all the core components. If we add community projects, the scope becomes even more extensive. Then we need to include hosting vendors and different ways to set up and manage Kubernetes. That would inevitably lead us to third-party solutions like OpenShift, Rancher, and DockerEE, to name a few. It doesn't end there. We'd need to explore other types of community and third-party additions like those related to networking and storage. And don't forget the processes like, for example, continuous delivery and deployment. All those things could not be explored in a single book so *The DevOps 2.3 Toolkit: Kubernetes* ended up being an introduction to Kubernetes. It can serve as the base for exploring everything else.

The moment I published the last chapter of [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy), I started working on the next material. A lot of ideas and tryouts came out of it. It took me a while until the subject and the form of the forthcoming book materialized. After a lot of consultation with the readers of the previous book, the decision was made to explore continuous delivery and deployment processes in a Kubernetes cluster. The high-level scope of the book you are reading right now was born.

# Overview

Just like the other books I wrote, this one does not have a fixed scope. I did not start with an index. I didn't write a summary of each chapter in an attempt to define the scope. I do not do such things. There is only a high-level goal to explore **continuous delivery and deployment inside Kubernetes clusters**. What I did do, though, was to set a few guidelines.

The first guideline is that *all the examples will be tested on all major Kubernetes platforms.* Well, that might be a bit far-fetched. I'm aware that any sentence that mentions "all" together with "Kubernetes" is bound to be incorrect. New platforms are popping out like mushrooms after rain. Still, what I can certainly do is to choose a few of the most commonly used ones.

**Minikube** and **Docker for Mac or Windows** should undoubtedly be there for those who prefer to "play" with Docker locally.

AWS is the biggest hosting provider so **Kubernetes Operations (kops)** must be included as well.

Since it would be silly to cover only un-managed cloud, I had to include managed Kubernetes clusters as well. **Google Kubernetes Engine (GKE)** is the obvious choice. It is the most stable and features rich managed Kubernetes solution. Adding GKE to the mix means that Azure Container Service (AKS) and **Amazon's Elastic Container Service (EKS)** should be included as well so that we can have the "big trio" of the hosting vendors that offer managed Kubernetes. Unfortunately, even though AKS is available, it is, at this moment (June 2018), still too unstable. So, I'm forced to scale down from the trio to the GKE and EKS duo as representatives of managed Kubernetes we'll explore.

Finally, a possible on-prem solution should be included as well. Since **OpenShift** shines in that area, the choice was relatively easy.

All in all, I decided to test everything in minikube and Docker for Mac locally, AWS with kops as the representative of a cluster in the cloud, GKE for managed Kubernetes clusters, and OpenShift (with minishift) as a potential on-prem solution. That, in itself, already constitutes a real challenge that might prove to be more than I can chew. Still, making sure that all the examples work with all those platforms and solutions should provide some useful insights.

Some of you already chose the Kubernetes flavor you'll use. Others might still wonder whether to adopt one or the other. Even though the comparison of different Kubernetes platforms is not the primary scope of the book, I'll do my best to explain the differences as they come.

Once I decided that many different platforms should be used in the book, I had to make a similar decision for CD tools as well. Just as exploring different Kubernetes platforms gives us knowledge that'll allow us to make better choices, the same is true for continuous deployment processes as well. Should we use a self-hosted solution like [Jenkins](https://jenkins.io/) or a service like [CodeShip](https://codeship.com/)? If we're hosting the solution ourselves, should it be open source Jenkins or the [enterprise edition](https://www.cloudbees.com/products/cloudbees-jenkins-enterprise)? How about [Jenkins X](https://jenkins-x.io/)? It was made public for the first time when I just started thinking about this book. It's a solution built on top of Kubernetes, and only for Kubernetes. How can I not include a CD tool specifically designed to work with Kubernetes? So, the potential set of tools could be Jenkins open source, Jenkins enterprise, Jenkins X, and CodeShip.

To summarize the guidelines, it should be a smaller book that **explores continuous delivery and deployment using Jenkins OSS, Jenkins EE, Jenkins X, and CodeShip**. All the examples will the tested in **minikube, Docker for Mac (or Windows), AWS with kops, GKE, OpenShift with minishift, and EKS**.

The moment I finished writing the previous paragraph I realized that I am repeating the same mistakes from the past. I start with something that looks like a reasonable scope, and I end up with something much bigger and longer. Will I be able to follow all of those guidelines? I honestly don't know. I'll do my best.

I was supposed to follow the "best practice" by writing the overview at the end. I'm not doing that. Instead, you are reading about the plans for the book, not the end result. This is not an overview. You can consider this as the first page of the diary. The end of the story is still unknown.

Eventually, you might get stuck and will be in need of help. Or you might want to write a review or comment on the book's content. Please join the [DevOps20](http://slack.devops20toolkit.com/) Slack channel and post your thoughts, ask questions, or participate in a discussion. If you prefer a more one-on-one communication, you can use Slack to send me a private message or send an email to viktor@farcic.com. All the books I wrote are very dear to me, and I want you to have a good experience reading them. Part of that experience is the option to reach out to me. Don't be shy.

Please note that this one, just as the previous books, is self-published. I believe that having no intermediaries between the writer and the reader is the best way to go. It allows me to write faster, update the book more frequently, and have more direct communication with you. Your feedback is part of the process. No matter whether you purchased the book while only a few or all chapters were written, the idea is that it will never be truly finished. As time passes, it will require updates so that it is aligned with the change in technology or processes. When possible, I will try to keep it up to date and release updates whenever that makes sense. Eventually, things might change so much that updates are not a good option anymore, and that will be a sign that a whole new book is required. **I will keep writing as long as I continue getting your support.**

# Audience

This book explores continuous deployment to a Kubernetes cluster. It uses a wide range of Kubernetes platforms and provides instructions how to develop a pipeline on few of the most commonly used CI/CD tools.

This book is not your first contact with Kubernetes. I am assuming that you are already proficient with Deployments, ReplicaSets, Pods, Ingress, Services, PersistentVolumes, PersistentVolumeClaims, Namespaces and a few other things. This book assumes that we do not need to go through the basic stuff. At least, not through all of it. The book assumes a certain level of Kubernetes knowledge and hands-on experience. If that's not the case, what follows might be too confusing and advanced. Please read [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy) first, or consult the Kubernetes documentation. Come back once you're done and once you think you can claim that you understand at least basic Kubernetes concepts and resource types.

# About the Author

Viktor Farcic is a Senior Consultant at [CloudBees](https://www.cloudbees.com/), a member of the [Docker Captains](https://www.docker.com/community/docker-captains) group, and author.

He coded using a plethora of languages starting with Pascal (yes, he is old), Basic (before it got Visual prefix), ASP (before it got .Net suffix), C, C++, Perl, Python, ASP.Net, Visual Basic, C#, JavaScript, Java, Scala, etc. He never worked with Fortran. His current favorite is Go.

His big passions are Microservices, Continuous Deployment and Test-Driven Development (TDD).

He often speaks at community gatherings and conferences.

He wrote [The DevOps 2.0 Toolkit: Automating the Continuous Deployment Pipeline with Containerized Microservices](http://amzn.to/2xSIBCI), [The DevOps 2.1 Toolkit: Docker Swarm: Building, testing, deploying, and monitoring services inside Docker Swarm clusters](http://amzn.to/2xSJ9bK), [The DevOps 2.2 Toolkit: Self-Sufficient Docker Clusters: Building Self-Adaptive And Self-Healing Docker Clusters](http://amzn.to/2yBPWDC), [The DevOps 2.3 Toolkit: Kubernetes: Deploying and managing highly-available and fault-tolerant applications at scale](https://amzn.to/2GvzDjy), and [Test-Driven Java Development](https://www.packtpub.com/application-development/test-driven-java-development).

His random thoughts and tutorials can be found in his blog [TechnologyConversations.com](https://technologyconversations.com/).

# Dedication

To Sara, the only person that truly matters in this world.

# Prerequisites

Each chapter will assume that you have a working Kubernetes cluster. It doesn't matter whether that's a single-node cluster running locally or a fully operational production-like cluster. What matters is that you have (at least) one.

We won't go into details how to create a Kubernetes cluster. I'm sure that you already know how to do that and that you have `kubectl` installed on your laptop. If that's not the case, you might want to read [Appendix A: Installing kubectl and Creating A Cluster With minikube](#appendix-a). While minikube is great for running a local single-node Kubernetes cluster, you'll probably want to try some of the ideas in a more production-like cluster. I hope that you already have a "real" Kubernetes cluster running in AWS, GKE, DigitalOcean, on-prem, or somewhere else. If you don't, and you don't know how to create one, please read *[Appendix B: Using Kubernetes Operations (kops)](#appendix-b)*. It'll give you just enough information you need to prepare, create, and destroy a cluster.

Even though *[Appendix A](#appendix-a)* and [Appendix B](#appendix-b) explain how to create a Kubernetes cluster locally and in AWS, you do not need to limit yourself to minikube locally and kops in AWS. I did my best to provide instructions on some of the most commonly used flavors of Kubernetes clusters.

I> All the examples in the book are tested against Kubernetes clusters created with **minikube and Docker For Mac (or Windows) locally, kops in AWS, OpenShift with minishift, Google Container Engine (GKE), and Amazon Kubernetes Service (EKS)**. 

In most cases, the same examples and commands will work in all of the tested combinations. When that is not the case, you'll see a note explaining what should be done to accomplish the same result in your favorite Kubernetes and hosting flavor. Even if you use something else, you should have no problems adapting the commands and specifications to comply with your platform.

Each chapter will contain a short list of requirements that your Kubernetes cluster will need to meet. If you are unsure about some of the requirements, I prepared a few Gists with the commands I used to create them. Since each chapter might need different cluster components and sizes, the Gists used for setting up a cluster might differ from one chapter to another. Please use them as guidelines, not necessarily as the exact commands you should execute. After all, the book assumes that you already have some Kubernetes knowledge. It would be tough to claim that you are not a Kubernetes newbie and yet you never created a Kubernetes cluster.

Long story short, the prerequisites are hands-on experience with Kubernetes and at least one Kubernetes cluster.

I> I will assume that this is not your first contact with Kubernetes. If my assumption is wrong, please consider going through [The DevOps 2.3 Toolkit: Kubernetes: Deploying and managing highly-available and fault-tolerant applications at scale](https://amzn.to/2GvzDjy) first.