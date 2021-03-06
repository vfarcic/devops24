cd k8s-specs

git pull

export AWS_ACCESS_KEY_ID=[...]

export AWS_SECRET_ACCESS_KEY=[...]

aws --version

export AWS_DEFAULT_REGION=us-east-2

aws iam create-group \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/IAMFullAccess \
    --group-name kops

aws iam create-user \
    --user-name kops

aws iam add-user-to-group \
    --user-name kops \
    --group-name kops

aws iam create-access-key \
    --user-name kops >kops-creds

cat kops-creds

export AWS_ACCESS_KEY_ID=$(\
    cat kops-creds | jq -r \
    '.AccessKey.AccessKeyId')

export AWS_SECRET_ACCESS_KEY=$(
    cat kops-creds | jq -r \
    '.AccessKey.SecretAccessKey')

aws ec2 describe-availability-zones \
    --region $AWS_DEFAULT_REGION

export ZONES=$(aws ec2 \
    describe-availability-zones \
    --region $AWS_DEFAULT_REGION \
    | jq -r \
    '.AvailabilityZones[].ZoneName' \
    | tr '\n' ',' | tr -d ' ')

ZONES=${ZONES%?}

echo $ZONES

mkdir -p cluster

cd cluster

aws ec2 create-key-pair \
    --key-name devops23 \
    | jq -r '.KeyMaterial' \
    >devops23.pem

chmod 400 devops23.pem

ssh-keygen -y -f devops23.pem \
    >devops23.pub

export NAME=devops23.k8s.local

export BUCKET_NAME=devops23-$(date +%s)

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --create-bucket-configuration \
    LocationConstraint=$AWS_DEFAULT_REGION

export KOPS_STATE_STORE=s3://$BUCKET_NAME

# MacOS only
brew update && brew install kops

# MacOS only
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-darwin-amd64

# MacOS only
chmod +x ./kops

# MacOS only
sudo mv ./kops /usr/local/bin/

# Linux only
wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64

# Linux only
chmod +x ./kops

# Linux only
sudo mv ./kops /usr/local/bin/

# Windows only
mkdir config

# Windows only
alias kops="docker run -it --rm \
    -v $PWD/devops23.pub:/devops23.pub \
    -v $PWD/config:/config \
    -e KUBECONFIG=/config/kubecfg.yaml \
    -e NAME=$NAME -e ZONES=$ZONES \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e KOPS_STATE_STORE=$KOPS_STATE_STORE \
    vfarcic/kops"

kops create cluster \
    --name $NAME \
    --master-count 3 \
    --node-count 1 \
    --node-size t2.small \
    --master-size t2.small \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --authorization RBAC \
    --yes

# Windows only
kops export kubecfg --name ${NAME}

# Windows only
export KUBECONFIG=$PWD/config/kubecfg.yaml

kops get cluster

kubectl cluster-info

kops validate cluster

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

kubectl -n kube-ingress \
    rollout status \
    deployment ingress-nginx

echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export ZONES=$ZONES
export NAME=$NAME" \
    >kops

kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
