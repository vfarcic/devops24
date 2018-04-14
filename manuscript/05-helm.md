# Helm

## Cluster

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
    --node-size t2.medium \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --authorization RBAC \
    --yes

kops validate cluster

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

cd ..
```

## Setup

```bash
open "https://github.com/kubernetes/helm/releases"

# Or https://docs.helm.sh/using_helm/#installing-the-helm-client

cat helm/tiller-rbac.yml

kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy

kubectl -n kube-system get pods
```

## Claire

```bash
# git clone \
#     https://github.com/coreos/clair \
#     ../clair

# cat ../clair/contrib/helm/clair/values.yaml

# helm dependency update claire

# helm dependency update \
#     ../clair/contrib/helm/clair/

# ll ../clair/contrib/helm/clair/charts

# helm install --name clair \
#     ../clair/contrib/helm/clair \
#     --set image:.repository=quay.io/coreos/clair
```

## Jenkins

```bash
helm repo update

helm search

helm search jenkins

kubectl create ns jenkins

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins    

kubectl -n jenkins \
    get svc jenkins \
    -o json

kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"

DNS=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

kubectl -n jenkins get all

open "http://$DNS:8080"

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo

# Login with user `admin`

helm inspect stable/jenkins

helm ls

helm status jenkins

helm delete jenkins

helm status jenkins

helm delete jenkins --purge

helm status jenkins

helm inspect values stable/jenkins

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.112-alpine

kubectl -n jenkins \
    rollout status deployment jenkins

DNS=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

open "http://$DNS:8080"

# Note the version on the bottom-right

helm upgrade jenkins stable/jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.116-alpine

kubectl -n jenkins \
    describe deployment jenkins

kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$DNS:8080/manage"

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo

# Login with user `admin`

helm list

helm rollback jenkins 1

helm delete jenkins --purge

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml

# TODO: Modify /etc/hosts

open "http://jenkins.acme.com"

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo
    
helm get values jenkins

# Click the *New Item* link in the left-hand menu

# Type *my-k8s-job* in the *item name* field

# Select *Pipeline* as the type

# Click the *OK* button

# Click the *Pipeline* tab

# Write the script that follows in the *Pipeline Script* field
```

```groovy
podTemplate(
    label: 'kubernetes',
    containers: [
        containerTemplate(name: 'maven', image: 'maven:alpine', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'golang', image: 'golang:alpine', ttyEnabled: true, command: 'cat')
    ]
) {
    node('kubernetes') {
        container('maven') {
            stage('build') {
                sh 'mvn --version'
            }
            stage('unit-test') {
                sh 'java -version'
            }
        }
        container('golang') {
            stage('deploy') {
                sh 'go version'
            }
        }
    }
}
```

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

helm delete jenkins --purge

kubectl delete ns jenkins

helm repo list

# helm repo add dev https://example.com/dev-charts
```

## Creating Charts

```bash
helm create go-demo-3

helm dependency update

helm package my-app

helm lint my-app

helm install ./my-app-0.1.0.tgz \
    --name my-app

helm delete my-app --purge

# TODO: Update templates/
# TODO: Update values.yaml
# TODO: Update LICENSE
# TODO: Update README.md
# TODO: Update requirements.yaml
# TODO: Update charts/

helm dependency update

helm lint go-demo-3

helm package go-demo-3

helm install ./go-demo-3-0.0.1.tgz \
    --name go-demo-3 \
    --namespace go-demo-3

helm install ./go-demo-3-0.0.1.tgz \
    --name go-demo-3 \
    --namespace go-demo-3 \
    --set ingress.path=/beta/demo

curl -H "Host: go-demo-3.com" \
    "http://$(minikube ip)/demo/hello"

helm delete go-demo-3 --purge
```

TODO: helm

## What Now?

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```