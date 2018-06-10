## Chapter

- [X] Code
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
- [ ] Publish on LeanPub.co

# Jenkins Setup

## Creating A Cluster

TODO: Commands

```bash
# If Docker For Mac/Windows
LB_IP="192.168.0.189" # Use `ifconfig` to find the IP

echo $LB_IP
```

```
52.15.140.221
```

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

open "http://$JENKINS_ADDR"

JENKINS_PASS=$(kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo)

echo $JENKINS_PASS

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
                sh "sleep 5"
                sh "mvn --version"
            }
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

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

kubectl -n jenkins get pods

# Observe the results in UI
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
                sh "helm version"
            }
        }
    }
}
```

```bash
# Click *Save*

# Click the *Open Blue Ocean* link from the left-hand menu

# Click the *Run* button

# `Waiting for next available executor`

kubectl apply \
    -f ../go-demo-3/k8s/build-ns.yml \
    --record

kubectl apply \
    -f ../go-demo-3/k8s/prod-ns.yml \
    --record

kubectl get ns

open "http://$JENKINS_ADDR/configure"

# Change *Jenkins URL* to *http://jenkins.jenkins:8080*

# Change *Jenkins tunnel* to *jenkins-agent.jenkins:50000*

open "http://$JENKINS_ADDR/blue/organizations/jenkins/my-k8s-job/activity"

# Click the *Run* button

kubectl -n go-demo-3-build \
    get pods
```

## Docker Node

### VirtualBox

```bash
cd cd/docker-build

vagrant up

echo $JENKINS_PASS

echo $JENKINS_ADDR

vagrant ssh -c "sudo docker version"

open "http://$JENKINS_ADDR/computer/new"

# Type *docker-build* as the *Node name*

# Type *2* as *# of executors*

# Type */tmp* as *Remote root directory*

# Type *docker ubuntu* as *Labels*

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

# Click the *Save* button

# Wait a few moments and refresh the screen

cd ../../
```

### AWS Manual

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

## Docker Jenkins

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
                sh "helm version"
            }
        }
    }
}
```

## Automate Setup

```bash
mkdir -p cluster/jenkins/secrets

kubectl -n jenkins \
    describe deployment jenkins

kubectl -n jenkins \
    get pods \
    -l component=jenkins-jenkins-master

JENKINS_POD=$(kubectl -n jenkins \
    get pods \
    -l component=jenkins-jenkins-master \
    -o jsonpath='{.items[0].metadata.name}')

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

helm dependency update helm/jenkins

helm inspect values helm/jenkins

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
                sh "helm version"
            }
        }
    }
}
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
