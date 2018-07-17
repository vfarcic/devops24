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
    --cpus 2 \
    --memory 2048

minikube addons enable ingress

minikube addons enable storage-provisioner

minikube addons enable default-storageclass

#######################
# Destroy the cluster #
#######################

minikube delete
