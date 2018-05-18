# Auto-Scaling

## Creating A Cluster

```bash
source cluster/kops

chmod +x kops/cluster-setup.sh

NODE_COUNT=1 NODE_SIZE=t2.small \
    ./kops/cluster-setup.sh

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.7.0.yaml

kubectl -n kube-system \
    rollout status \
    deployment heapster
```

## Horizontal Pod Autoscaler With Heapster

```bash
kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80

kubectl rollout status deployment php-apache

kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

kubectl get hpa

kubectl describe hpa php-apache

kubectl run -i --tty load-generator --image=busybox sh

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