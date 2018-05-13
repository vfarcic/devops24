# The Story (Episode 1)

## The Place

Go Demo Inc headquarters.

## The Actors

**John**: Team lead behind the flagship application *go-demo*. The team is fully in charge of everything related to the application. They gather requirements, they write tests and application code, they deploy, and they monitor. They are truly self-sufficient. The application has already been running in a small Kubernetes cluster for a week. The PoC proved to be successful and the team is preparing to launch it to production.

**Eva**: SRE in charge of overall stability and performance of the system. Her job is split between taking care of the system as a whole as well as helping other teams (like John's) meet some of their objectives like stability and performance. Her job is to make them self-sufficient, at least from infrastruture and deployment points of view. She is known as a person who does not speak much. When you're lucky, you can get a single sentence as a response to your questions.

**Sarah**: In charge of company-wide tools. Her job is to explore those available in the market and help the teams adopt them if they choose to do so. The teams in charge of applications (like John's) bear full responsibility and that means that they can choose which tools and languages they will adopt. Sarah cannot force anyone to adopt anything because that would prevent those teams from being responsible for their own destiny. Her job is not to enforce anything, but to help those in need of guidance and expertise.

## The Scene

**John**: We already proved through PoC that we want to adopt Kubernetes as a platform we'll use to run our applications. Our next step is to do the finishing touches and, from there on, to concentrate on our continuous deployment processes.

**Sarah**: Which tool will you use for continuous deployment?

**John**: We are inclined towards using Jenkins. We already created a Kubernetes Deployment with Jenkins and attached it to an external storage. It worked fine so far and we'd like to fully adopt it. We plan to explore Kubernetes plugin in the next sprint.

**Sarah**: That sounds like a good plan. We are moving away from company-wide Jenkins shared among many teams. Each team should be in charge of their own instance and your plan is well much aligned with ours. By giving each team their own instance we'll provide more freedom and isolate problems we are experiencing with the shared instances.

**John**: Before we move into CD with Jenkins, we still need to scale our MongoDB instance. In our PoC cluster we are running only a single DB replica. Since we already have the database defined as a Kubernetes Deployment with a PersistentVolume, it should be fairly simple to scale it up by increasing the number of replicas. The only thing left to figure out is how to create a MongoDB replica set. I'm confident it'll be relatively easy. Once we're done with scaling and DB replica set, we can focus on Jenkins and continuous deployment processes.

Up until this moment, Eva was silent. It seemed like she's not even paying attention. All of a sudden, she changed her expression. It's as if John's words woke he up from a trance.

**Eva**: You're planning to use Kubernetes Deployment for your MongoDB?

**John**: Yes.

**Eva**: You want to run stateful application at scale through Kubernetes Deployments?

**John**: (nervously) Yes.

**Eva**: You're entering a world of pain! It is certain that you'll fail.

**John**: (obviously distressed) Why? We already used Deployments to scale our applications. It worked well. We already know how to create claims that attach PersistentVolumes to our applications. We know that those things work. Why would we face issues? Creating a DB replica set is the only task we have left pending.

**Eva**: You should use StatefulSets. They will provide you with the tools you need to accomplish your goals.

**John**: I understand that the name clearly indicates that StatefulSets should be used with stateful applications, or something like that. Still, why would we move away from Deployments. Can you provide a bit more info?

Eva made a move with her hand as if brushing away John's questions. That was a clear indication that she will ignore whatever John said and continue her discourse.

**Eva**: Here's the plan. Move Jenkins from the Deployment into a StatefulSet. Jenkins is a relatively simple example. It cannot scale, so that will limit the unknowns. It'll be a good entry point into StatefulSets even though you will not see any tangible benefits. You'll have a concrete example that will allow you to focus on exploring StatefulSet syntax and benefits without going too much astray. With Jenkins, you won't be able to fail. It'll work, more or less, equally well with a StatefulSet as with Deployments. Once you're done with Jenkins, go back to your MongoDB Deployment definition and scale it up to, let's say, three instances. The result will be a total disaster. But, you'll learn something. You'll gain an understanding of the problems you're facing and what you should expect from StatefulSets. Once you understand the issues, change your DB definition to a StatefulSet. Use the knowledge you obtained by running Jenkins. Once you prove that your MongoDB StatefulSet provides all the tools you need to run stateful applications like MongoDB, create a replica set manually. Get familiar with the process. Once you're done, replace your manual steps with containers based on Docker image made by cvallance. You'll find it. I'm sure you know how to Google "cvallance Mongo". Once all that is done, you'll find out that you will still fail. You won't be able to accomplish your goal. Just when you think that you are finished, you'll discover that you're not and you'll get depressed. Failure is good for you. We'll talk about your depression on the next spring planning session. See you in a week.

With those words, Eva left the meeting clearly indicating that it is over. In her mind, everyone knew what to do. Unfortunately, John was even more confused than before. He was told to change his strategy even though it'll lead to a failure. Never the less, he already knows that there's no point arguing with Eva nor requesting more information from her. She's gone, leaving them bewildered.
