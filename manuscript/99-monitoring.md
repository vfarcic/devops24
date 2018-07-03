# Monitoring

## Creating A Cluster with kops

```bash
source cluster/kops

chmod +x kops/cluster-setup.sh

NODE_COUNT=2 \
    NODE_SIZE=t2.medium \
    USE_HELM=true \
    ./kops/cluster-setup.sh
```

## Creating a Cluster with Minikube

```bash
minikube start \
    --vm-driver virtualbox \
    --cpus 3 \
    --memory 4056

minikube addons enable ingress
```

## Prometheus Chart

```bash
export LB_ADDR=$(kubectl \
    -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

dig +short $LB_ADDR

# If empty, LB is still not fully set up. Wait and repeat.

LB_IP=$(dig +short $LB_ADDR \
    | tail -n 1)

MON_ADDR="mon.$LB_IP.xip.io"

kubectl create ns mon

helm install stable/prometheus \
    --name mon \
    --namespace mon \
    --set server.ingress.hosts={"$MON_ADDR"} \
    --values mon/prom-values.yml

kubectl -n mon \
    rollout status \
    deploy mon-prometheus-server

open "http://$MON_ADDR"

helm upgrade -i go-demo-3 \
    ../go-demo-3/helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0

kubectl -n go-demo-3 \
    rollout status deployment go-demo-3

export LB_DNS=$(kubectl -n go-demo-3 \
    get ing go-demo-3 \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

curl http://$LB_DNS/demo/hello

open "http://$MON_ADDR"

# container_memory_usage_bytes{pod_name!=""}

# container_memory_usage_bytes{pod_name!=""} / container_spec_memory_limit_bytes{pod_name!=""}

# container_memory_usage_bytes{namespace="go-demo-3"}

# sum(container_memory_usage_bytes{namespace="go-demo-3"})

# container_memory_usage_bytes{pod_name=~"go-demo-3-db.+"}

# container_memory_usage_bytes{pod_name=~"go-demo-3-db.+", container_name="db"}

# container_memory_usage_bytes{pod_name=~"go-demo-3-db.+", container_name="db"} / container_spec_memory_limit_bytes{pod_name=~"go-demo-3-db.+", container_name="db"}

# node_memory_MemTotal

# node_memory_MemFree

# node_memory_MemAvailable

# up

# sum(up{job="kubernetes-nodes", kubernetes_io_role="master"})

# TODO: Alertmanager

# TODO: Instrumentation

# TODO: PushGateway
```

## Grafana Chart

```bash
GRAFANA_ADDR="grafana.$LB_IP.xip.io"

helm install stable/grafana \
    --name grafana \
    --namespace mon \
    --set ingress.enabled=true \
    --set ingress.hosts="{$GRAFANA_ADDR}" \
    --set persistence.enabled=true \
    --set persistence.accessModes="{ReadWriteOnce}" \
    --set persistence.size=1Gi

kubectl -n mon \
    rollout status deploy grafana

# Automate Prometheus config

open "http://$GRAFANA_ADDR"

echo $(kubectl get secret \
    -n mon grafana \
    -o go-template \
    --template="{.data.admin-password | base64decode}")

echo "http://$MON_ADDR"

# Import dashboards 3131, 1621
```

## Something

```bash
TODO: Operator

TODO: tools

TODO: tools-production

TODO: heapster

TODO: best-practices

TODO: prometheus-fast

TODO: prometheus-2

TODO: prom-repo

TODO: gs-repo

TODO: prom-operator

TODO: https://github.com/stakater/IngressMonitorController
```

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
