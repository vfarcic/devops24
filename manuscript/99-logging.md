# Logging

## Cluster

TODO: Gists

## kubectl logs

```bash
kubectl create -f logs/go-demo-3.yml \
    --save-config --record

kubectl -n go-demo-3 \
    rollout status deployment api

DNS=$(kubectl -n go-demo-3 \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

curl "http://$DNS/demo/hello"

kubectl -n go-demo-3 \
    logs db-0 \
    -c db

kubectl -n go-demo-3 \
    logs -l app=api

kubectl -n go-demo-3 \
    get pods -l app=api

POD_NAME=$(kubectl -n go-demo-3 \
    get pods -l app=api \
    -o jsonpath="{.items[0].metadata.name}")

kubectl -n go-demo-3 logs $POD_NAME
```

## FluentD + ELK

```bash
# TODO: https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch

# TODO: intro

# TODO: Define resources for all containers

# TODO: Increase the number of es replicas

# TODO: Move es-startup to sts/es

kubectl create \
    -f logs/fluentd-elk.yml \
    --save-config --record

kubectl -n kube-system get pods

KIBANA_POD_NAME=$(kubectl \
    -n kube-system get pods \
    -l k8s-app=kibana-logging \
    -o jsonpath="{.items[0].metadata.name}")

kubectl -n kube-system \
    logs $KIBANA_POD_NAME

DNS=$(kubectl -n kube-system \
    get ing kibana-logging \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

open "http://$DNS"

# kubernetes.namespace_name: "go-demo-3"

# kubernetes.namespace_name: "go-demo-3" AND kubernetes.container_name: "api"

# kubernetes.namespace_name: "go-demo-3" AND kubernetes.container_name: "db"

cat logs/logger.yml

kubectl create -f logs/logger.yml

kubectl logs -f random-logger

open "http://$DNS"

# kubernetes.pod_name: "random-logger"
```
