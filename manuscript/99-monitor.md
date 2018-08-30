# Monitoring

## Cluster

* [gke-scale.sh](TODO): TODO
* [eks-scale.sh](TODO): TODO
* [aks-scale.sh](TODO): TODO
* [docker-scale.sh](TODO): TODO
* [minikube-scale.sh](TODO): TODO
* [minishift-scale.sh](TODO): TODO

```bash
# Only if NOT GKE (it's already installed)
helm install stable/metrics-server \
    --name metrics \
    --namespace metrics
```

## Prometheus Chart

```bash
PROM_ADDR=mon.$LB_IP.nip.io

echo $PROM_ADDR

AM_ADDR=alertmanager.$LB_IP.nip.io

echo $AM_ADDR

helm install stable/prometheus \
    --name prometheus \
    --namespace metrics \
    --set server.ingress.enabled=true \
    --set server.ingress.hosts={$PROM_ADDR}
    --set alertmanager.ingress.enabled=true \
    --set alertmanager.ingress.hosts={$AM_ADDR}

kubectl -n metrics \
    rollout status \
    deploy prometheus-server

open "http://$PROM_ADDR/config"

open "http://$PROM_ADDR/targets"

open "http://$PROM_ADDR/graph"
```

## Metric Types

### Key metrics

* Latency - The time it takes to service a request
* Traffic - A measure of how much demand is being placed on your system
* Errors - The rate of requests that fail
* Saturation - How "full" your service is

### The USE Method

* Resource: all physical server functional components (CPUs, disks, busses, …)
* Utilization: the average time that the resource was busy servicing work
* Saturation: the degree to which the resource has extra work which it can’t service, often queued
* Errors: the count of error events

## The RED Method

* Rate: The number of requests per second.
* Errors: The number of those requests that are failing.
* Duration: The amount of time those requests take.

## Node Count

```bash
# kube_node_info

# count(kube_node_info)

# k8s-viktor: prometheus-values.yaml: serverFiles...alert: TooManyNodes|TooFewNodes

open "http://$PROM_ADDR/alerts"

# k8s-viktor: prometheus-values.yaml: alertmanagerFiles...receiver: slack

open "http://$AM_ADDR"

# Open Slack
```

## Node CPU Usage

```bash
kubectl -n metrics get ds

TODO: Continue

# kube_node_status_allocatable_cpu_cores

# sum(rate(node_cpu_seconds_total{mode!="idle", mode!="iowait", mode!~"^(?:guest.*)$"}[5m])) by (instance)

# count(node_cpu_seconds_total{mode="system"}) by (node)

# sum(rate(node_cpu_seconds_total{mode!="idle", mode!="iowait", mode!~"^(?:guest.*)$"}[5m])) / count(node_cpu_seconds_total{mode="system"})

# sum(rate(node_cpu_seconds_total{mode!="idle", mode!="iowait", mode!~"^(?:guest.*)$"}[5m])) by (instance) / count(node_cpu_seconds_total{mode="system"}) by (instance)
```

## Node Memory Usage

```bash
# sum(node_memory_MemFree + node_memory_Cached + node_memory_Buffers)

# node_memory_MemTotal_bytes

# node_memory_MemAvailable_bytes

# 1 - sum(node_memory_MemAvailable_bytes) by (instance) / sum(node_memory_MemTotal_bytes) by (instance)

# kube_node_status_allocatable_memory_bytes

# kube_pod_container_resource_requests_memory_bytes

# sum(kube_pod_container_resource_requests_memory_bytes)

# sum(node_memory_MemTotal_bytes) - sum(node_memory_MemAvailable_bytes)

# sum(node_memory_MemTotal_bytes) - sum(node_memory_MemAvailable_bytes) - sum(kube_pod_container_resource_requests_memory_bytes)
# 1.5G

# (sum(node_memory_MemTotal_bytes) - sum(node_memory_MemAvailable_bytes) - sum(kube_pod_container_resource_requests_memory_bytes)) / sum(node_memory_MemTotal_bytes)
# 0.37

kubectl describe nodes
```

## Pending Pods

TODO: Continue

## Container Memory and CPU

```bash
# container_memory_usage_bytes

# container_memory_usage_bytes{container_name="prometheus-server"}
# 130M

# sum(rate(container_cpu_usage_seconds_total{container_name="prometheus-server"}[5m]))
# 0.02

# container_memory_usage_bytes{container_name="prometheus-pushgateway"}
# 8M

# sum(rate(container_cpu_usage_seconds_total{container_name="prometheus-pushgateway"}[5m]))
# 0.5m

# container_memory_usage_bytes{container_name="prometheus-node-exporter"}
# 11M

# sum(rate(container_cpu_usage_seconds_total{container_name="prometheus-node-exporter"}[5m]))
# 0.5m

# container_memory_usage_bytes{container_name="prometheus-kube-state-metrics"}
# 20M

# sum(rate(container_cpu_usage_seconds_total{container_name="prometheus-kube-state-metrics"}[5m]))
# 1m

# container_memory_usage_bytes{container_name="prometheus-alertmanager"}
# 7M

# sum(rate(container_cpu_usage_seconds_total{container_name="prometheus-alertmanager"}[5m]))
# 0.0025

helm upgrade prom stable/prometheus \
    --namespace metrics \
    --set server.ingress.hosts={$PROM_ADDR} \
    -f mon/prom-values.yml

kubectl describe nodes

# TODO: Continue

# TODO: Container mem usage % of requested memory

# TODO: Request % of limits

# kube_node_status_allocatable_pods

# TODO: Understand the metrics from the targets

GD5_ADDR=go-demo-5.$LB_IP.nip.io

echo $GD5_ADDR

helm upgrade -i go-demo-5 \
    ../go-demo-5/helm/go-demo-5 \
    --namespace go-demo-5 \
    --set ingress.host=$GD5_ADDR

kubectl -n go-demo-5 \
    rollout status deployment go-demo-5

for i in {1..100}; do
    curl "http://$GD5_ADDR/demo/hello"
done

open "http://$MON_ADDR/graph"

# container_memory_usage_bytes{pod_name!=""}

# container_memory_usage_bytes{pod_name!=""} / container_spec_memory_limit_bytes{pod_name!=""}

# container_memory_usage_bytes{namespace="go-demo-5"}

# sum(container_memory_usage_bytes{namespace="go-demo-5"})

# container_memory_usage_bytes{pod_name=~"go-demo-5-db.+"}

# container_memory_usage_bytes{pod_name=~"go-demo-5-db.+", container_name="db"}

# container_memory_usage_bytes{pod_name=~"go-demo-5-db.+", container_name="db"} / container_spec_memory_limit_bytes{pod_name=~"go-demo-5-db.+", container_name="db"}

# nginx_ingress_controller_requests

# nginx_ingress_controller_requests{ingress="go-demo-5", namespace="go-demo-5"}

# rate(nginx_ingress_controller_requests{ingress="go-demo-5", namespace="go-demo-5"}[5m])

for i in {1..30}; do
    DELAY=$[ $RANDOM % 6000 ]
    curl "http://$GD5_ADDR/demo/hello?delay=$DELAY"
done

# nginx_ingress_controller_response_duration_seconds_bucket{ingress="go-demo-5", namespace="go-demo-5"}

# nginx_ingress_controller_response_duration_seconds_bucket{ingress="go-demo-5", namespace="go-demo-5", le="0.5"}

# rate(nginx_ingress_controller_response_duration_seconds_bucket{ingress="go-demo-5", namespace="go-demo-5", le="0.5"}[5m])

# nginx_ingress_controller_response_duration_seconds_count{ingress="go-demo-5", namespace="go-demo-5"}

# rate(nginx_ingress_controller_response_duration_seconds_count{ingress="go-demo-5", namespace="go-demo-5"}[5m])

# rate(nginx_ingress_controller_response_duration_seconds_sum{ingress="go-demo-5", namespace="go-demo-5"}[5m]) / rate(nginx_ingress_controller_response_duration_seconds_count{ingress="go-demo-5", namespace="go-demo-5"}[5m])

# up

# sum(up{job="kubernetes-nodes", kubernetes_io_role="master"})
```

# Instrumentation

```bash
# http_server_resp_time_count

# sum(rate(http_server_resp_time_count[5m]))

# http_server_resp_time_sum / http_server_resp_time_count

for i in {1..30}; do
    DELAY=$[ $RANDOM % 6000 ]
    curl "http://$GD5_ADDR/demo/hello?delay=$DELAY"
done

# http_server_resp_time_sum / http_server_resp_time_count

# rate(http_server_resp_time_sum[5m]) / rate(http_server_resp_time_count[5m])

# rate(http_server_resp_time_sum{service="go-demo"}[5m]) / rate(http_server_resp_time_count{service="go-demo"}[5m])

# rate(http_server_resp_time_sum{kubernetes_name="go-demo-5", kubernetes_namespace="go-demo-5"}[5m]) / rate(http_server_resp_time_count{kubernetes_name="go-demo-5", kubernetes_namespace="go-demo-5"}[5m])

# sum(rate(http_server_resp_time_sum[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_sum[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name) > 0.1

# sum(rate(http_server_resp_time_bucket{le="0.1"}[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_bucket{kubernetes_name="go-demo-5",le="0.1"}[5m])) / sum(rate(http_server_resp_time_count{kubernetes_name="go-demo-5"}[5m]))

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name)

for i in {1..300}; do
    curl "http://$GD5_ADDR/demo/random-error"
done

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name) / sum(rate(http_server_resp_time_count[5m])) by (kubernetes_name)

# sum(rate(http_server_resp_time_count{code=~"^5..$"}[5m])) by (kubernetes_name)
```

## Alertmanager

TODO: Code

TODO: Alert when a Pod is in pending state

TODO: Alert when resources are not defined

## Using Prometheus To Better Define Resources

TODO: Code

## PushGateway

TODO: Code

## Grafana Chart

TODO: Verify

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

## Cloud metrics

### GKE

TODO: Code

### EKS

TODO: Code

### AKS

TODO: Code

## Datadog

TODO: Code
