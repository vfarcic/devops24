## Chapter

- [X] Code
- [X] Code review Docker for Mac/Windows
- [X] Code review minikube
- [X] Code review kops
- [X] Code review minishift
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

* [docker4mac-ip.sh](https://gist.github.com/66842a54ef167219dc18b03991c26edb): **Docker for Mac** with 3 CPUs, 3 GB RAM, with **nginx Ingress**, and with **tiller**.
* [minikube-ip.sh](https://gist.github.com/df5518b24bc39a8b8cca95cc37617221): **minikube** with 3 CPUs, 3 GB RAM, with `ingress`, `storage-provisioner`, and `default-storageclass` addons enabled, and with **tiller**.
* [kops-ip.sh](https://gist.github.com/7ee11f4dd8a130b51407582505c817cb): **kops in AWS** with 3 t2.small masters and 2 t2.medium nodes spread in three availability zones, with **nginx Ingress**, and with **tiller**. The Gist assumes that the prerequisites are set through [Appendix B](#appendix-b).
* [minishift-ip.sh](https://gist.github.com/fa902cc2e2f43dcbe88a60138dd20932): **minishift** with 3 CPUs, 3 GB RAM, with version 1.16+, and with **tiller**.
* [gke-ip.sh](https://gist.github.com/3e53def041591f3c0f61569d49ffd879): **Google Kubernetes Engine (GKE)** with 3 n1-highcpu-2 (2 CPUs, 1.8 GB RAM) nodes (one in each zone), and with **nginx Ingress** controller running on top of the "standard" one that comes with GKE, and with **tiller**. We'll use nginx Ingress for compatibility with other platforms. Feel free to modify the YAML files and Helm Charts if you prefer NOT to install nginx Ingress.

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
# If minishift
oc patch scc restricted -p '{"runAsUser":{"type": "RunAsAny"}}'

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
# If minishift
oc -n jenkins create route edge --service jenkins --insecure-policy Allow --hostname $JENKINS_ADDR

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

# Click the *Pipeline* tab

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

# Click the row with the new build

kubectl -n jenkins get pods
```

```
NAME                        READY     STATUS              RESTARTS   AGE
jenkins-c7f7c77b4-cgxx8     1/1       Running             0          16m
jenkins-slave-qnkwc-s6jfx   0/5       ContainerCreating   0          19s
```

```bash
# Observe the results in UI

# Click the *helm* stage once the build reaches it

# Click the *helm version* step
```

```
[my-k8s-job] Running shell script

+ helm version

Client: &version.Version{SemVer:"v2.8.2", GitCommit:"a80231648a1473929271764b920a8e346f6de844", GitTreeState:"clean"}
```

```bash
# It will take around 5 minutes until it's finished running
```

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

# Click the *Pipeline* tab

# Replace the script with the one that follows
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
# Click the *Save* button

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
# Docker For Mac/Windows is exception

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
kube-ingress      Active    3h
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

### Vagrant w/VirtualBox (Docker for Mac/Windows, minikube, minishift)

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

### AWS

```bash
# Make sure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_DEFAULT_REGION are set (e.g., `source cluster/kops`)

aws ec2 create-security-group \
    --description "For building Docker images" \
    --group-name docker \
    | tee cluster/sg.json
```

```json
{
    "GroupId": "sg-5fe96935"
}
```

```bash
SG_ID=$(cat cluster/sg.json \
    | jq -r ".GroupId")

echo $SG_ID
```

```
sg-5fe96935
```

```bash
echo "export SG_ID=$SG_ID" \
    | tee -a cluster/docker-ec2

aws ec2 \
    authorize-security-group-ingress \
    --group-name docker \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Install Packer

cat jenkins/docker-ami.json
```

```json
{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-2",
    "source_ami_filter": {
      "filters": {
        "virtualization-type": "hvm",
        "name": "*ubuntu-xenial-16.04-amd64-server-*",
        "root-device-type": "ebs"
      },
      "most_recent": true
    },
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "docker",
    "force_deregister": true
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sleep 15",
      "sudo apt-get clean",
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates nfs-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo add-apt-repository -y ppa:openjdk-r/ppa",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install -y openjdk-8-jdk"
    ]
  }]
}
```

```bash
packer build -machine-readable \
    jenkins/docker-ami.json \
    | tee cluster/docker-ami.log
```

```
...
1528917568,,ui,say,==> amazon-ebs: Deleting temporary security group...
1528917568,,ui,say,==> amazon-ebs: Deleting temporary keypair...
1528917568,,ui,say,Build 'amazon-ebs' finished.
1528917568,,ui,say,\n==> Builds finished. The artifacts of successful builds are:
1528917568,amazon-ebs,artifact-count,1
1528917568,amazon-ebs,artifact,0,builder-id,mitchellh.amazonebs
1528917568,amazon-ebs,artifact,0,id,us-east-2:ami-ea053b8f
1528917568,amazon-ebs,artifact,0,string,AMIs were created:\nus-east-2: ami-ea053b8f\n
1528917568,amazon-ebs,artifact,0,files-count,0
1528917568,amazon-ebs,artifact,0,end
1528917568,,ui,say,--> amazon-ebs: AMIs were created:\nus-east-2: ami-ea053b8f\n
```

```bash
AMI_ID=$(grep 'artifact,0,id' \
    cluster/docker-ami.log \
    | cut -d: -f2)

echo $AMI_ID
```

```
ami-ea053b8f
```

```bash
echo "export AMI_ID=$AMI_ID" \
    | tee -a cluster/docker-ec2

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

# TODO: Create the `devops23.pem` key

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
```

### GCE

```bash
gcloud iam service-accounts create jenkins
```

```
Created service account [jenkins].
```

```bash
export G_PROJECT=$(gcloud info \
    --format='value(config.project)')

export SA_EMAIL=$(gcloud iam \
    service-accounts list \
    --filter="name:jenkins" \
    --format='value(email)')

gcloud projects add-iam-policy-binding \
    --member serviceAccount:$SA_EMAIL \
    --role roles/compute.admin \
    $G_PROJECT

gcloud projects add-iam-policy-binding \
    --member serviceAccount:$SA_EMAIL \
    --role roles/iam.serviceAccountUser \
    $G_PROJECT

gcloud iam service-accounts \
    keys create \
    --iam-account $SA_EMAIL \
    cluster/gce-jenkins.json

cat cluster/gce-jenkins.json
```

```json
{
  "type": "service_account",
  "project_id": "devops24-book",
  "private_key_id": "dfce27679642cc7920d4535a82c0d18456ee4ebc",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "jenkins@devops24-book.iam.gserviceaccount.com",
  "client_id": "107184483848459278542",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/jenkins%40devops24-book.iam.gserviceaccount.com"
}
```

```bash
cat jenkins/docker-gce.json
```

```json
{
  "variables": {
    "project_id": ""
  },
  "builders": [{
    "type": "googlecompute",
    "account_file": "cluster/gce-jenkins.json",
    "project_id": "{{user `project_id`}}",
    "source_image_project_id": "ubuntu-os-cloud",
    "source_image_family": "ubuntu-1604-lts",
    "ssh_username": "ubuntu",
    "zone": "us-east1-b",
    "image_name": "docker"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sleep 15",
      "sudo apt-get clean",
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates nfs-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo add-apt-repository -y ppa:openjdk-r/ppa",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install -y openjdk-8-jdk"
    ]
  }]
}
```

```bash
packer build -machine-readable \
    --force \
    -var "project_id=$G_PROJECT" \
    jenkins/docker-gce.json \
    | tee cluster/docker-gce.log

G_IMAGE_ID=$(grep 'artifact,0,id' \
    cluster/docker-gce.log \
    | cut -d: -f2)

echo $G_IMAGE_ID
```

```
TODO: Output
```

```bash
open "http://$JENKINS_ADDR/configure"

# Click the *Add a new cloud* drop-down list (near the bottom of the screen)

# Select *Google Compute Engine*

# Type *docker* as the *Name*

echo $G_PROJECT

# Copy the output and paste it to the *Project ID* field

# Expand the *Add* drop-down list next to *Service Account Credentials*

# Select *Jenkins*

# Select *Google Service Account from private key* as the *Kind*

# Paste the name of the project to the *Project Name* field

# Click *Choose File* butotn in the *JSON Key* field

# Select *gce-jenkins.json* file we created earlier

# Click the *Add* button
```

![Figure 6-TODO: Jenkins Google credentials screen](images/ch06/jenkins-google-credentials.png)

```bash
# Select the newly created credential

# Click the *Add* button next to *Instance Configurations*

# Type *docker* as the *Name Prefix*

# Type *Docker build instances* as the *Description*

# Type *1* as the *Node Retention Time*

# Type *docker ubuntu linux* as the *Labels*

# Select *us-east1* as the *Region*

# Select *us-east1-b* as the *Region*

# Select *n1-standard-2* as the *Machine Type*

# Select *default* as the *Network*

# Select *default* as the *Subnetwork*

# Select $G_PROJECT as the *Image project*

# Select *docker* as the *Image name*

# Click the *Save* button
```

## Test Docker Builds

```bash
open "http://$JENKINS_ADDR/job/my-k8s-job/configure"

# Click the *Pipeline* tab

# Replace the script with the one that follows
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

# If GKE
kubectl -n jenkins cp \
    $JENKINS_POD:var/jenkins_home/gauth/ \
    cluster/jenkins/secrets

# If GKE
cd cluster/jenkins/secrets

# If GKE
G_AUTH_FILE=$(ls key*.json)

# If GKE
cd ../../../

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
    ImageTag: "2.121.1-alpine"
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
    # DockerAMI:
    # DockerEC2PrivateKey:
    # GProject:
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
    --set jenkins.Master.HostName=$JENKINS_ADDR \
    --set jenkins.Master.DockerAMI=$AMI_ID \
    --set jenkins.Master.GProject=$G_PROJECT \
    --set jenkins.Master.GAuthFile=$G_AUTH_FILE

kubectl -n jenkins describe cm jenkins
```

```
TODO: Output
```

```bash
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

# Login with user `admin`

open "http://$JENKINS_ADDR/configure"

# Observe that the *Cloud Kubernetes* section fields *Jenkins URL* and *Jenkins tunnel* are correctly populated.

# Observe that the *Cloud Kubernetes* section fields *Jenkins URL* and *Jenkins tunnel* are correctly populated.

# Only if AWS
cat cluster/devops23.pem

# Only if AWS
# Copy the output

# Only if AWS
# Scroll to the *EC2 Key Pair's Private Key* field

# Only if AWS
# Paste the output

# Only if Vagrant VM
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/docker-build/update"

# Only if AWS
open "http://$JENKINS_ADDR/credentials/store/system/domain/_/credential/aws/update"

# Observe that the credential is created

open "http://$JENKINS_ADDR/computer"

# Only if Vagrant VM
# Observe that the *docker-build* agent is created and available

# Only if AWS
# Observe that the *Provision via docker-agents* drop-down list is available

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

# Only if Vagrant
cd cd/docker-build

# Only if Vagrant
vagrant suspend

# Only if Vagrant
cd ../../
```
