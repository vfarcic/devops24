## Metrics Server

```bash
helm install stable/metrics-server \
    --name metrics \
    --namespace metrics

kubectl top node

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
    -f hpa/go-demo-5-no-sidecar-mem.yml \
    --record

kubectl -n go-demo-5 \
    rollout status deployment api

kubectl -n go-demo-5 get pods

kubectl apply \
    -f hpa/go-demo-5-api-hpa.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa api

kubectl -n go-demo-5 get pods

kubectl apply \
    -f hpa/go-demo-5-db-hpa.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa db

kubectl -n go-demo-5 get pods

kubectl apply \
    -f hpa/go-demo-5-no-hpa.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa db

kubectl -n go-demo-5 get pods

kubectl apply \
    -f hpa/go-demo-5-api-hpa-low-mem.yml \
    --record

kubectl -n go-demo-5 get hpa

kubectl -n go-demo-5 describe hpa api

kubectl -n go-demo-5 get pods

kubectl apply \
    -f hpa/go-demo-5-api-hpa.yml \
    --record

# --horizontal-pod-autoscaler-downscale-delay: The value for this option is a duration that specifies how long the autoscaler has to wait before another downscale operation can be performed after the current one has completed. The default value is 5 minutes (5m0s).

# --horizontal-pod-autoscaler-upscale-delay: The value for this option is a duration that specifies how long the autoscaler has to wait before another upscale operation can be performed after the current one has completed. The default value is 3 minutes (3m0s).

# TODO: metrics.external: ExternalMetricSource

# TODO: metrics.object: ObjectMetricSource

# TODO: metrics.pods: PodsMetricSource
```

## Prometheus

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

helm install stable/prometheus-adapter \
    --name prom-adapter \
    --namespace metrics \
    --set prometheus.url=http://prom-prometheus-server \
    --set prometheus.port=80

kubectl get --raw \
    "/apis/custom.metrics.k8s.io/v1beta1" \
    | jq '.'

kubectl get --raw \
    "/apis/custom.metrics.k8s.io/v1beta1/namespaces/metrics/pods/*/kube_pod_info" \
    | jq .

# https://hub.kubeapps.com/charts/stable/prometheus-adapter

# https://github.com/directXMan12/k8s-prometheus-adapter
```