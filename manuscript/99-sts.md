**DO NOT REVIEW THIS JUST YET**

## Chapter

- [ ] Code
- [ ] Write
- [ ] Compare with Swarm
- [ ] Text Review
- [ ] Diagrams
- [ ] Code Review
- [ ] Gist
- [ ] Review the title
- [ ] Proofread
- [ ] Add to slides
- [ ] Publish on TechnologyConversations.com
- [ ] Add to Book.txt
- [ ] Publish on LeanPub.com

# StatefulSets

## Using StatefulSets To Deploy Stateful Applications

Using Deployments for stateful applications served us well when combined with PersistentVolumes. Still, there is a better way to run such applications.

## Cluster

```bash
cd k8s-specs

git pull

cd cluster

source kops

export BUCKET_NAME=devops23-$(date +%s)

export KOPS_STATE_STORE=s3://$BUCKET_NAME

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --create-bucket-configuration \
    LocationConstraint=$AWS_DEFAULT_REGION

kops create cluster \
    --name $NAME \
    --master-count 3 \
    --node-count 2 \
    --node-size t2.small \
    --master-size t2.medium \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --authorization RBAC \
    --yes

kops validate cluster

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

cd ..
```

```bash
# TODO: sts_start

# TODO: sts2

# TODO: sts3

# TODO: sts

# TODO: mongo

cat sts/jenkins.yml
```

```bash
kubectl apply \
    -f sts/jenkins.yml \
    --record
```

```
namespace "jenkins" configured
ingress "jenkins" configured
service "jenkins" configured
statefulset "jenkins" created
```

```bash
kubectl --namespace jenkins \
    get sts
```

```
NAME    DESIRED CURRENT AGE
jenkins 1       1       3m
```

```bash
kubectl --namespace jenkins \
    get pvc
```

```
NAME                   STATUS VOLUME  CAPACITY ACCESS MODES STORAGECLASS AGE
jenkins-home-jenkins-0 Bound  pvc-... 1Gi      RWO          gp2          4m
```

```bash
kubectl --namespace jenkins \
    get pv
```

```
NAME    CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM                          STORAGECLASS REASON AGE
pvc-... 1Gi      RWO          Delete         Bound  jenkins/jenkins-home-jenkins-0 gp2                 5m
```

```bash
open "http://$CLUSTER_DNS/jenkins"

kubectl delete ns jenkins
```

## Mongo

```bash
kubectl create \
    -f sts/go-demo-2-deploy.yml \
    --record --save-config

kubectl -n go-demo-2 get pods

DB_1=$(kubectl -n go-demo-2 get pods \
    -l type=db,app=go-demo-2 \
    -o jsonpath="{.items[0].metadata.name}")

DB_2=$(kubectl -n go-demo-2 get pods \
    -l type=db,app=go-demo-2 \
    -o jsonpath="{.items[2].metadata.name}")

kubectl -n go-demo-2 logs $DB_1

kubectl -n go-demo-2 logs $DB_2

kubectl get pv

kubectl delete ns go-demo-2

kubectl create \
    -f sts/go-demo-2-sts.yml \
    --record --save-config

kubectl -n go-demo-2 get pods

kubectl get pv

kubectl -n go-demo-2 \
    exec -it go-demo-2-db-0 -- sh

mongo

db.inventory.insertOne({item: "test"})

db.inventory.find({item: "test"})

exit

exit

kubectl -n go-demo-2 \
    exec -it go-demo-2-db-1 -- sh

mongo

db.inventory.find({item: "test"})

exit

exit

kubectl -n go-demo-2 \
    run -ti \
    --image busybox dns-test \
    --restart=Never \
    --rm /bin/sh

nslookup go-demo-2-db

nslookup go-demo-2-db-0.go-demo-2-db

nslookup go-demo-2-db-1.go-demo-2-db

nslookup go-demo-2-db-2.go-demo-2-db

exit

kubectl -n go-demo-2 \
    exec -it go-demo-2-db-0 -- sh

mongo

rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "go-demo-2-db-0.go-demo-2-db:27017" },
      { _id: 1, host: "go-demo-2-db-1.go-demo-2-db:27017" },
      { _id: 2, host: "go-demo-2-db-2.go-demo-2-db:27017" }
   ]
})

rs.conf()

rs.status()

db.inventory.insertOne({item: "test"})

db.inventory.find({item: "test"})

exit

exit

kubectl -n go-demo-2 get pods

kubectl -n go-demo-2 \
    logs go-demo-2-db-0 \
    -c db-sidecar

kubectl delete ns go-demo-2
```

## What Now?

```bash
kubectl get pvc

kubectl get pv

# Wait until pv is removed

kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
