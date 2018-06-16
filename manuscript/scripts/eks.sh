open "https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html"

curl -o heptio-authenticator-aws \
    https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/darwin/amd64/heptio-authenticator-aws

chmod +x ./heptio-authenticator-aws

mv ./heptio-authenticator-aws /usr/local/bin/

source cluster/kops

eksctl create cluster \
    --cluster-name devop24 \
    --node-type t2.medium \
    --nodes 2 \
    --nodes-max 3 \
    --nodes-min 1 \
    --region us-west-2 \
    --ssh-public-key devops23.pem