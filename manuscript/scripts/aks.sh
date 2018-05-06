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

az aks create \
    --resource-group devops24-group \
    --name devops24-cluster \
    --node-count 2 \
    --node-vm-size Standard_DS1 \
    --generate-ssh-keys

az aks get-credentials \
    --resource-group devops24-group \
    --name devops24-cluster

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

# kubectl apply -f \
#     https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/rbac.yaml

# kubectl apply -f \
#     https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/without-rbac.yaml \
    | kubectl apply -f -

kubectl patch deployment -n ingress-nginx nginx-ingress-controller --type='json' \
  --patch="$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/publish-service-patch.yaml)"

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/azure/service.yaml \
    | kubectl apply -f -

# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/patch-service-with-rbac.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/patch-service-without-rbac.yaml

IP=[...]

DNSNAME="demo-aks-ingress"

RESOURCEGROUP=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[resourceGroup]" --output tsv)

PIPNAME=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[name]" --output tsv)

az network public-ip update --resource-group $RESOURCEGROUP --name  $PIPNAME --dns-name $DNSNAME

#######################
# Destroy the cluster #
#######################

az group delete \
    --name devops24-group \
    --yes
