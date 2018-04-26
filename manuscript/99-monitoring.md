# Monitoring

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
    --set server.ingress.enabled=true \
    --set server.ingress.hosts={"$MON_ADDR"}

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

# container_memory_usage_bytes{namespace="go-demo-3"}

# sum(container_memory_usage_bytes{namespace="go-demo-3"})

# container_memory_usage_bytes{pod_name=~"go-demo-3-db.+"}

# container_memory_usage_bytes{pod_name=~"go-demo-3-db.+", container_name="db"}

# node_memory_MemTotal

# node_memory_MemFree

# node_memory_MemAvailable

# TODO: Alertmanager

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

kubectl get secret \
    -n mon grafana \
    -o jsonpath="{.data.admin-password}" \
    | base64 --decode ; echo

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
```

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```