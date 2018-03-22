# Helm

## Cluster

```bash
cd k8s-specs

git pull

minikube start --vm-driver=virtualbox

minikube addons enable ingress

kubectl config current-context
```

## Setup

```bash
open "https://github.com/kubernetes/helm/releases"

# Or https://docs.helm.sh/using_helm/#installing-the-helm-client

helm init

kubectl --namespace kube-system \
    get pods

kubectl --namespace kube-system \
    rollout status deploy tiller-deploy
```

## Example Chart

```bash
helm repo update

helm search

helm search mysql

helm inspect stable/mysql

helm install stable/mysql

helm ls

helm ls -q

NAME=$(helm ls -q)

helm status $NAME

helm delete $NAME

helm inspect values stable/mariadb

echo '{mariadbUser: user0, mariadbDatabase: user0db}' > config.yaml

helm install -f config.yaml stable/mariadb

# helm install --set name=value ...

# helm upgrade -f panda.yaml happy-panda stable/mariadb

helm get values $NAME

# helm rollback $NAME 1

# helm install --wait

helm list

helm list --all

helm repo list

# helm repo add dev https://example.com/dev-charts

mkdir tmp

helm create tmp/go-demo-2

helm lint
```

## Creating Charts

```bash
cd helm/go-demo-2

helm dependency update

cd ..

helm package go-demo-2

helm lint go-demo-2

helm install ./go-demo-2-1.tgz

curl -H "Host: go-demo-2.com" \
    "http://$(minikube ip)/demo/hello"

# values.yml

# helm install --values=myvals.yaml wordpress

# helm install --set ...
```