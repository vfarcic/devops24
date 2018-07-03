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

# CDP With Jenkins

T> Continuous Deployment is about making a decision to do things right. It is a clear goal and a proof that the changes across all levels were successful. The major obstacle is thinking that we can get there without drastic changes in application's architecture, processes, and culture. Tools are the least of our problems.

I spend a significant chunk of my time helping companies improve their systems. The most difficult part of my job is going back home after an engagement knowing that the next time I visit the same company I will discover that there was no significant improvement. I cannot say that is not partly my fault. It certainly is. I might not be very good at what I do. Or maybe I am not good at conveying the right message. Maybe my advices were wrong. I do my best to be critical to myself and to improve my knowledge and the way I work. Still, I cannot shake the feeling that my failures are caused mostly by false expectations.

People want to improve. That is in our nature. Or, at least, most of us do. We became engineers because we are curious. We like to play with new toys. We like to explore new possibilities. And yet, the more we work in a same company, the more we become complacent. We learn something, and than we stop learning. We shift our focus on climbing company ladders. The more time passes, the more focus we put on defending our positions which often mean status quo. We become an expert in something and that expertise bring us glory and, hopefully, a promotion, or two. From there on, we ride on that glory. Look at me, I'm an DB2 expert. That's me, I set up VMWare virtualization. I brought the benefits of Spring to our Java development. Once that happens, we often try to make sure that those benefits stay intact forever. We won't switch to NoSQL because that would mean that my DB2 expertise is not as important any more. We won't move to Cloud, because I am the guru behind VMWare. We will not adopt Go, because I know how to code in Java.

Those voices are important because they are being voiced by senior people. Everyone needs to listen to them, even though the real motivations behind those voices are selfish. They are not based on real knowledge, but often on repeated experience. Having twenty years of experience with DB2 is not truly twenty years of improvement, but rather twenty times repeated experience. Yet, twenty years has weight. People listen to you, but not because they trust you, but because you are senior and management trusts you.

Combine voices from the old with management's fear of unknown and their quest for short term benefits, and the result is often status quo. That worked for years, why would I change it for something else. Why would I trust a junior developer telling me what to do. Even if a claim for change is backed with the experience from giants like Google, Amazon, and Netflix (just to name a few), you are likely to get a response along the lines of "we are different", "that does not apply here", and "I'd like to do that but regulations I do not truly understand prevent me from changing anything".

Still, sooner or later, a directive to change comes along. Your CTO might have gone to a Gartner meeting where he was told to switch to microservices. Too many people spoke about Agile for upper management to ignore it. DevOps is a huge thing, so we need to employ it as well. Kubernetes is everywhere, so we'll start working on a PoC soon. When those things do happen, when a change is approved, you might be ecstatic. This is your moment. This is when you'll start doing something really good. That is often the moment when I receive a call. "We want to do this and that. Can you help us?" I often (not always) say yes. That's what I do. And yet, I know that my engagement will not produce a tangible improvement. I guess that hope dies last.

Why am I so pessimistic? Why do I think that improvements do not produce tangible benefits? The answer lies in the scope of required changes.

Almost every tool is a result of certain processes. A processes, on the other hand, are a product of certain culture. Adopting a process without making cultural changes is a waste of time. Adopting tools without acepting the processes behind them is a futule effort that will result only in wasted time and potentially huge license costs. In very rare ocasions company do choose to acept the need to change all three (culture, processes, and tools). They make a decision, and sometime even start moving into the right direction. Those are precious cases that should be cherished. But they are likely to fail as well. After a while, usually a few months later, we realize the scope of those changes. Only the brave will survive, and only those committed will see it through.

Those who do choose to proceed and truly change their culture, and their processes, and their tools, will realize that they are incompatible with the applications they've been developing over years. Containers work with everything, but benefits are truly huge when developing microservices, not monoliths. Test-driven development increases confidence, quality, and speed, but only if applications are designed to be testable. Zero-downtime deployments are not a myth. They work, but only if our applications are cloud native, follow at least some of [twelve factors](TODO), and so on.

It's not only about tools, processes, and culture, but also about getting rid of the technical debt you've been accumulating over the years. By debt, I don't necessarily mean that you did something wrong when you started, but rather that time converted an awsome thing into a horrible monster. Do you spend fifty percent of your time refactoring? If you're not, you're accumulating technical debt. It's unavoidable.

When faced with all those challenges, giving up is an expected outcome. It's human to throw down the towel when there's no light at the end of the tunnel. I don't judge you. I feel your pain. You're not moving forward because the obstacles are too big. Still, you have to get up, because there is no alternative. You will continue. You will improve. It'll hurt a lot, but there is no alternative, except slow death while your competition is looking over your soon to be corpse.

You got this far and I can assume only two possible explanations. You are either one of those who read technical books as a way to escape from reality, or you are applying at least some of the things we discussed thus far. I hope it's latter. If that's the case, you do not fall into "yet another failure of mine".

If you do employ the lessons from this chapter, without faking, you are truly doing something great. There is no faking continuous delivery (CD). Every commit you make is ready for production if all the stages are green. The decision whether to deploy it to production is based on business or marketing needs, and is not technical in any sense. You can even take a step forward and practice continuous deployment (CDP) that removes the only step performed by a humand and deploys every green commit to production. Neither of the two can be faked. You cannot do CD or CDP partly, while retaining the name. You cannot be almost there. If you are, you're doing continuous integration, it-will-be-deployed-eventually process, or something else.

All in all, you are hopefully, ready to do this. You will take a step towards continuous deployment. By the end of this chapter, assuming that you'll choose to use Jenkins, the only thing left for you is to spend an unknown amount of time "modernizing" architecture of your applications or throwing them to thrash and starting over. You'll be changing your tools, processes, and culture. This book will not help you with all of those. We're focused on tools and processes, you'll have to figure out what to do with your culture and architecture. The same holds true for the way you write your tests. I won't teach you testing, and I won't preach TDD. I'll assume that you already know all that, and that we can focus on continuous deployment pipeline only.

At this moment, you might feel desperate. You might not be ready. You might feel that you don't have a buyout from your management, that the people in your company will not accept this direction, or that you don't have enough time and funds. Do not get depressed. Knowing the direction is the most important part. Even if you cannot get there any time soon, you should still know what the destination is, so that your steps are at least moving you in the right direction. Who knows, we might even invert the order and strip down continuous deployment pipeline to get to continuous delivery and continuous integration.

Without further ado, we are about to combine all the lessons we learned so far, and we are about to design a fully automated continuous deployment pipeline. Put on your seat belts, and stay calm. We're in for a ride.

TODO: Need to re-run the previous chapter

## Cluster

TODO: Increase Docker For Mac/Windows to 4GB and 4CPU

## Continuous delivery process

TODO: Write

## Jenkins

TODO: Write

```bash
# If Docker For Mac/Windows
cd cd/docker-build

# If Docker For Mac/Windows
vagrant up

# If Docker For Mac/Windows
cd ../../

kubectl apply \
    -f ../go-demo-3/k8s/ns.yml \
    --record

kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets

helm init --service-account build \
    --tiller-namespace go-demo-3-build

JENKINS_ADDR="go-demo-3-jenkins.$LB_IP.nip.io"

helm dependency update helm/jenkins

helm install helm/jenkins \
    --name go-demo-3-jenkins \
    --namespace go-demo-3-jenkins \
    --set jenkins.Master.HostName=$JENKINS_ADDR \
    --set jenkins.Master.DockerAMI=$AMI_ID \
    --set jenkins.Master.GProject=$G_PROJECT \
    --set jenkins.Master.GAuthFile=$G_AUTH_FILE

kubectl -n go-demo-3-jenkins \
    rollout status deployment \
    go-demo-3-jenkins

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n go-demo-3-jenkins \
    get secret go-demo-3-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

# Login with user *admin*
```

## Scripted vs Declarative Pipeline

TODO: Write

## Defining The Continuous Deployment Stages

TODO: Write

## Build Stage

TODO: Write

TODO: Discard old builds

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
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

```bash
DH_USER=[...]

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"
```

## Functional Stage

TODO: Write

```bash
export ADDR=$LB_IP.nip.io

# If Docker For Mac/Windows get the IP from ifconfig. It's probably en0. 
export ADDR=[...].nip.io

echo $ADDR
```

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.TAG_BETA = "${currentBuild.displayName}-${env.BRANCH_NAME}"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
"""
) {
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
  node("kubernetes") {
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
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

TODO: Explain shared workspace

```bash
# While in `func-test` stage

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3-build \
    get all

# After the build is finished

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3-build \
    get all
```

## Release Stage

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
"""
) {
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
  node("kubernetes") {
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
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
  node("docker") {
    stage("release") {
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
  }
}
```

```bash
# TODO: Release files to GH

# TODO: Manifest

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"
```

## Deploy Stage

```groovy
import java.text.SimpleDateFormat

currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER // NEW!!!
env.REPO = "https://github.com/vfarcic/go-demo-3.git" // Replace me
env.IMAGE = "vfarcic/go-demo-3" // Replace me
env.ADDRESS = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.PROD_ADDRESS = "go-demo-3.acme.com" // Replace `acme.com` with the $ADDR retrieved earlier
env.TAG = "${currentBuild.displayName}"
env.TAG_BETA = "${env.TAG}-${env.BRANCH_NAME}"
env.CHART_NAME = "go-demo-3-${env.BUILD_NUMBER}-${env.BRANCH_NAME}"

podTemplate(
  label: "kubernetes",
  namespace: "go-demo-3-build",
  serviceAccount: "build",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
"""
) {
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
  node("kubernetes") {
    stage("func-test") {
      try {
        container("helm") {
          git "${env.REPO}"
          sh """helm upgrade \
            ${env.CHART_NAME} \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --set image.tag=${env.TAG_BETA} \
            --set ingress.host=${env.ADDRESS}"""
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
    node("docker") {
      stage("release") {
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
    }
    stage("deploy") {
      try {
        container("helm") {
          sh """helm upgrade \
            go-demo-3 \
            helm/go-demo-3 -i \
            --tiller-namespace go-demo-3-build \
            --namespace go-demo-3 \
            --set image.tag=${env.TAG} \
            --set ingress.host=${env.PROD_ADDRESS}"""
        }
        container("kubectl") {
          sh """kubectl -n go-demo-3 \
            rollout status deployment \
            go-demo-3"""
        }
        container("golang") {
          sh "go get -d -v -t"
          sh """DURATION=1 ADDRESS=${env.PROD_ADDRESS} \
            go test ./... -v \
            --run ProductionTest"""
        }
      } catch(e) {
        container("helm") {
          sh """helm rollback \
            go-demo-3 0 \
            --tiller-namespace go-demo-3-build"""
          error "Failed production tests"
        }
      }
    }
  }
}
```

```bash
open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

helm ls \
    --tiller-namespace go-demo-3-build

helm history go-demo-3 \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3 get pods
```

TODO: Release files to GH

TODO: Manifest

TODO: Failure notifications

## Shared Libraries

TODO: Code

## Jenkinsfile & Multistage Builds

TODO: Code

## Webhooks

TODO: Code

## Manual Testing & The Attempt To Use The Same Artifacts

TODO: Write

TODO: Reference to the CI chapter

## Destroying The Cluster

```bash
cd cd/docker-build

vagrant suspend

cd ../../
```
