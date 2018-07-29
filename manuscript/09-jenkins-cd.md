## TODO

- [ ] Code
- [ ] Code review Docker for Mac/Windows
- [ ] Code review minikube
- [ ] Code review kops
- [ ] Code review minishift
- [ ] Code review GKE
- [ ] Write
- [ ] Text review
- [ ] Diagrams
- [ ] Gist
- [ ] Review the title
- [ ] Proofread
- [ ] Add to slides
- [ ] Publish on TechnologyConversations.com
- [ ] Add to Book.txt
- [ ] Publish on LeanPub.com

# CD With Jenkins

## Cluster

* [docker4mac-cd.sh](TODO): TODO

```bash
cd k8s-specs

git pull
```

## Infra

```bash
GH_USER=[...]

# Fork https://github.com/vfarcic/k8s-prod.git

cd ..

git clone https://github.com/$GH_USER/k8s-prod.git

cd k8s-prod

# Add prod Namespace ResourceQuotas, etc

# Explore the files in *chart* directory.

cat helm/requirements.yaml

cat helm/values-orig.yaml

ADDR=$LB_IP.nip.io

echo $ADDR

ADDR_ESC=$(echo $ADDR \
    | sed -e "s@\.@\\\.@g")

echo $ADDR_ESC

cat helm/values-orig.yaml \
    | sed -e "s@acme-escaped.com@$ADDR_ESC@g" \
    | sed -e "s@acme.com@$ADDR@g" \
    | tee helm/values.yaml

git commit -a -m "Address"

git push

helm install helm \
    -n prod \
    --namespace prod

kubectl -n prod \
    create secret generic \
    jenkins-credentials \
    --from-file ../k8s-specs/cluster/jenkins/credentials.xml

kubectl -n prod \
    create secret generic \
    jenkins-secrets \
    --from-file ../k8s-specs/cluster/jenkins/secrets

helm ls

helm status prod

kubectl -n prod \
    rollout status \
    deploy prod-chartmuseum

curl "http://cm.$ADDR/health"

kubectl -n prod \
    rollout status \
    deploy prod-jenkins

JENKINS_ADDR="jenkins.$ADDR"

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n prod \
    get secret prod-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

cd ..

# Fork go-demo-5

DH_USER=[...]

git clone \
    https://github.com/$DH_USER/go-demo-5.git

cd go-demo-5

# Replace `vfarcic/go-demo-5` with `$DH_USER/go-demo-5` in helm/go-demo-5/Chart.yaml, helm/go-demo-5/templates/deployment.yaml

kubectl apply -f k8s/build.yml --record

helm init --service-account build \
    --tiller-namespace go-demo-5-build

# Combination of ../go-demo-3/k8s/ns.yml and ../go-demo-3/k8s/build-config.yml

# Renamed go-demo-3 to go-demo-5

cat Jenkinsfile.orig

cat Jenkinsfile.orig \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee Jenkinsfile

git commit -a -m "Jenkinsfile"

git push

open "http://$JENKINS_ADDR/configure"

# Add a new cloud > Kubernetes
# Name = go-demo-5-build
# Kubernetes URL = https://kubernetes.default
# Kubernetes Namespace = go-demo-5-build
# Jenkins URL = http://prod-jenkins.prod:8080
# Jenkins tunnel = prod-jenkins-agent.prod:50000
# Save

# Create a multistage build job for go-demo-5

curl -u admin:admin \
    "http://cm.$ADDR/index.yaml"

# Copy the output from the last step of the job

cd ../go-demo-5

GD5_TAG=[...]

cat helm/values-orig.yaml \
    | sed -e "s@acme-escaped.com@$ADDR_ESC@g" \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@go-demo-5-tag@latest@g" \
    | tee helm/values.yaml

# Create a multistage build job for k8s-prod

helm repo add chartmuseum \
    http://cm.$ADDR \
    --username admin \
    --password admin

helm repo list

helm repo update

helm inspect chartmuseum/go-demo-5

helm dependency update helm

# Fails due to a bug

helm fetch \
    -d helm/charts \
    --version 0.0.1 \
    chartmuseum/go-demo-5
```