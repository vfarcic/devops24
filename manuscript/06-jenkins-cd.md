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

kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller
```

## Running Jenkins

```bash
export LB_ADDR=$(kubectl \
    -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

dig +short $LB_ADDR

# If empty, LB is still not fully set up. Wait and repeat.

LB_IP=$(dig +short $LB_ADDR \
    | tail -n 1)

JENKINS_ADDR="jenkins.$LB_IP.xip.io"

echo $JENKINS_ADDR

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$JENKINS_ADDR

kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$JENKINS_ADDR"

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo

# Login with user `admin`
```

## Pipeline

TODO: Write

## CD Pipeline

TODO: Write

## Shared Libraries

TODO: Write

## Multi-Stage Pipeline

```bash
# TODO: Create a Multi-Stage Pipeline for go-demo-3
```

## Webhooks

TODO: Write

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
