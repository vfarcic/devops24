# Preface

Soon after I started working on [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy), I realized that a single book could only scratch the surface. Kubernetes is vast, and no single book can envelop even all the core components. If we add community projects, the scope becomes even more extensive. Then we need to include hosting vendors and different ways to set up and manage Kubernetes. That would inevitably lead us to third-party solutions like OpenShift, Rancher, and DockerEE, to name a few. It doesn't end there. We'd need to explore other types of community and third-party additions like those related to networking and storage. And don't forget the processes like, for example, continuous delivery and deployment. All those things could not be explored in a single book so *The DevOps 2.3 Toolkit: Kubernetes* ended up being an introduction to Kubernetes. It can serve as the base for exploring everything else.

The moment I published the last chapter of [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy), I started working on the next material. A lot of ideas and tryouts came out of it. It took me a while until the subject and the form of the forthcoming book materialized. After a lot of consultation with the readers of the previous book, the decision was made to explore continuous delivery and deployment processes in a Kubernetes cluster. The high-level scope of the book you are reading right now was born.

# Overview

Just like the other books I wrote, this one does not have a fixed scope. I did not start with an index. I didn't write a summary of each chapter in an attempt to define the scope. I do not do such things. There is only a high-level goal to explore **continuous delivery and deployment inside Kubernetes clusters**. What I did do, though, was to set a few guidelines.

The first guideline is that *all the examples will be tested on all major Kubernetes platforms.* Well, that might be a bit far-fetched. I'm aware that any sentence that mentions "all" together with "Kubernetes" is bound to be incorrect. New platforms are popping out like mushrooms after rain. Still, what I can certainly do is to choose a few of the most commonly used ones.

**Minikube** and **Docker for Mac or Windows** should undoubtedly be there for those who prefer to "play" with Docker locally.

AWS is the biggest hosting provider so **Kubernetes Operations (kops)** must be included as well.

Since it would be silly to cover only un-managed cloud, I had to include managed Kubernetes clusters as well. **Google Kubernetes Engine (GKE)** is the obvious choice. It is the most stable and features rich managed Kubernetes solution. Adding GKE to the mix means that Azure Container Service (AKS) and **Amazon's Elastic Container Service (EKS)** should be included as well so that we can have the "big trio" of the hosting vendors that offer managed Kubernetes. Unfortunately, even though AKS is available, it is, at this moment (June 2018), still too unstable and it's missing a lot of features. So, I'm forced to scale down from the trio to the GKE and EKS duo as representatives of managed Kubernetes we'll explore.

Finally, a possible on-prem solution should be included as well. Since **OpenShift** shines in that area, the choice was relatively easy.

All in all, I decided to test everything in minikube and Docker for Mac locally, AWS with kops as the representative of a cluster in the cloud, GKE for managed Kubernetes clusters, and OpenShift (with minishift) as a potential on-prem solution. That, in itself, already constitutes a real challenge that might prove to be more than I can chew. Still, making sure that all the examples work with all those platforms and solutions should provide some useful insights.

Some of you already chose the Kubernetes flavor you'll use. Others might still wonder whether to adopt one or the other. Even though the comparison of different Kubernetes platforms is not the primary scope of the book, I'll do my best to explain the differences as they come.

To summarize the guidelines, the book has to **explores continuous delivery and deployment in Kubernetes using Jenkins**. All the examples have to be tested in **minikube, Docker for Mac (or Windows), AWS with kops, GKE, OpenShift with minishift, and EKS**.

The moment I finished writing the previous paragraph I realized that I am repeating the same mistakes from the past. I start with something that looks like a reasonable scope, and I end up with something much bigger and longer. Will I be able to follow all of those guidelines? I honestly don't know. I'll do my best.

I was supposed to follow the "best practice" by writing the overview at the end. I'm not doing that. Instead, you are reading about the plans for the book, not the end result. This is not an overview. You can consider this as the first page of the diary. The end of the story is still unknown.

Eventually, you might get stuck and will be in need of help. Or you might want to write a review or comment on the book's content. Please join the [DevOps20](http://slack.devops20toolkit.com/) Slack channel and post your thoughts, ask questions, or participate in a discussion. If you prefer a more one-on-one communication, you can use Slack to send me a private message or send an email to viktor@farcic.com. All the books I wrote are very dear to me, and I want you to have a good experience reading them. Part of that experience is the option to reach out to me. Don't be shy.

Please note that this one, just as the previous books, is self-published. I believe that having no intermediaries between the writer and the reader is the best way to go. It allows me to write faster, update the book more frequently, and have more direct communication with you. Your feedback is part of the process. No matter whether you purchased the book while only a few or all chapters were written, the idea is that it will never be truly finished. As time passes, it will require updates so that it is aligned with the change in technology or processes. When possible, I will try to keep it up to date and release updates whenever that makes sense. Eventually, things might change so much that updates are not a good option anymore, and that will be a sign that a whole new book is required. **I will keep writing as long as I continue getting your support.**

# Audience

This book explores continuous deployment to a Kubernetes cluster. It uses a wide range of Kubernetes platforms and provides instructions how to develop a pipeline on few of the most commonly used CI/CD tools.

This book is not your first contact with Kubernetes. I am assuming that you are already proficient with Deployments, ReplicaSets, Pods, Ingress, Services, PersistentVolumes, PersistentVolumeClaims, Namespaces and a few other things. This book assumes that we do not need to go through the basic stuff. At least, not through all of it. The book assumes a certain level of Kubernetes knowledge and hands-on experience. If that's not the case, what follows might be too confusing and advanced. Please read [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy) first, or consult the Kubernetes documentation. Come back once you're done and once you think you can claim that you understand at least basic Kubernetes concepts and resource types.

# About the Author

Viktor Farcic is a Principal Consultant at [CloudBees](https://www.cloudbees.com/), a member of the [Docker Captains](https://www.docker.com/community/docker-captains) group, and author.

He coded using a plethora of languages starting with Pascal (yes, he is old), Basic (before it got Visual prefix), ASP (before it got .Net suffix), C, C++, Perl, Python, ASP.Net, Visual Basic, C#, JavaScript, Java, Scala, etc. He never worked with Fortran. His current favorite is Go.

His big passions are containers, distributed systems, microservices, continuous delivery and deployment (CD) and test-driven development (TDD).

He often speaks at community gatherings and conferences.

He wrote [The DevOps Toolkit Series](http://www.devopstoolkitseries.com/), and [Test-Driven Java Development](https://www.packtpub.com/application-development/test-driven-java-development).

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

# Rumblings Of An Old Men

T> Continuous Deployment is about making a decision to do things right. It is a clear goal and a proof that the changes across all levels were successful. The primary obstacle is thinking that we can get there without drastic changes in the application's architecture, processes, and culture. Tools are the least of our problems.

I spend a significant chunk of my time helping companies improve their systems. The most challenging part of my job is going back home after an engagement knowing that the next time I visit the same company, I will discover that there was no significant improvement. I cannot say that is not partly my fault. It certainly is. I might not be very good at what I do. Or maybe I am not good at conveying the right message. Maybe my advice was wrong. There can be many reasons for those failures, and I do admit that they are probably mostly my fault. Still, I cannot shake the feeling that my failures are caused by something else. I think that the root cause is in false expectations.

People want to improve. That is in our nature. Or, at least, most of us do. We became engineers because we are curious. We like to play with new toys. We love to explore new possibilities. And yet, the more we work in a company, the more we become complacent. We learn something, and then we stop learning. We shift our focus towards climbing company ladders. The more time passes, the more emphasis we put on defending our positions which often mean the status quo.

We become experts in something, and that expertise brings us to glory and, hopefully, it lands a promotion, or two. From there on, we ride on that glory. *Look at me, I'm a DB2 expert. That's me, I set up VMWare virtualization. I brought the benefits of Spring to our Java development.* Once that happens, we often try to make sure that those benefits stay intact forever. We won't switch to NoSQL because that would mean that my DB2 expertise is not as valuable anymore. We won't move to Cloud, because I am the guru behind VMWare. We will not adopt Go, because I know how to code in Java.

Those voices are critical because they are being voiced by senior people. Everyone needs to listen to them, even though the real motivations behind those voices are selfish. They are not based on actual knowledge, but often on repeated experience. Having twenty years of experience with DB2 is not truly twenty years of improvement, but rather the same experience repeated twenty times. Yet, twenty years has weight. People listen to you, but not because they trust you, but because you are senior and management believes in your capabilities to make decisions.

Combine voices from the old with management's fear of unknown and their quest for short-term benefits. The result is often status quo. *That worked for years, why would we change it to something else. Why would I trust a junior developer telling me what to do?* Even if a claim for change is backed by the experience from giants like Google, Amazon, and Netflix (just to name a few), you are likely to get a response along the following lines. *"We are different"*. *"That does not apply here."* *"I'd like to do that but regulations, which I do not truly understand, prevent me from changing anything."*

Still, sooner or later, a directive to change comes along. Your CTO might have gone to the Gartner meeting where he was told to switch to microservices. Too many people spoke about Agile for upper management to ignore it. DevOps is a huge thing, so we need to employ it as well. Kubernetes is everywhere, so we'll start working on a PoC soon.

When those things do happen, when a change is approved, you might be ecstatic. This is your moment. This is when you'll start doing something delicious. That is often the moment when I receive a call. *"We want to do this and that. Can you help us?"* I usually (not always) say yes. That's what I do. And yet, I know that my engagement will not produce a tangible improvement. I guess that hope dies last.

Why am I so pessimistic? Why do I think that improvements do not produce tangible benefits? The answer lies in the scope of required changes.

Almost every tool is a result of specific processes. A process, on the other hand, is a product of a particular culture. Adopting a process without making cultural changes is a waste of time. Adopting tools without accepting the processes behind them is a futile effort that will result only in wasted time and potentially substantial license costs. In infrequent occasions, companies do choose to accept the need to change all three (culture, processes, and tools). They make a decision, and sometimes they even start moving in the right direction. Those are precious cases that should be cherished. But they are likely to fail as well. After a while, usually a few months later, we realize the scope of those changes. Only the brave will survive, and only those committed will see it through.

Those who do choose to proceed and indeed change their culture, and their processes, and their tools, will realize that they are incompatible with the applications they've been developing over the years. Containers work with everything, but benefits are genuinely tremendous when developing microservices, not monoliths. Test-driven development increases confidence, quality, and speed, but only if applications are designed to be testable. Zero-downtime deployments are not a myth. They work, but only if our applications are cloud-native, if they follow at least some of [twelve factors](https://12factor.net/), and so on.

It's not only about tools, processes, and culture, but also about getting rid of the technical debt you've been accumulating over the years. By debt, I don't necessarily mean that you did something wrong when you started, but rather that time converted something awesome into a horrible monster. Do you spend fifty percent of your time refactoring? If you're not, you're accumulating technical debt. It's unavoidable.

When faced with all those challenges, giving up is the expected outcome. It's human to throw down the towel when there's no light at the end of the tunnel. I don't judge you. I feel your pain. You're not moving forward because the obstacles are too big. Still, you have to get up because there is no alternative. You will continue. You will improve. It'll hurt a lot, but there is no alternative, except slow death while your competition is looking over your soon-to-be corpse.

You got this far, and I can assume only two possible explanations. You are one of those who read technical books as a way to escape from reality, or you are applying at least some of the things we discussed thus far. I hope it's the latter. If that's the case, you do not fall into "yet another failure of mine." I thank you for that. It makes me feel better.

If you do employ the lessons from this book, without faking, you are indeed doing something great. There is no way of pretending continuous delivery (CD). Every commit you make is ready for production if all the stages are green. The decision whether to deploy it to production is based on business or marketing needs, and it is not technical in any sense. You can even take a step forward and practice continuous deployment (CDP). It removes the only action performed by a human and deploys every green commit to production. Neither of the two can be faked. You cannot do CD or CDP partly. You cannot be almost there. If you are, you're doing continuous integration, it-will-be-deployed-eventually process, or something else.

All in all, you are, hopefully, ready to do this. You will take a step towards continuous deployment inside a Kubernetes cluster. By the end of this book, the only thing left for you is to spend an unknown amount of time "modernizing" architecture of your applications or throwing them to thrash and starting over. You'll be changing your tools, processes, and culture. This book will not help you with all of those. We're focused on tools and processes. You'll have to figure out what to do with your culture and architecture. The same holds true for the way you write your tests. I won't teach you testing, and I won't preach TDD. I'll assume that you already know all that and that we can focus on continuous deployment pipeline only.

At this moment, you might feel desperate. You might not be ready. You might think that you don't have a buyout from your management, that the people in your company will not accept this direction, or that you don't have enough time and funds. Do not get depressed. Knowing the path is the most crucial part. Even if you cannot get there any time soon, you should still know what the destination is, so that your steps are at least moving you in the right direction.

## What Is Continuous Deployment?

I> Practicing continuous deployment means that every commit to the master branch is deployed to production without human intervention.

That's it. That's the shortest, and probably the most accurate definition of continuous deployment you'll ever find. Is that too much for you? If you don't think you can (or should) ever get there, we can fall back to continuous delivery.

I> Practicing continuous delivery means that every commit to the master branch is deployable to production unless it failed a fully automated pipeline.

The only substantial difference between continuous deployment (CDP) and continuous delivery (CD) is that one deploys to production while the other requires that we choose which commit is deployed to production. That's much easier, isn't it? Actually, it isn't. It's almost the same since in both cases we are so confident in the process that every commit is or can be deployed to production. In the case of continuous delivery, we (humans) do need to make a decision on what to deploy. However, that is the cause of significant confusion. What follows is the vital part so please read it carefully.

I> The decision which commit to deploy to production is based on business or marketing needs, and it has nothing to do with engineers.

If every commit (that did not fail the pipeline) is deployable to production, there is no need for an engineer to decide what will be deployed. **Every commit is deployable**, we just might not want to have a feature available to users straight away. It's a business decision. Period.

As a learning experience, you should take the least technical person in a company and put him (or her) in front of a screen with the builds and let him (or her) choose which release to deploy. Someone from cleaning services is an excellent candidate to be that person. Now, before that person clicks the button to deploy a random release, you need to remove yourself from that room.

Here comes the critical question. How would you feel in that situation? If you'd go to the closest bar to have a coffee confident that nothing wrong will happen, you are in the right place. If you would have a nervous breakdown, you're still far from being there. If that's the case, do not despair. Most of us would have a nervous breakdown from letting a random person deploy a random release. That's not what matters. What is important is whether you want to get there. If you do, read on. If you don't, I hope you're reading a free sample of the book, and you can make an educated decision not to waste money. Get something else to read.

"Hold on," you might say. "I am already doing continuous integration," could be the thought in your head right now. "Is continuous delivery or deployment truly that different?" Well, the answer is that it's not, but that you probably misunderstood what continuous integration is. I won't even try to define it for you. Over fifteen years passed since CI became a thing. I will, however, ask you a few questions. If you answer with "no" to at least one of them, you're not doing CI. Here it goes.

* Are you building and, at least partially, testing your application on every commit without exceptions and no matter to which branch that commit is pushed to?
* Is everyone committing at least once a day?
* Do you merge your branches to the *master* after a couple of days, if not more frequently?
* Do you stop doing whatever you're doing to fix a failed build? Is that the highest priority (after fire emergency, earthquakes, and other life-threatening events)?

That's it. Those are the only questions you need to answer. Be honest with yourself. Did you really respond with "yes" to all four of those questions? If you did, you're my hero. If you didn't, there is only one more question left to answer.

**Do you really want to do continuous integration (CI), delivery (CD), or deployment (CDP)?**
