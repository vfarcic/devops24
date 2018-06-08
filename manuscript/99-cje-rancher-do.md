# Installing CJE In Digital Ocean

The goal of this document is to describe how to install a Kubernets cluster in **DigitalOcean** using **Rancher**. Unlike AWS, GCE, and Azure, DigitalOcean does not offer many services and it's used mostly for spinning up VMs. As such, running a cluster in DigitalOcean is very close to what we'd experience when running a cluster **on-prem**, be it **bare metal or VMs** created with, for example, VMWare.

You will be able to choose between **Ubuntu** and **CentOS** as operating systems. For storage, the instructions explain setup of a Kubernetes **NFS** client. We'll use Digital Ocean's load balancer. The logic behind its setup should be applicable to any other load balancer.

Throughout the document, we'll have sets of validations aimed at confirming that the cluster is set up correctly and can be used to install **CJE**. Feel free to jump straight into validations if you already have an operational cluster. The validations are focused on **RBAC** and **ServiceAccounts**, **load balancers** and **Ingress**, and **storage**.

Once we're confident that the cluster works as expected, we'll proceed with the CJE installation. We'll create CJOC, a managed master, and a job that will run in a separate Namespace.

We'll try to do as much work as possible through CLI. In a few cases, it will not be possible (or practical) to accomplish some tasks through a terminal window, so we'll have to jump into UIs. Hopefully, that will be only for very brief periods. The reason for insisting on CLI over UI, lies in the fact that commands are easier to reproduce and lead us towards automation. More importantly, I have a medical condition that results in severe pain when surrounded with many colors. The only medically allowed ones are black, white, and green. Unfortunatelly, most UIs are not designed for people with disabilities like mine.

At some later date, this document will be extended with the following items. Feel free to suggest additional ones.

* HAProxy as external LB
* nginx as external LB
* Ceph storage
* Gluster storage
* Basic CNI networking
* Flannel networking
* Calico networking
* Weave networking

## Requirements

We'll need a few prerequisites first.

Please make sure that you have the following items.

* [kubectl](TODO): Used for communication with a Kubernetes cluster.
* [jq](TODO): Used for formatting and filtering of JSON outputs.
* [ssh-keygen](TODO): Used for generating SSH keys required for accessing nodes.
* [GitBash (if Windows)](TODO): Used for compatibility with other operating systems. Please use it **only if you are a Windows user**.
* [DigitalOcean account](TODO): That's where we'll create a cluster.
* [doctl](TODO): CLI used for interaction with DigitalOcean API.

## Creating A Rancher Server

We'll need a DigitalOcean token that will allow us to authenticate with its API. Please open the API Tokens screen.

```bash
open "https://cloud.digitalocean.com/settings/api/tokens"
```

> If you are a **Windows user**, you might not be able to use `open` command to interact with your browser. If that's the case, please replace `open` with `echo`, copy the output, and paste it into a new tab of your favorite browser.

Please type *cje* as the token name and click the *Generate Token* button. This is the first and the last time you will be able to see the token through DigitalOcean UI. Please store it somewhere safe. We'll need it soon.

Next, we'll create an SSH key that will allow us to enter into the virtual machines we'll create soon.

Please execute the command that follows.

```bash
ssh-keygen -t rsa
```

TODO: Continue

```bash
# Type `cje` as the file, answer with the enter key to the rest of the questions

doctl auth init
```

```
Using token [c8c54c9cd375eb144d5d5d556ade43be13bf3f6316152ea9de99bdab436c9331]

Validating token... OK
```

```bash
doctl compute ssh-key create cje \
    --public-key "$(cat cje.pub)"
```

```
ID       Name FingerPrint
21418650 cje  28:f8:51:f0...
```

```bash
KEY_ID=$(doctl compute ssh-key list \
    | grep cje \
    | awk '{print $1}')

echo $KEY_ID
```

```
21418650
```

```bash
# If Ubuntu
DISTRIBUTION=ubuntu-18-04-x64

# If CentOS
DISTRIBUTION=centos-7-x64

IMAGE_ID=$(doctl compute \
    image list-distribution \
    -o json \
    | jq ".[] | select(.slug==\"$DISTRIBUTION\").id")

echo $IMAGE_ID
```

```
34487567
```

```bash
doctl compute droplet create rancher \
    --enable-private-networking \
    --image $IMAGE_ID \
    --size s-2vcpu-4gb \
    --region nyc1 \
    --ssh-keys $KEY_ID
```

```
ID       Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image          Status Tags Features Volumes
96650503 rancher                                   4096   2     80   nyc1   CentOS 7.5 x64 new
```

```bash
RANCHER_IP=$(doctl compute droplet list \
    -o json | \
    jq -r '.[] | select(.name=="rancher").networks.v4[0].ip_address')

echo $RANCHER_IP
```

```
208.68.39.72
```

```bash
ssh -i cje root@$RANCHER_IP

# If Ubuntu
apt update

# If Ubuntu
apt install -y docker.io

# If CentOS
yum install -y \
    yum-utils \
    device-mapper-persistent-data \
    lvm2

# If CentOS
yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# If CentOS
yum install -y docker-ce

# If CentOS
systemctl start docker

docker version
```

```
Client:
 Version:      18.03.1-ce
 API version:  1.37
 Go version:   go1.9.5
 Git commit:   9ee9f40
 Built:        Thu Apr 26 07:20:16 2018
 OS/Arch:      linux/amd64
 Experimental: false
 Orchestrator: swarm

Server:
 Engine:
  Version:      18.03.1-ce
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.9.5
  Git commit:   9ee9f40
  Built:        Thu Apr 26 07:23:58 2018
  OS/Arch:      linux/amd64
  Experimental: false
```

```bash
docker run -d \
    --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    rancher/server:preview
```

```
Unable to find image 'rancher/server:preview' locally
preview: Pulling from rancher/server
68393378db12: Pull complete
9e3366501e0e: Pull complete
156ec05da9a5: Pull complete
281cba1133d9: Pull complete
0acdc2cc8ed1: Pull complete
a8cef3d8a877: Pull complete
3e968117f1c2: Pull complete
cf62fef10dfd: Pull complete
098edd097869: Pull complete
77a837c0bf2d: Pull complete
Digest: sha256:38839bb19bdcac084a413a4edce7efb97ab99b6d896bda2f433dfacfd27f8770
Status: Downloaded newer image for rancher/server:preview
660b65bf9b0db1a88ab902c9fccb28c31ac8f63cbeaec3786228e49f1addc162
```

```bash
exit

RANCHER_ADDR=$RANCHER_IP.nip.io

echo $RANCHER_ADDR
```

```
208.68.39.72.nip.io
```

```bash
open "https://$RANCHER_ADDR"

# If you see *This site can’t be reached* message, wait a few moments and refresh the screen.

# There are no certificates. In Chrome, click the *ADVANCED* link, followed with *Proceed to 208.68.39.72.nip.io (unsafe)*.

# Type the admin password (twice)

# Click the *Continue* button
```

![Figure 1: Rancher's welcome screen](images/ch99-cje-rancher-do/rancher-welcome.png)

```bash
# Click the *Save URL* button
```

![Figure 2: Rancher's Server URL screen](images/ch99-cje-rancher-do/rancher-server-url.png)

## Creating An NFS Server

```bash
NFS_SERVER_ADDR=$RANCHER_IP

ssh -i cje root@$NFS_SERVER_ADDR

# If Ubuntu
apt-get update

# If Ubuntu
apt-get install -y \
    nfs-kernel-server

# If CentOS
systemctl enable nfs-server.service

# If CentOS
systemctl start nfs-server.service

# If CentOS
systemctl status nfs-server.service
```

```
nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
   Active: active (exited) since Wed 2018-06-06 21:22:13 UTC; 7s ago
  Process: 10479 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 10474 ExecStartPre=/bin/sh -c /bin/kill -HUP `cat /run/gssproxy.pid` (code=exited, status=0/SUCCESS)
  Process: 10472 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 10479 (code=exited, status=0/SUCCESS)
    Tasks: 0
   Memory: 0B
   CGroup: /system.slice/nfs-server.service

Jun 06 21:22:13 rancher systemd[1]: Starting NFS server and services...
Jun 06 21:22:13 rancher systemd[1]: Started NFS server and services.
```

```bash
mkdir /var/nfs/cje -p

# If Ubuntu
chown nobody:nogroup /var/nfs/cje

# If CentOS
chown nfsnobody:nfsnobody /var/nfs/cje

echo "/var/nfs/cje    *(rw,sync,no_subtree_check)" \
    | tee -a /etc/exports

# If Ubuntu
systemctl restart nfs-kernel-server

# If Ubuntu
systemctl status nfs-kernel-server

# If CentOS
exportfs -a

exit
```

## Creating A Kubernetes Cluster

```bash
open "https://$RANCHER_ADDR"

# Click *Add Cluster* button

# Click the *DigitalOcean* image

# Type *cje* as the *Cluster Name*

# Type *master* as the *Node Pool* *Name Prefix*, *Count* set to *3*, and *etcd* and *Control* checked.

# Click on *Add Node Template*, type the token, select *New York 3* as the *Region*, select *2 GB RAM, 60 GB Disk, 2 vCPUs* as *Droplet Size*, type *k8s* as the *Name*

# If Ubuntu
# Select *Ubuntu 16.04 x64* as the *Image*

# If CentOS
# Select *CentOS 7.X x64* as the *Image*

# Click the *Create* button

# Click the *Add Node Pool* button

# Create a *Node Pool* with *Name Prefix* set to *worker*, *Count* set to *3*, and *Worker* checked.

# Click the *Create* button
```

![Figure 3: Rancher's Add Cluster screen](images/ch99-cje-rancher-do/rancher-create-cluster.png)

```bash
# Click the *cje* link
```

![Figure 4: Rancher's Clusters screen](images/ch99-cje-rancher-do/rancher-clusters.png)

```bash
# Wait until the cluster is created (everything is green)
```

![Figure 5: Rancher's Cluster Dashboard screen](images/ch99-cje-rancher-do/rancher-cluster-dashboard.png)

```bash
vim do-kube-config.yaml

# Click the *Kubeconfig File* button

# Click the *Copy to Clipboard* link
```

![Figure 6: Rancher's Kubeconfig screen](images/ch99-cje-rancher-do/rancher-kubeconfig.png)

```bash
# Click the *i* button

# Paste into `do-kube-config.yaml`

# Press *esc* button, press *:*, type *wq*, press the enter key

export KUBECONFIG=$PWD/do-kube-config.yaml

kubectl get nodes
```

```
NAME    STATUS ROLES             AGE  VERSION
master1 Ready  controlplane,etcd 1h   v1.10.1
master2 Ready  controlplane,etcd 1h   v1.10.1
master3 Ready  controlplane,etcd 1h   v1.10.1
worker1 Ready  worker            1h   v1.10.1
worker2 Ready  worker            1h   v1.10.1
worker3 Ready  worker            1h   v1.10.1
```

```bash
kubectl create ns cjoc

kubectl create ns build
```

## Validating RBAC

```bash
kubectl create ns test1
```

```
namespace "test1" created
```

```bash
kubectl create ns test2
```

```
namespace "test2" created
```

```bash
kubectl apply \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/sa/pods-all.yml
```

```
serviceaccount "pods-all" created
role "pods-all" created
role "pods-all" created
rolebinding "pods-all" created
rolebinding "pods-all" created
```

```bash
kubectl apply \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/sa/kubectl-test2.yml
```

```
pod "kubectl" created
```

```bash
kubectl -n test1 exec -it kubectl -- sh
```

```
No resources found.
```

```bash
kubectl -n test2 \
    run new-test \
    --image=alpine \
    --restart=Never \
    sleep 10000
```

```
pod "new-test" created
```

```bash
kubectl -n test2 get pods
```

```
NAME     READY STATUS  RESTARTS AGE
new-test 1/1   Running 0        17s
```

```bash
kubectl -n default get pods
```

```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:test1:pods-all" cannot list pods in the namespace "default"
```

```bash
exit

kubectl delete ns test1 test2
```

```
namespace "test1" deleted
namespace "test2" deleted
```

## Creating A Load Balancer

### DigitalOcean LB

```
WORKER_IDS=$(doctl compute \
    droplet list -o json | \
    jq -r '.[] | select(.name | startswith("worker")).id' \
    | tr '\n' ',' | tr -d ' ')

echo $WORKER_IDS
```

```
104.131.98.145,104.236.49.97,104.131.106.27,
```

```bash
WORKER_IDS=${WORKER_IDS: :-1}

echo $WORKER_IDS
```

```
104.131.98.145,104.236.49.97,104.131.106.27
```

```bash
kubectl -n ingress-nginx get svc default-http-backend

doctl compute load-balancer create \
    --droplet-ids $WORKER_IDS \
    --forwarding-rules "entry_protocol:tcp,entry_port:80,target_protocol:tcp,target_port:80" \
    --health-check protocol:http,port:80,path:/healthz,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 \
    --name cje \
    --region nyc3

LB_IP=$(doctl compute load-balancer \
    list -o json | jq -r '.[0].ip')

echo $LB_IP
```

```
45.55.123.83
```

```bash
LB_ADDR=$LB_IP.nip.io
```

## Validating Load Balancer And Ingress

```bash
kubectl apply \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/ingress/go-demo-2.yml
```

```
ingress "go-demo-2" created
deployment "go-demo-2-db" created
service "go-demo-2-db" created
deployment "go-demo-2-api" created
service "go-demo-2-api" created
```

```bash
kubectl rollout status \
    deploy go-demo-2-api
```

```
Waiting for rollout to finish: 0 of 3 updated replicas are available...
Waiting for rollout to finish: 1 of 3 updated replicas are available...
Waiting for rollout to finish: 2 of 3 updated replicas are available...
deployment "go-demo-2-api" successfully rolled out
```

```bash
curl -i "http://$LB_ADDR/demo/hello"
```

```
HTTP/1.1 200 OK
Server: nginx/1.13.8
Date: Thu, 07 Jun 2018 00:30:51 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 14
Connection: keep-alive
Strict-Transport-Security: max-age=15724800; includeSubDomains;

hello, world!
```

```bash
curl -i "http://$LB_ADDR/this/does/not/exist"
```

```
HTTP/1.1 404 Not Found
Server: nginx/1.13.8
Date: Thu, 07 Jun 2018 00:31:23 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 21
Connection: keep-alive
Strict-Transport-Security: max-age=15724800; includeSubDomains;

default backend - 404
```

```bash
kubectl delete \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/ingress/go-demo-2.yml
```

```
ingress "go-demo-2" deleted
deployment "go-demo-2-db" deleted
service "go-demo-2-db" deleted
deployment "go-demo-2-api" deleted
service "go-demo-2-api" deleted
```

## Creating StorageClasses

### NFS

```bash
kubectl -n cjoc create \
    -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/auth/serviceaccount.yaml
```

```
serviceaccount "nfs-client-provisioner" created
```

```bash
kubectl create \
    -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/auth/clusterrole.yaml
```

```
clusterrole "nfs-client-provisioner-runner" created
```

```bash
curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/auth/clusterrolebinding.yaml \
    | sed -e "s@namespace: default@namespace: cjoc@g" \
    | kubectl create -f -
```

```
clusterrolebinding "run-nfs-client-provisioner" created
```

```bash
curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/deployment.yaml \
    | sed -e "s@10.10.10.60@$NFS_SERVER_ADDR@g" \
    | sed -e "s@/ifs/kubernetes@/var/nfs/cje@g" \
    | sed -e "s@fuseim.pri/ifs@cloudbees.com/cje-nfs@g" \
    | kubectl -n cjoc create -f -
```

```
deployment "nfs-client-provisioner" created
```

```bash
kubectl -n cjoc \
    rollout status \
    deploy nfs-client-provisioner
```

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "nfs-client-provisioner" successfully rolled out
```

```bash
curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/class.yaml \
    | sed -e "s@managed-nfs-storage@cje-storage@g" \
    | sed -e "s@fuseim.pri/ifs@cloudbees.com/cje-nfs@g" \
    | kubectl -n cjoc create -f -
```

```
storageclass "cje-storage" created
```

```bash
curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/test-claim.yaml \
    | sed -e "s@managed-nfs-storage@cje-storage@g" \
    | kubectl -n cjoc create -f -
```

```
persistentvolumeclaim "test-claim" created
```

```bash
kubectl create \
    -n cjoc \
    -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/test-pod.yaml
```

```
pod "test-pod" created
```

```bash
ssh -i cje root@$NFS_SERVER_ADDR \
    "ls -l /var/nfs/cje"
```

```
drwxrwxrwx. 2 nfsnobody nfsnobody 21 Jun  7 00:44 cjoc-test-claim-pvc-d5fa9106-69eb-11e8-b65a-ea9238c4f6a5
```

```bash
ssh -i cje root@$NFS_SERVER_ADDR \
    "ls -l /var/nfs/cje/cjoc-test*"
```

```
-rw-r--r--. 1 nfsnobody nfsnobody 0 Jun  7 00:44 SUCCESS
```

```bash
kubectl delete \
    -n cjoc \
    -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/test-pod.yaml
```

```
pod "test-pod" deleted
```

```bash
kubectl delete \
    -n cjoc \
    -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/test-claim.yaml
```

```
persistentvolumeclaim "test-claim" deleted
```

```bash
ssh -i cje root@$NFS_SERVER_ADDR \
    "ls -l /var/nfs/cje"
```

```
drwxrwxrwx. 2 nfsnobody nfsnobody 21 Jun  7 00:44 archived-cjoc-test-claim-pvc-d5fa9106-69eb-11e8-b65a-ea9238c4f6a5
```

## Validating StorageClasses

```bash
kubectl -n cjoc apply \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/sts/cje-test.yml
```

```
statefulset "test" created
service "test" created
```

```bash
kubectl -n cjoc exec test-0 \
    -- touch /tmp/something

kubectl -n cjoc exec test-0 \
    -- ls -l /tmp
```

```
-rw-r--r--    1 nobody   nobody           0 Jun  7 01:04 something
```

```bash
kubectl -n cjoc delete pod test-0
```

```
pod "test-0" deleted
```

```bash
kubectl -n cjoc get pods
```

```
NAME                                      READY     STATUS        RESTARTS   AGE
nfs-client-provisioner-69688c76dd-b2bjj   1/1       Running       0          33m
test-0                                    1/1       Terminating   0          3m
```

```bash
kubectl -n cjoc get pods
```

```
NAME                                      READY     STATUS    RESTARTS   AGE
nfs-client-provisioner-69688c76dd-b2bjj   1/1       Running   0          34m
test-0                                    1/1       Running   0          9s
```

```bash
kubectl -n cjoc exec test-0 \
    -- ls -l /tmp
```

```
-rw-r--r--    1 nobody   nobody           0 Jun  7 01:04 something
```

```bash
kubectl -n cjoc delete \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/sts/cje-test.yml
```

```
statefulset "test" deleted
service "test" deleted
```

```bash
kubectl -n cjoc \
    delete pvc test-data-test-0
```

```
persistentvolumeclaim "test-data-test-0" deleted
```

```bash
kubectl -n build apply \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/sts/cje-test.yml
```

```
statefulset "test" created
service "test" created
```

```bash
kubectl -n build exec test-0 \
    -- touch /tmp/something

kubectl -n build exec test-0 \
    -- ls -l /tmp
```

```
-rw-r--r--    1 nobody   nobody           0 Jun  7 01:11 something
```

```bash
kubectl -n build delete pod test-0
```

```
pod "test-0" deleted
```

```bash
kubectl -n build get pods
```

```
NAME      READY     STATUS        RESTARTS   AGE
test-0    1/1       Terminating   0          58s
```

```bash
kubectl -n build get pods
```

```
NAME      READY     STATUS    RESTARTS   AGE
test-0    1/1       Running   0          3s
```

```bash
kubectl -n build exec test-0 \
    -- ls -l /tmp
```

```
-rw-r--r--    1 nobody   nobody           0 Jun  7 01:11 something
```

```bash
kubectl -n build delete \
    -f https://raw.githubusercontent.com/vfarcic/k8s-specs/master/sts/cje-test.yml
```

```
statefulset "test" deleted
service "test" deleted
```

```bash
kubectl -n build \
    delete pvc test-data-test-0
```

```
persistentvolumeclaim "test-data-test-0" deleted
```

TODO: Speed tests

## Installing CJE

```bash
open "https://downloads.cloudbees.com/cje2/latest/"

# Copy the link address of cje2 Kubernetes release

RELEASE_URL=[...]

curl -o cje.tgz $RELEASE_URL

tar -xvf cje.tgz
```

```
x cje2_2.121.1.2_kubernetes/
x cje2_2.121.1.2_kubernetes/cjoc-external-masters.yml
x cje2_2.121.1.2_kubernetes/INSTALLATION.md
x cje2_2.121.1.2_kubernetes/SCALING.md
x cje2_2.121.1.2_kubernetes/TROUBLESHOOTING.md
x cje2_2.121.1.2_kubernetes/PROXY.md
x cje2_2.121.1.2_kubernetes/ANALYTICS.md
x cje2_2.121.1.2_kubernetes/cje.yml
```

```bash
cd cje2_*

ls -l
```

```
-rw-r--r--  1 vfarcic  staff    158  6 Jun 07:06 ANALYTICS.md
-rw-r--r--  1 vfarcic  staff   5144  6 Jun 07:06 INSTALLATION.md
-rw-r--r--  1 vfarcic  staff   1498  6 Jun 07:06 PROXY.md
-rw-r--r--  1 vfarcic  staff   1466  6 Jun 07:06 SCALING.md
-rw-r--r--  1 vfarcic  staff   4950  6 Jun 07:06 TROUBLESHOOTING.md
-rw-r--r--  1 vfarcic  staff  11884  6 Jun 07:06 cje.yml
-rw-r--r--  1 vfarcic  staff    509  6 Jun 07:06 cjoc-external-masters.yml
```

```bash
cat cje.yml

kubectl create ns jenkins

cat cje.yml \
    | sed -e \
    "s@https://cje.example.com@http://cje.example.com@g" \
    | sed -e \
    "s@cje.example.com@$LB_ADDR@g" \
    | sed -e \
    "s@ssl-redirect: \"true\"@ssl-redirect: \"false\"@g" \
    | sed -e \
    "s@# storageClassName: some-storage-class@storageClassName: cje-storage@g" \
    | kubectl --namespace cjoc \
    apply -f -
```

```
serviceaccount "cjoc" created
role "master-management" created
rolebinding "cjoc" created
configmap "cjoc-config" created
configmap "cjoc-configure-jenkins-groovy" created
statefulset "cjoc" created
service "cjoc" created
ingress "cjoc" created
serviceaccount "jenkins" created
role "pods-all" created
rolebinding "jenkins" created
configmap "jenkins-agent" created
```

```bash
kubectl -n cjoc \
    rollout status sts cjoc
```

```
Waiting for 1 pods to be ready...
statefulset rolling update complete 1 pods at revision cjoc-578b8fd6b4...
```

```bash
kubectl -n cjoc get all
```

```
NAME                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/nfs-client-provisioner   1         1         1            1           51m

NAME                                   DESIRED   CURRENT   READY     AGE
rs/nfs-client-provisioner-69688c76dd   1         1         1         51m

NAME                DESIRED   CURRENT   AGE
statefulsets/cjoc   1         1         1m

NAME                                         READY     STATUS    RESTARTS   AGE
po/cjoc-0                                    1/1       Running   0          1m
po/nfs-client-provisioner-69688c76dd-b2bjj   1/1       Running   0          51m

NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)            AGE
svc/cjoc   ClusterIP   10.43.128.241   <none>        80/TCP,50000/TCP   1m
```

```bash
open "http://$LB_ADDR/cjoc"

kubectl -n cjoc exec cjoc-0 -- \
    cat /var/jenkins_home/secrets/initialAdminPassword
```

```
c9b802a409a04d1f8755e9d394749a58
```

```bash
# Copy the output and paste it into Jenkins UI field *Administrative password*

# Click the *Continue* button

# Click the *Use a license key* button

# Type your *License Key* and *License Certificate*

# Click the *OK* button

# Click the *Install suggested plugins* button

# Fill in the field in the *Create First Admin User* screen

# Click the *Save and Continue* button

# Click the *Start using Operations Center* button

kubectl -n cjoc get pvc
```

```
NAME                  STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
jenkins-home-cjoc-0   Bound     pvc-271f09c1-69f1-11e8-b65a-ea9238c4f6a5   20Gi       RWO            cje-storage    11m
```

```bash
kubectl get pv
```

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                      STORAGECLASS   REASON    AGE
pvc-271f09c1-69f1-11e8-b65a-ea9238c4f6a5   20Gi       RWO            Delete           Bound     cjoc/jenkins-home-cjoc-0   cje-storage              15m
```

### Creating Managed Masters

TODO: Create

TODO: Fail and confirm that the state is preserved

### Managed Agents (PodTemplates)

TODO

### External Masters

TODO

### External Agents

TODO

## Validating CJE

## Destroying The Cluster

TODO
