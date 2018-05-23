cd k8s-specs

git pull

open "https://github.com/vfarcic/go-demo-3"

cd ..

rm -rf go-demo-3

export GH_USER=[...]

git clone https://github.com/$GH_USER/go-demo-3.git

cd go-demo-3

git pull

cat k8s/build-ns.yml

kubectl apply \
    -f k8s/build-ns.yml \
    --record

cat k8s/prod-ns.yml

kubectl apply \
    -f k8s/prod-ns.yml \
    --record

cat k8s/cd.yml

kubectl apply -f k8s/cd.yml --record

kubectl -n go-demo-3-build \
    exec -it cd -c docker -- sh

docker container ls

export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git \
    .

export DH_USER=[...]

docker login -u $DH_USER

cat Dockerfile

docker image build \
    -t $DH_USER/go-demo-3:1.0-beta \
    .

# Only if the build command failed
docker image pull vfarcic/go-demo-3:1.0-beta

# Only if the build command failed
docker image tag vfarcic/go-demo-3:1.0-beta $DH_USER/go-demo-3:1.0-beta

docker image ls

docker image push \
    $DH_USER/go-demo-3:1.0-beta

exit

kubectl -n go-demo-3-build \
    exec -it cd -c kubectl -- sh

cat k8s/build.yml

diff k8s/build.yml k8s/prod.yml

cat k8s/build.yml | sed -e \
    "s@:latest@:1.0-beta@g" | \
    tee /tmp/build.yml

kubectl apply \
    -f /tmp/build.yml --record

kubectl rollout status deployment api

echo $?

# Only if GKE
kubectl -n go-demo-3-build patch svc api -p '{"spec":{"type": "NodePort"}}'

# Only if minishift
exit

# Only if minishift
kubectl -n go-demo-3-build \
    exec -it cd -c oc -- sh

# Only if minishift
oc apply -f k8s/build-oc.yml

# Only if GKE
ADDR=$(kubectl -n go-demo-3-build \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")/beta

# Only if minikube
ADDR=[...]/beta # Replace [...] with minikube IP

# Only if minishift
ADDR=$(oc -n go-demo-3-build get routes -o jsonpath="{.items[0].spec.host}")

# Only if kops or Docker for Mac/Windows
ADDR=$(kubectl -n go-demo-3-build \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")/beta

echo $ADDR | tee /workspace/addr

exit

kubectl -n go-demo-3-build \
    exec -it cd -c golang -- sh

curl "http://$(cat addr)/demo/hello"

go get -d -v -t

export ADDRESS=api:8080

go test ./... -v --run FunctionalTest

# Only if NOT Docker For Mac/Windows
export ADDRESS=$(cat addr)

# Only if NOT Docker For Mac/Windows
go test ./... -v --run FunctionalTest

exit

kubectl -n go-demo-3-build \
    exec -it cd -c kubectl -- sh

kubectl delete \
    -f /workspace/k8s/build.yml

kubectl -n go-demo-3-build get all

exit

kubectl -n go-demo-3-build \
    exec -it cd -c docker -- sh

export DH_USER=[...]

docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:1.0

docker image push \
    $DH_USER/go-demo-3:1.0

docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:latest

docker image push \
    $DH_USER/go-demo-3:latest

exit

kubectl -n go-demo-3-build \
    exec -it cd -c kubectl -- sh

cat k8s/prod.yml \
    | sed -e "s@:latest@:1.0@g" \
    | tee /tmp/prod.yml

kubectl apply -f /tmp/prod.yml --record

kubectl -n go-demo-3 \
    rollout status deployment api

echo $?

# Only if GKE
kubectl -n go-demo-3 patch svc api -p '{"spec":{"type": "NodePort"}}'

# Only if minishift
exit

# Only if minishift
kubectl -n go-demo-3-build \
    exec -it cd -c oc -- sh

# Only if minishift
oc apply -f k8s/prod-oc.yml

# Only if GKE
ADDR=$(kubectl -n go-demo-3 \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Only if minikube
ADDR=[...]/beta # Replace [...] with minikube IP

# Only if minishift
ADDR=$(oc -n go-demo-3 get routes -o jsonpath="{.items[0].spec.host}")

# Only if kops or Docker for Mac/Windows
ADDR=$(kubectl -n go-demo-3 \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $ADDR | tee /workspace/prod-addr

exit

kubectl -n go-demo-3-build \
    exec -it cd -c golang -- sh

export ADDRESS=$(cat prod-addr)

# Only if Docker For Mac/Windows
export ADDRESS=api.go-demo-3:8080

go test ./... -v --run ProductionTest

exit

kubectl -n go-demo-3-build \
    delete pods --all

kubectl delete ns \
    go-demo-3 go-demo-3-build
