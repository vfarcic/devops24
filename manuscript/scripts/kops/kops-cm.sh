######################
# Create The Cluster #
######################

# Make sure that your kops version is v1.9 or higher.

# Make sure that all the prerequisites described in the "Appendix B" are met.

# Do not run the commands from below if you are a **Windows** user. You'll have to follow the instructions from the Appendix B instead.

source cluster/kops

chmod +x kops/cluster-setup.sh

NODE_COUNT=2 NODE_SIZE=t2.medium \
    USE_HELM=true \
    ./kops/cluster-setup.sh

##################
# Get Cluster IP #
##################

# If using Linux or MacOS, `export LB` command is already part of the output of the `cluster-setup.sh` script.

# Please execute the commands that follow only if you're using Windows.

LB_HOST=$(kubectl -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

export LB_IP="$(dig +short $LB_HOST \
    | tail -n 1)"

#######################
# Install ChartMuseum #
#######################

export CM_ADDR="cm.$LB_IP.nip.io"

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

kops delete cluster --name $NAME --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
