######################
# Create The Cluster #
######################

# Follow the instructions from https://github.com/weaveworks/eksctl to intall `eksctl`

export AWS_ACCESS_KEY_ID=[...] # Replace [...] with AWS access key ID

export AWS_SECRET_ACCESS_KEY=[...] # Replace [...] with AWS secret access key

export AWS_DEFAULT_REGION=us-west-2

mkdir -p cluster

eksctl create cluster \
    -n devops24 \
    --kubeconfig cluster/kubecfg-eks \
    --node-type t2.medium \
    --nodes 2

export KUBECONFIG=$PWD/cluster/kubecfg-eks

###################
# Install Ingress #
###################

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/mandatory.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/provider/aws/service-l4.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/1cd17cd12c98563407ad03812aebac46ca4442f2/deploy/provider/aws/patch-configmap-l4.yaml

########################
# Install StorageClass #
########################

echo 'kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gp2
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  encrypted: "true"' \
    | kubectl create -f -

kubectl patch storageclass gp2 \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

##################
# Install Tiller #
##################

kubectl create \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy

#######################
# Destroy the cluster #
#######################

LB_NAME=$(aws elb \
    describe-load-balancers \
    | jq -r \
    ".LoadBalancerDescriptions[0] \
    | select(.SourceSecurityGroup.GroupName \
    | contains (\"k8s-elb\")) \
    .LoadBalancerName")

aws elb delete-load-balancer \
    --load-balancer-name $LB_NAME

eksctl delete cluster -n devops24
