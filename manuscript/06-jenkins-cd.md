# Jenkins

## Creating A Cluster

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
    --node-count 3 \
    --node-size t2.xlarge \
    --master-size t2.small \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --yes

kops validate cluster

# Windows only
kops export kubecfg --name ${NAME}

# Windows only
export \
    KUBECONFIG=$PWD/config/kubecfg.yaml

kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml
```

## Running Jenkins

```bash
kubectl create -f cd/jenkins.yml \
    --save-config --record

kubectl -n jenkins \
    rollout status sts cjoc

DNS=$(kubectl -n jenkins \
    get ing master \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

open "http://$DNS/jenkins"

kubectl --namespace jenkins \
    exec master-0 -- \
    cat /var/jenkins_home/secrets/initialAdminPassword

# TODO: Wizard steps

kubectl -n jenkins get pvc

kubectl get pv
```

## Running On-Shot Agents

```bash
# TODO: Create a new Pipeline job called *my-job*
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

```bash
# TODO: Install BlueOcean

# TODO: Run the job

kubectl --namespace jenkins \
    get pods

# TODO: Display the results in UI

# TODO: Delete the job
```

## Shared Libraries

TODO: Write

## Multi-Stage Pipeline

```bash
# TODO: Create a Multi-Stage Pipeline for go-demo-3
```

## Webhooks

TODO: Write

## Destroying The Cluster

```bash
kubectl delete ns jenkins

kubectl get pvc

kubectl get pv

# Wait until pv is removed

kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
