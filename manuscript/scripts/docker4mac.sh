######################
# Create The Cluster #
######################

# Open Docker Preferences, select the Kubernetes tab, and select the "Enable Kubernetes" checkbox

# Open Docker Preferences, select the Advanced tab, set CPUs to 2, and Memory to 2.0

# Make sure that your current kubectl context is pointing to your Docker for Mac/Windows cluster

# To install Ingress: execute the commands that follow from a terminal

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/namespace.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/default-backend.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/configmap.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/tcp-services-configmap.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/udp-services-configmap.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/rbac.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml \
    | kubectl apply -f -

kubectl patch deployment -n ingress-nginx nginx-ingress-controller --type='json' \
    --patch="$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/publish-service-patch.yaml)"

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/docker-for-mac/service.yaml \
    | kubectl apply -f -

#######################
# Destroy the cluster #
#######################

# Reset Kubernetes cluster
