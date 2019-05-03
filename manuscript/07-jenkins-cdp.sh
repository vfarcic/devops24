cd k8s-specs

git pull

# Only if local cluster
cd cd/docker-build

# Only if local cluster
vagrant up

# Only if local cluster
cd ../../

# Only if local cluster
export DOCKER_VM=true

# Only if AWS
AMI_ID=$(grep 'artifact,0,id' \
    cluster/docker-ami.log \
    | cut -d: -f2)

# Only if AWS
echo $AMI_ID

# Only if GKE
export G_PROJECT=$(gcloud info \
    --format='value(config.project)')

# Only if GKE
echo $G_PROJECT

# Only if GKE
G_AUTH_FILE=$(ls cluster/jenkins/secrets/key*json | xargs -n 1 basename)

# Only if GKE
echo $G_AUTH_FILE

cat ../go-demo-3/k8s/ns.yml

kubectl apply \
    -f ../go-demo-3/k8s/ns.yml \
    --record

kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl -n go-demo-3-jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets

helm init --service-account build \
    --tiller-namespace go-demo-3-build

# Only if minishift
oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'

JENKINS_ADDR="go-demo-3-jenkins.$LB_IP.nip.io"

helm install helm/jenkins \
    --name go-demo-3-jenkins \
    --namespace go-demo-3-jenkins \
    --set jenkins.master.hostName=$JENKINS_ADDR \
    --set jenkins.master.DockerVM=$DOCKER_VM \
    --set jenkins.master.DockerAMI=$AMI_ID \
    --set jenkins.master.GProject=$G_PROJECT \
    --set jenkins.master.GAuthFile=$G_AUTH_FILE

# Only if minishift
oc -n go-demo-3-jenkins create route edge --service go-demo-3-jenkins --insecure-policy Allow --hostname $JENKINS_ADDR

kubectl -n go-demo-3-jenkins \
    rollout status deployment \
    go-demo-3-jenkins

open "http://$JENKINS_ADDR/computer"

JENKINS_PASS=$(kubectl -n go-demo-3-jenkins \
    get secret go-demo-3-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

# Only if AWS
cat cluster/devops24.pem

# Only if AWS
open "http://$JENKINS_ADDR/configure"

open "http://$JENKINS_ADDR"

export DH_USER=[...]

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

export ADDR=$LB_IP.nip.io

echo $ADDR

open "http://$JENKINS_ADDR/job/go-demo-3/configure"

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3-build \
    get pods

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3-build \
    get pods

open "http://$JENKINS_ADDR/credentials/store/system/domain/_/newCredentials"

JENKINS_POD=$(kubectl \
    -n go-demo-3-jenkins \
    get pods \
    -l component=go-demo-3-jenkins-jenkins-master \
    -o jsonpath='{.items[0].metadata.name}')

echo $JENKINS_POD

kubectl -n go-demo-3-jenkins cp \
    $JENKINS_POD:var/jenkins_home/credentials.xml \
    cluster/jenkins

open "http://$JENKINS_ADDR/job/go-demo-3/configure"

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

curl -u admin:admin \
    "http://$CM_ADDR/index.yaml"

open "http://$JENKINS_ADDR/job/go-demo-3/configure"

helm ls \
    --tiller-namespace go-demo-3-build

kubectl -n go-demo-3 get pods

curl "http://go-demo-3.$ADDR/demo/hello"

open "http://$JENKINS_ADDR/configure"

export GH_USER=[...]

open "https://github.com/$GH_USER/jenkins-shared-libraries.git"

kubectl -n go-demo-3-jenkins cp \
    $JENKINS_POD:var/jenkins_home/org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml \
    cluster/jenkins/secrets

open "http://$JENKINS_ADDR/job/go-demo-3/configure"

open "https://hub.docker.com/r/$DH_USER/go-demo-3/tags/"

helm ls \
    --tiller-namespace go-demo-3-build

helm history go-demo-3 \
    --tiller-namespace go-demo-3-build

open "https://github.com/$GH_USER/jenkins-shared-libraries/tree/master/vars"

curl "https://raw.githubusercontent.com/$GH_USER/jenkins-shared-libraries/master/vars/k8sBuildImageBeta.txt"

open "http://$JENKINS_ADDR/configureSecurity/"

open "http://$JENKINS_ADDR/job/go-demo-3/"

cat ../go-demo-3/Jenkinsfile

cat ../go-demo-3/k8s/build-config.yml

cat ../go-demo-3/k8s/build-config.yml \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | kubectl apply -f - --record

open "http://$JENKINS_ADDR/job/go-demo-3/"

open "http://$JENKINS_ADDR/blue/create-pipeline"

# Only if local cluster
cd cd/docker-build

# Only if local cluster
vagrant suspend

# Only if local cluster
cd ../../
