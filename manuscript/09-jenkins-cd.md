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

* [docker4mac.sh](TODO): TODO

## Infra

```bash
GH_USER=[...]

# If Docker For Mac / Win
# TODO: Fork https://github.com/vfarcic/k8s-docker4macwin.git

# If Docker For Mac / Win
REPO=k8s-prod

cd ..

git clone https://github.com/$GH_USER/$REPO.git

cd $REPO

ADDR=$LB_IP.nip.io

echo $ADDR

ADDR_ESC=$(echo $ADDR \
    | sed -e "s@\.@\\\.@g")

echo $ADDR_ESC

helm dependency update chart

# TODO: Add prod Namespace ResourceQuotas, etc

# TODO: Explore the files in *chart* directory.

cat helm/values-orig.yaml \
    | sed -e "s@acme-escaped.com@$ADDR_ESC@g" \
    | sed -e "s@acme.com@$ADDR@g" \
    | tee helm/values.yaml

kubectl -n prod \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl -n prod \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets

helm install helm \
    -n prod \
    --namespace prod

helm init --service-account build \
    --tiller-namespace go-demo-3-build

helm ls

helm status prod

kubectl -n prod \
    rollout status \
    deploy prod-chartmuseum

curl "http://cm.$ADDR/health"

kubectl -n prod \
    rollout status \
    deploy prod-jenkins

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

cat k8s/build.yml \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | kubectl apply -f - --record

# Combination of ../go-demo-3/k8s/ns.yml and ../go-demo-3/k8s/build-config.yml

# Renamed go-demo-3 to go-demo-5

cat Jenkinsfile.orig

cat Jenkinsfile.orig \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee Jenkinsfile

cat Jenkinsfile
```
