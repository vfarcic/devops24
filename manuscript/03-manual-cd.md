## TODO

- [X] Code
- [ ] Write
- [X] Code review Docker for Mac/Windows
- [ ] Code review minikube
- [ ] Code review kops
- [ ] Code review minishift
- [ ] Code review GKE
- [ ] The story
- [ ] Text review
- [ ] Diagrams
- [ ] Gist
- [ ] Review the title
- [ ] Proofread
- [ ] Add to slides
- [ ] Publish on TechnologyConversations.com
- [ ] Add to Book.txt
- [ ] Publish on LeanPub.com

# Manual CD

## Cluster

```bash
cd k8s-specs

git pull
```

## Preparing build ns

```bash
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
rolebinding "build" created
limitrange "build" created
resourcequota "build" created
```

```bash
kubectl -n go-demo-3-build \
    describe rolebinding build
```

```
Name:         build
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"rbac.authorization.k8s.io/v1beta1","kind":"RoleBinding","metadata":{"annotations":{},"name":"build","namespace":"go-demo-3-build"},"role...
              kubernetes.io/change-cause=kubectl apply --filename=../go-demo-3/k8s/build-ns.yml --record=true
Role:
  Kind:  ClusterRole
  Name:  admin
Subjects:
  Kind            Name   Namespace
  ----            ----   ---------
  ServiceAccount  build  
```

```bash
kubectl -n go-demo-3-build \
    describe clusterrole admin
```

```
Name:         admin
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate=true
PolicyRule:
  Resources                                       Non-Resource URLs  Resource Names  Verbs
  ---------                                       -----------------  --------------  -----
  bindings                                        []                 []              [get list watch]
  configmaps                                      []                 []              [create delete deletecollection get list patch update watch]
  cronjobs.batch                                  []                 []              [create delete deletecollection get list patch update watch]
  daemonsets.apps                                 []                 []              [create delete deletecollection get list patch update watch]
  daemonsets.extensions                           []                 []              [create delete deletecollection get list patch update watch]
  deployments.apps                                []                 []              [create delete deletecollection get list patch update watch]
  deployments.extensions                          []                 []              [create delete deletecollection get list patch update watch]
  deployments.apps/rollback                       []                 []              [create delete deletecollection get list patch update watch]
  deployments.extensions/rollback                 []                 []              [create delete deletecollection get list patch update watch]
  deployments.apps/scale                          []                 []              [create delete deletecollection get list patch update watch]
  deployments.extensions/scale                    []                 []              [create delete deletecollection get list patch update watch]
  endpoints                                       []                 []              [create delete deletecollection get list patch update watch]
  events                                          []                 []              [get list watch]
  horizontalpodautoscalers.autoscaling            []                 []              [create delete deletecollection get list patch update watch]
  ingresses.extensions                            []                 []              [create delete deletecollection get list patch update watch]
  jobs.batch                                      []                 []              [create delete deletecollection get list patch update watch]
  limitranges                                     []                 []              [get list watch]
  localsubjectaccessreviews.authorization.k8s.io  []                 []              [create]
  namespaces                                      []                 []              [get list watch]
  namespaces/status                               []                 []              [get list watch]
  persistentvolumeclaims                          []                 []              [create delete deletecollection get list patch update watch]
  poddisruptionbudgets.policy                     []                 []              [create delete deletecollection get list patch update watch]
  pods                                            []                 []              [create delete deletecollection get list patch update watch]
  pods/attach                                     []                 []              [create delete deletecollection get list patch update watch]
  pods/exec                                       []                 []              [create delete deletecollection get list patch update watch]
  pods/log                                        []                 []              [get list watch]
  pods/portforward                                []                 []              [create delete deletecollection get list patch update watch]
  pods/proxy                                      []                 []              [create delete deletecollection get list patch update watch]
  pods/status                                     []                 []              [get list watch]
  replicasets.apps                                []                 []              [create delete deletecollection get list patch update watch]
  replicasets.extensions                          []                 []              [create delete deletecollection get list patch update watch]
  replicasets.apps/scale                          []                 []              [create delete deletecollection get list patch update watch]
  replicasets.extensions/scale                    []                 []              [create delete deletecollection get list patch update watch]
  replicationcontrollers                          []                 []              [create delete deletecollection get list patch update watch]
  replicationcontrollers/scale                    []                 []              [create delete deletecollection get list patch update watch]
  replicationcontrollers.extensions/scale         []                 []              [create delete deletecollection get list patch update watch]
  replicationcontrollers/status                   []                 []              [get list watch]
  resourcequotas                                  []                 []              [get list watch]
  resourcequotas/status                           []                 []              [get list watch]
  rolebindings.rbac.authorization.k8s.io          []                 []              [create delete deletecollection get list patch update watch]
  roles.rbac.authorization.k8s.io                 []                 []              [create delete deletecollection get list patch update watch]
  secrets                                         []                 []              [create delete deletecollection get list patch update watch]
  serviceaccounts                                 []                 []              [create delete deletecollection get list patch update watch impersonate]
  services                                        []                 []              [create delete deletecollection get list patch update watch]
  services/proxy                                  []                 []              [create delete deletecollection get list patch update watch]
  statefulsets.apps                               []                 []              [create delete deletecollection get list patch update watch]
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
rolebinding "build" created
limitrange "build" created
resourcequota "build" created
```

## Build, Unit Tests, and release beta

```bash
cat cd/docker-socket.yml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: docker
spec:
  containers:
  - name: docker
    image: docker:18.03-git
    command: ["sleep"]
    args: ["100000"]
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-socket
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
      type: Socket
```

```bash
kubectl -n go-demo-3-build \
    create -f cd/docker-socket.yml \
    --save-config --record
```

```
pod "docker" created
```

```bash
kubectl -n go-demo-3-build \
    get pods
```

```
NAME   READY STATUS  RESTARTS AGE
docker 1/1   Running 0        3m
```

```bash
kubectl -n go-demo-3-build \
    describe pod docker
```

```
Name:         docker
Namespace:    go-demo-3-build
Node:         docker-for-desktop/192.168.65.3
Start Time:   Mon, 14 May 2018 15:46:31 +0200
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"docker","namespace":"go-demo-3-build"},"spec":{"containers":[{"args":["100000"],"c...
              kubernetes.io/change-cause=kubectl apply --namespace=go-demo-3-build --filename=cd/docker-socket.yml --record=true
              kubernetes.io/limit-ranger=LimitRanger plugin set: cpu, memory request for container docker; cpu, memory limit for container docker
Status:       Running
IP:           10.1.1.54
Containers:
  docker:
    Container ID:  docker://1a85f00992a251cece95608a245ce90b0e4b75bdb7bf2669ce5466513e82d4df
    Image:         docker:18.03-git
    Image ID:      docker-pullable://docker@sha256:edca22de7cdfcb2a8807d634f6e83cab226e7751660970dd2cb50925bee162d4
    Port:          <none>
    Command:
      sleep
    Args:
      100000
    State:          Running
      Started:      Mon, 14 May 2018 15:46:34 +0200
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     200m
      memory:  200Mi
    Requests:
      cpu:        100m
      memory:     100Mi
    Environment:  <none>
    Mounts:
      /var/run/docker.sock from docker-socket (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-9fv5r (ro)
Conditions:
  Type           Status
  Initialized    True 
  Ready          True 
  PodScheduled   True 
Volumes:
  docker-socket:
    Type:          HostPath (bare host directory volume)
    Path:          /var/run/docker.sock
    HostPathType:  Socket
  default-token-9fv5r:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-9fv5r
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                 Age   From                         Message
  ----    ------                 ----  ----                         -------
  Normal  Scheduled              31s   default-scheduler            Successfully assigned docker to docker-for-desktop
  Normal  SuccessfulMountVolume  30s   kubelet, docker-for-desktop  MountVolume.SetUp succeeded for volume "docker-socket"
  Normal  SuccessfulMountVolume  30s   kubelet, docker-for-desktop  MountVolume.SetUp succeeded for volume "default-token-9fv5r"
  Normal  Pulled                 28s   kubelet, docker-for-desktop  Container image "docker:18.03-git" already present on machine
  Normal  Created                28s   kubelet, docker-for-desktop  Created container
  Normal  Started                28s   kubelet, docker-for-desktop  Started container
```

```bash
kubectl -n go-demo-3-build \
    exec -it docker -- sh

docker version
```

```
Client:
 Version:      18.03.1-ce
 API version:  1.37
 Go version:   go1.9.2
 Git commit:   9ee9f40
 Built:        Thu Apr 26 07:12:25 2018
 OS/Arch:      linux/amd64
 Experimental: false
 Orchestrator: swarm

Server:
 Engine:
  Version:      18.05.0-ce-rc1
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.10.1
  Git commit:   33f00ce
  Built:        Thu Apr 26 01:06:49 2018
  OS/Arch:      linux/amd64
  Experimental: true
```

```bash
docker container ls
```

```
CONTAINER ID        IMAGE                                                            COMMAND                  CREATED              STATUS                           PORTS               NAMES
63bbe026648a        dockerflow/docker-flow-swarm-listener:beta                       "docker-flow-swarm-l…"   3 seconds ago        Up 1 second (health: starting)   8080/tcp            dfsl_swarm-listener.1.bgl785791aa91d80gtxx5t0uf
1a85f00992a2        docker                                                           "sleep 100000"           About a minute ago   Up About a minute                k8s_docker_docker_go-demo-3-build_35c7536a-577d-11e8-b1a3-025000000001_0
215e82278a54        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 About a minute ago   Up About a minute                k8s_POD_docker_go-demo-3-build_35c7536a-577d-11e8-b1a3-025000000001_0
b97a7f396a7e        quay.io/kubernetes-ingress-controller/nginx-ingress-controller   "/usr/bin/dumb-init …"   2 minutes ago        Up 2 minutes                k8s_nginx-ingress-controller_nginx-ingress-controller-5bf7ccc6b4-pp7hx_ingress-nginx_14036138-577d-11e8-b1a3-025000000001_0
bc20905c14cf        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 2 minutes ago        Up 2 minutes                k8s_POD_nginx-ingress-controller-5bf7ccc6b4-pp7hx_ingress-nginx_14036138-577d-11e8-b1a3-025000000001_0
e8eb7367742d        gcr.io/google_containers/defaultbackend                          "/server"                2 minutes ago        Up 2 minutes                k8s_default-http-backend_default-http-backend-55c6c69b88-crqjb_ingress-nginx_12f7c926-577d-11e8-b1a3-025000000001_0
6b42d32b31b8        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 2 minutes ago        Up 2 minutes                k8s_POD_default-http-backend-55c6c69b88-crqjb_ingress-nginx_12f7c926-577d-11e8-b1a3-025000000001_0
0be4402c362c        docker/kube-compose-controller                                   "/compose-controller…"   2 minutes ago        Up 2 minutes                k8s_compose_compose-5d4f4d67b6-rmrq4_docker_fd5fe34e-577c-11e8-b1a3-025000000001_0
e2b61c6d49d8        docker/kube-compose-api-server                                   "/api-server --kubec…"   2 minutes ago        Up 2 minutes                k8s_compose_compose-api-7bb7b5968f-nntvv_docker_fd57b881-577c-11e8-b1a3-025000000001_0
cf052e65a487        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 2 minutes ago        Up 2 minutes                k8s_POD_compose-5d4f4d67b6-rmrq4_docker_fd5fe34e-577c-11e8-b1a3-025000000001_0
0cb95ee02f23        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 2 minutes ago        Up 2 minutes                k8s_POD_compose-api-7bb7b5968f-nntvv_docker_fd57b881-577c-11e8-b1a3-025000000001_0
1f7d2474e231        gcr.io/google_containers/k8s-dns-sidecar-amd64                   "/sidecar --v=2 --lo…"   3 minutes ago        Up 3 minutes                k8s_sidecar_kube-dns-6f4fd4bdf-g9rq9_kube-system_d4d320d9-577c-11e8-b1a3-025000000001_0
1ab0a7bcede3        gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64             "/dnsmasq-nanny -v=2…"   3 minutes ago        Up 3 minutes                k8s_dnsmasq_kube-dns-6f4fd4bdf-g9rq9_kube-system_d4d320d9-577c-11e8-b1a3-025000000001_0
d9825d1cff13        gcr.io/google_containers/k8s-dns-kube-dns-amd64                  "/kube-dns --domain=…"   3 minutes ago        Up 3 minutes                k8s_kubedns_kube-dns-6f4fd4bdf-g9rq9_kube-system_d4d320d9-577c-11e8-b1a3-025000000001_0
2d55540feb09        gcr.io/google_containers/kube-proxy-amd64                        "/usr/local/bin/kube…"   3 minutes ago        Up 3 minutes                k8s_kube-proxy_kube-proxy-7md2v_kube-system_d4d1167f-577c-11e8-b1a3-025000000001_0
99b00504fa89        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 3 minutes ago        Up 3 minutes                k8s_POD_kube-dns-6f4fd4bdf-g9rq9_kube-system_d4d320d9-577c-11e8-b1a3-025000000001_0
84a72f74977e        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 3 minutes ago        Up 3 minutes                k8s_POD_kube-proxy-7md2v_kube-system_d4d1167f-577c-11e8-b1a3-025000000001_0
ab77444a7a82        gcr.io/google_containers/etcd-amd64                              "etcd --listen-clien…"   4 minutes ago        Up 4 minutes                k8s_etcd_etcd-docker-for-desktop_kube-system_7278f85057e8bf5cb81c9f96d3b25320_0
16853e653086        gcr.io/google_containers/kube-scheduler-amd64                    "kube-scheduler --ad…"   4 minutes ago        Up 4 minutes                k8s_kube-scheduler_kube-scheduler-docker-for-desktop_kube-system_0f95caae4a7fffab092dfa6db3c27347_0
4516664a67f0        gcr.io/google_containers/kube-controller-manager-amd64           "kube-controller-man…"   4 minutes ago        Up 4 minutes                k8s_kube-controller-manager_kube-controller-manager-docker-for-desktop_kube-system_50b9c96de6fe3cf3d48014834c5d7d07_0
c7ec6cf02fff        gcr.io/google_containers/kube-apiserver-amd64                    "kube-apiserver --ad…"   4 minutes ago        Up 4 minutes                k8s_kube-apiserver_kube-apiserver-docker-for-desktop_kube-system_0698cc99b34a38000d47b70173683757_0
51457b65dedf        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 4 minutes ago        Up 4 minutes                k8s_POD_etcd-docker-for-desktop_kube-system_7278f85057e8bf5cb81c9f96d3b25320_0
52abbb30c3ff        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 4 minutes ago        Up 4 minutes                k8s_POD_kube-scheduler-docker-for-desktop_kube-system_0f95caae4a7fffab092dfa6db3c27347_0
d5f456e10e6a        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 4 minutes ago        Up 4 minutes                k8s_POD_kube-controller-manager-docker-for-desktop_kube-system_50b9c96de6fe3cf3d48014834c5d7d07_0
0d55ab5c8b52        gcr.io/google_containers/pause-amd64:3.0                         "/pause"                 4 minutes ago        Up 4 minutes                k8s_POD_kube-apiserver-docker-for-desktop_kube-system_0698cc99b34a38000d47b70173683757_0
```

```bash
# Fork https://github.com/vfarcic/go-demo-3.git

# Change `vfarcic` to your GH user in *k8s/build.yml*, *k8s/prod.yml*, and *k8s/functional.yml*

export GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-3.git
```

```
Cloning into 'go-demo-3'...
remote: Counting objects: 102, done.
remote: Compressing objects: 100% (73/73), done.
remote: Total 102 (delta 46), reused 82 (delta 26), pack-reused 0
Receiving objects: 100% (102/102), 34.82 KiB | 1.09 MiB/s, done.
Resolving deltas: 100% (46/46), done.
```

```bash
# It should be a specific commit

cd go-demo-3

# Register to Docker Hub

export DH_USER=[...]

docker login -u $DH_USER
```

```
Login Succeeded
```

```bash
docker image build \
    -t $DH_USER/go-demo-3:1.0-beta .
```

```
Sending build context to Docker daemon  139.8kB
Step 1/15 : FROM golang:1.9 AS build
 ---> 1a34fad76b34
Step 2/15 : ADD . /src
 ---> 4d820ca03495
Step 3/15 : WORKDIR /src
Removing intermediate container 03c110d26992
 ---> b380ae2b641e
Step 4/15 : RUN go get -d -v -t
 ---> Running in 201a967b840f
github.com/prometheus/client_golang (download)
github.com/beorn7/perks (download)
github.com/golang/protobuf (download)
github.com/prometheus/client_model (download)
github.com/prometheus/common (download)
github.com/matttproud/golang_protobuf_extensions (download)
github.com/prometheus/procfs (download)
Fetching https://gopkg.in/mgo.v2?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2?go-get=1 (status code 200)
get "gopkg.in/mgo.v2": found meta tag get.metaImport{Prefix:"gopkg.in/mgo.v2", VCS:"git", RepoRoot:"https://gopkg.in/mgo.v2"} at https://gopkg.in/mgo.v2?go-get=1
gopkg.in/mgo.v2 (download)
Fetching https://gopkg.in/mgo.v2/bson?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2/bson?go-get=1 (status code 200)
get "gopkg.in/mgo.v2/bson": found meta tag get.metaImport{Prefix:"gopkg.in/mgo.v2", VCS:"git", RepoRoot:"https://gopkg.in/mgo.v2"} at https://gopkg.in/mgo.v2/bson?go-get=1
get "gopkg.in/mgo.v2/bson": verifying non-authoritative meta tag
Fetching https://gopkg.in/mgo.v2?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2?go-get=1 (status code 200)
github.com/stretchr/testify (download)
Removing intermediate container 201a967b840f
 ---> e01c11cb1b1d
Step 5/15 : RUN go test --cover -v ./... --run UnitTest
 ---> Running in bfddc4b6c7c3
=== RUN   TestMainUnitTestSuite
=== RUN   TestMainUnitTestSuite/Test_HelloServer_Waits_WhenDelayIsPresent
=== RUN   TestMainUnitTestSuite/Test_HelloServer_WritesHelloWorld
=== RUN   TestMainUnitTestSuite/Test_HelloServer_WritesNokEventually
=== RUN   TestMainUnitTestSuite/Test_HelloServer_WritesOk
=== RUN   TestMainUnitTestSuite/Test_PersonServer_InvokesUpsertId_WhenPutPerson
=== RUN   TestMainUnitTestSuite/Test_PersonServer_Panics_WhenFindReturnsError
=== RUN   TestMainUnitTestSuite/Test_PersonServer_Panics_WhenUpsertIdReturnsError
=== RUN   TestMainUnitTestSuite/Test_PersonServer_WritesPeople
=== RUN   TestMainUnitTestSuite/Test_RunServer_InvokesListenAndServe
=== RUN   TestMainUnitTestSuite/Test_SetupMetrics_InitializesHistogram
--- PASS: TestMainUnitTestSuite (0.02s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_Waits_WhenDelayIsPresent (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_WritesHelloWorld (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_WritesNokEventually (0.01s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_WritesOk (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_InvokesUpsertId_WhenPutPerson (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_Panics_WhenFindReturnsError (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_Panics_WhenUpsertIdReturnsError (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_WritesPeople (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_RunServer_InvokesListenAndServe (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_SetupMetrics_InitializesHistogram (0.00s)
PASS
coverage: 76.8% of statements
ok      _/src   0.032s
Removing intermediate container bfddc4b6c7c3
 ---> 930cf3d2b7d9
Step 6/15 : RUN go build -v -o go-demo
 ---> Running in 06c80c9f1d2f
github.com/golang/protobuf/proto
github.com/beorn7/perks/quantile
github.com/prometheus/common/internal/bitbucket.org/ww/goautoneg
github.com/prometheus/common/model
github.com/prometheus/procfs/internal/util
github.com/prometheus/procfs/nfs
github.com/prometheus/procfs/xfs
github.com/prometheus/procfs
gopkg.in/mgo.v2/internal/json
github.com/prometheus/client_model/go
github.com/matttproud/golang_protobuf_extensions/pbutil
github.com/prometheus/common/expfmt
gopkg.in/mgo.v2/bson
github.com/prometheus/client_golang/prometheus
gopkg.in/mgo.v2/internal/scram
gopkg.in/mgo.v2
_/src
Removing intermediate container 06c80c9f1d2f
 ---> 77225e838ab6
Step 7/15 : FROM alpine:3.4
 ---> dc98aa467aa0
Step 8/15 : MAINTAINER  Viktor Farcic <viktor@farcic.com>
 ---> Using cache
 ---> d2db97f1b049
Step 9/15 : RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
 ---> Using cache
 ---> 8b84266096fe
Step 10/15 : EXPOSE 8080
 ---> Using cache
 ---> 235d879d0d1a
Step 11/15 : ENV DB db
 ---> Using cache
 ---> 8f1fcf20f82f
Step 12/15 : CMD ["go-demo"]
 ---> Using cache
 ---> 4209b946e2aa
Step 13/15 : HEALTHCHECK --interval=10s CMD wget -qO- localhost:8080/demo/hello
 ---> Using cache
 ---> 7e9e4d5a7f6d
Step 14/15 : COPY --from=build /src/go-demo /usr/local/bin/go-demo
 ---> Using cache
 ---> 0cb666cb406a
Step 15/15 : RUN chmod +x /usr/local/bin/go-demo
 ---> Using cache
 ---> 36f283384ba7
Successfully built 36f283384ba7
Successfully tagged vfarcic/go-demo-3:1.0-beta
```

```bash
# Docker might be too too old

# Socket is exposed

# The node is logged in

exit

kubectl delete ns go-demo-3-build

export GH_USER=[...]

rm -rf ../go-demo-3

git clone \
    https://github.com/$GH_USER/go-demo-3.git \
    ../go-demo-3

export DH_USER=[...]

# Install Docker for Mac, Docker for Windows, or Docker (for Linux)

# Must be 17.05+

# Build on a separate VM

docker image build \
    -t $DH_USER/go-demo-3:1.0-beta \
    ../go-demo-3/
```

```
Sending build context to Docker daemon  139.3kB
Step 1/15 : FROM golang:1.9 AS build
 ---> 1a34fad76b34
Step 2/15 : ADD . /src
 ---> cda7fc5fde79
Step 3/15 : WORKDIR /src
Removing intermediate container 97489b8edaa0
 ---> c1fb04a2a09e
Step 4/15 : RUN go get -d -v -t
 ---> Running in f0801205375c
github.com/prometheus/client_golang (download)
github.com/beorn7/perks (download)
github.com/golang/protobuf (download)
github.com/prometheus/client_model (download)
github.com/prometheus/common (download)
github.com/matttproud/golang_protobuf_extensions (download)
github.com/prometheus/procfs (download)
Fetching https://gopkg.in/mgo.v2?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2?go-get=1 (status code 200)
get "gopkg.in/mgo.v2": found meta tag get.metaImport{Prefix:"gopkg.in/mgo.v2", VCS:"git", RepoRoot:"https://gopkg.in/mgo.v2"} at https://gopkg.in/mgo.v2?go-get=1
gopkg.in/mgo.v2 (download)
Fetching https://gopkg.in/mgo.v2/bson?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2/bson?go-get=1 (status code 200)
get "gopkg.in/mgo.v2/bson": found meta tag get.metaImport{Prefix:"gopkg.in/mgo.v2", VCS:"git", RepoRoot:"https://gopkg.in/mgo.v2"} at https://gopkg.in/mgo.v2/bson?go-get=1
get "gopkg.in/mgo.v2/bson": verifying non-authoritative meta tag
Fetching https://gopkg.in/mgo.v2?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2?go-get=1 (status code 200)
github.com/stretchr/testify (download)
Removing intermediate container f0801205375c
 ---> ae6ede4e928f
Step 5/15 : RUN go test --cover -v ./... --run UnitTest
 ---> Running in 01a58520b8bf
=== RUN   TestMainUnitTestSuite
=== RUN   TestMainUnitTestSuite/Test_HelloServer_Waits_WhenDelayIsPresent
=== RUN   TestMainUnitTestSuite/Test_HelloServer_WritesHelloWorld
=== RUN   TestMainUnitTestSuite/Test_HelloServer_WritesNokEventually
=== RUN   TestMainUnitTestSuite/Test_HelloServer_WritesOk
=== RUN   TestMainUnitTestSuite/Test_PersonServer_InvokesUpsertId_WhenPutPerson
=== RUN   TestMainUnitTestSuite/Test_PersonServer_Panics_WhenFindReturnsError
=== RUN   TestMainUnitTestSuite/Test_PersonServer_Panics_WhenUpsertIdReturnsError
=== RUN   TestMainUnitTestSuite/Test_PersonServer_WritesPeople
=== RUN   TestMainUnitTestSuite/Test_RunServer_InvokesListenAndServe
=== RUN   TestMainUnitTestSuite/Test_SetupMetrics_InitializesHistogram
--- PASS: TestMainUnitTestSuite (0.02s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_Waits_WhenDelayIsPresent (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_WritesHelloWorld (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_WritesNokEventually (0.01s)
    --- PASS: TestMainUnitTestSuite/Test_HelloServer_WritesOk (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_InvokesUpsertId_WhenPutPerson (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_Panics_WhenFindReturnsError (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_Panics_WhenUpsertIdReturnsError (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_PersonServer_WritesPeople (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_RunServer_InvokesListenAndServe (0.00s)
    --- PASS: TestMainUnitTestSuite/Test_SetupMetrics_InitializesHistogram (0.00s)
PASS
coverage: 76.8% of statements
ok      _/src   0.033s
Removing intermediate container 01a58520b8bf
 ---> f4d70d990f82
Step 6/15 : RUN go build -v -o go-demo
 ---> Running in 91d2243517c6
github.com/golang/protobuf/proto
github.com/beorn7/perks/quantile
github.com/prometheus/common/internal/bitbucket.org/ww/goautoneg
github.com/prometheus/common/model
github.com/prometheus/procfs/internal/util
github.com/prometheus/procfs/nfs
github.com/prometheus/procfs/xfs
github.com/prometheus/procfs
gopkg.in/mgo.v2/internal/json
github.com/prometheus/client_model/go
github.com/matttproud/golang_protobuf_extensions/pbutil
github.com/prometheus/common/expfmt
gopkg.in/mgo.v2/bson
github.com/prometheus/client_golang/prometheus
gopkg.in/mgo.v2/internal/scram
gopkg.in/mgo.v2
_/src
Removing intermediate container 91d2243517c6
 ---> de1a02ffbb84
Step 7/15 : FROM alpine:3.4
 ---> dc98aa467aa0
Step 8/15 : MAINTAINER  Viktor Farcic <viktor@farcic.com>
 ---> Using cache
 ---> d2db97f1b049
Step 9/15 : RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
 ---> Using cache
 ---> 8b84266096fe
Step 10/15 : EXPOSE 8080
 ---> Using cache
 ---> 235d879d0d1a
Step 11/15 : ENV DB db
 ---> Using cache
 ---> 8f1fcf20f82f
Step 12/15 : CMD ["go-demo"]
 ---> Using cache
 ---> 4209b946e2aa
Step 13/15 : HEALTHCHECK --interval=10s CMD wget -qO- localhost:8080/demo/hello
 ---> Using cache
 ---> 7e9e4d5a7f6d
Step 14/15 : COPY --from=build /src/go-demo /usr/local/bin/go-demo
 ---> Using cache
 ---> 0cb666cb406a
Step 15/15 : RUN chmod +x /usr/local/bin/go-demo
 ---> Using cache
 ---> 36f283384ba7
Successfully built 36f283384ba7
Successfully tagged vfarcic/go-demo-3:1.0-beta
```

```bash
docker image ls
```

```
REPOSITORY                                                       TAG                       IMAGE ID            CREATED             SIZE
<none>                                                           <none>                    de1a02ffbb84        45 seconds ago      763MB
<none>                                                           <none>                    77225e838ab6        4 minutes ago       763MB
<none>                                                           <none>                    5ffbf08ae73b        12 minutes ago      25.8MB
vfarcic/go-demo-3                                                1.0-beta                  36f283384ba7        4 hours ago         25.8MB
<none>                                                           <none>                    f1eeeccf69b0        4 hours ago         763MB
gcr.io/kaniko-project/executor                                   latest                    4f5ac047c19d        2 days ago          36.8MB
golang                                                           alpine                    05fe62871090        10 days ago         376MB
<none>                                                           <none>                    926242576a5a        11 days ago         763MB
vfarcic/go-demo-3                                                1.0                       1aef1abcd9ad        13 days ago         25.8MB
vfarcic/go-demo-3                                                latest                    1aef1abcd9ad        13 days ago         25.8MB
go-demo-2                                                        latest                    1aef1abcd9ad        13 days ago         25.8MB
vfarcic/go-demo-2                                                beta                      1aef1abcd9ad        13 days ago         25.8MB
<none>                                                           <none>                    f12797035f2a        13 days ago         763MB
mongo                                                            3.4                       69fa4aaef06d        13 days ago         360MB
dockerflow/docker-flow-swarm-listener                            beta                      fba6b90d3116        2 weeks ago         23.1MB
<none>                                                           <none>                    4a44963c3a36        2 weeks ago         600MB
<none>                                                           <none>                    d5414c481352        2 weeks ago         392MB
quay.io/kubernetes-ingress-controller/nginx-ingress-controller   0.14.0                    036ea1188e19        2 weeks ago         287MB
docker                                                           18.03-git                 8ff9a0906a2d        2 weeks ago         153MB
vfarcic/jenkins                                                  beta                      190ee1277a9c        3 weeks ago         396MB
vfarcic/jenkins                                                  latest                    190ee1277a9c        3 weeks ago         396MB
vfarcic/go-demo-2                                                <none>                    3f92f213ba6a        3 weeks ago         21.9MB
vfarcic/go-demo-3                                                <none>                    3f92f213ba6a        3 weeks ago         21.9MB
vfarcic/helm                                                     0.0.1                     ba9a15281bb0        3 weeks ago         136MB
vfarcic/helm                                                     latest                    ba9a15281bb0        3 weeks ago         136MB
dockerflow/docker-flow-swarm-listener                            <none>                    55eea45b426d        4 weeks ago         23.1MB
dockerflow/docker-flow-proxy                                     18.04.14-34               7478cdfda6cb        4 weeks ago         41.4MB
dockerflow/docker-flow-proxy                                     18.04.14-34-linux-amd64   7478cdfda6cb        4 weeks ago         41.4MB
dockerflow/docker-flow-proxy                                     latest                    7478cdfda6cb        4 weeks ago         41.4MB
vfarcic/kubectl                                                  latest                    f127d30febdb        4 weeks ago         72.1MB
jenkins/jenkins                                                  lts-alpine                22fbb1b0672c        4 weeks ago         223MB
jenkinsci/jenkins                                                lts-alpine                22fbb1b0672c        4 weeks ago         223MB
vfarcic/go-demo-3                                                <none>                    5b4e3136ac87        5 weeks ago         21.9MB
dockerflow/docker-flow-swarm-listener                            latest                    eaca11fdd451        5 weeks ago         23.1MB
vfarcic/docker-flow-swarm-listener                               latest                    eaca11fdd451        5 weeks ago         23.1MB
busybox                                                          latest                    8ac48589692a        5 weeks ago         1.15MB
vfarcic/docker-flow-proxy-test-base                              latest                    6756c8ce11f7        6 weeks ago         1.03GB
dockerflow/docker-flow-proxy-test-base                           latest                    6756c8ce11f7        6 weeks ago         1.03GB
jenkins/jnlp-slave                                               alpine                    9a9ac5d3082e        7 weeks ago         129MB
gcr.io/google_containers/kube-controller-manager-amd64           v1.9.6                    472b6fcfe871        7 weeks ago         139MB
gcr.io/google_containers/kube-apiserver-amd64                    v1.9.6                    a5c066e8c9bf        7 weeks ago         212MB
gcr.io/google_containers/kube-proxy-amd64                        v1.9.6                    70e63dd90b80        7 weeks ago         109MB
gcr.io/google_containers/kube-scheduler-amd64                    v1.9.6                    25d7b2c6f653        7 weeks ago         62.9MB
cvallance/mongo-k8s-sidecar                                      latest                    9cf0677e1253        7 weeks ago         87.3MB
vfarcic/go-demo-2                                                latest                    0e1ba2c8c4e1        8 weeks ago         21.9MB
vfarcic/go-demo-3                                                <none>                    0e1ba2c8c4e1        8 weeks ago         21.9MB
maven                                                            alpine                    08790c3343de        2 months ago        119MB
docker/kube-compose-controller                                   v0.3.0-rc4                960fed8457c5        2 months ago        30.6MB
docker/kube-compose-api-server                                   v0.3.0-rc4                adfd9ebd6d6d        2 months ago        43.8MB
golang                                                           1.10.0-alpine3.7          85256d3905e2        2 months ago        376MB
alpine                                                           3.7                       3fd9065eaf02        4 months ago        4.15MB
alpine                                                           latest                    3fd9065eaf02        4 months ago        4.15MB
gcr.io/kubernetes-helm/tiller                                    v2.8.0-rc.1               9c7df06f129b        4 months ago        71.5MB
vfarcic/devops-toolkit-series                                    beta2                     22f9af36862e        4 months ago        25.5MB
vfarcic/devops-toolkit-series                                    beta3                     22f9af36862e        4 months ago        25.5MB
vfarcic/github-release                                           latest                    c2389c562799        4 months ago        742MB
vfarcic/golang                                                   latest                    c840e5bf1149        4 months ago        737MB
vfarcic/gox                                                      <none>                    c840e5bf1149        4 months ago        737MB
golang                                                           1.8                       ba52c9ef0f5c        5 months ago        712MB
vfarcic/go-demo-private                                          latest                    15cb30c30c7b        5 months ago        21.5MB
vfarcic/go-demo-2                                                <none>                    15cb30c30c7b        5 months ago        21.5MB
gcr.io/google_containers/etcd-amd64                              3.1.11                    59d36f27cceb        5 months ago        194MB
books-ms                                                         latest                    1d7d5e7c39c1        5 months ago        776MB
vfarcic/books-ms                                                 latest                    1d7d5e7c39c1        5 months ago        776MB
vfarcic/presentations                                            latest                    7613ab68872e        6 months ago        15.5MB
golang                                                           1.9                       1a34fad76b34        6 months ago        733MB
alpine                                                           3.4                       dc98aa467aa0        6 months ago        4.81MB
gcr.io/google_containers/defaultbackend                          1.4                       846921f0fe0e        6 months ago        4.84MB
gcr.io/google_containers/k8s-dns-sidecar-amd64                   1.14.7                    db76ee297b85        6 months ago        42MB
gcr.io/google_containers/k8s-dns-kube-dns-amd64                  1.14.7                    5d049a8c4eec        6 months ago        50.3MB
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64             1.14.7                    5feec37454f4        6 months ago        41MB
mongo                                                            3.3                       3abda4f46443        18 months ago       401MB
gcr.io/google_containers/pause-amd64                             3.0                       99e59f495ffa        2 years ago         747kB
```

```bash
# If Docker For Mac/Windows, we are already logged in

docker login -u $DH_USER
```

```
Login Succeeded
```

```bash
docker image push \
    $DH_USER/go-demo-3:1.0-beta
```

```
The push refers to repository [docker.io/vfarcic/go-demo-3]
204fac4edea9: Pushed
f47c6332965c: Layer already exists
ef763da74d91: Layer already exists
1.0-beta: digest: sha256:586094296a214dbdbc5a3d7a921cb5f3679d89b66dd07e2879d1954f18ce9f99 size: 1157
```

* Explore [kaniko](https://github.com/GoogleContainerTools/kaniko)

## Functional Tests

```bash
cat ../go-demo-3/k8s/kubectl.yml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo-3-build

---

apiVersion: v1
kind: Pod
metadata:
  name: kubectl
  namespace: go-demo-3-build
spec:
  containers:
  - name: kubectl
    image: vfarcic/kubectl
    command: ["sleep"]
    args: ["100000"]
  serviceAccount: build
```

```bash
kubectl apply \
    -f ../go-demo-3/k8s/kubectl.yml
```

```
namespace "go-demo-3-build" configured
pod "kubectl" created
```

```bash
kubectl -n go-demo-3-build \
    get pods
```

```
NAME      READY     STATUS    RESTARTS   AGE
kubectl   1/1       Running   0          1m
```

```bash
# TODO: Need to figure out how to deploy kubectl without kubectl

kubectl -n go-demo-3-build \
    cp ../go-demo-3/k8s/build.yml \
    kubectl:/tmp/build.yml

kubectl -n go-demo-3-build \
    exec -it kubectl -- sh

kubectl auth can-i create deployment
```

```
yes
```

```bash
kubectl -n go-demo-3 \
    auth can-i create sts
```

```
yes
```

```bash
kubectl -n default \
    auth can-i create deployment
```

```
yes
```

```bash
kubectl auth can-i create ns
```

```
yes
```

```bash
cat /tmp/build.yml | sed -e \
    "s@:latest@:1.0-beta@g" | \
    tee build.yml
```

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: api
  namespace: go-demo-3-build
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    ingress.kubernetes.io/rewrite-target: "/demo"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: "/demo"
spec:
  rules:
  - http:
      paths:
      - path: /beta/demo
        backend:
          serviceName: api
          servicePort: 8080

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: db
  namespace: go-demo-3-build

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: db
  namespace: go-demo-3-build
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list"]

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: db
  namespace: go-demo-3-build
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: db
subjects:
- kind: ServiceAccount
  name: db

---

apiVersion: apps/v1beta2
kind: StatefulSet
metadata:
  name: db
  namespace: go-demo-3-build
spec:
  serviceName: db
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      serviceAccountName: db
      terminationGracePeriodSeconds: 10
      containers:
      - name: db
        image: mongo:3.3
        command:
          - mongod
          - "--replSet"
          - rs0
          - "--smallfiles"
          - "--noprealloc"
        ports:
          - containerPort: 27017
        resources:
          limits:
            memory: "200Mi"
            cpu: 0.2
          requests:
            memory: "100Mi"
            cpu: 0.1
        volumeMounts:
        - name: mongo-data
          mountPath: /data/db
      - name: db-sidecar
        image: cvallance/mongo-k8s-sidecar
        env:
        - name: MONGO_SIDECAR_POD_LABELS
          value: "app=db"
        - name: KUBE_NAMESPACE
          value: go-demo-3-build
        - name: KUBERNETES_MONGO_SERVICE_NAME
          value: db
  volumeClaimTemplates:
  - metadata:
      name: mongo-data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi

---

apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: go-demo-3-build
spec:
  ports:
  - port: 27017
  clusterIP: None
  selector:
    app: db

---

apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: api
  namespace: go-demo-3-build
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: vfarcic/go-demo-3:1.0-beta
        env:
        - name: DB
          value: db
        readinessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
          periodSeconds: 1
        livenessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
        resources:
          limits:
            memory: "20Mi"
            cpu: 0.2
          requests:
            memory: "10Mi"
            cpu: 0.1

---

apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: go-demo-3-build
spec:
  ports:
  - port: 8080
  selector:
    app: api
```

```bash
kubectl apply \
    -f /tmp/build.yml \
    --record
```

```
ingress "api" created
serviceaccount "db" created
role "db" created
rolebinding "db" created
statefulset "db" created
service "db" created
deployment "api" created
service "api" created
```

```bash
exit

# We won't do this any more. It's painful and unintuitive, but we'll need something similar later.

kubectl -n go-demo-3-build \
    rollout status deployment api
```

```
deployment "api" successfully rolled out
```

```bash
echo $?
```

```
0
```

```bash
kubectl -n go-demo-3-build \
    get pods
```

```
NAME                  READY     STATUS    RESTARTS   AGE
api-678bdd5b5-4sxsv   1/1       Running   1          1m
api-678bdd5b5-gnzjn   1/1       Running   1          1m
api-678bdd5b5-jpjnt   1/1       Running   1          1m
db-0                  2/2       Running   0          1m
db-1                  2/2       Running   0          1m
db-2                  2/2       Running   0          1m
kubectl               1/1       Running   0          4m
```

```bash
kubectl describe ns go-demo-3-build
```

```
Name:         go-demo-3-build
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"name":"go-demo-3-build","namespace":""}}

Status:  Active

Resource Quotas
 Name:            build
 Resource         Used    Hard
 --------         ---     ---
 limits.cpu       2       3
 limits.memory    1460Mi  4Gi
 pods             7       15
 requests.cpu     1       2
 requests.memory  730Mi   3Gi

Resource Limits
 Type       Resource  Min   Max    Default Request  Default Limit  Max Limit/Request Ratio
 ----       --------  ---   ---    ---------------  -------------  -----------------------
 Container  cpu       50m   500m   100m             200m           -
 Container  memory    10Mi  500Mi  100Mi            200Mi          -
```

```bash
DNS=$(kubectl -n go-demo-3-build \
    get ing api \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

curl "http://$DNS/beta/demo/hello"
```

```
hello, world!
```

```bash
kubectl -n go-demo-3-build \
    run golang \
    --quiet \
    --restart Never \
    --env GH_USER=$GH_USER \
    --env DNS=$DNS \
    --image golang:1.9 \
    sleep 1000000
```

```
pod "golang" created
```

```bash
# TODO: It'll be slow because of low defaults

kubectl -n go-demo-3-build \
    get pods
```

```
NAME                  READY     STATUS    RESTARTS   AGE
api-678bdd5b5-4sxsv   1/1       Running   1          4m
api-678bdd5b5-gnzjn   1/1       Running   1          4m
api-678bdd5b5-jpjnt   1/1       Running   1          4m
db-0                  2/2       Running   0          4m
db-1                  2/2       Running   0          4m
db-2                  2/2       Running   0          4m
golang                1/1       Running   0          1m
kubectl               1/1       Running   0          8m
```

```bash
kubectl -n go-demo-3-build \
    exec -it golang -- sh

git clone \
    https://github.com/$GH_USER/go-demo-3.git
```

```
Cloning into 'go-demo-3'...
remote: Counting objects: 102, done.
remote: Compressing objects: 100% (73/73), done.
remote: Total 102 (delta 46), reused 82 (delta 26), pack-reused 0
Receiving objects: 100% (102/102), 34.82 KiB | 0 bytes/s, done.
Resolving deltas: 100% (46/46), done.
```

```bash
cd go-demo-3

export ADDRESS=api:8080

go get -d -v -t
```

```
github.com/prometheus/client_golang (download)
github.com/beorn7/perks (download)
github.com/golang/protobuf (download)
github.com/prometheus/client_model (download)
github.com/prometheus/common (download)
github.com/matttproud/golang_protobuf_extensions (download)
github.com/prometheus/procfs (download)
Fetching https://gopkg.in/mgo.v2?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2?go-get=1 (status code 200)
get "gopkg.in/mgo.v2": found meta tag get.metaImport{Prefix:"gopkg.in/mgo.v2", VCS:"git", RepoRoot:"https://gopkg.in/mgo.v2"} at https://gopkg.in/mgo.v2?go-get=1
gopkg.in/mgo.v2 (download)
Fetching https://gopkg.in/mgo.v2/bson?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2/bson?go-get=1 (status code 200)
get "gopkg.in/mgo.v2/bson": found meta tag get.metaImport{Prefix:"gopkg.in/mgo.v2", VCS:"git", RepoRoot:"https://gopkg.in/mgo.v2"} at https://gopkg.in/mgo.v2/bson?go-get=1
get "gopkg.in/mgo.v2/bson": verifying non-authoritative meta tag
Fetching https://gopkg.in/mgo.v2?go-get=1
Parsing meta tags from https://gopkg.in/mgo.v2?go-get=1 (status code 200)
github.com/stretchr/testify (download)
```

```bash
go test ./... -v --run FunctionalTest
```

```
=== RUN   TestFunctionalTestSuite
=== RUN   TestFunctionalTestSuite/Test_Hello_ReturnsStatus200
2018/05/14 14:41:25 Sending a request to http://api:8080/demo/hello
=== RUN   TestFunctionalTestSuite/Test_Person_ReturnsStatus200
2018/05/14 14:41:25 Sending a request to http://api:8080/demo/person
--- PASS: TestFunctionalTestSuite (0.03s)
    --- PASS: TestFunctionalTestSuite/Test_Hello_ReturnsStatus200 (0.01s)
    --- PASS: TestFunctionalTestSuite/Test_Person_ReturnsStatus200 (0.01s)
PASS
ok      _/go/go-demo-3  0.129s
```

```bash
export ADDRESS=$DNS/beta

go test ./... -v --run FunctionalTest

# Fails on Docker for Mac/Windows bacause of localhost. Change to `export ADDRESS=api:8080`

exit

# TODO: Can't delete the Namespace since it's set up by a cluster admin. Also, we still need that Namespace.

kubectl delete \
    -f ../go-demo-3/k8s/build.yml
```

```
kubectl -n go-demo-3-build get all
ingress "api" deleted
serviceaccount "db" deleted
role "db" deleted
rolebinding "db" deleted
statefulset "db" deleted
service "db" deleted
deployment "api" deleted
service "api" deleted
```

```bash
kubectl -n go-demo-3-build get all
```

```
NAME         READY     STATUS    RESTARTS   AGE
po/golang    1/1       Running   0          32m
po/kubectl   1/1       Running   0          39m
```

## Release

```bash
docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:1.0

docker image push \
    $DH_USER/go-demo-3:1.0
```

```
The push refers to repository [docker.io/vfarcic/go-demo-3]
204fac4edea9: Layer already exists
f47c6332965c: Layer already exists
ef763da74d91: Layer already exists
1.0: digest: sha256:586094296a214dbdbc5a3d7a921cb5f3679d89b66dd07e2879d1954f18ce9f99 size: 1157
```

```bash
docker image tag \
    $DH_USER/go-demo-3:1.0-beta \
    $DH_USER/go-demo-3:latest

docker image push \
    $DH_USER/go-demo-3:latest
```

```
The push refers to repository [docker.io/vfarcic/go-demo-3]
204fac4edea9: Preparing
204fac4edea9: Preparing
f47c6332965c: Preparing
ef763da74d91: Preparing
f47c6332965c: Layer already exists
ef763da74d91: Layer already exists
204fac4edea9: Layer already exists
latest: digest: sha256:586094296a214dbdbc5a3d7a921cb5f3679d89b66dd07e2879d1954f18ce9f99 size: 1157
```

## Deploy

```bash
cat ../go-demo-3/k8s/prod.yml \
    | sed -e "s@:latest@:1.0@g" \
    | tee prod.yml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo-3

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: api
  namespace: go-demo-3
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /demo
        backend:
          serviceName: api
          servicePort: 8080

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: db
  namespace: go-demo-3

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: db
  namespace: go-demo-3
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list"]

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: db
  namespace: go-demo-3
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: db
subjects:
- kind: ServiceAccount
  name: db

---

apiVersion: apps/v1beta2
kind: StatefulSet
metadata:
  name: db
  namespace: go-demo-3
spec:
  serviceName: db
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      serviceAccountName: db
      terminationGracePeriodSeconds: 10
      containers:
      - name: db
        image: mongo:3.3
        command:
          - mongod
          - "--replSet"
          - rs0
          - "--smallfiles"
          - "--noprealloc"
        ports:
          - containerPort: 27017
        resources:
          limits:
            memory: "200Mi"
            cpu: 0.2
          requests:
            memory: "100Mi"
            cpu: 0.1
        volumeMounts:
        - name: mongo-data
          mountPath: /data/db
      - name: db-sidecar
        image: cvallance/mongo-k8s-sidecar
        env:
        - name: MONGO_SIDECAR_POD_LABELS
          value: "app=db"
        - name: KUBE_NAMESPACE
          value: go-demo-3
        - name: KUBERNETES_MONGO_SERVICE_NAME
          value: db
  volumeClaimTemplates:
  - metadata:
      name: mongo-data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi

---

apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: go-demo-3
spec:
  ports:
  - port: 27017
  clusterIP: None
  selector:
    app: db

---

apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: api
  namespace: go-demo-3
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: vfarcic/go-demo-3:1.0
        env:
        - name: DB
          value: db
        readinessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
          periodSeconds: 1
        livenessProbe:
          httpGet:
            path: /demo/hello
            port: 8080
        resources:
          limits:
            memory: "20Mi"
            cpu: 0.2
          requests:
            memory: "10Mi"
            cpu: 0.1

---

apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: go-demo-3
spec:
  ports:
  - port: 8080
  selector:
    app: api
```

```bash
kubectl apply -f prod.yml --record
```

```
namespace "go-demo-3" configured
ingress "api" created
serviceaccount "db" created
role "db" created
rolebinding "db" created
statefulset "db" created
service "db" created
deployment "api" created
service "api" created
```

```bash
kubectl -n go-demo-3 \
    rollout status deployment api
```

```
deployment "api" successfully rolled out
```

```bash
echo $?
```

```
0
```

```bash
kubectl -n go-demo-3 get pods
```

```
NAME                   READY     STATUS    RESTARTS   AGE
api-6556587fcc-2nbj2   1/1       Running   1          1m
api-6556587fcc-hgznt   1/1       Running   1          1m
api-6556587fcc-v2bw4   1/1       Running   1          1m
db-0                   2/2       Running   0          1m
db-1                   2/2       Running   0          1m
db-2                   2/2       Running   0          1m
```

```bash
curl "http://$DNS/demo/hello"
```

```
hello, world!
```

## Production Testing

```bash
kubectl -n go-demo-3-build \
    exec -it golang -- sh

cd go-demo-3

export ADDRESS=$DNS

# Fails on Docker for Mac/Windows bacause of localhost. Change to `export ADDRESS=api.go-demo-3:8080`

go test ./... -v --run ProductionTest
```

```
=== RUN   TestProductionTestSuite
=== RUN   TestProductionTestSuite/Test_Hello_ReturnsStatus200
--- PASS: TestProductionTestSuite (0.10s)
    --- PASS: TestProductionTestSuite/Test_Hello_ReturnsStatus200 (0.01s)
PASS
ok      _/go/go-demo-3  0.107s
```

```bash
exit

# TODO: Release files to GH

# TODO: Manifest

# TODO: Static analysis

# TODO: Security scanning

# TODO: Need a single Pod with everything
```

## Cleaning Up

```bash
kubectl -n go-demo-3-build \
    get pods
```

```
NAME      READY     STATUS    RESTARTS   AGE
golang    1/1       Running   0          1h
kubectl   1/1       Running   0          1h
```

```bash
# Still left with "tool" Pods. Need to figure out how to remove them automatically.

kubectl -n go-demo-3-build \
    delete pods --all 
```

```
pod "golang" deleted
pod "kubectl" deleted
```

## What Now?

```bash
kubectl delete ns \
    go-demo-3 go-demo-3-build
```