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
# TODO: The the available zones

gcloud container clusters \
    create devops24 \
    --zone us-east1-b \
    --node-locations us-east1-b,us-east1-c,us-east1-d \
    --machine-type n1-standard-2

kubectl get nodes

# TODO: Auto-scaling
```

## CJE

```bash
open "https://downloads.cloudbees.com/cje2/latest/"

# Copy the link address of the `cje2_*_kubernetes.tgz` archive

cd cluster

RELEASE_URL=[...]

curl -o cje.tgz $RELEASE_URL

tar -xvf cje.tgz

cd cje2-kubernetes

# TODO: Modify cje.yml

kubectl create ns cje2

kubectl create clusterrolebinding \
    cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)

kubectl -n cje2 create -f cje.yml

kubectl -n cje2 get events

kubectl -n cje2 get all

# TODO: Get the IP from the service
CJE_IP=[...]

gcloud compute addresses create \
    $CJE_IP --global
```

## What Now?

```bash
# TODO: Delete the cluster

kubectl config delete-cluster \
    gke_devops24-book_us-east1_cluster-1

kubectl config delete-context \
    gke_devops24-book_us-east1_cluster-1

kubectl config unset \
    users.gke_devops24-book_us-east1_cluster-1
```