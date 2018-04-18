## Cluster And Repository

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
    --master-size t2.small \
    --node-count 3 \
    --node-size t2.medium \
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

## Preparing build ns

```bash
kubectl create \
    -f ../go-demo-3/k8s/build-ns.yml \
    --save-config --record

kubectl -n go-demo-3-build \
    describe rolebinding build

kubectl -n go-demo-3-build \
    describe clusterrole admin

kubectl create \
    -f ../go-demo-3/k8s/prod-ns.yml \
    --save-config --record
```

## Build, Unit Tests, and release beta

```bash
kubectl create ns go-demo-3-1-0-beta

kubectl -n go-demo-3-1-0-beta \
    create -f cd/docker-socket.yml \
    --save-config --record

kubectl -n go-demo-3-1-0-beta \
    get pods

kubectl -n go-demo-3-1-0-beta \
    describe pod docker

kubectl -n go-demo-3-1-0-beta \
    exec -it docker -- sh

docker version

docker container ls

# TODO: Fork https://github.com/vfarcic/go-demo-3.git

# TODO: Change `vfarcic` to your GH user in k8s/build.yml, k8s/prod.yml, and k8s/functional.yml

export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git

# TODO: It should be a specific commit

cd go-demo-3

# TODO: Register to Docker Hub

export DH_USER=[...]

# TODO: Docker is too old
docker image build \
    -t $DH_USER/go-demo-3:1.0-beta .

# TODO: Socket is exposed

# TODO: The node is logged in

exit

kubectl delete ns go-demo-3-1-0-beta

export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git \
    ../go-demo-3

export DH_USER=[...]

# TODO: Install Docker for Mac, Docker for Windows, or Docker (for Linux)

# TODO: Must be 17.05+

docker image build \
    -t $DH_USER/go-demo-3:1.0-beta \
    ../go-demo-3/

docker image ls

docker image push \
    $DH_USER/go-demo-3:1.0-beta

docker login -u $DH_USER

docker image push \
    $DH_USER/go-demo-3:1.0-beta
```

## Functional Tests

```bash
open "https://github.com/vfarcic/kubectl"

open "https://hub.docker.com/r/vfarcic/kubectl/"

kubectl apply \
    -f ../go-demo-3/k8s/kubectl.yml

kubectl -n go-demo-3-build \
    get pods

# TODO: Need to figure out how to deploy kubectl without kubectl

kubectl -n go-demo-3-build \
    cp ../go-demo-3/k8s/build.yml \
    kubectl:/tmp/build.yml

kubectl -n go-demo-3-build \
    exec -it kubectl -- sh

kubectl auth can-i create deployment

kubectl -n go-demo-3 \
    auth can-i create sts

kubectl -n default \
    auth can-i create deployment

kubectl auth can-i create ns

cat /tmp/build.yml |
    sed -e \
    "s@:latest@:1.0-beta@g" |
    tee build.yml

kubectl -n go-demo-3-build \
    exec -it kubectl -- \
    kubectl apply \
    -f /tmp/build.yml \
    --record

# TODO: We won't do this any more. It's painful and unintuitive, but we'll need something similar later.

kubectl -n go-demo-3-build \
    rollout status deployment api

kubectl -n go-demo-3-build \
    get pods

kubectl describe ns go-demo-3-build

DNS=$(kubectl -n go-demo-3-build \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

curl "http://$DNS/beta/demo/hello"

kubectl -n go-demo-3-build \
    run golang \
    --quiet \
    --restart Never \
    --env GH_USER=$GH_USER \
    --env DNS=$DNS \
    --image golang:1.9 \
    sleep 1000000

# TODO: It'll be slow because of low defaults

kubectl -n go-demo-3-build \
    get pods

kubectl -n go-demo-3-build \
    exec -it golang -- sh

git clone \
    https://github.com/$GH_USER/go-demo-3.git

cd go-demo-3

export ADDRESS=api:8080

go get -d -v -t

go test ./... -v --run FunctionalTest

export ADDRESS=$DNS/beta

go test ./... -v --run FunctionalTest

exit

# TODO: Can't delete the Namespace since it's set up by a cluster admin. Also, we still need that Namespace.

kubectl delete -f build.yml

kubectl -n go-demo-3-build get all
```

## Release

```bash
docker image tag $GH_USER/go-demo-3:1.0-beta $GH_USER/go-demo-3:1.0

docker image push $GH_USER/go-demo-3:1.0

docker image tag $GH_USER/go-demo-3:1.0-beta $GH_USER/go-demo-3:latest

docker image push $GH_USER/go-demo-3:latest

# TODO: Release files to GH
```

## Deploy

```bash
cat ../go-demo-3/k8s/prod.yml |
    sed -e \
    "s@:latest@:1.0@g" |
    tee prod.yml

kubectl apply -f prod.yml --record

kubectl -n go-demo-3 \
    rollout status deployment api

kubectl -n go-demo-3 get pods

curl "http://$DNS/demo/hello"
```

## Production Testing

```bash
kubectl -n go-demo-3-build \
    exec -it golang -- sh

cd go-demo-3

export ADDRESS=$DNS

go test ./... -v --run ProductionTest

exit
```

## Cleaning Up

```bash
kubectl -n go-demo-3-build \
    get pods

# TODO: Still left with "tool" Pods. Need to figure out how to remove them automatically.

kubectl -n go-demo-3-build \
    delete pods --all 
```

## What Now?

```bash
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```