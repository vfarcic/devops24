######################
# Create The Cluster #
######################

# Make sure that your minikube version is v0.25 or higher

# WARNING!!!
# Some users experienced problems starting the cluster with minikube v0.26 and v0.27.
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
# Destroy the cluster #
#######################

minikube delete
