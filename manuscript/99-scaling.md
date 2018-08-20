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

## Prometheus

https://github.com/directXMan12/k8s-prometheus-adapter