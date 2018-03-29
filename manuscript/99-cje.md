# CJE

## Creating A Cluster

```bash
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

kubectl --namespace kube-ingress \
    get all
```

## Deploying CJOC

```bash
kubectl create ns jenkins

CLUSTER_DNS=$(aws elb describe-load-balancers \
    | jq -r \
    ".LoadBalancerDescriptions[] \
    | select(.DNSName \
    | contains (\"api\") | not)\
    .DNSName")

echo $CLUSTER_DNS

open "https://downloads.cloudbees.com/cje2/latest/"

# Copy the link to cje2_*_kubernetes.tgz

curl -o cje.tgz [ADDRESS_OF_THE_RELEASE]

tar -xvf cje.tgz

cd cje2-kubernetes

ls -l

kubectl get sc -o yaml

cat cje.yml

cat cje.yml \
    | sed -e \
    "s@https://cje.example.com@http://cje.example.com@g" \
    | sed -e \
    "s@cje.example.com@$CLUSTER_DNS@g" \
    | sed -e \
    "s@ssl-redirect: \"true\"@ssl-redirect: \"false\"@g" \
    | kubectl --namespace jenkins \
    create -f - \
    --save-config --record

kubectl -n jenkins \
    rollout status sts cjoc

kubectl -n jenkins \
    get all

open "http://$CLUSTER_DNS/cjoc"

kubectl --namespace jenkins \
    exec cjoc-0 -- \
    cat /var/jenkins_home/secrets/initialAdminPassword

# TODO: Wizard steps

kubectl get pvc

kubectl get pv

# TODO: Create a master called *my-master*

# TODO: Set *Jenkins Master Memory in MB* to *1024*

# TODO: Set *Jenkins Master CPUs* to *0.5*

kubectl --namespace jenkins \
    get all

kubectl --namespace jenkins \
    describe pod my-master-0

kubectl --namespace jenkins \
    logs my-master-0

# TODO: Go to *my-master*

# TODO: Wizard steps

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

# TODO: Run the job *my-job*

kubectl --namespace jenkins \
    get pods

# TODO: Present different stages of the *jenkins-slave-* Pod

# TODO: Display the results in UI

# TODO: Delete a master

kubectl get pvc

kubectl get pv
```

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
