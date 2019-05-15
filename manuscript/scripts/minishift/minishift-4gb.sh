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

oc -n charts create route edge \
    --service cm-chartmuseum \
    --hostname $CM_ADDR \
    --insecure-policy Allow

kubectl -n charts \
    rollout status deploy \
    cm-chartmuseum

curl "http://$CM_ADDR/health" # It should return `{"healthy":true}`

#######################
# Destroy the cluster #
#######################

minishift delete -f

# Only if creating the cluster fails with `The server uses a certificate signed by unknown authority` message
# rm -rf ~/.minishift ~/.kube

kubectl config delete-cluster $NAME:8443

kubectl config delete-context myproject/$NAME:8443/developer

kubectl config delete-context myproject/$NAME:8443/system:admin

kubectl config delete-context minishift

kubectl config unset users.developer/$NAME:8443

kubectl config unset users.system:admin/$NAME:8443
