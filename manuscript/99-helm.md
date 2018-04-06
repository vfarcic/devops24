# Helm

## Cluster

```bash
cd k8s-specs

git pull

minikube start --vm-driver=virtualbox

minikube addons enable ingress
```

## Setup

```bash
open "https://github.com/kubernetes/helm/releases"

# Or https://docs.helm.sh/using_helm/#installing-the-helm-client

helm init

kubectl -n kube-system get pods

kubectl -n kube-system \
    rollout status deploy tiller-deploy
```

## Example Chart

```bash
helm repo update

helm search

helm search jenkins

helm inspect stable/jenkins

kubectl create ns jenkins

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins

kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.spec.ports[0].nodePort}"

PORT=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.spec.ports[0].nodePort}")

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo

open "http://$(minikube ip):$PORT"

# Login with user `admin`

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
    --set Master.ImageTag=2.107.1-alpine

kubectl -n jenkins \
    get deployment jenkins \
    -o jsonpath="{.spec.template.spec.containers[0].image}"

helm upgrade jenkins stable/jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.112-alpine

kubectl -n jenkins \
    get deployment jenkins \
    -o jsonpath="{.spec.template.spec.containers[0].image}"

cat jenkins-config.yml

kubectl -n jenkins \
    get svc

helm upgrade jenkins stable/jenkins \
    --namespace jenkins \
    --set Master.ImageTag=lts-alpine \
    -f jenkins-config.yml

kubectl -n jenkins \
    get svc

kubectl -n jenkins \
    rollout status deploy jenkins

open "http://$(minikube ip):31001"

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo
    
helm get values jenkins

helm list

helm rollback jenkins 2

helm delete jenkins --purge

kubectl delete ns jenkins

helm repo list

# helm repo add dev https://example.com/dev-charts
```

## Creating Charts

```bash
helm create my-app

helm dependency update

helm package my-app

helm lint my-app

helm install ./my-app-0.1.0.tgz \
    --name my-app

helm delete my-app --purge

# TODO: Update go-demo-3/LICENSE

# TODO: Update go-demo-3/README.md

# TODO: Update go-demo-3/requirements.yaml

# TODO: Update go-demo-3/values.yaml

# TODO: Update go-demo-3/templates

# TODO: Update go-demo-3/Charts

helm dependency update

helm package go-demo-3

helm lint go-demo-3

helm install ./go-demo-3-0.1.0.tgz \
    --name go-demo-3

curl -H "Host: go-demo-3.com" \
    "http://$(minikube ip)/demo/hello"

helm delete go-demo-3 --purge
```

TODO: tiller + RBAC

TODO: Plugins

TODO: Environment variables

TODO: Helm