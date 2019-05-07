cd k8s-specs

git pull

GH_USER=[...]

cd ..

git clone https://github.com/$GH_USER/k8s-prod.git

cd k8s-prod

cat helm/Chart.yaml

cp helm/requirements-orig.yaml \
    helm/requirements.yaml

cat helm/requirements.yaml

cat helm/values-orig.yaml

ls -1 helm/templates

cat helm/templates/ns.yaml

ADDR=$LB_IP.nip.io

echo $ADDR

cat helm/values-orig.yaml \
    | sed -e "s@acme.com@$ADDR@g" \
    | tee helm/values.yaml

git add .

git commit -m "Address"

git push

helm dependency update helm

ls -1 helm/charts

# Only if minishift
oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'


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

kubectl -n prod \
    rollout status \
    deploy prod-chartmuseum

# Only if minishift
oc -n prod create route edge --service prod-chartmuseum --hostname cm.$ADDR --insecure-policy Allow

curl "http://cm.$ADDR/health"

kubectl -n prod \
    rollout status \
    deploy prod-jenkins

# Only if minishift
oc -n prod create route edge --service prod-jenkins --insecure-policy Allow --hostname jenkins.$ADDR

JENKINS_ADDR="jenkins.$ADDR"

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n prod \
    get secret prod-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

cd ..

git clone \
    https://github.com/$GH_USER/go-demo-5.git

cd go-demo-5

DH_USER=[...]

cat helm/go-demo-5/deployment-orig.yaml \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee helm/go-demo-5/templates/deployment.yaml

kubectl apply -f k8s/build.yml --record

helm init --service-account build \
    --tiller-namespace go-demo-5-build

cat Dockerfile

cat Jenkinsfile.orig

cat KubernetesPod.yaml
```

The output is as follows.

```yaml
apiVersion: v1
kind: Pod
spec:

# Only if minishift
oc adm policy add-scc-to-user hostmount-anyuid -z build -n go-demo-5-build

# Only if minishift
cat Jenkinsfile.oc \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee Jenkinsfile

# Only if NOT minishift
cat Jenkinsfile.orig \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee Jenkinsfile

git add .

git commit -m "Jenkinsfile"

git push

cd ..

git clone https://github.com/$GH_USER/jenkins-shared-libraries.git

cd jenkins-shared-libraries

git remote add upstream \
    https://github.com/vfarcic/jenkins-shared-libraries.git

git fetch upstream

git checkout master

git merge upstream/master

cd ../go-demo-5

open "http://$JENKINS_ADDR/configure"

open "http://$JENKINS_ADDR/blue/organizations/jenkins/"

curl "http://cm.$ADDR/index.yaml"

VERSION=[...]

helm repo add chartmuseum \
    http://cm.$ADDR

helm repo list

helm repo update

helm inspect chartmuseum/go-demo-5 \
    --version $VERSION

cd ../k8s-prod

cat helm/requirements.yaml

echo "- name: go-demo-5
  repository: \"@chartmuseum\"
  version: $VERSION" \
  | tee -a helm/requirements.yaml

cat helm/requirements.yaml

echo "go-demo-5:
  ingress:
    host: go-demo-5.$ADDR" \
    | tee -a helm/values.yaml

cat helm/values.yaml

git add .

git commit -m "Added go-demo-5"

git push

helm dependency update helm

ls -1 helm/charts

helm upgrade prod helm \
    --namespace prod

kubectl -n prod get pods

# Only if minishift
oc -n prod create route edge --service prod-go-demo-5 --hostname go-demo-5.$ADDR --insecure-policy Allow

kubectl -n prod rollout status \
    deployment prod-go-demo-5

curl -i "http://go-demo-5.$ADDR/demo/hello"

kubectl -n prod \
    describe deploy prod-go-demo-5

open "http://$JENKINS_ADDR/blue/organizations/jenkins/go-demo-5/branches"

cd ../go-demo-5

git add .

git commit -m "Version bump"

git push

open "http://$JENKINS_ADDR/blue/organizations/jenkins/go-demo-5/branches"

cd ../k8s-prod

cat Jenkinsfile.orig

cat Jenkinsfile.orig \
    | sed -e "s@acme.com@$ADDR@g" \
    | tee Jenkinsfile

git add .

git commit -m "Jenkinsfile"

git push

open "http://$JENKINS_ADDR/blue/pipelines"

helm history prod
