## TODO

- [X] Code
- [X] Code review Docker for Mac/Windows
- [X] Code review minikube
- [X] Code review kops
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
* [minikube-cd.sh](TODO): TODO
* [kops-cd.sh](TODO): TODO (--kubernetes-version v1.11.1)

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

# Explore the files in *chart* directory.

cat helm/Chart.yaml
```

```yaml
apiVersion: v1
name: prod-env
version: 0.0.1
description: Docker For Mac or Windows Production Environment
maintainers:
- name: Viktor Farcic
  email: viktor@farcic.com
```

```bash
cat helm/requirements.yaml
```

```yaml
dependencies:
- name: chartmuseum
  repository: "@stable"
  version: 1.6.0
- name: jenkins
  repository: "@stable"
  version: 0.16.6
```

```bash
cat helm/values-orig.yaml
```

```yaml
chartmuseum:
  env:
    open:
      DISABLE_API: false
      AUTH_ANONYMOUS_GET: true
    secret:
      BASIC_AUTH_USER: admin # Change me!
      BASIC_AUTH_PASS: admin # Change me!
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 80m
      memory: 64Mi
  persistence:
    enabled: true
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "nginx"
      ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
    hosts:
      cm.acme-escaped.com: # Change me!
      - /

jenkins:
  Master:
    ImageTag: "2.129-alpine"
    Cpu: "500m"
    Memory: "500Mi"
    ServiceType: ClusterIP
    ServiceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    GlobalLibraries: true
    InstallPlugins:
    - durable-task:1.22
    - blueocean:1.7.1
    - credentials:2.1.18
    - ec2:1.39
    - git:3.9.1
    - git-client:2.7.3
    - github:1.29.2
    - kubernetes:1.12.0
    - pipeline-utility-steps:2.1.0
    - pipeline-model-definition:1.3.1
    - script-security:1.44
    - slack:2.3
    - thinBackup:1.9
    - workflow-aggregator:2.5
    - ssh-slaves:1.26
    - ssh-agent:1.15
    - jdk-tool:1.1
    - command-launcher:1.2
    - github-oauth:0.29
    - google-compute-engine:1.0.4
    - pegdown-formatter:1.3
    Ingress:
      Annotations:
        kubernetes.io/ingress.class: "nginx"
        nginx.ingress.kubernetes.io/ssl-redirect: "false"
        nginx.ingress.kubernetes.io/proxy-body-size: 50m
        nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
        ingress.kubernetes.io/ssl-redirect: "false"
        ingress.kubernetes.io/proxy-body-size: 50m
        ingress.kubernetes.io/proxy-request-buffering: "off"
    HostName: jenkins.acme.com # Change me!
    CustomConfigMap: true
    CredentialsXmlSecret: jenkins-credentials
    SecretsFilesSecret: jenkins-secrets
    DockerVM: false
  rbac:
    install: true
```

```bash
ls -1 helm/templates
```

```
config.tpl
ns.yaml
```

```bash
cat helm/templates/ns.yaml
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: build
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: build

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: build
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: build
  namespace: {{ .Release.Namespace }}
```

```bash
ADDR=$LB_IP.nip.io

echo $ADDR

ADDR_ESC=$(echo $ADDR \
    | sed -e "s@\.@\\\.@g")

echo $ADDR_ESC

cat helm/values-orig.yaml \
    | sed -e "s@acme-escaped.com@$ADDR_ESC@g" \
    | sed -e "s@acme.com@$ADDR@g" \
    | tee helm/values.yaml

git add .

git commit -m "Address"

git push

helm dependency update helm
```

```
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "local" chart repository (http://127.0.0.1:8879/charts):
        Get http://127.0.0.1:8879/charts/index.yaml: dial tcp 127.0.0.1:8879: connect: connection refused
...Successfully got an update from the "stable" chart repository
...Unable to get an update from the "chartmuseum" chart repository (http://cm.192.168.99.100.nip.io):
        Get http://cm.192.168.99.100.nip.io/index.yaml: dial tcp 192.168.99.100:80: i/o timeout
Update Complete. ⎈Happy Helming!⎈
Saving 2 charts
Downloading chartmuseum from repo https://kubernetes-charts.storage.googleapis.com
Downloading jenkins from repo https://kubernetes-charts.storage.googleapis.com
Deleting outdated charts
```

```bash
helm install helm \
    -n prod \
    --namespace prod
```

```
NAME:   prod
LAST DEPLOYED: Tue Aug  7 22:16:39 2018
NAMESPACE: prod
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                DATA  AGE
prod-jenkins        4     1s
prod-jenkins-tests  1     1s

==> v1/PersistentVolumeClaim
NAME              STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
prod-chartmuseum  Bound   pvc-cb312443-9a7e-11e8-8fcb-0a23b7988602  8Gi       RWO           gp2           1s
prod-jenkins      Bound   pvc-cb3288b2-9a7e-11e8-8fcb-0a23b7988602  8Gi       RWO           gp2           1s

==> v1beta1/RoleBinding
NAME   AGE
build  1s
build  1s

==> v1/Service
NAME                TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)    AGE
prod-chartmuseum    ClusterIP  100.68.140.14   <none>       8080/TCP   1s
prod-jenkins-agent  ClusterIP  100.65.138.150  <none>       50000/TCP  1s
prod-jenkins        ClusterIP  100.66.79.10    <none>       8080/TCP   1s

==> v1/Secret
NAME              TYPE    DATA  AGE
prod-chartmuseum  Opaque  2     2s
prod-jenkins      Opaque  2     2s

==> v1/ServiceAccount
NAME          SECRETS  AGE
prod-jenkins  1        1s
build         1        1s

==> v1beta1/ClusterRoleBinding
NAME                       AGE
prod-jenkins-role-binding  1s

==> v1beta1/Deployment
NAME              DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
prod-chartmuseum  1        1        1           0          1s
prod-jenkins      1        1        1           0          1s

==> v1beta1/Ingress
NAME              HOSTS                         ADDRESS  PORTS  AGE
prod-chartmuseum  cm.18.219.103.63.nip.io       80       1s
prod-jenkins      jenkins.18.219.103.63.nip.io  80       1s

==> v1/Pod(related)
NAME                               READY  STATUS   RESTARTS  AGE
prod-chartmuseum-68bc575fb7-jgs98  0/1    Pending  0         1s
prod-jenkins-6dbc74554d-gbzp4      0/1    Pending  0         1s
```

```bash
kubectl -n prod \
    create secret generic \
    jenkins-credentials \
    --from-file ../k8s-specs/cluster/jenkins/credentials.xml

kubectl -n prod \
    create secret generic \
    jenkins-secrets \
    --from-file ../k8s-specs/cluster/jenkins/secrets

helm ls
```

```
NAME    REVISION        UPDATED                         STATUS          CHART           NAMESPACE
prod    1               Tue Aug  7 22:16:39 2018        DEPLOYED        prod-env-0.0.1  prod
```

```bash
kubectl -n prod \
    rollout status \
    deploy prod-chartmuseum
```

```
Waiting for deployment "prod-chartmuseum" rollout to finish: 0 of 1 updated replicas are available...
deployment "prod-chartmuseum" successfully rolled out
```

```bash
curl "http://cm.$ADDR/health"
```

```json
{"healthy":true}
```

```bash
kubectl -n prod \
    rollout status \
    deploy prod-jenkins
```

```
Waiting for deployment "prod-jenkins" rollout to finish: 0 of 1 updated replicas are available...
deployment "prod-jenkins" successfully rolled out
```

```bash
JENKINS_ADDR="jenkins.$ADDR"

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n prod \
    get secret prod-jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS
```

```
APi2MZDPth
```

```bash
# Fork vfarcic/go-demo-5

# Copied go-demo-3 to go-demo-5

cd ..

git clone \
    https://github.com/$GH_USER/go-demo-5.git

cd go-demo-5

DH_USER=[...]

cat helm/go-demo-5/templates/deployment.yaml.orig \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee helm/go-demo-5/templates/deployment.yaml

cat k8s/build.yml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo-5-build

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: build
  namespace: go-demo-5-build

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: build
  namespace: go-demo-5-build
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: build

---

apiVersion: v1
kind: LimitRange
metadata:
  name: build
  namespace: go-demo-5-build
spec:
  limits:
  - default:
      memory: 500Mi
      cpu: 0.2
    defaultRequest:
      memory: 250Mi
      cpu: 0.1
    max:
      memory: 500Mi
      cpu: 0.5
    min:
      memory: 10Mi
      cpu: 0.05
    type: Container

---

apiVersion: v1
kind: ResourceQuota
metadata:
  name: build
  namespace: go-demo-5-build
spec:
  hard:
    requests.cpu: 2
    requests.memory: 3Gi
    limits.cpu: 3
    limits.memory: 4Gi
    pods: 15
```

```bash
# Combination of ../go-demo-3/k8s/ns.yml and ../go-demo-3/k8s/build-config.yml

kubectl apply -f k8s/build.yml --record
```

```
namespace/go-demo-5-build created
serviceaccount/build created
rolebinding.rbac.authorization.k8s.io/build created
limitrange/build created
```

```bash
helm init --service-account build \
    --tiller-namespace go-demo-5-build
```

```
$HELM_HOME has been configured at /Users/vfarcic/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

```bash
cat Dockerfile
```

```
FROM alpine:3.4
MAINTAINER 	Viktor Farcic <viktor@farcic.com>

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

EXPOSE 8080
ENV DB db
CMD ["go-demo"]

COPY go-demo /usr/local/bin/go-demo
RUN chmod +x /usr/local/bin/go-demo
```

```bash
cat Jenkinsfile.orig
```

```groovy
import java.text.SimpleDateFormat

pipeline {
  options {
    buildDiscarder logRotator(numToKeepStr: '5')
    disableConcurrentBuilds()
  }
  agent {
    kubernetes {
      cloud "go-demo-5-build"
      label "go-demo-5-build"
      serviceAccount "build"
      yamlFile "KubernetesPod.yaml"
    }      
  }
  environment {
    image = "vfarcic/go-demo-5"
    project = "go-demo-5"
    domain = "acme.com"
    cmAddr = "cm.acme.com"
  }
  stages {
    stage("build") {
      steps {
        container("golang") {
          script {
            currentBuild.displayName = new SimpleDateFormat("yy.MM.dd").format(new Date()) + "-${env.BUILD_NUMBER}"
          }
          k8sBuildGolang("go-demo")
        }
        container("docker") {
          k8sBuildImageBeta(image, false)
        }
      }
    }
    stage("func-test") {
      steps {
        container("helm") {
          k8sUpgradeBeta(project, domain, "--set replicaCount=2 --set dbReplicaCount=1")
        }
        container("kubectl") {
          k8sRolloutBeta(project)
        }
        container("golang") {
          k8sFuncTestGolang(project, domain)
        }
      }
      post {
        always {
          container("helm") {
            k8sDeleteBeta(project)
          }
        }
      }
    }
    stage("release") {
      when {
          branch "master"
      }
      steps {
        container("docker") {
          k8sPushImage(image, false)
        }
        container("helm") {
          k8sPushHelm(project, "", cmAddr, true, true)
        }
      }
    }
  }
}
```

```bash
cat Jenkinsfile.orig \
    | sed -e "s@acme.com@$ADDR@g" \
    | sed -e "s@vfarcic@$DH_USER@g" \
    | tee Jenkinsfile

git add .

git commit -m "Jenkinsfile"

git push

open "http://$JENKINS_ADDR/configure"

# Add a new cloud > Kubernetes
# Name = go-demo-5-build
# Kubernetes URL = https://kubernetes.default
# Kubernetes Namespace = go-demo-5-build
# Jenkins URL = http://prod-jenkins.prod:8080
# Jenkins tunnel = prod-jenkins-agent.prod:50000
# Save
```

![Figure 7-TODO: Jenkins Kubernetes Cloud settings for go-demo-5-build](images/ch08/jenkins-k8s-cloud-go-demo-5.png)

```bash
open "http://$JENKINS_ADDR/blue/organizations/jenkins/"

# Click the *Create a New Pipeline* button
# Select *GitHub*
# Type *Your GitHub access token* and click the *Connect* button
# Select the organization
# Select *go-demo-5* repository
# Click the *Create Pipelin* button

# Wait until the build is finished

# TODO: Screenshot

curl "http://cm.$ADDR/index.yaml"
```

```yaml
apiVersion: v1
entries:
  go-demo-5:
  - apiVersion: v1
    created: "2018-08-08T20:47:34.322943263Z"
    description: A silly demo based on API written in Go and MongoDB
    digest: a30aa7921b890b1f919286113e4a8193a2d4d3137e8865b958acd1a2bfd97c7e
    home: http://www.devopstoolkitseries.com/
    keywords:
    - api
    - backend
    - go
    - database
    - mongodb
    maintainers:
    - email: viktor@farcic.com
      name: Viktor Farcic
    name: go-demo-5
    sources:
    - https://github.com/vfarcic/go-demo-5
    urls:
    - charts/go-demo-5-0.0.1.tgz
    version: 0.0.1
generated: "2018-08-08T21:03:01Z"
```

```bash
VERSION=[...]

helm repo add chartmuseum \
    http://cm.$ADDR

helm repo list
```

```
NAME            URL
stable          https://kubernetes-charts.storage.googleapis.com
local           http://127.0.0.1:8879/charts
chartmuseum     http://cm.18.219.191.38.nip.io
```

```bash
helm repo update
```

```
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

```bash
helm inspect chartmuseum/go-demo-5 \
    --version $VERSION
```

```yaml
apiVersion: v1
description: A silly demo based on API written in Go and MongoDB
home: http://www.devopstoolkitseries.com/
keywords:
- api
- backend
- go
- database
- mongodb
maintainers:
- email: viktor@farcic.com
  name: Viktor Farcic
name: go-demo-5
sources:
- https://github.com/vfarcic/go-demo-5
version: 0.0.1

---
replicaCount: 3
dbReplicaCount: 3
image:
  tag: 18.08.08-3
  dbTag: 3.3
ingress:
  enabled: true
  host: acme.com
service:
  type: ClusterIP
rbac:
  enabled: true
resources:
  limits:
    cpu: 0.2
    memory: 20Mi
  requests:
    cpu: 0.1
    memory: 10Mi
dbResources:
  limits:
    memory: 200Mi
    cpu: 0.2
  requests:
    memory: 100Mi
    cpu: 0.1
dbPersistence:
  accessMode: ReadWriteOnce
  size: 2Gi

---
This is just a silly demo.
```

```bash
cd ../k8s-prod

cat helm/requirements.yaml
```

```yaml
dependencies:
- name: chartmuseum
  repository: "@stable"
  version: 1.6.0
- name: jenkins
  repository: "@stable"
  version: 0.16.6
```

```bash
echo "- name: go-demo-5
  repository: \"@chartmuseum\"
  version: $VERSION" \
  | tee -a helm/requirements.yaml

cat helm/requirements.yaml
```

```yaml
dependencies:
- name: chartmuseum
  repository: "@stable"
  version: 1.6.0
- name: jenkins
  repository: "@stable"
  version: 0.16.6
- name: go-demo-5
  repository: "@chartmuseum"
  version: 0.0.1
```

```bash
echo "go-demo-5:
  ingress:
    host: go-demo-5.$ADDR" \
    | tee -a helm/values.yaml

cat helm/values.yaml
```

```yaml
chartmuseum:
  env:
    open:
      DISABLE_API: false
      AUTH_ANONYMOUS_GET: true
    secret:
      BASIC_AUTH_USER: admin # Change me!
      BASIC_AUTH_PASS: admin # Change me!
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 80m
      memory: 64Mi
  persistence:
    enabled: true
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "nginx"
      ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
    hosts:
      cm.18.219.191.38.nip.io: # Change me!
      - /

jenkins:
  Master:
    ImageTag: "2.129-alpine"
    Cpu: "500m"
    Memory: "500Mi"
    ServiceType: ClusterIP
    ServiceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    GlobalLibraries: true
    InstallPlugins:
    - durable-task:1.22
    - workflow-durable-task-step:2.19
    - blueocean:1.7.1
    - credentials:2.1.18
    - ec2:1.39
    - git:3.9.1
    - git-client:2.7.3
    - github:1.29.2
    - kubernetes:1.12.0
    - pipeline-utility-steps:2.1.0
    - pipeline-model-definition:1.3.1
    - script-security:1.44
    - slack:2.3
    - thinBackup:1.9
    - workflow-aggregator:2.5
    - ssh-slaves:1.26
    - ssh-agent:1.15
    - jdk-tool:1.1
    - command-launcher:1.2
    - github-oauth:0.29
    - google-compute-engine:1.0.4
    - pegdown-formatter:1.3
    Ingress:
      Annotations:
        kubernetes.io/ingress.class: "nginx"
        nginx.ingress.kubernetes.io/ssl-redirect: "false"
        nginx.ingress.kubernetes.io/proxy-body-size: 50m
        nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
        ingress.kubernetes.io/ssl-redirect: "false"
        ingress.kubernetes.io/proxy-body-size: 50m
        ingress.kubernetes.io/proxy-request-buffering: "off"
    HostName: jenkins.18.219.191.38.nip.io # Change me!
    CustomConfigMap: true
    CredentialsXmlSecret: jenkins-credentials
    SecretsFilesSecret: jenkins-secrets
    DockerVM: false
  rbac:
    install: true
go-demo-5:
  ingress:
    host: go-demo-5.18.219.191.38.nip.io
```

```bash
git add .

git commit -m "Added go-demo-5"

git push

helm dependency update helm
```

```
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "local" chart repository (http://127.0.0.1:8879/charts):
        Get http://127.0.0.1:8879/charts/index.yaml: dial tcp 127.0.0.1:8879: connect: connection refused
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 3 charts
Downloading chartmuseum from repo https://kubernetes-charts.storage.googleapis.com
Downloading jenkins from repo https://kubernetes-charts.storage.googleapis.com
Downloading go-demo-5 from repo http://cm.18.219.191.38.nip.io
Deleting outdated charts
```

```bash
ls -1 helm/charts
```

```
chartmuseum-1.6.0.tgz
go-demo-5-0.0.1.tgz
jenkins-0.16.6.tgz
```

```bash
helm upgrade prod helm \
    --namespace prod
```

```
Release "prod" has been upgraded. Happy Helming!
LAST DEPLOYED: Wed Aug  8 23:10:45 2018
NAMESPACE: prod
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME                TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)    AGE
prod-chartmuseum    ClusterIP  100.66.187.127  <none>       8080/TCP   4h
prod-go-demo-5      ClusterIP  100.64.173.243  <none>       8080/TCP   1s
prod-go-demo-5-db   ClusterIP  None            <none>       27017/TCP  1s
prod-jenkins-agent  ClusterIP  100.66.213.155  <none>       50000/TCP  4h
prod-jenkins        ClusterIP  100.67.196.236  <none>       8080/TCP   4h

==> v1/Secret
NAME              TYPE    DATA  AGE
prod-chartmuseum  Opaque  2     4h
prod-jenkins      Opaque  2     4h

==> v1beta1/ClusterRoleBinding
NAME                       AGE
prod-jenkins-role-binding  4h

==> v1beta1/RoleBinding
NAME               AGE
prod-go-demo-5-db  1s
build              4h
build              4h

==> v1beta1/Role
NAME               AGE
prod-go-demo-5-db  1s

==> v1beta1/Deployment
NAME              DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
prod-chartmuseum  1        1        1           1          4h
prod-jenkins      1        1        1           1          4h

==> v1beta2/Deployment
prod-go-demo-5  3  3  3  0  1s

==> v1beta2/StatefulSet
NAME               DESIRED  CURRENT  AGE
prod-go-demo-5-db  3        1        1s

==> v1beta1/Ingress
NAME              HOSTS                           ADDRESS           PORTS  AGE
prod-chartmuseum  cm.18.219.191.38.nip.io         a097d24929b28...  80     4h
prod-go-demo-5    go-demo-5.18.219.191.38.nip.io  80                1s
prod-jenkins      jenkins.18.219.191.38.nip.io    a097d24929b28...  80  4h

==> v1/ConfigMap
NAME                DATA  AGE
prod-jenkins        4     4h
prod-jenkins-tests  1     4h

==> v1/PersistentVolumeClaim
NAME              STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
prod-chartmuseum  Bound   pvc-5f483fc7-9b29-11e8-a994-0a37c44add8a  8Gi       RWO           gp2           4h
prod-jenkins      Bound   pvc-5f49d107-9b29-11e8-a994-0a37c44add8a  8Gi       RWO           gp2           4h

==> v1/ServiceAccount
NAME               SECRETS  AGE
prod-go-demo-5-db  1        1s
prod-jenkins       1        4h
build              1        4h

==> v1/Pod(related)
NAME                               READY  STATUS             RESTARTS  AGE
prod-chartmuseum-68bc575fb7-dn6h5  1/1    Running            0         4h
prod-go-demo-5-66c9d649bd-kq45m    0/1    ContainerCreating  0         1s
prod-go-demo-5-66c9d649bd-lgjb7    0/1    ContainerCreating  0         1s
prod-go-demo-5-66c9d649bd-pwnjg    0/1    ContainerCreating  0         1s
prod-jenkins-676cc64756-bj45v      1/1    Running            0         4h
prod-go-demo-5-db-0                0/2    Pending            0         1s
```

```bash
kubectl -n prod get pods
```

```
NAME                                READY     STATUS              RESTARTS   AGE
prod-chartmuseum-68bc575fb7-dn6h5   1/1       Running             0          4h
prod-go-demo-5-66c9d649bd-kq45m     1/1       Running             2          51s
prod-go-demo-5-66c9d649bd-lgjb7     1/1       Running             2          51s
prod-go-demo-5-66c9d649bd-pwnjg     1/1       Running             2          51s
prod-go-demo-5-db-0                 2/2       Running             0          51s
prod-go-demo-5-db-1                 0/2       ContainerCreating   0          15s
prod-jenkins-676cc64756-bj45v       1/1       Running             0          4h
```

```bash
kubectl -n prod rollout status \
    deployment prod-go-demo-5
```

```
deployment "prod-go-demo-5" successfully rolled out
```

```bash
curl -i "http://go-demo-5.$ADDR/demo/hello"
```

```
HTTP/1.1 200 OK
Server: nginx/1.13.9
Date: Wed, 08 Aug 2018 21:12:31 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 14
Connection: keep-alive

hello, world!
```

```bash
kubectl -n prod \
    describe deploy prod-go-demo-5
```

```yaml
Name:                   prod-go-demo-5
Namespace:              prod
CreationTimestamp:      Wed, 08 Aug 2018 23:10:45 +0200
Labels:                 app=go-demo-5
                        chart=go-demo-5-0.0.1
                        heritage=Tiller
                        release=prod
Annotations:            deployment.kubernetes.io/revision=1
Selector:               app=go-demo-5,release=prod
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=go-demo-5
           release=prod
  Containers:
   api:
    Image:      vfarcic/go-demo-5:18.08.08-3
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     200m
      memory:  20Mi
    Requests:
      cpu:      100m
      memory:   10Mi
    Liveness:   http-get http://:8080/demo/hello delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/demo/hello delay=0s timeout=1s period=1s #success=1 #failure=3
    Environment:
      DB:    prod-go-demo-5-db
    Mounts:  <none>
  Volumes:   <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   prod-go-demo-5-66c9d649bd (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  2m    deployment-controller  Scaled up replica set prod-go-demo-5-66c9d649bd to 3
```

```bash
open "http://$JENKINS_ADDR/blue/organizations/jenkins/go-demo-5/branches"

# Click the play button from the right side of the *master* row.

# Wait until the build is finished

# TODO: Screenshot

cd ../go-demo-5

# Increment the version of *helm/go-demo-5/Chart.yaml*

git add .

git commit -m "Version bump"

git push

open "http://$JENKINS_ADDR/blue/organizations/jenkins/go-demo-5/branches"

# Click the play button from the right side of the *master* row.

# Wait until the build is finished

cd ../k8s-prod

cat Jenkinsfile.orig

cat Jenkinsfile.orig \
    | sed -e "s@acme.com@$ADDR@g" \
    | tee Jenkinsfile

# Increment go-demo-5 version in helm/requirements.yaml

# Increment version in helm/Chart.yaml

git add .

git commit -m "Jenkinsfile"

git push

open "http://$JENKINS_ADDR/blue/pipelines"

# Click *New Pipeline"
# Select *GitHub*
# Select the organization
# Select *k8s-prod* repository
# Click the *Create Pipelin* button

# Wait until the new build is finished
```

![Figure 7-TODO: k8s-prod build screen](images/ch08/jenkins-k8s-prod-build.png)

```bash
helm history prod
```

```
REVISION        UPDATED                         STATUS          CHART           DESCRIPTION
1               Wed Aug  8 18:37:42 2018        SUPERSEDED      prod-env-0.0.1  Install complete
2               Wed Aug  8 23:10:45 2018        SUPERSEDED      prod-env-0.0.1  Upgrade complete
3               Wed Aug  8 23:47:35 2018        DEPLOYED        prod-env-0.0.2  Upgrade complete
```

```bash
kubectl -n prod \
    describe deploy prod-go-demo-5
```

```yaml
Name:                   prod-go-demo-5
Namespace:              prod
CreationTimestamp:      Wed, 08 Aug 2018 23:10:45 +0200
Labels:                 app=go-demo-5
                        chart=go-demo-5-0.0.2
                        heritage=Tiller
                        release=prod
Annotations:            deployment.kubernetes.io/revision=2
Selector:               app=go-demo-5,release=prod
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=go-demo-5
           release=prod
  Containers:
   api:
    Image:      vfarcic/go-demo-5:18.08.08-5
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     200m
      memory:  20Mi
    Requests:
      cpu:      100m
      memory:   10Mi
    Liveness:   http-get http://:8080/demo/hello delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/demo/hello delay=0s timeout=1s period=1s #success=1 #failure=3
    Environment:
      DB:    prod-go-demo-5-db
    Mounts:  <none>
  Volumes:   <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   prod-go-demo-5-666b96c46 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  40m   deployment-controller  Scaled up replica set prod-go-demo-5-66c9d649bd to 3
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled up replica set prod-go-demo-5-666b96c46 to 1
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled down replica set prod-go-demo-5-66c9d649bd to 2
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled up replica set prod-go-demo-5-666b96c46 to 2
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled down replica set prod-go-demo-5-66c9d649bd to 1
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled up replica set prod-go-demo-5-666b96c46 to 3
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled down replica set prod-go-demo-5-66c9d649bd to 0
```

```bash
curl -i "http://go-demo-5.$ADDR/demo/hello"
```

```
HTTP/1.1 200 OK
Server: nginx/1.13.9
Date: Wed, 08 Aug 2018 21:51:57 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 14
Connection: keep-alive

hello, world!
```