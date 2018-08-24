## Cluster

* [gke-scale.sh](TODO): TODO
* [eks-scale.sh](TODO): TODO
* [aks-scale.sh](TODO): TODO
* [docker-scale.sh](TODO): TODO
* [minikube-scale.sh](TODO): TODO
* [minishift-scale.sh](TODO): TODO

## Metrics Server And HPA

```bash
# CA does not work in EKS (https://github.com/kubernetes-incubator/metrics-server/issues/80 and https://github.com/aws-samples/aws-workshop-for-kubernetes/issues/495)

# Only if NOT GKE (it's already installed)
helm install stable/metrics-server \
    --name metrics \
    --namespace metrics

kubectl top nodes

kubectl -n kube-system top pod

kubectl top pod --all-namespaces

kubectl top pod --all-namespaces --containers

kubectl get \
    --raw "/apis/metrics.k8s.io/v1beta1" \
    | jq '.'

kubectl get \
    --raw "/apis/metrics.k8s.io/v1beta1/pods" \
    | jq '.'
```

## HPA

```bash
kubectl apply \
    -f scaling/go-demo-5-no-sidecar-mem.yml \
    --record

kubectl -n go-demo-5 \
    rollout status deployment api

kubectl -n go-demo-5 get pods

kubectl apply \
    -f scaling/go-demo-5-api-hpa.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa api

kubectl -n go-demo-5 get pods

kubectl apply \
    -f scaling/go-demo-5-db-hpa.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa db

kubectl -n go-demo-5 get pods

kubectl apply \
    -f scaling/go-demo-5-no-hpa.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa db

kubectl -n go-demo-5 get pods

kubectl apply \
    -f scaling/go-demo-5-api-hpa-low-mem.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa api

kubectl -n go-demo-5 get pods

kubectl apply \
    -f scaling/go-demo-5-api-hpa.yml \
    --record

# --horizontal-pod-autoscaler-downscale-delay: The value for this option is a duration that specifies how long the autoscaler has to wait before another downscale operation can be performed after the current one has completed. The default value is 5 minutes (5m0s).

# --horizontal-pod-autoscaler-upscale-delay: The value for this option is a duration that specifies how long the autoscaler has to wait before another upscale operation can be performed after the current one has completed. The default value is 3 minutes (3m0s).

# TODO: metrics.external: ExternalMetricSource

# TODO: metrics.object: ObjectMetricSource

# TODO: metrics.pods: PodsMetricSource
```

## Prometheus (TODO: HPA v2beta1 is still green)

```bash
PROM_ADDR=prom.$LB_IP.nip.io

helm install stable/prometheus \
    --name prom \
    --namespace metrics \
    --set server.ingress.enabled=true \
    --set server.ingress.hosts={$PROM_ADDR}

kubectl -n metrics rollout status \
    deployment prom-prometheus-server

open "http://$PROM_ADDR"

open "http://$PROM_ADDR/targets"

for i in {1..100}; do
    curl "http://$LB_IP/demo/hello"
done

# NOTE: Query: `nginx_ingress_controller_requests{ingress="api", namespace="go-demo-5"}`
# NOTE: Query: `nginx_ingress_controller_request_size_count{ingress="api", namespace="go-demo-5"}`
# NOTE: Query: `rate(nginx_ingress_controller_request_size_count{ingress="api", namespace="go-demo-5"}[5m])`

helm install stable/prometheus-adapter \
    --name prom-adapter \
    --namespace metrics \
    --set prometheus.url=http://prom-prometheus-server \
    --set prometheus.port=80

kubectl -n metrics rollout status \
    deployment prom-adapter-prometheus-adapter

kubectl get --raw \
    "/apis/custom.metrics.k8s.io/v1beta1" \
    | jq '.'

kubectl get --raw \
    "/apis/custom.metrics.k8s.io/v1beta1/namespaces/go-demo-5/pods/api/nginx_ingress_controller_requests" \
    | jq .

kubectl get --raw \
    "/apis/custom.metrics.k8s.io/v1beta1/namespaces/go-demo-5/ingresses.extensions/api/nginx_ingress_controller_response_duration_seconds_sum" \
    | jq .

# nginx_ingress_controller_request_duration_seconds_sum{ingress="api", namespace="go-demo-5"}

# https://hub.kubeapps.com/charts/stable/prometheus-adapter

# https://github.com/directXMan12/k8s-prometheus-adapter
```

## Cluster Autoscaler

### GKE

```bash
`--enable-autoscaling` argument
```

### EKS

```bash
# Add `k8s.io/cluster-autoscaler/enabled=true` tag to ASG

# Add the policy that follows to the EKS-devops24-DefaultNodeGroup-NodeInstanceRole-* IAM role
```

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
}
```

```bash
helm install stable/cluster-autoscaler \
    --name ca \
    --namespace kube-system \
    --set autoDiscovery.clusterName=devops24 \
    --set awsRegion=$AWS_DEFAULT_REGION \
    --set sslCertPath=/etc/kubernetes/pki/ca.crt \
    --set rbac.create=true
```

### AKS (buggy, still in preview)

```bash
# Must be k8s 1.10+

ID=`az account show --query id -o json`
SUBSCRIPTION_ID=`echo $ID | tr -d '"' `

TENANT=`az account show --query tenantId -o json`
TENANT_ID=`echo $TENANT | tr -d '"' | base64`

cluster_name=devops24-cluster
resource_group=devops24-group

CLUSTER_NAME=`echo $cluster_name | base64`
RESOURCE_GROUP=`echo $resource_group | base64`

PERMISSIONS=`az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID" -o json`
CLIENT_ID=`echo $PERMISSIONS | sed -e 's/^.*"appId"[ ]*:[ ]*"//' -e 's/".*//' | base64`
CLIENT_SECRET=`echo $PERMISSIONS | sed -e 's/^.*"password"[ ]*:[ ]*"//' -e 's/".*//' | base64`

SUBSCRIPTION_ID=`echo $ID | tr -d '"' | base64 `

NODE_RESOURCE_GROUP=`az aks show --name $cluster_name  --resource-group $resource_group -o tsv --query 'nodeResourceGroup' | base64`

echo "apiVersion: v1
kind: Secret
metadata:
    name: cluster-autoscaler-azure
    namespace: kube-system
data:
    ClientID: $CLIENT_ID
    ClientSecret: $CLIENT_SECRET
    ResourceGroup: $RESOURCE_GROUP
    SubscriptionID: $SUBSCRIPTION_ID
    TenantID: $TENANT_ID
    VMType: QUtTCg==
    ClusterName: $CLUSTER_NAME
    NodeResourceGroup: $NODE_RESOURCE_GROUP
" | kubectl apply -f -

kubectl apply \
    -f scaling/aks-cluster-autoscaler.yml \
    --record
```

### All

```bash
kubectl get nodes

kubectl apply \
    -f scaling/go-demo-5-many.yml \
    --record

# Targets do not work in EKS since there is no metrics server. Minimum number of Pods will be set nevertheless.
kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 rollout status \
    deployment api

kubectl -n go-demo-5 get pods

kubectl get nodes

# Different in AKS
kubectl -n kube-system get cm \
    cluster-autoscaler-status \
    -o yaml

kubectl -n go-demo-5 get pods

kubectl -n go-demo-5 \
    describe pods \
    -l app=api \
    | grep cluster-autoscaler

kubectl apply \
    -f scaling/go-demo-5.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 rollout status \
    deployment api

kubectl -n go-demo-5 get pods

kubectl get nodes

kubectl -n kube-system get configmap \
    cluster-autoscaler-status \
    -o yaml

kubectl get nodes

# TODO: Annotation: "cluster-autoscaler.kubernetes.io/safe-to-evict": "false"
```