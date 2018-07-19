######################
# Create The Cluster #
######################

# Make sure that your minishift version is v1.15 or higher

minishift start \
    --vm-driver virtualbox \
    --cpus 4 \
    --memory 4096

IP=$(minishift ip)

NAME=$(echo $IP | tr '.' '-')

oc config set current-context \
    default/$NAME:8443/system:admin

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
# Install ChartMuseum #
#######################

CM_ADDR="cm.$LB_IP.nip.io"

echo $CM_ADDR

CM_ADDR_ESC=$(echo $CM_ADDR \
    | sed -e "s@\.@\\\.@g")

echo $CM_ADDR_ESC

helm install stable/chartmuseum \
    --namespace charts \
    --name cm \
    --values helm/chartmuseum-values.yml \
    --set ingress.hosts."$CM_ADDR_ESC"={"/"} \
    --set env.secret.BASIC_AUTH_USER=admin \
    --set env.secret.BASIC_AUTH_PASS=admin

kubectl -n charts \
    rollout status deploy \
    cm-chartmuseum

curl "http://$CM_ADDR/health" # It should return `{"healthy":true}`

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
