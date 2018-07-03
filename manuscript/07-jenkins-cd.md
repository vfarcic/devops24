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

# CD With Jenkins

TODO: Need to re-run the previous chapter

TODO: Write

## Cluster

TODO: Increase Docker For Mac/Windows to 4GB and 4CPU

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
