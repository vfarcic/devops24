# The Story (Episode 2)

## The Place

Go Demo Inc headquarters.

## The Actors

**John**: Team lead behind the flagship application *go-demo*. The team is in charge of everything related to the application. They gather requirements, they write tests and application code, they deploy, and they monitor. They are truly self-sufficient. The app has already been running in a small Kubernetes cluster for a week. The PoC proved to be successful, and the team is preparing to launch it to production.

**Eva**: SRE in charge of overall stability and performance of the system. Her job is split between taking care of the system as a whole as well as helping other teams (like John's) meet some of their objectives like stability and performance. Her job is to make them self-sufficient, at least from infrastructure and deployment points of view. She is known as a person who does not speak much. When you're lucky, you can get a single sentence as a response to your questions.

**Sarah**: In charge of company-wide tools. Her job is to explore those available in the market and help the teams adopt them if they choose to do so. The teams in charge of applications (like John's) bear full responsibility, and that means that they can decide which tools and languages they will adopt. Sarah cannot force anyone to adopt anything because that would prevent those teams from being responsible for their destiny. Her job is not to enforce anything, but to help those in need of guidance and expertise.

**Jason**: In charge of security. He's rarely seen. Some are even questioning where he exists and is a simple script that answers to all requests with the same text. "Denied. It is insecure; therefore it's not allowed."

## The Scene

**John**: Eva, are you in charge of RBAC permissions in our production cluster?

**Eva**: I did.

**John**: We followed your instructions from the previous sprint, and we indeed failed. However, the ball is now in your court. You set up the cluster, and our side-car container does not have permissions to interact with Kube API. You'll have to create a user that will allow it to retrieve the Pods.

**Eva**: (calm and confident) I will do no such thing!

**Sarah**: John, if your side-car container could not send requests to Kube API, that means that your Jenkins with Kubernetes plugin will also not be able to do the same. It probably needs even more permissions since it'll need not only to list but also to create Pods. I wouldn't be surprised to find out that it also needs to execute processes in those containers and a few other things.

**Eva**: (obviously enjoying the discussion) You're right. John will double-fail.

**John**: So, Eva, will you create a user for us that will allow our MongoDB side-car and Jenkins to interact with Kube API.

**Eva**: Absolutely not. I will create ServiceAccounts instead.

**John**: Service what?

**Eva**: ServiceAccounts are all you need. But, I'll need something from you first. I'll need you to go back to your PoC cluster and experiment with ServiceAccounts. Once you learn how to use them, you'll know what to request from me. I need you to tell me the exact permissions you need and in which Namespaces. Ask the right question, and you shall receive what you need.

**Jason**: (enters the room) Did someone mention permissions?

**Eva**: Did you develop a teleport that is triggered by words like "permissions", "security", and "something new"?

**Jason**: (ignoring Eva's malicious comment) You cannot give anyone permissions without my permission.

**Eva**: Shall I open a JIRA ticket?

**Jason**: Yes.

**Eva**: Check the definition of the word "sarcasm" first. JIRA is where hope dies, especially when tickets are filed under "security". We are trying to make things more secure, not less. That's why John got the task to learn about ServiceAccounts. He should be empowered to do things more securely. As for you Jason, go back where you came from. Come back once you learn about RBAC in Kubernetes. I'll will open a JIRA ticket with the title "Security personnel needs to go out of their basement more often".

**Jason**: Sarcasm again?

**Eva**: Not this time.
