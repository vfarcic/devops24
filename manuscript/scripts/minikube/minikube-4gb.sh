######################
# Create The Cluster #
######################

# Make sure that your minikube version is v0.25 or higher

# WARNING!!!
# Some users experienced problems starting the cluster with minikuber v0.26 and v0.27.
# A few of the reported issues are https://github.com/kubernetes/minikube/issues/2707 and https://github.com/kubernetes/minikube/issues/2703
# If you are experiencing problems creating a cluster, please consider downgrading to minikube v0.25.

minikube start \
    --vm-driver virtualbox \
    --cpus 4 \
    --memory 4096

###############################
# Install Ingress and Storage #
###############################

minikube addons enable ingress

minikube addons enable storage-provisioner

minikube addons enable default-storageclass

##################
# Install Tiller #
##################

kubectl create \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy

##################
# Get Cluster IP #
##################

export LB_IP=$(minikube ip)

#######################
# Install ChartMuseum #
#######################

CM_ADDR="cm.$LB_IP.nip.io"

echo $CM_ADDR

helm install stable/chartmuseum \
    --namespace charts \
    --name cm \
    --values helm/chartmuseum-values.yml \
    --set "ingress.hosts[0].name=$CM_ADDR" \
    --set env.secret.BASIC_AUTH_USER=admin \
    --set env.secret.BASIC_AUTH_PASS=admin

kubectl -n charts \
    rollout status deploy \
    cm-chartmuseum

curl "http://$CM_ADDR/health" # It should return `{"healthy":true}`
    
#######################
# Destroy the cluster #
#######################

minikube delete
