######################
# Create The Cluster #
######################

az login

az provider register -n Microsoft.Network

az provider register -n Microsoft.Storage

az provider register -n Microsoft.Compute

az provider register -n Microsoft.ContainerService

az group create \
    --name devops24-group \
    --location eastus

az vm list-sizes -l eastus

export VM_SIZE=Standard_DS1

az aks create \
    --resource-group devops24-group \
    --name devops24-cluster \
    --node-count 2 \
    --node-vm-size $VM_SIZE \
    --generate-ssh-keys

az aks get-credentials \
    --resource-group devops24-group \
    --name devops24-cluster

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/mandatory.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/provider/cloud-generic.yaml

LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $LB_IP

#######
# CJE #
#######

CLUSTER_DNS=$LB_IP.nip.io

echo $CLUSTER_DNS

JENKINS_DNS=jenkins.$CLUSTER_DNS

echo $JENKINS_DNS

mkdir -p cluster

cd cluster

open "https://downloads.cloudbees.com/cje2/latest/"

RELEASE_URL=[...]

curl -o cje.tgz $RELEASE_URL

tar -xvf cje.tgz

cd cje2_*

ls -l

kubectl get sc -o yaml

cat cje.yml

kubectl create ns jenkins

cat cje.yml \
    | sed -e \
    "s@https://cje.example.com@http://cje.example.com@g" \
    | sed -e \
    "s@cje.example.com@$JENKINS_DNS@g" \
    | sed -e \
    "s@ssl-redirect: \"true\"@ssl-redirect: \"false\"@g" \
    | kubectl --namespace jenkins \
    create -f - \
    --save-config --record

kubectl -n jenkins \
    rollout status sts cjoc

kubectl -n jenkins \
    get all

open "http://$JENKINS_DNS/cjoc"

#######################
# Destroy the cluster #
#######################

az group delete \
    --name devops24-group \
    --yes
