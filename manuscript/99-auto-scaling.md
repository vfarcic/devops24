# Auto-Scaling

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

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.7.0.yaml

kubectl -n kube-system \
    rollout status \
    deployment heapster

cd ..

# kubectl create \
#     -f helm/tiller-rbac.yml \
#     --record --save-config

# helm init --service-account tiller

# kubectl -n kube-system \
#     rollout status \
#     deployment tiller-deploy
```

## Horizontal Pod Autoscaler With Heapster

```bash
kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80

kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

kubectl get hpa

kubectl run -i --tty load-generator --image=busybox /bin/sh

while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done

kubectl get hpa

kubectl get deployment php-apache

kubectl get hpa.v2beta1.autoscaling -o yaml > /tmp/hpa-v2.yaml

kubectl get hpa

kubectl get deployment php-apache
```

## Something

TODO: hpa

TODO: hpa2

TODO: autoscaler

TODO: cluster-autoscaler

TODO: custom-metrics

TODO: hpa-prom

TODO: custom-metrics2

TODO: kops

## Destroying The Cluster

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```