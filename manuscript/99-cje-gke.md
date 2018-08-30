# Create The Cluster

```bash
gcloud auth login

ZONE=$(gcloud compute zones list \
    --filter "region:(us-east1)" \
    | awk '{print $1}' \
    | tail -n 1)

echo $ZONE

ZONES=$(gcloud compute zones list \
    --filter "region:(us-east1)" \
    | tail -n +2 \
    | awk '{print $1}' \
    | tr '\n' ',')

echo $ZONES

MACHINE_TYPE=n1-standard-2

gcloud container clusters \
    create devops24 \
    --zone $ZONE \
    --node-locations $ZONES \
    --machine-type $MACHINE_TYPE \
    --enable-autoscaling \
    --num-nodes 1 \
    --max-nodes 3 \
    --min-nodes 1

kubectl create clusterrolebinding \
    cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)
```

# Install Ingress

```bash
kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml
```

# Get Cluster IP

```bash
export LB_IP=$(kubectl -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $LB_IP

# Repeat the `export` command if the output is empty
```

## CJE

```bash
kubectl create ns cje

kubectl config set-context \
    $(kubectl config current-context) \
    --namespace=cje

open "https://downloads.cloudbees.com/cje2/latest/"

# Copy the link address of the `cje2_*_kubernetes.tgz` archive

RELEASE_URL=[...]

curl -o cje.tgz $RELEASE_URL

tar -xvf cje.tgz

cd cje2*

CJE_ADDR=cjoc.$LB_IP.nip.io

echo $CJE_ADDR

cat cloudbees-core.yml \
    | sed -e \
    "s@https://cje.example.com@http://cje.example.com@g" \
    | sed -e \
    s@cje.example.com@$CJE_ADDR@g \
    | sed -e \
    "s@ssl-redirect: \"true\"@ssl-redirect: \"false\"@g" \
    | kubectl apply -f -

kubectl rollout status sts cjoc

open "http://$CJE_ADDR"

kubectl exec cjoc-0 -- cat \
    /var/jenkins_home/secrets/initialAdminPassword

# Copy the password and paste it into the UI

# Finish the setup wizard

# Create a master

# Create a job
```

```groovy
podTemplate(
    label: 'kubernetes',
    containers: [
        containerTemplate(name: 'maven', image: 'maven:alpine', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'golang', image: 'golang:alpine', ttyEnabled: true, command: 'cat')
    ]
) {
    node('kubernetes') {
        container('maven') {
            stage('build') {
                sh "sleep 5"
                sh 'mvn --version'
            }
            stage('unit-test') {
                sh "sleep 5"
                sh 'java -version'
            }
        }
        container('golang') {
            stage('deploy') {
                sh "sleep 5"
                sh 'go version'
            }
        }
    }
}
```

## What Now?

```bash
gcloud container clusters \
    delete devops24 \
    --zone $ZONE \
    --quiet
```