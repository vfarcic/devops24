git clone \
    https://github.com/vfarcic/k8s-specs.git

cd k8s-specs

# Create a Kubernetes cluster

cat sts/jenkins.yml

# Only if minishift
oc create -f sts/jenkins-oc.yml --record --save-config

kubectl create \
    -f sts/jenkins.yml \
    --record --save-config

kubectl -n jenkins \
    rollout status sts jenkins

kubectl -n jenkins get pvc

kubectl -n jenkins get pv

# Only if GKE
CLUSTER_DNS=$(kubectl -n jenkins \
    get ing jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Only if kops or Docker for Mac/Windows
CLUSTER_DNS=$(kubectl -n jenkins \
    get ing jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

# Only if minikube
CLUSTER_DNS=$(minikube ip)

# Only if minishift
CLUSTER_DNS=jenkins-jenkins.$(minishift ip).nip.io

echo $CLUSTER_DNS

open "http://$CLUSTER_DNS/jenkins"

kubectl delete ns jenkins

cat sts/go-demo-3-deploy.yml

kubectl create \
    -f sts/go-demo-3-deploy.yml \
    --record --save-config

kubectl -n go-demo-3 \
    rollout status deployment api

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

# Wait for a few moments

kubectl -n go-demo-3 \
    logs db-0 \
    -c db-sidecar

kubectl delete ns go-demo-3
