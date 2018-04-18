## GCE Account

```bash
# Register
open "https://console.cloud.google.com/"

# Install
open "https://cloud.google.com/sdk/"

# Enable "Compute Engine Instance Group Manager API"
open "https://console.developers.google.com/apis/api/replicapool.googleapis.com/overview"

gcloud config list project

gcloud auth login

gcloud auth application-default login
```

## Cluster

```bash
gcloud compute zones list \
    --filter="region:(us-east1)"

ZONE=$(gcloud compute zones list \
    --filter "region:(us-east1)" \
    | awk '{print $1}' \
    | tail -n 1)

ZONES=$(gcloud compute zones list \
    --filter "region:(us-east1)" \
    | awk '{print $1}' \
    | tr '\n' ',')

gcloud compute machine-types list \
    --filter="zone:($ZONE)"

MACHINE_TYPE=n1-standard-2

gcloud container clusters \
    create devops23 \
    --zone us-east1-b \
    --node-locations $ZONES \
    --machine-type $MACHINE_TYPE

kubectl get nodes

kubectl create clusterrolebinding \
    cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)

# TODO: Auto-scaling
```

## Ingress

```bash
# TODO: Switch to Helm

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/namespace.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/default-backend.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/configmap.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/tcp-services-configmap.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/udp-services-configmap.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/rbac.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml

kubectl patch deployment \
    -n ingress-nginx nginx-ingress-controller \
    --type='json' \
    --patch="$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/publish-service-patch.yaml)"

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/gce-gke/service.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/patch-service-with-rbac.yaml

kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o json

CJE_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    
CJE_ADDR="jenkins.$CJE_IP.xip.io"
```

## CJE

```bash
kubectl create ns cje

kubectl config set-context \
    $(kubectl config current-context) \
    --namespace=cje

open "https://downloads.cloudbees.com/cje2/latest/"

# Copy the link address of the `cje2_*_kubernetes.tgz` archive

cd cluster

RELEASE_URL=[...]

curl -o cje.tgz $RELEASE_URL

tar -xvf cje.tgz

cd cje2-kubernetes

cat cje.yml \
    | sed -e \
    s@cje.example.com@$CJE_ADDR@g \
    | sed -e \
    "s@ssl-redirect: \"true\"@ssl-redirect: \"false\"@g" \
    | kubectl apply -f -

kubectl get events

kubectl rollout status sts cjoc

open "http://$CJE_ADDR"

kubectl exec cjoc-0 -- cat \
    /var/jenkins_home/secrets/initialAdminPassword

# Copy the password and paste it into the UI

# Finish the setup wizard

# Create a master

# Create a job
```

## What Now?

```bash
gcloud container clusters \
    delete devops23 \
    --zone us-east1-b \
    --quiet
```