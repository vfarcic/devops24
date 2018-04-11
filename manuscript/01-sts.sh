git clone \
    https://github.com/vfarcic/k8s-specs.git

cd k8s-specs

mkdir -p cluster

cd cluster

cat kops

source kops

export BUCKET_NAME=devops23-$(date +%s)

export KOPS_STATE_STORE=s3://$BUCKET_NAME

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --create-bucket-configuration \
    LocationConstraint=$AWS_DEFAULT_REGION

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
    --master-size t2.small \
    --node-count 2 \
    --node-size t2.medium \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --authorization RBAC \
    --yes

kops validate cluster

# Windows Only
kops export kubecfg --name ${NAME}

# Windows Only
export KUBECONFIG=$PWD/config/kubecfg.yaml

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

cd ..

cat sts/jenkins.yml

kubectl create \
    -f sts/jenkins.yml \
    --record --save-config

kubectl -n jenkins \
    rollout status sts jenkins

kubectl -n jenkins get pvc

kubectl -n jenkins get pv

CLUSTER_DNS=$(kubectl -n jenkins \
    get ing jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

open "http://$CLUSTER_DNS/jenkins"

kubectl delete ns jenkins

cat sts/go-demo-3-deploy.yml

kubectl create \
    -f sts/go-demo-3-deploy.yml \
    --record --save-config

kubectl -n go-demo-3 \
    rollout status \
    deployment api

kubectl -n go-demo-3 get pods

DB_1=$(kubectl -n go-demo-3 get pods \
    -l app=db \
    -o jsonpath="{.items[0].metadata.name}")

DB_2=$(kubectl -n go-demo-3 get pods \
    -l app=db \
    -o jsonpath="{.items[1].metadata.name}")

kubectl -n go-demo-3 logs $DB_1

kubectl -n go-demo-3 logs $DB_2

kubectl get pv

kubectl delete ns go-demo-3

cat sts/go-demo-3-sts.yml

kubectl create \
    -f sts/go-demo-3-sts.yml \
    --record --save-config

kubectl -n go-demo-3 get pods

kubectl -n go-demo-3 get pods

kubectl -n go-demo-3 get pods

kubectl -n go-demo-3 get pods

kubectl get pv

kubectl -n go-demo-3 \
    exec -it db-0 -- hostname

kubectl -n go-demo-3 \
    run -it \
    --image busybox dns-test \
    --restart=Never \
    --rm /bin/sh

nslookup db

nslookup db-0.db

exit

kubectl -n go-demo-3 \
    exec -it db-0 -- sh

mongo

rs.initiate( {
   _id : "rs0",
   members: [
      {_id: 0, host: "db-0.db:27017"},
      {_id: 1, host: "db-1.db:27017"},
      {_id: 2, host: "db-2.db:27017"}
   ]
})

rs.status()

exit

exit

kubectl -n go-demo-3 get pods

diff sts/go-demo-3-sts.yml \
    sts/go-demo-3-sts-upd.yml

kubectl apply \
    -f sts/go-demo-3-sts-upd.yml \
    --record

kubectl -n go-demo-3 get pods

kubectl delete ns go-demo-3

cat sts/go-demo-3.yml

kubectl create \
    -f sts/go-demo-3.yml \
    --record --save-config

kubectl -n go-demo-3 \
    logs db-0 \
    -c db-sidecar

kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
