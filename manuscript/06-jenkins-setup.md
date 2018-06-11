## Chapter

- [X] Code
- [ ] Code review Docker for Mac/Windows
- [X] Code review minikube
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
- [ ] Publish on LeanPub.co

# Jenkins Setup

## Creating A Cluster And Retrieving Its IP

TODO: Rewrite

You know the drill. Create a new cluster or reuse the one you dedicated to the exercises.

First, we'll go to the local copy of the *vfarcic/k8s-specs* repository and make sure that we have the latest revision. Who knows? I might have changed something since you read the last chapter.

I> All the commands from this chapter are available in the [05-chart-museum.sh](https://gist.github.com/e0657623045b43259fe258a146f05e1a) Gist.

```bash
cd k8s-specs

git pull
```

The requirements for the cluster are now slightly different. We'll need **Helm server** (**tiller**). On top of that, if you are a **minishift** user, you'll need a cluster with 4GB RAM.

For your convenience, the new Gists and the specs are available.

* [docker4mac-helm.sh](TODO): **Docker for Mac** with 3 CPUs, 3 GB RAM, with **nginx Ingress**, and with **tiller**.
* [minikube-ip.sh](TODO): **minikube** with 3 CPUs, 3 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, and with **tiller**.
* [kops-helm.sh](TODO): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, and with **tiller**. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).
* [minishift-helm.sh](TODO): **minishift** with 3 CPUs, 3 GB RAM, with version 1.16+, and with **tiller**.
* [gke-helm.sh](TODO): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-2 (2 CPUs, 1.8 GB RAM) nodes (one in each zone), and with **nginx Ingress** controller running on top of the "standard" one that comes with GKE, and with **tiller**. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files and Helm Charts if you prefer NOT to install nginx Ingress.

NOTE: Retrieval of cluster IP is now in the Gists

## Running Jenkins

```bash
JENKINS_ADDR="jenkins.$LB_IP.nip.io"

echo $JENKINS_ADDR
```

```
jenkins.52.15.140.221.nip.io
```

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$JENKINS_ADDR

kubectl -n jenkins \
    rollout status deployment jenkins
```

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "jenkins" successfully rolled out
```

```bash
open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS
```

```
Ucg2tab4FK
```

```bash
# Login with user `admin`

# NOTE: Should change authentication
```

## Tools in the same Namespace

```bash
# Click the *New Item* link in the left-hand menu

# Type *my-k8s-job* in the *item name* field

# Select *Pipeline* as the type

# Click the *OK* button

# Click the *Pipeline* tab

# Write the script that follows in the *Pipeline Script* field
```

```groovy
podTemplate(
    label: "kubernetes",
    containers: [
        containerTemplate(name: "maven", image: "maven:alpine", ttyEnabled: true, command: "cat"),
        containerTemplate(name: "golang", image: "golang:alpine", ttyEnabled: true, command: "cat")
    ]
) {
    node("kubernetes") {
        container("maven") {
            stage("build") {
                sh "mvn --version"
            }
            stage("unit-test") {
                sh "java -version"
            }
        }
        container("golang") {
            stage("deploy") {
                sh "go version"
            }
        }
    }
}
```

```bash
# Click the *Save* button

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# Click the newly created build
```

```bash
kubectl -n jenkins get pods
```

```
NAME                        READY     STATUS              RESTARTS   AGE
jenkins-c7f7c77b4-cgxx8     1/1       Running             0          5m
jenkins-slave-6hssz-250tw   0/3       ContainerCreating   0          16s
```

```bash
# Go back to Jenkins UI and wait until it starts running

# Wait until its finished and it's green

open "http://$JENKINS_ADDR/job/my-k8s-job/configure"

# Replace the script with the one that follows
```

```groovy
podTemplate(label: "kubernetes", yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version"
            }
        }
    }
}
```

```bash
# Click the *Save* button

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

kubectl -n jenkins get pods
```

```
NAME                        READY     STATUS              RESTARTS   AGE
jenkins-c7f7c77b4-cgxx8     1/1       Running             0          16m
jenkins-slave-qnkwc-s6jfx   0/5       ContainerCreating   0          19s
```

```bash
# Observe the results in UI
```

NOTE: Output from the `helm version` command

```
[my-k8s-job] Running shell script

+ helm version

Client: &version.Version{SemVer:"v2.8.2", GitCommit:"a80231648a1473929271764b920a8e346f6de844", GitTreeState:"clean"}

EXITCODE   0Error: cannot connect to Tiller

script returned exit code 1
```

```bash
# Docker For Mac/Windows allows unrestricted communication from Pods to Kube API. You won't see that error.

kubectl -n jenkins get pods
```

```
NAME                      READY     STATUS    RESTARTS   AGE
jenkins-c7f7c77b4-cgxx8   1/1       Running   0          42m
```

## Tools in a Different Namespace

```bash
open "http://$JENKINS_ADDR/job/my-k8s-job/configure"
```

```groovy
podTemplate(
    label: "kubernetes",
    namespace: "go-demo-3-build",
    serviceAccount: "build",
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version --tiller-namespace go-demo-3-build"
            }
        }
    }
}
```

```bash
# Click *Save*

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

# Click on the row with the latest build

# `Waiting for next available executor`

kubectl -n go-demo-3-build \
    get pods
```

```
No resources found.
```

```bash
# Click the *Stop* button in the top-right corner

cat ../go-demo-3/k8s/build-ns.yml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo-3-build

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: build
  namespace: go-demo-3-build

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: build
  namespace: go-demo-3-build
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
  namespace: go-demo-3-build
spec:
  limits:
  - default:
      memory: 200Mi
      cpu: 0.2
    defaultRequest:
      memory: 100Mi
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
  namespace: go-demo-3-build
spec:
  hard:
    requests.cpu: 2
    requests.memory: 3Gi
    limits.cpu: 3
    limits.memory: 4Gi
    pods: 15
```

```bash
kubectl apply \
    -f ../go-demo-3/k8s/build-ns.yml \
    --record
```

```
namespace "go-demo-3-build" created
serviceaccount "build" created
rolebinding.rbac.authorization.k8s.io "build" created
limitrange "build" created
resourcequota "build" created
```

```bash
cat ../go-demo-3/k8s/prod-ns.yml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo-3

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: build
  namespace: go-demo-3
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: build
  namespace: go-demo-3-build

---

apiVersion: v1
kind: LimitRange
metadata:
  name: build
  namespace: go-demo-3
spec:
  limits:
  - default:
      memory: 200Mi
      cpu: 0.2
    defaultRequest:
      memory: 100Mi
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
  namespace: go-demo-3
spec:
  hard:
    requests.cpu: 2
    requests.memory: 3Gi
    limits.cpu: 3
    limits.memory: 4Gi
    pods: 15
```

```bash
kubectl apply \
    -f ../go-demo-3/k8s/prod-ns.yml \
    --record
```

```
namespace "go-demo-3" created
rolebinding.rbac.authorization.k8s.io "build" created
limitrange "build" created
resourcequota "build" created
```

```bash
kubectl get ns
```

```
NAME              STATUS    AGE
default           Active    3h
go-demo-3         Active    1m
go-demo-3-build   Active    5m
jenkins           Active    3h
kube-public       Active    3h
kube-system       Active    3h
```

```bash
open "http://$JENKINS_ADDR/configure"

# Change *Jenkins URL* in the *Cloud* section to *http://jenkins.jenkins:8080*

# Change *Jenkins tunnel* to *jenkins-agent.jenkins:50000*

# Click the *Save* button

helm init --service-account build \
    --tiller-namespace go-demo-3-build
```

```
$HELM_HOME has been configured at /Users/vfarcic/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

```bash
kubectl -n go-demo-3-build \
    rollout status \
    deployment tiller-deploy
```

```
deployment "tiller-deploy" successfully rolled out
```

```bash
open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

# Click the row of the new build

kubectl -n go-demo-3-build \
    get pods
```

```
NAME                            READY     STATUS    RESTARTS   AGE
jenkins-slave-xfl6l-f5ftn       5/5       Running   0          36s
tiller-deploy-f844d6b64-gmdxb   1/1       Running   0          3m
```

```bash
# Observe that the build is green
```

![Figure 6-TODO: Jenkins job for testing tools](images/ch06/jenkins-tools-build.png)

## Docker Node

### Vagrant w/VirtualBox (Docker for Mac/Windows, minikube)

```bash
cd cd/docker-build

cat Vagrantfile
```

```ruby
# vi: set ft=ruby :
 
Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/xenial64"

    config.vm.define "docker-build" do |node|
      node.vm.hostname = "docker-build"
      node.vm.network :private_network, ip: "10.100.198.200"
      node.vm.provision :shell, inline: "apt update && apt install -y docker.io && apt install -y default-jre"
    end
end
```

```bash
vagrant up

vagrant ssh -c "sudo docker version"
```

```
...
Client:
 Version:      1.13.1
 API version:  1.26
 Go version:   go1.6.2
 Git commit:   092cba3
 Built:        Thu Nov  2 20:40:23 2017
 OS/Arch:      linux/amd64

Server:
 Version:      1.13.1
 API version:  1.26 (minimum version 1.12)
 Go version:   go1.6.2
 Git commit:   092cba3
 Built:        Thu Nov  2 20:40:23 2017
 OS/Arch:      linux/amd64
 Experimental: false
Connection to 127.0.0.1 closed.
```

```bash
open "http://$JENKINS_ADDR/computer/new"

# Type *docker-build* as the *Node name*

# Select *Permanent Agent*

# Click the *OK* button
```

![Figure 6-TODO: Jenkins screen for adding new nodes/agents](images/ch06/jenkins-new-node.png)

```bash
# Type *2* as *# of executors*

# Type */tmp* as *Remote root directory*

# Type *docker ubuntu linux* as *Labels*

# Select *Launch slave agents via SSH*

# Type *10.100.198.200* as *Host*

# Click *Add* dropdown next to *Credentials* and select *Jenkins*

# Select *SSH Username with private key* as the *Kind*

# Type *vagrant* as the *Username*

# Select *Enter directly* as the *Private Key*

cat .vagrant/machines/docker-build/virtualbox/private_key

# Copy the output and paste it to the *Key* field

# Type *docker-build* as the *ID*

# Click the *Add* button

# Select *vagrant* in the *Credentials* drop-down list

# Select *Not verifying Verification Strategy* as the *Host Key Verification Strategy*
```

![Figure 6-TODO: Jenkins node/agent configuration screen](images/ch06/jenkins-node-config.png)

```bash
# Click the *Save* button

# Wait a few moments and refresh the screen
```

![Figure 6-TODO: Jenkins nodes/agents screen](images/ch06/jenkins-nodes.png)

```bash
cd ../../
```

### AWS Manual

TODO: Review

```bash
aws ec2 create-security-group \
    --description "For building Docker images" \
    --group-name docker \
    | tee cluster/sg.json

SG_ID=$(cat cluster/sg.json \
    | jq -r ".GroupId")

echo "export SG_ID=$SG_ID" \
    | tee -a cluster/kops

aws ec2 \
    authorize-security-group-ingress \
    --group-name docker \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Install Packer

packer build -machine-readable \
    jenkins/docker.json \
    | tee cluster/docker-packer.log

AMI_ID=$(grep 'artifact,0,id' \
    cluster/docker-packer.log \
    | cut -d: -f2)

echo $AMI_ID

echo "export AMI_ID=$AMI_ID" \
    | tee -a cluster/kops

aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name devops23 \
    --security-groups docker \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=docker}]' \
    | tee cluster/docker-ec2.json

INSTANCE_ID=$(cat \
    cluster/docker-ec2.json \
    | jq -r ".Instances[0].InstanceId")

aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    | jq -r ".Reservations[0]\
    .Instances[0].State.Name"

# Wait until it's `running`, and then wait some more

aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    | jq -r ".Reservations[0]\
    .Instances[0].PublicIpAddress"

PUBLIC_IP=$(aws ec2 \
    describe-instances \
    --instance-ids $INSTANCE_ID \
    | jq -r ".Reservations[0]\
    .Instances[0].PublicIpAddress")

ssh -i cluster/devops23.pem \
    ubuntu@$PUBLIC_IP

docker version

export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git

cd go-demo-3

export DH_USER=[...]

docker image build \
    -t $DH_USER/go-demo-3:1.0-beta .

docker login -u $DH_USER

docker image push \
    $DH_USER/go-demo-3:1.0-beta

exit

aws ec2 terminate-instances \
    --instance-ids $INSTANCE_ID
```

## Docker Jenkins AWS

TODO: Review

```bash
open "http://$JENKINS_ADDR/configure"

# Click the *Add a new cloud* drop-down list
# Choose *Amazon EC2*
# Type *docker-agents* as the *Name*
# Click *Add* next to *Amazon EC2 Credentials*
# Choose *Jenkins*
# Choose *AWS Credentials* as the *Kind*
# Type *aws* as the *ID*
# Type *aws* as the *Description*

echo $AWS_ACCESS_KEY_ID

# Copy the output and paste it into the *Access Key ID* field

echo $AWS_SECRET_ACCESS_KEY

# Copy the output and paste it into the *Secret Access Key* field
# Click the *Add* button
# Choose the newly created credentials
# Select *us-east-2* as the *Region*

cat cluster/devops23.pem

# Copy the output and paste it into the *EC2 Key Pair's Private Key* field
# Click the *Test Connection* button
# Click the *Add* button next to *AMIs*
# Type *docker* as the *Description*

echo $AMI_ID

# Copy the output and paste it into the *AMI ID* field
# Click the *Check AMI* button
# Select *T2Micro* as the *Instance Type*
# Type *docker* as the *Security group names*
# Type *ubuntu* as the *Remote user*
# Type *22* as the *Remote ssh port*
# Type *docker* as labels
# Type *1* as *Idle termination time*
# Click the *Save* button

open "http://$JENKINS_ADDR/job/my-k8s-job/configure"
```

```groovy
podTemplate(
    label: "kubernetes",
    containers: [
        containerTemplate(name: "maven", image: "maven:alpine", ttyEnabled: true, command: "cat"),
        containerTemplate(name: "golang", image: "golang:alpine", ttyEnabled: true, command: "cat")
    ],
    namespace: "go-demo-3-build"
) {
    node("docker") {
        stage("build") {
            sh "sleep 5"
            sh "docker version"
        }    
    }
    node("kubernetes") {
        container("maven") {
            stage("unit-test") {
                sh "sleep 5"
                sh "java -version"
            }
        }
        container("golang") {
            stage("deploy") {
                sh "sleep 5"
                sh "go version"
            }
        }
    }
}
```

## Test Docker Builds

```bash
open "http://$JENKINS_ADDR/job/my-k8s-job/configure"
```

```groovy
podTemplate(
    label: "kubernetes",
    namespace: "go-demo-3-build",
    serviceAccount: "build",
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("docker") {
        stage("docker") {
            sh "sudo docker version"
        }
    }
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version --tiller-namespace go-demo-3-build"
            }
        }
    }
}
```

```bash
# Click the *Save* button

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

# Click the row with the new build

# Wait until all the stages are executed
```

![Figure 6-TODO: Jenkins job for testing tools](images/ch06/jenkins-tools-with-docker-build)

## Automate Setup

```bash
mkdir -p cluster/jenkins/secrets

kubectl -n jenkins \
    describe deployment jenkins
```

```
Name:                   jenkins
Namespace:              jenkins
CreationTimestamp:      Mon, 11 Jun 2018 19:13:37 +0200
Labels:                 chart=jenkins-0.16.1
                        component=jenkins-jenkins-master
                        heritage=Tiller
                        release=jenkins
Annotations:            deployment.kubernetes.io/revision=1
Selector:               component=jenkins-jenkins-master
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:           app=jenkins
                    chart=jenkins-0.16.1
                    component=jenkins-jenkins-master
                    heritage=Tiller
                    release=jenkins
  Annotations:      checksum/config=67ba4de5bdd4b6e03bc4256e9d73c9ede8ba5b0618af4be548ccfe93eb7d8498
  Service Account:  jenkins
  Init Containers:
   copy-default-config:
    Image:      jenkins/jenkins:2.116-alpine
    Port:       <none>
    Host Port:  <none>
    Command:
      sh
      /var/jenkins_config/apply_config.sh
    Environment:  <none>
    Mounts:
      /usr/share/jenkins/ref/secrets/ from secrets-dir (rw)
      /var/jenkins_config from jenkins-config (rw)
      /var/jenkins_home from jenkins-home (rw)
      /var/jenkins_plugins from plugin-dir (rw)
  Containers:
   jenkins:
    Image:       jenkins/jenkins:2.116-alpine
    Ports:       8080/TCP, 50000/TCP
    Host Ports:  0/TCP, 0/TCP
    Args:
      --argumentsRealm.passwd.$(ADMIN_USER)=$(ADMIN_PASSWORD)
      --argumentsRealm.roles.$(ADMIN_USER)=admin
    Requests:
      cpu:      500m
      memory:   500Mi
    Liveness:   http-get http://:http/login delay=60s timeout=5s period=10s #success=1 #failure=12
    Readiness:  http-get http://:http/login delay=60s timeout=1s period=10s #success=1 #failure=3
    Environment:
      JAVA_OPTS:       
      JENKINS_OPTS:    
      ADMIN_PASSWORD:  <set to the key 'jenkins-admin-password' in secret 'jenkins'>  Optional: false
      ADMIN_USER:      <set to the key 'jenkins-admin-user' in secret 'jenkins'>      Optional: false
    Mounts:
      /usr/share/jenkins/ref/plugins/ from plugin-dir (rw)
      /usr/share/jenkins/ref/secrets/ from secrets-dir (rw)
      /var/jenkins_config from jenkins-config (ro)
      /var/jenkins_home from jenkins-home (rw)
  Volumes:
   jenkins-config:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      jenkins
    Optional:  false
   plugin-dir:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  
   secrets-dir:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  
   jenkins-home:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  jenkins
    ReadOnly:   false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  jenkins-c7f7c77b4 (1/1 replicas created)
NewReplicaSet:   <none>
Events:          <none>
```

```bash
kubectl -n jenkins \
    get pods \
    -l component=jenkins-jenkins-master
```

```
NAME                      READY     STATUS    RESTARTS   AGE
jenkins-c7f7c77b4-cgxx8   1/1       Running   0          3h
```

```bash
JENKINS_POD=$(kubectl -n jenkins \
    get pods \
    -l component=jenkins-jenkins-master \
    -o jsonpath='{.items[0].metadata.name}')

echo $JENKINS_POD
```

```
jenkins-c7f7c77b4-cgxx8
```

```bash
kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/credentials.xml \
    cluster/jenkins

kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/secrets/hudson.util.Secret \
    cluster/jenkins/secrets

kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/secrets/master.key \
    cluster/jenkins/secrets

helm delete jenkins --purge
```

```
release "jenkins" deleted
```

```bash
helm dependency update helm/jenkins
```

```
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "local" chart repository (http://127.0.0.1:8879/charts):
        Get http://127.0.0.1:8879/charts/index.yaml: dial tcp 127.0.0.1:8879: connect: connection refused
...Unable to get an update from the "chartmuseum" chart repository (http://cm.127.0.0.1.nip.io):
        Get http://cm.127.0.0.1.nip.io/index.yaml: dial tcp 127.0.0.1:80: connect: connection refused
...Successfully got an update from the "azure-samples" chart repository
...Successfully got an update from the "monocular" chart repository
...Successfully got an update from the "coreos" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "jenkins-x" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading jenkins from repo https://kubernetes-charts.storage.googleapis.com
Deleting outdated charts
```

```bash
helm inspect values helm/jenkins
```

```yaml
jenkins:
  Master:
    ImageTag: "2.126-alpine"
    Cpu: "500m"
    Memory: "500Mi"
    ServiceType: ClusterIP
    ServiceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    InstallPlugins:
      - blueocean:1.5.0
      - credentials:2.1.16
      - ec2:1.39
      - git:3.9.1
      - git-client:2.7.2
      - github:1.29.1
      - kubernetes:1.7.1
      - pipeline-utility-steps:2.1.0
      - script-security:1.44
      - slack:2.3
      - thinBackup:1.9
      - workflow-aggregator:2.5
      - ssh-slaves:1.26
      - ssh-agent:1.15
      - jdk-tool:1.1
      - command-launcher:1.2
      - github-oauth:0.29
    Ingress:
      Annotations:
        nginx.ingress.kubernetes.io/ssl-redirect: "false"
        nginx.ingress.kubernetes.io/proxy-body-size: 50m
        nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
        ingress.kubernetes.io/ssl-redirect: "false"
        ingress.kubernetes.io/proxy-body-size: 50m
        ingress.kubernetes.io/proxy-request-buffering: "off"
    HostName: jenkins.acme.com
    CustomConfigMap: true
    CredentialsXmlSecret: jenkins-credentials
    SecretsFilesSecret: jenkins-secrets
  rbac:
    install: true
```

```bash
kubectl -n jenkins \
    create secret generic \
    jenkins-credentials \
    --from-file cluster/jenkins/credentials.xml

kubectl -n jenkins \
    create secret generic \
    jenkins-secrets \
    --from-file cluster/jenkins/secrets

helm install helm/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set jenkins.Master.HostName=$JENKINS_ADDR

kubectl -n jenkins describe cm jenkins
```

```
Name:         jenkins
Namespace:    jenkins
Labels:       <none>
Annotations:  <none>

Data
====
apply_config.sh:
----
mkdir -p /usr/share/jenkins/ref/secrets/;
echo "false" > /usr/share/jenkins/ref/secrets/slave-to-master-security-kill-switch;
cp -n /var/jenkins_config/config.xml /var/jenkins_home;
cp -n /var/jenkins_config/jenkins.CLI.xml /var/jenkins_home;
mkdir -p /var/jenkins_home/nodes/docker-build
cp /var/jenkins_config/docker-build /var/jenkins_home/nodes/docker-build/config.xml;
# Install missing plugins
cp /var/jenkins_config/plugins.txt /var/jenkins_home;
rm -rf /usr/share/jenkins/ref/plugins/*.lock
/usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;
# Copy plugins to shared volume
cp -n /usr/share/jenkins/ref/plugins/* /var/jenkins_plugins;
cp -n /var/jenkins_credentials/credentials.xml /var/jenkins_home;
cp -n /var/jenkins_secrets/* /usr/share/jenkins/ref/secrets;
config.xml:
----
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <disabledAdministrativeMonitors/>
  <version>2.126-alpine</version>
  <numExecutors>0</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
    <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
  </authorizationStrategy>
  <securityRealm class="hudson.security.LegacySecurityRealm"/>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
  <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
  <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
  <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds>
    <org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud plugin="kubernetes@1.7.1">
      <name>kubernetes</name>
      <templates>
        <org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
          <inheritFrom></inheritFrom>
          <name>default</name>
          <instanceCap>2147483647</instanceCap>
          <idleMinutes>0</idleMinutes>
          <label>jenkins-jenkins-slave</label>
          <nodeSelector></nodeSelector>
            <nodeUsageMode>NORMAL</nodeUsageMode>
          <volumes>
          </volumes>
          <containers>
            <org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
              <name>jnlp</name>
              <image>jenkins/jnlp-slave:3.10-1</image>
              <privileged>false</privileged>
              <alwaysPullImage>false</alwaysPullImage>
              <workingDir>/home/jenkins</workingDir>
              <command></command>
              <args>${computer.jnlpmac} ${computer.name}</args>
              <ttyEnabled>false</ttyEnabled>
              <resourceRequestCpu>200m</resourceRequestCpu>
              <resourceRequestMemory>256Mi</resourceRequestMemory>
              <resourceLimitCpu>200m</resourceLimitCpu>
              <resourceLimitMemory>256Mi</resourceLimitMemory>
              <envVars>
                <org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                  <key>JENKINS_URL</key>
                  <value>http://jenkins.jenkins:8080</value>
                </org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
              </envVars>
            </org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
          </containers>
          <envVars/>
          <annotations/>
          <imagePullSecrets/>
          <nodeProperties/>
        </org.csanchez.jenkins.plugins.kubernetes.PodTemplate></templates>
      <serverUrl>https://kubernetes.default</serverUrl>
      <skipTlsVerify>false</skipTlsVerify>
      <namespace>jenkins</namespace>
      <jenkinsUrl>http://jenkins.jenkins:8080</jenkinsUrl>
      <jenkinsTunnel>jenkins-agent.jenkins:50000</jenkinsTunnel>
      <containerCap>10</containerCap>
      <retentionTimeout>5</retentionTimeout>
      <connectTimeout>0</connectTimeout>
      <readTimeout>0</readTimeout>
    </org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud>
  </clouds>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>50000</slaveAgentPort>
  <disabledAgentProtocols>
    <string>JNLP-connect</string>
    <string>JNLP2-connect</string>
  </disabledAgentProtocols>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
  <noUsageStatistics>true</noUsageStatistics>
</hudson>
docker-build:
----
<?xml version='1.1' encoding='UTF-8'?>
<slave>
  <name>docker-build</name>
  <description></description>
  <remoteFS>/tmp</remoteFS>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.26">
    <host>10.100.198.200</host>
    <port>22</port>
    <credentialsId>docker-build</credentialsId>
    <maxNumRetries>0</maxNumRetries>
    <retryWaitTime>0</retryWaitTime>
    <sshHostKeyVerificationStrategy class="hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy"/>
  </launcher>
  <label>docker ubuntu</label>
  <nodeProperties/>
</slave>
jenkins.CLI.xml:
----
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.CLI>
  <enabled>false</enabled>
</jenkins.CLI>
plugins.txt:
----
blueocean:1.5.0
credentials:2.1.16
ec2:1.39
git:3.9.1
git-client:2.7.2
github:1.29.1
kubernetes:1.7.1
pipeline-utility-steps:2.1.0
script-security:1.44
slack:2.3
thinBackup:1.9
workflow-aggregator:2.5
ssh-slaves:1.26
ssh-agent:1.15
jdk-tool:1.1
command-launcher:1.2
github-oauth:0.29
Events:  <none>
```

```bash
kubectl -n jenkins \
    rollout status deployment jenkins

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

# Login with user `admin`

open "http://$JENKINS_ADDR/configure"

# Observe that the *cloud* section fields *Jenkins URL* and *Jenkins tunnel* are correctly populated.

open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/docker-build/update"

# Observe that the credential is created

open "http://$JENKINS_ADDR/computer"

# Observe that the *docker-build* agent is created and available

open "http://$JENKINS_ADDR/newJob"

# Type *my-k8s-job* as the job name

# Select *Pipeline* as the job type

# Click the *OK* button

# Click the *Pipeline* tab

# Copy the script that follows and paste it into the *Script* field.
```

```groovy
podTemplate(
    label: "kubernetes",
    namespace: "go-demo-3-build", 
    serviceAccount: "build",
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  - name: oc
    image: vfarcic/openshift-client
    command: ["sleep"]
    args: ["100000"]
  - name: golang
    image: golang:1.9
    command: ["sleep"]
    args: ["100000"]
  - name: helm
    image: vfarcic/helm:2.8.2
    command: ["sleep"]
    args: ["100000"]
"""
) {
    node("docker") {
        stage("docker") {
            sh "sudo docker version"
        }
    }
    node("kubernetes") {
        container("kubectl") {
            stage("kubectl") {
                sh "kubectl version"
            }
        }
        container("oc") {
            stage("oc") {
                sh "oc version"
            }
        }
        container("golang") {
            stage("golang") {
                sh "go version"
            }
        }
        container("helm") {
            stage("helm") {
                sh "helm version --tiller-namespace go-demo-3-build"
            }
        }
    }
}
```

```bash
# Click the *Save* button

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

# Click the row of the new build

# Wait until all the stages are finished and that it is green
```

## Destroying The Cluster

```bash
helm delete $(helm ls -q) --purge

kubectl delete ns \
    go-demo-3 go-demo-3-build jenkins

cd cd/docker-build

vagrant suspend

cd ../../
```
