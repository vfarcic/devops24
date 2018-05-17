######################
# Create The Cluster #
######################

# Open Docker Preferences, select the Kubernetes tab, and select the "Enable Kubernetes" checkbox

# Open Docker Preferences, select the Advanced tab, set CPUs to 3, and Memory to 3.0

# Make sure that your current kubectl context is pointing to your Docker for Mac/Windows cluster

# To install Ingress: execute the commands that follow from a terminal

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml

#######################
# Destroy the cluster #
#######################

# Reset Kubernetes cluster
