######################
# Create The Cluster #
######################

# Make sure that your minishift version is v1.15 or higher

minishift start \
    --vm-driver virtualbox \
    --cpus 3 \
    --memory 4096

IP=$(minishift ip)

NAME=$(echo $IP | tr '.' '-')

oc config set current-context \
    myproject/$NAME:8443/system:admin

# Change `myproject` to `default` if the previous command fails

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

export LB_IP=$(minishift ip)

#######################
# Destroy the cluster #
#######################

minishift delete -f --clear-cache

# Only if creating the cluster fails with `The server uses a certificate signed by unknown authority` message
# rm -rf ~/.minishift ~/.kube

kubectl config delete-cluster $NAME:8443

kubectl config delete-cluster 127-0-0-1:8443

kubectl config delete-context /$NAME:8443/developer

kubectl config delete-context default/$NAME:8443/system:admin

kubectl config delete-context minishift

kubectl config delete-context myproject/$NAME:8443/developer

kubectl config delete-context myproject/$NAME:8443/system:admin

kubectl config delete-context default/127-0-0-1:8443/system:admin

kubectl config unset users.developer/$NAME:8443

kubectl config unset users.system:admin/$NAME:8443

kubectl config unset users.system:admin/127-0-0-1:8443
