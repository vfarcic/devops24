# Source: https://gist.github.com/e0657623045b43259fe258a146f05e1a

cd k8s-specs

git pull

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
LB_IP=$(minikube ip)

# Only if minishift
LB_IP=$(minishift ip)

# Only if GKE
LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $LB_IP

cd ../go-demo-3

git add .

git commit -m \
    "Packaging Kubernetes Applications chapter"

git push

git remote add upstream \
    https://github.com/vfarcic/go-demo-3.git

git fetch upstream

git checkout master

git merge upstream/master

cd ../k8s-specs

helm repo add stable \
    https://charts.helm.sh/stable

helm inspect values stable/chartmuseum

CM_ADDR="cm.$LB_IP.nip.io"

echo $CM_ADDR

cat helm/chartmuseum-values.yml

kubectl create namespace charts

helm install cm stable/chartmuseum \
    --namespace charts \
    --values helm/chartmuseum-values.yml \
    --set "ingress.hosts[0].name=$CM_ADDR" \
    --set env.secret.BASIC_AUTH_USER=admin \
    --set env.secret.BASIC_AUTH_PASS=admin

# Only if minishift
oc -n charts create route edge --service cm-chartmuseum --hostname $CM_ADDR --insecure-policy Allow

kubectl --namespace charts \
    rollout status deploy \
    cm-chartmuseum

curl "http://$CM_ADDR/health"

open "http://$CM_ADDR"

curl "http://$CM_ADDR/index.yaml"

curl -u admin:admin \
    "http://$CM_ADDR/index.yaml"

helm repo add chartmuseum \
    http://$CM_ADDR \
    --username admin \
    --password admin

helm plugin install \
    https://github.com/chartmuseum/helm-push

helm push \
    ../go-demo-3/helm/go-demo-3/ \
    chartmuseum \
    --username admin \
    --password admin

curl "http://$CM_ADDR/index.yaml" \
    -u admin:admin

helm search repo chartmuseum/

helm repo update

helm search repo chartmuseum/

helm inspect chart \
    chartmuseum/go-demo-3

GD3_ADDR="go-demo-3.$LB_IP.nip.io"

echo $GD3_ADDR

kubectl create namespace go-demo-3

helm upgrade -i go-demo-3 \
    chartmuseum/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0 \
    --set ingress.host=$GD3_ADDR \
    --reuse-values

# Only if minishift
oc -n go-demo-3 create route edge --service go-demo-3 --hostname $GD3_ADDR --insecure-policy Allow

kubectl --namespace go-demo-3 \
    rollout status deploy go-demo-3

curl "http://$GD3_ADDR/demo/hello"

helm --namespace go-demo-3 \
    delete go-demo-3

kubectl delete namespace go-demo-3

curl -XDELETE \
    "http://$CM_ADDR/api/charts/go-demo-3/0.0.1" \
    -u admin:admin

helm repo add monocular \
    https://helm.github.io/monocular

helm inspect values monocular/monocular

cat helm/monocular-values.yml

MONOCULAR_ADDR="monocular.$LB_IP.nip.io"

echo $MONOCULAR_ADDR

# Only if minishift
open https://blog.openshift.com/deploy-monocular-openshift/ # And follow the instructions

# Only if NOT minishift
helm install \
    monocular monocular/monocular \
    --namespace charts \
    --values helm/monocular-values.yml \
    --set ingress.hosts={$MONOCULAR_ADDR}

kubectl --namespace charts \
    rollout status \
    deploy monocular-monocular-ui

open "http://$MONOCULAR_ADDR"

helm --namespace charts \
    delete $(helm --namespace charts ls -q)

kubectl delete namespace \
    charts
