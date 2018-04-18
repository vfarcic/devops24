# Jenkins

## Creating A Cluster

```bash
cd k8s-specs

git pull

cd cluster

source kops

export BUCKET_NAME=devops23-$(date +%s)

export KOPS_STATE_STORE=s3://$BUCKET_NAME

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --create-bucket-configuration \
    LocationConstraint=$AWS_DEFAULT_REGION

kops create cluster \
    --name $NAME \
    --master-count 3 \
    --master-size t2.small \
    --node-count 2 \
    --node-size t2.large \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --authorization RBAC \
    --yes

kops validate cluster

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

kubectl -n kube-ingress \
    rollout status \
    deployment ingress-nginx

cd ..

kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller

kubectl -n kube-system \
    rollout status \
    deployment tiller-deploy

kubectl create \
    -f ../go-demo-3/k8s/build-ns.yml \
    --save-config --record

kubectl create \
    -f ../go-demo-3/k8s/prod-ns.yml \
    --save-config --record

export LB_ADDR=$(kubectl \
    -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

dig +short $LB_ADDR

# If empty, LB is still not fully set up. Wait and repeat.

LB_IP=$(dig +short $LB_ADDR \
    | tail -n 1)

JENKINS_ADDR="jenkins.$LB_IP.xip.io"

helm install helm/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set jenkins.Master.HostName=$JENKINS_ADDR \
    --set jenkins.Master.AMI=$AMI_ID

kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$JENKINS_ADDR"

alias get-jsecret='kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo'

# Login with user `admin`

open "http://$JENKINS_ADDR/credentials/store/system/domain/_/newCredentials"

# Choose *AWS Credentials* as the *Kind*
# Type *aws* as the *ID*
# Type *aws* as the *Description*

echo $AWS_ACCESS_KEY_ID

# Copy the output and paste it into the *Access Key ID* field

echo $AWS_SECRET_ACCESS_KEY

# Copy the output and paste it into the *Secret Access Key* field
# Click the *OK* button

open "http://$JENKINS_ADDR/credentials/store/system/domain/_/newCredentials"

# Type DH user to the *Username* field
# Type DH password to the *Password* field
# Type *docker* to the *ID* field
# Type *docker* to the *Description* field
# Click the *OK* button

open "http://$JENKINS_ADDR/configure"

cat cluster/devops23.pem

# Copy the output and paste it into the *EC2 Key Pair's Private Key* field
# Click the *Test Connection* button
# Click the *Save* button
```

## Build Stage

```groovy
import java.text.SimpleDateFormat

podTemplate(
  label: "kubernetes",
  containers: [
    containerTemplate(name: "helm", image: "vfarcic/helm:2.8.2", ttyEnabled: true, command: "cat"),
    containerTemplate(name: "golang", image: "golang:1.10", ttyEnabled: true, command: "cat")
  ],
  namespace: "go-demo-3-build"
) {
  env.GH_USER = "vfarcic" // Replace me
  env.DH_USER = "vfarcic" // Replace me
  env.PROJECT = "go-demo-3"
  currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
  node("docker") {
    stage("build") {
      git "https://github.com/${env.GH_USER}/${env.PROJECT}.git"
      sh """docker image build \
        -t ${env.DH_USER}/${env.PROJECT}:${currentBuild.displayName}-beta ."""
      withCredentials([usernamePassword(
        credentialsId: "docker",
        usernameVariable: "USER",
        passwordVariable: "PASS"
      )]) {
        sh "docker login -u $USER -p $PASS"
      }
      sh """docker image push \
        ${env.DH_USER}/${env.PROJECT}:${currentBuild.displayName}-beta"""
      sh "docker logout"
    }  
  }
}
```

```bash
GH_USER=[...]

open "https://hub.docker.com/r/$GH_USER/go-demo-3/tags/"
```

## Functional Stage

```groovy
import java.text.SimpleDateFormat

podTemplate(
  label: "kubernetes",
  containers: [
    containerTemplate(name: "helm", image: "vfarcic/helm:2.8.2", ttyEnabled: true, command: "cat"),
    containerTemplate(name: "golang", image: "golang:1.10", ttyEnabled: true, command: "cat")
  ],
  namespace: "go-demo-3-build",
  serviceAccount: "build"
) {
  env.GH_USER = "vfarcic" // Replace me
  env.DH_USER = "vfarcic" // Replace me
  env.PROJECT = "go-demo-3"
  currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-" + env.BUILD_NUMBER
  node("docker") {
    stage("build") {
      git "https://github.com/${env.GH_USER}/${env.PROJECT}.git"
      sh """docker image build  \
        -t ${env.DH_USER}/${env.PROJECT}:${currentBuild.displayName}-beta ."""
      withCredentials([usernamePassword(
        credentialsId: "docker",
        usernameVariable: "USER",
        passwordVariable: "PASS"
      )]) {
        sh "docker login -u $USER -p $PASS"
      }
      sh """docker image push \
        ${env.DH_USER}/${env.PROJECT}:${currentBuild.displayName}-beta"""
      sh "docker logout"
    }  
  }
  node("kubernetes") {
    stage("func-test") {
      try {
        container("helm") {
          sh "git clone https://github.com/${env.GH_USER}/${env.PROJECT}.git ."
          sh """helm upgrade \
            ${env.PROJECT}-${env.BUILD_NUMBER}-beta \
            helm/go-demo-3 \
            --install \
            --set image.tag=${currentBuild.displayName}-beta \
            --set ingress.path=/${env.PROJECT}-${env.BUILD_NUMBER}-beta/demo"""
          sh """kubectl rollout status \
            deployment ${env.PROJECT}-${env.BUILD_NUMBER}-beta"""
          env.HOST = sh script: """kubectl get \
            ing ${env.PROJECT}-${env.BUILD_NUMBER}-beta \
            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'""",
            returnStdout: true
        }
        container("golang") {
          sh "go get -d -v -t"
          withEnv(["ADDRESS=${env.HOST}/${env.PROJECT}-${env.BUILD_NUMBER}-beta"]) {
            sh """go test ./... -v \
              --run FunctionalTest"""
          }
        }
      } catch(e) {
          error "Failed functional tests"
      } finally {
        container("helm") {
          sh """helm delete \
            ${env.PROJECT}-${env.BUILD_NUMBER}-beta \
            --purge"""
        }
      }
    }
  }
}
```

```bash
TODO: Reduce kube-system privileges

# While in `func-test` stage
kubectl -n go-demo-3-build \
    get all
```

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
