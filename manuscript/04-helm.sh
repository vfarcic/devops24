cd k8s-specs

git pull

# Only if MacOS
brew install kubernetes-helm

# Only if Windows
choco install kubernetes-helm

# Only if Linux
open https://github.com/kubernetes/helm/releases

# Only if Linux
# Download `tar.gz` file, unpack it, and move the binary to `/usr/local/bin/`.

cat helm/tiller-rbac.yml

kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config

helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy

kubectl -n kube-system get pods

helm repo update

helm search

helm search jenkins

# Only if minishift
oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins

# Only if minikube
helm upgrade jenkins stable/jenkins \
    --set Master.ServiceType=NodePort

# Only if minishift
oc -n jenkins create route edge \
    --service jenkins \
    --insecure-policy Allow

kubectl -n jenkins \
    rollout status deploy jenkins

ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080

# Only if minikube
ADDR=$(minikube ip):$(kubectl -n jenkins get svc jenkins -o jsonpath="{.spec.ports[0].nodePort}")

# Only if GKE
ADDR=$(kubectl -n jenkins get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

# Only if minishift
ADDR=$(oc -n jenkins get route jenkins -o jsonpath="{.status.ingress[0].host}")

echo $ADDR

open "http://$ADDR"

kubectl -n jenkins \
     get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo

helm inspect stable/jenkins

helm ls

helm status jenkins

kubectl -n kube-system get cm

kubectl -n kube-system \
    describe cm jenkins.v1

helm delete jenkins

kubectl -n jenkins get all

helm status jenkins

helm delete jenkins --purge

helm status jenkins

helm inspect values stable/jenkins

helm inspect stable/jenkins

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.112-alpine

# Only if minikube
helm upgrade jenkins stable/jenkins --set Master.ServiceType=NodePort --reuse-values

kubectl -n jenkins \
    rollout status deployment jenkins

ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080

# Only if minikube
ADDR=$(minikube ip):$(kubectl -n jenkins get svc jenkins -o jsonpath="{.spec.ports[0].nodePort}")

# Only if GKE
ADDR=$(kubectl -n jenkins get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

# Only if minishift
ADDR=$(oc -n jenkins get route jenkins -o jsonpath="{.status.ingress[0].host}")

echo $ADDR

open "http://$ADDR"

helm upgrade jenkins stable/jenkins \
    --set Master.ImageTag=2.116-alpine \
    --reuse-values

kubectl -n jenkins \
    describe deployment jenkins

kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$ADDR"

helm list

helm rollback jenkins 0

helm list

kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$ADDR"

helm delete jenkins --purge

# Only if AWS with kops
LB_HOST=$(kubectl -n kube-ingress \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

# Only if AWS with kops
LB_IP="$(dig +short $LB_HOST \
    | tail -n 1)"

# Only if Docker For Mac/Windows
LB_IP="127.0.0.1"

# Only if minikube
LB_IP="$(minikube ip)"

# Only if GKE
LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $LB_IP

HOST="jenkins.$LB_IP.nip.io"

echo $HOST

# Only if minishift
HOST=$ADDR && echo $HOST

helm inspect values stable/jenkins

cat helm/jenkins-values.yml

helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$HOST

kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$HOST"

helm get values jenkins

helm delete jenkins --purge

kubectl delete ns jenkins

cd ../go-demo-3

git add .

git commit -m \
    "Defining Continuous Deployment chapter"

git push

git remote add upstream \
    https://github.com/vfarcic/go-demo-3.git

git fetch upstream

git checkout master

git merge upstream/master

helm create my-app

ls -1 my-app

helm dependency update my-app

helm package my-app

helm lint my-app

helm install ./my-app-0.1.0.tgz \
    --name my-app

helm delete my-app --purge

rm -rf my-app

rm -rf my-app-0.1.0.tgz

ls -1 helm/go-demo-3

cat helm/go-demo-3/Chart.yaml

cat helm/go-demo-3/LICENSE

cat helm/go-demo-3/README.md

cat helm/go-demo-3/values.yaml

ls -1 helm/go-demo-3/templates/

cat helm/go-demo-3/templates/NOTES.txt

cat helm/go-demo-3/templates/_helpers.tpl

cat helm/go-demo-3/templates/deployment.yaml

cat helm/go-demo-3/templates/ing.yaml

helm lint helm/go-demo-3

helm package helm/go-demo-3 -d helm

helm inspect values helm/go-demo-3

# Only if NOT minishift
HOST="go-demo-3.$LB_IP.nip.io"

# Only if minishift
HOST="go-demo-3-go-demo-3.$(minishift ip).nip.io"

echo $HOST

helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0 \
    --set ingress.host=$HOST \
    --reuse-values

# Only if minishift
oc -n go-demo-3 create route edge --service go-demo-3 --insecure-policy Allow

kubectl -n go-demo-3 \
    rollout status deployment go-demo-3

curl http://$HOST/demo/hello

helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=2.0 \
    --reuse-values

helm delete go-demo-3 --purge

kubectl delete ns go-demo-3
