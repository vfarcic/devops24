# Logging

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

# Windows only
alias kops="docker run -it --rm \
    -v $PWD/devops23.pub:/devops23.pub \
    -v $PWD/config:/config \
    -e KUBECONFIG=/config/kubecfg.yaml \
    -e NAME=$NAME -e ZONES=$ZONES \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e KOPS_STATE_STORE=$KOPS_STATE_STORE \
    vfarcic/kops"

kops create cluster \
    --name $NAME \
    --master-count 3 \
    --node-count 3 \
    --node-size t2.xlarge \
    --master-size t2.small \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --yes

kops validate cluster

# Windows only
kops export kubecfg --name ${NAME}

# Windows only
export \
    KUBECONFIG=$PWD/config/kubecfg.yaml

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

cd ..
```

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

kubectl -n go-demo-3 \
    logs $POD_NAME

kubectl -n go-demo-3 \
    logs sts/db -c db
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

KIBANA_POD_NAME=[...]

kubectl -n kube-system \
    logs -f $KIBANA_POD_NAME

DNS=$(kubectl -n kube-system \
    get ing kibana-logging \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

open "http://$DNS"

kubectl create -f logs/logger.yml

kubectl logs -f random-logger

open "http://$DNS"
```

## Something

```bash
TODO: rsyslog

TODO: start

TODO: es

TODO: stackdriver

TODO: fluentd

TODO: fluentd2

TODO: centralized-logging
```

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```