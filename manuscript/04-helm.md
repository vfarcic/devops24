`## TODO

- [X] Code
- [X] Code review Docker for Mac/Windows
- [X] Code review minikube
- [ ] Code review kops
- [ ] Code review minishift
- [ ] Code review GKE
- [ ] Write
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

# Helm

## Cluster

```bash
cd k8s-specs

git pull
```

## Setup

```bash
open "https://github.com/kubernetes/helm/releases"

# Or https://docs.helm.sh/using_helm/#installing-the-helm-client

# helm 2.8.2 or older fails on Docker For Mac/Windows. Upgrade

cat helm/tiller-rbac.yml
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

```bash
kubectl create \
    -f helm/tiller-rbac.yml \
    --record --save-config
```

```
serviceaccount "tiller" created
clusterrolebinding "tiller" created
```

```bash
helm init --service-account tiller

kubectl -n kube-system \
    rollout status deploy tiller-deploy
```

```
deployment "tiller-deploy" successfully rolled out
```

```bash
kubectl -n kube-system get pods
```

```
NAME              READY STATUS  RESTARTS AGE
...
tiller-deploy-... 1/1   Running 0        59s
```

## Jenkins

```bash
helm repo update
```

```
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

```bash
helm search
```

```
...
stable/weave-scope 0.9.2 1.6.5 A Helm chart for the Weave Scope cluster visual...
stable/wordpress   1.0.7 4.9.6 Web publishing platform for building blogs and ...
stable/zeppelin    1.0.1 0.7.2 Web-based notebook that enables data-driven, in...
stable/zetcd       0.1.9 0.0.3 CoreOS zetcd Helm chart for Kubernetes            
```

```bash
helm search jenkins
```

```
NAME           CHART VERSION APP VERSION DESCRIPTION                                       
stable/jenkins 0.16.1        2.107       Open source continuous integration server. It s...
```

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins

# If minikube
helm upgrade jenkins stable/jenkins \
    --set Master.ServiceType=NodePort
```

```
NAME:   jenkins
LAST DEPLOYED: Thu May 24 11:46:38 2018
NAMESPACE: jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                      READY  STATUS   RESTARTS  AGE
jenkins-7b878f4bc5-g949p  0/1    Pending  0         0s

==> v1/Secret
NAME     TYPE    DATA  AGE
jenkins  Opaque  2     1s

==> v1/ConfigMap
NAME           DATA  AGE
jenkins        4     1s
jenkins-tests  1     1s

==> v1/PersistentVolumeClaim
NAME     STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
jenkins  Bound   pvc-5aff839b-5f37-11e8-8048-0298ec4acca6  8Gi       RWO           gp2           1s

==> v1/Service
NAME           TYPE          CLUSTER-IP     EXTERNAL-IP  PORT(S)         AGE
jenkins-agent  ClusterIP     100.69.82.146  <none>       50000/TCP       1s
jenkins        LoadBalancer  100.67.217.52  <pending>    8080:31001/TCP  0s

==> v1beta1/Deployment
NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
jenkins  1        1        1           0          0s


NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
```

```bash
kubectl -n jenkins \
    rollout status deploy jenkins
```

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "jenkins" successfully rolled out
```

```bash
kubectl -n jenkins get all
```

```
NAME           DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
deploy/jenkins 1       1       1          1         3m
NAME           DESIRED CURRENT READY AGE
rs/jenkins-... 1       1       1     3m
NAME           DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
deploy/jenkins 1       1       1          1         3m
NAME           DESIRED CURRENT READY AGE
rs/jenkins-... 1       1       1     3m
NAME           READY STATUS  RESTARTS AGE
po/jenkins-... 1/1   Running 0        3m
NAME              TYPE         CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
svc/jenkins       LoadBalancer 100.67.217.52 a5b0e62445f37... 8080:31001/TCP 3m
svc/jenkins-agent ClusterIP    100.69.82.146 <none>           50000/TCP      3m
```

```bash
ADDR=$(kubectl -n jenkins \
    get svc jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080

# If Minikube
ADDR=$(minikube ip):$(kubectl \
    -n jenkins get svc jenkins \
    -o jsonpath="{.spec.ports[0].nodePort}")

echo $ADDR
```

```
a5b0e62445f3711e880480298ec4acca-2100257423.us-east-2.elb.amazonaws.com
```

```bash
open "http://$ADDR"

kubectl -n jenkins \
    get secret jenkins \
    -o jsonpath="{.data.jenkins-admin-password}" \
    | base64 --decode; echo
```

```
shP7Fcsb9g
```

```bash
# Copy the output
# Type *admin* into the *User* field
# Paste the copied output into the *Password* field
# Press the *log in* button

helm inspect stable/jenkins

# Output is too big. It contains all the info we need.

helm ls
```

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 1        Thu May ... DEPLOYED jenkins-0.16.1 jenkins
```

```bash
helm status jenkins
```

```
LAST DEPLOYED: Thu May 24 11:46:38 2018
NAMESPACE: jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME     TYPE    DATA  AGE
jenkins  Opaque  2     12m

==> v1/ConfigMap
NAME           DATA  AGE
jenkins        4     12m
jenkins-tests  1     12m

==> v1/PersistentVolumeClaim
NAME     STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
jenkins  Bound   pvc-5aff839b-5f37-11e8-8048-0298ec4acca6  8Gi       RWO           gp2           12m

==> v1/Service
NAME           TYPE          CLUSTER-IP     EXTERNAL-IP       PORT(S)         AGE
jenkins-agent  ClusterIP     100.69.82.146  <none>            50000/TCP       12m
jenkins        LoadBalancer  100.67.217.52  a5b0e62445f37...  8080:31001/TCP  12m

==> v1beta1/Deployment
NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
jenkins  1        1        1           1          12m

==> v1/Pod(related)
NAME                      READY  STATUS   RESTARTS  AGE
jenkins-7b878f4bc5-g949p  1/1    Running  0         12m


NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
```

```bash
helm delete jenkins
```

```
release "jenkins" deleted
```

```bash
kubectl -n jenkins get all
```

```
No resources found.
```

```bash
helm status jenkins
```

```
LAST DEPLOYED: Thu May 24 11:46:38 2018
NAMESPACE: jenkins
STATUS: DELETED

NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
```

```bash
helm delete jenkins --purge
```

```
release "jenkins" deleted
```

```bash
helm status jenkins
```

```
Error: getting deployed release "jenkins": release: "jenkins" not found
```

```bash
helm inspect values stable/jenkins
```

```
# Default values for jenkins.
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value

## Overrides for generated resource names
# See templates/_helpers.tpl
# nameOverride:
# fullnameOverride:

Master:
  Name: jenkins-master
  Image: "jenkins/jenkins"
  ImageTag: "lts"
  ImagePullPolicy: "Always"
# ImagePullSecret: jenkins
  Component: "jenkins-master"
  UseSecurity: true
  AdminUser: admin
  # AdminPassword: <defaults to random>
  Cpu: "200m"
  Memory: "256Mi"
  # Environment variables that get added to the init container (useful for e.g. http_proxy)
  # InitContainerEnv:
  #   - name: http_proxy
  #     value: "http://192.168.64.1:3128"
  # ContainerEnv:
  #   - name: http_proxy
  #     value: "http://192.168.64.1:3128"
  # Set min/max heap here if needed with:
  # JavaOpts: "-Xms512m -Xmx512m"
  # JenkinsOpts: ""
  # JenkinsUriPrefix: "/jenkins"
  # Set RunAsUser to 1000 to let Jenkins run as non-root user 'jenkins' which exists in 'jenkins/jenkins' docker image.
  # When setting RunAsUser to a different value than 0 also set FsGroup to the same value:
  # RunAsUser: <defaults to 0>
  # FsGroup: <will be omitted in deployment if RunAsUser is 0>
  ServicePort: 8080
  # For minikube, set this to NodePort, elsewhere use LoadBalancer
  # Use ClusterIP if your setup includes ingress controller
  ServiceType: LoadBalancer
  # Master Service annotations
  ServiceAnnotations: {}
  #   service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
  # Used to create Ingress record (should used with ServiceType: ClusterIP)
  # HostName: jenkins.cluster.local
  # NodePort: <to set explicitly, choose port between 30000-32767
  ContainerPort: 8080
  # Enable Kubernetes Liveness and Readiness Probes
  HealthProbes: true
  HealthProbesTimeout: 60
  # ~2 minutes to allow Jenkins to restart when upgrading plugins
  HealthProbeLivenessFailureThreshold: 12
  SlaveListenerPort: 50000
  DisabledAgentProtocols:
    - JNLP-connect
    - JNLP2-connect
  CSRF:
    DefaultCrumbIssuer:
      Enabled: true
      ProxyCompatability: true
  CLI: false
  # Kubernetes service type for the JNLP slave service
  # SETTING THIS TO "LoadBalancer" IS A HUGE SECURITY RISK: https://github.com/kubernetes/charts/issues/1341
  SlaveListenerServiceType: ClusterIP
  SlaveListenerServiceAnnotations: {}
  LoadBalancerSourceRanges:
  - 0.0.0.0/0
  # Optionally assign a known public LB IP
  # LoadBalancerIP: 1.2.3.4
  # Optionally configure a JMX port
  # requires additional JavaOpts, ie
  # JavaOpts: >
  #   -Dcom.sun.management.jmxremote.port=4000
  #   -Dcom.sun.management.jmxremote.authenticate=false
  #   -Dcom.sun.management.jmxremote.ssl=false
  # JMXPort: 4000
  # List of plugins to be install during Jenkins master start
  InstallPlugins:
    - kubernetes:1.1
    - workflow-aggregator:2.5
    - workflow-job:2.15
    - credentials-binding:1.13
    - git:3.6.4
  # Used to approve a list of groovy functions in pipelines used the script-security plugin. Can be viewed under /scriptApproval
  # ScriptApproval:
  #   - "method groovy.json.JsonSlurperClassic parseText java.lang.String"
  #   - "new groovy.json.JsonSlurperClassic"
  # List of groovy init scripts to be executed during Jenkins master start
  InitScripts:
  #  - |
  #    print 'adding global pipeline libraries, register properties, bootstrap jobs...'
  # Kubernetes secret that contains a 'credentials.xml' for Jenkins
  # CredentialsXmlSecret: jenkins-credentials
  # Kubernetes secret that contains files to be put in the Jenkins 'secrets' directory,
  # useful to manage encryption keys used for credentials.xml for instance (such as
  # master.key and hudson.util.Secret)
  # SecretsFilesSecret: jenkins-secrets
  # Jenkins XML job configs to provision
  # Jobs: |-
  #   test: |-
  #     <<xml here>>
  CustomConfigMap: false
  # Node labels and tolerations for pod assignment
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#taints-and-tolerations-beta-feature
  NodeSelector: {}
  Tolerations: {}

  Ingress:
    ApiVersion: extensions/v1beta1
    Annotations:
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"

    TLS:
    # - secretName: jenkins.cluster.local
    #   hosts:
    #     - jenkins.cluster.local

Agent:
  Enabled: true
  Image: jenkins/jnlp-slave
  ImageTag: 3.10-1
# ImagePullSecret: jenkins
  Component: "jenkins-slave"
  Privileged: false
  Cpu: "200m"
  Memory: "256Mi"
  # You may want to change this to true while testing a new image
  AlwaysPullImage: false
  # You can define the volumes that you want to mount for this container
  # Allowed types are: ConfigMap, EmptyDir, HostPath, Nfs, Pod, Secret
  # Configure the attributes as they appear in the corresponding Java class for that type
  # https://github.com/jenkinsci/kubernetes-plugin/tree/master/src/main/java/org/csanchez/jenkins/plugins/kubernetes/volumes
  volumes:
  # - type: Secret
  #   secretName: mysecret
  #   mountPath: /var/myapp/mysecret
  NodeSelector: {}
  # Key Value selectors. Ex:
  # jenkins-agent: v1

Persistence:
  Enabled: true
  ## A manually managed Persistent Volume and Claim
  ## Requires Persistence.Enabled: true
  ## If defined, PVC must be created manually before volume will be bound
  # ExistingClaim:

  ## jenkins data Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # StorageClass: "-"

  Annotations: {}
  AccessMode: ReadWriteOnce
  Size: 8Gi
  volumes:
  #  - name: nothing
  #    emptyDir: {}
  mounts:
  #  - mountPath: /var/nothing
  #    name: nothing
  #    readOnly: true

NetworkPolicy:
  # Enable creation of NetworkPolicy resources.
  Enabled: false
  # For Kubernetes v1.4, v1.5 and v1.6, use 'extensions/v1beta1'
  # For Kubernetes v1.7, use 'networking.k8s.io/v1'
  ApiVersion: extensions/v1beta1

## Install Default RBAC roles and bindings
rbac:
  install: false
  serviceAccountName: default
  # RBAC api version (currently either v1beta1 or v1alpha1)
  apiVersion: v1beta1
  # Cluster role reference
  roleRef: cluster-admin
```

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --set Master.ImageTag=2.112-alpine

# If minikube
helm upgrade jenkins stable/jenkins \
    --set Master.ServiceType=NodePort \
    --reuse-values
```

```
NAME:   jenkins
LAST DEPLOYED: Thu May 24 12:09:43 2018
NAMESPACE: jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME           DATA  AGE
jenkins        4     1s
jenkins-tests  1     1s

==> v1/PersistentVolumeClaim
NAME     STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
jenkins  Bound   pvc-9428598f-5f3a-11e8-8048-0298ec4acca6  8Gi       RWO           gp2           1s

==> v1/Service
NAME           TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)         AGE
jenkins-agent  ClusterIP     100.69.148.162  <none>       50000/TCP       1s
jenkins        LoadBalancer  100.69.89.148   <pending>    8080:32107/TCP  1s

==> v1beta1/Deployment
NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
jenkins  1        1        1           0          1s

==> v1/Pod(related)
NAME                     READY  STATUS   RESTARTS  AGE
jenkins-cb6699c65-ncsrx  0/1    Pending  0         1s

==> v1/Secret
NAME     TYPE    DATA  AGE
jenkins  Opaque  2     1s


NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
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
# If Minikube
ADDR=$(minikube ip):$(kubectl \
    -n jenkins get svc jenkins \
    -o jsonpath="{.spec.ports[0].nodePort}")

echo $ADDR

open "http://$ADDR"

# Note the version on the bottom-right (*Jenkins ver. 2.112*)

helm upgrade jenkins stable/jenkins \
    --set Master.ImageTag=2.116-alpine \
    --reuse-values
```

```
Release "jenkins" has been upgraded. Happy Helming!
LAST DEPLOYED: Thu May 24 12:51:03 2018
NAMESPACE: jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                      READY  STATUS       RESTARTS  AGE
jenkins-686d57d8dc-bgk2z  0/1    Init:0/1     0         1s
jenkins-cb6699c65-ncsrx   1/1    Terminating  0         41m

==> v1/Secret
NAME     TYPE    DATA  AGE
jenkins  Opaque  2     41m

==> v1/ConfigMap
NAME           DATA  AGE
jenkins        4     41m
jenkins-tests  1     41m

==> v1/PersistentVolumeClaim
NAME     STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
jenkins  Bound   pvc-9428598f-5f3a-11e8-8048-0298ec4acca6  8Gi       RWO           gp2           41m

==> v1/Service
NAME           TYPE          CLUSTER-IP      EXTERNAL-IP       PORT(S)         AGE
jenkins-agent  ClusterIP     100.69.148.162  <none>            50000/TCP       41m
jenkins        LoadBalancer  100.69.89.148   a943689835f3a...  8080:32107/TCP  41m

==> v1beta1/Deployment
NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
jenkins  1        1        1           0          41m


NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
```

```bash
kubectl -n jenkins \
    describe deployment jenkins
```

```
Name:              jenkins
Namespace:         jenkins
CreationTimestamp: Thu, 24 May 2018 12:09:43 +0200
Labels:            chart=jenkins-0.16.1
                   component=jenkins-jenkins-master
                   heritage=Tiller
                   release=jenkins
Annotations:       deployment.kubernetes.io/revision=2
Selector:          component=jenkins-jenkins-master
Replicas:          1 desired | 1 updated | 1 total | 0 available | 1 unavailable
StrategyType:      RollingUpdate
MinReadySeconds:   0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels: app=jenkins
          chart=jenkins-0.16.1
          component=jenkins-jenkins-master
          heritage=Tiller
          release=jenkins
  Annotations:     checksum/config=b52b9df091fdd8f124fe114294e33bebd438c0f8384e0ef784e17e5a7c37be20
  Service Account: default
  Init Containers:
   copy-default-config:
    Image: jenkins/jenkins:2.116-alpine
    Port:  <none>
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
    Image: jenkins/jenkins:2.116-alpine
    Ports: 8080/TCP, 50000/TCP
    Args:
      --argumentsRealm.passwd.$(ADMIN_USER)=$(ADMIN_PASSWORD)
      --argumentsRealm.roles.$(ADMIN_USER)=admin
    Requests:
      cpu:     200m
      memory:  256Mi
    Liveness:  http-get http://:http/login delay=60s timeout=5s period=10s #success=1 #failure=12
    Readiness: http-get http://:http/login delay=60s timeout=1s period=10s #success=1 #failure=3
    Environment:
      JAVA_OPTS:       
      JENKINS_OPTS:    
      ADMIN_PASSWORD: <set to the key 'jenkins-admin-password' in secret 'jenkins'>  Optional: false
      ADMIN_USER:     <set to the key 'jenkins-admin-user' in secret 'jenkins'>      Optional: false
    Mounts:
      /usr/share/jenkins/ref/plugins/ from plugin-dir (rw)
      /usr/share/jenkins/ref/secrets/ from secrets-dir (rw)
      /var/jenkins_config from jenkins-config (ro)
      /var/jenkins_home from jenkins-home (rw)
  Volumes:
   jenkins-config:
    Type:     ConfigMap (a volume populated by a ConfigMap)
    Name:     jenkins
    Optional: false
   plugin-dir:
    Type:   EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  
   secrets-dir:
    Type:   EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:  
   jenkins-home:
    Type:      PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName: jenkins
    ReadOnly:  false
Conditions:
  Type          Status  Reason
  ----          ------  ------
  Available     True    MinimumReplicasAvailable
OldReplicaSets: jenkins-686d57d8dc (1/1 replicas created)
NewReplicaSet:  <none>
Events:
  Type   Reason            Age  From                  Message
  ----   ------            ---- ----                  -------
  Normal ScalingReplicaSet 41m  deployment-controller Scaled up replica set jenkins-cb6699c65 to 1
  Normal ScalingReplicaSet 32s  deployment-controller Scaled up replica set jenkins-686d57d8dc to 1
  Normal ScalingReplicaSet 32s  deployment-controller Scaled down replica set jenkins-cb6699c65 to 0
```

```bash
kubectl -n jenkins \
    rollout status deployment jenkins
```

```
deployment "jenkins" successfully rolled out
```

```bash
open "http://$ADDR"

# Note the version on the bottom-right (*Jenkins ver. 2.116*)

helm list
```

```
NAME    REVISION UPDATED     STATUS   CHART          NAMESPACE
jenkins 2        Thu May ... DEPLOYED jenkins-0.16.1 jenkins  
```

```bash
# minikube will be on revision 3

# Do NOT Execute it
helm rollback jenkins 1

helm rollback jenkins 0

# 0 is an undocumented feature
```

```
Rollback was a success! Happy Helming!
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
open "http://$ADDR"

# Note the version on the bottom-right (*Jenkins ver. 2.112*)

helm delete jenkins --purge

# If AWS with kops
HOST=jenkins.$(kubectl \
    -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}").xip.io

# If Docker for Mac/Windows
HOST="jenkins.127.0.0.1.xip.io"

# If minikube
HOST="jenkins.$(minikube ip).xip.io"

echo $HOST
```

```
TODO: Output
```

```bash
helm inspect values stable/jenkins
```

```yaml
# Default values for jenkins.
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value

## Overrides for generated resource names
# See templates/_helpers.tpl
# nameOverride:
# fullnameOverride:

Master:
  Name: jenkins-master
  Image: "jenkins/jenkins"
  ImageTag: "lts"
  ImagePullPolicy: "Always"
# ImagePullSecret: jenkins
  Component: "jenkins-master"
  UseSecurity: true
  AdminUser: admin
  # AdminPassword: <defaults to random>
  Cpu: "200m"
  Memory: "256Mi"
  # Environment variables that get added to the init container (useful for e.g. http_proxy)
  # InitContainerEnv:
  #   - name: http_proxy
  #     value: "http://192.168.64.1:3128"
  # ContainerEnv:
  #   - name: http_proxy
  #     value: "http://192.168.64.1:3128"
  # Set min/max heap here if needed with:
  # JavaOpts: "-Xms512m -Xmx512m"
  # JenkinsOpts: ""
  # JenkinsUriPrefix: "/jenkins"
  # Set RunAsUser to 1000 to let Jenkins run as non-root user 'jenkins' which exists in 'jenkins/jenkins' docker image.
  # When setting RunAsUser to a different value than 0 also set FsGroup to the same value:
  # RunAsUser: <defaults to 0>
  # FsGroup: <will be omitted in deployment if RunAsUser is 0>
  ServicePort: 8080
  # For minikube, set this to NodePort, elsewhere use LoadBalancer
  # Use ClusterIP if your setup includes ingress controller
  ServiceType: LoadBalancer
  # Master Service annotations
  ServiceAnnotations: {}
  #   service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
  # Used to create Ingress record (should used with ServiceType: ClusterIP)
  # HostName: jenkins.cluster.local
  # NodePort: <to set explicitly, choose port between 30000-32767
  ContainerPort: 8080
  # Enable Kubernetes Liveness and Readiness Probes
  HealthProbes: true
  HealthProbesTimeout: 60
  # ~2 minutes to allow Jenkins to restart when upgrading plugins
  HealthProbeLivenessFailureThreshold: 12
  SlaveListenerPort: 50000
  DisabledAgentProtocols:
    - JNLP-connect
    - JNLP2-connect
  CSRF:
    DefaultCrumbIssuer:
      Enabled: true
      ProxyCompatability: true
  CLI: false
  # Kubernetes service type for the JNLP slave service
  # SETTING THIS TO "LoadBalancer" IS A HUGE SECURITY RISK: https://github.com/kubernetes/charts/issues/1341
  SlaveListenerServiceType: ClusterIP
  SlaveListenerServiceAnnotations: {}
  LoadBalancerSourceRanges:
  - 0.0.0.0/0
  # Optionally assign a known public LB IP
  # LoadBalancerIP: 1.2.3.4
  # Optionally configure a JMX port
  # requires additional JavaOpts, ie
  # JavaOpts: >
  #   -Dcom.sun.management.jmxremote.port=4000
  #   -Dcom.sun.management.jmxremote.authenticate=false
  #   -Dcom.sun.management.jmxremote.ssl=false
  # JMXPort: 4000
  # List of plugins to be install during Jenkins master start
  InstallPlugins:
    - kubernetes:1.1
    - workflow-aggregator:2.5
    - workflow-job:2.15
    - credentials-binding:1.13
    - git:3.6.4
  # Used to approve a list of groovy functions in pipelines used the script-security plugin. Can be viewed under /scriptApproval
  # ScriptApproval:
  #   - "method groovy.json.JsonSlurperClassic parseText java.lang.String"
  #   - "new groovy.json.JsonSlurperClassic"
  # List of groovy init scripts to be executed during Jenkins master start
  InitScripts:
  #  - |
  #    print 'adding global pipeline libraries, register properties, bootstrap jobs...'
  # Kubernetes secret that contains a 'credentials.xml' for Jenkins
  # CredentialsXmlSecret: jenkins-credentials
  # Kubernetes secret that contains files to be put in the Jenkins 'secrets' directory,
  # useful to manage encryption keys used for credentials.xml for instance (such as
  # master.key and hudson.util.Secret)
  # SecretsFilesSecret: jenkins-secrets
  # Jenkins XML job configs to provision
  # Jobs: |-
  #   test: |-
  #     <<xml here>>
  CustomConfigMap: false
  # Node labels and tolerations for pod assignment
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#taints-and-tolerations-beta-feature
  NodeSelector: {}
  Tolerations: {}

  Ingress:
    ApiVersion: extensions/v1beta1
    Annotations:
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"

    TLS:
    # - secretName: jenkins.cluster.local
    #   hosts:
    #     - jenkins.cluster.local

Agent:
  Enabled: true
  Image: jenkins/jnlp-slave
  ImageTag: 3.10-1
# ImagePullSecret: jenkins
  Component: "jenkins-slave"
  Privileged: false
  Cpu: "200m"
  Memory: "256Mi"
  # You may want to change this to true while testing a new image
  AlwaysPullImage: false
  # You can define the volumes that you want to mount for this container
  # Allowed types are: ConfigMap, EmptyDir, HostPath, Nfs, Pod, Secret
  # Configure the attributes as they appear in the corresponding Java class for that type
  # https://github.com/jenkinsci/kubernetes-plugin/tree/master/src/main/java/org/csanchez/jenkins/plugins/kubernetes/volumes
  volumes:
  # - type: Secret
  #   secretName: mysecret
  #   mountPath: /var/myapp/mysecret
  NodeSelector: {}
  # Key Value selectors. Ex:
  # jenkins-agent: v1

Persistence:
  Enabled: true
  ## A manually managed Persistent Volume and Claim
  ## Requires Persistence.Enabled: true
  ## If defined, PVC must be created manually before volume will be bound
  # ExistingClaim:

  ## jenkins data Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # StorageClass: "-"

  Annotations: {}
  AccessMode: ReadWriteOnce
  Size: 8Gi
  volumes:
  #  - name: nothing
  #    emptyDir: {}
  mounts:
  #  - mountPath: /var/nothing
  #    name: nothing
  #    readOnly: true

NetworkPolicy:
  # Enable creation of NetworkPolicy resources.
  Enabled: false
  # For Kubernetes v1.4, v1.5 and v1.6, use 'extensions/v1beta1'
  # For Kubernetes v1.7, use 'networking.k8s.io/v1'
  ApiVersion: extensions/v1beta1

## Install Default RBAC roles and bindings
rbac:
  install: false
  serviceAccountName: default
  # RBAC api version (currently either v1beta1 or v1alpha1)
  apiVersion: v1beta1
  # Cluster role reference
  roleRef: cluster-admin
```

```bash
cat helm/jenkins-values.yml
```

```yaml
Master:
  ImageTag: "2.116-alpine"
  Cpu: "500m"
  Memory: "500Mi"
  ServiceType: ClusterIP
  ServiceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
  InstallPlugins:
    - blueocean:1.5.0
    - credentials:2.1.16
    - ec2:1.39
    - git:3.8.0
    - git-client:2.7.1
    - github:1.29.0
    - kubernetes:1.5.2
    - pipeline-utility-steps:2.0.2
    - script-security:1.43
    - slack:2.3
    - thinBackup:1.9
    - workflow-aggregator:2.5
  Ingress:
    Annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      ingress.kubernetes.io/ssl-redirect: "false"
      ingress.kubernetes.io/proxy-body-size: 50m
      ingress.kubernetes.io/proxy-request-buffering: "off"
  HostName: jenkins.acme.com
rbac:
  install: true
```

```bash
helm install stable/jenkins \
    --name jenkins \
    --namespace jenkins \
    --values helm/jenkins-values.yml \
    --set Master.HostName=$HOST

kubectl -n jenkins \
    rollout status deployment jenkins
```

```
Waiting for rollout to finish: 0 of 1 updated replicas are available...
deployment "jenkins" successfully rolled out
```

```bash
open "http://$HOST"

helm get values jenkins
```

```yaml
Master:
  Cpu: 500m
  HostName: jenkins.18.220.212.56.xip.io
  ImageTag: 2.116-alpine
  Ingress:
    Annotations:
      ingress.kubernetes.io/proxy-body-size: 50m
      ingress.kubernetes.io/proxy-request-buffering: "off"
      ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
  InstallPlugins:
  - blueocean:1.5.0
  - credentials:2.1.16
  - ec2:1.39
  - git:3.8.0
  - git-client:2.7.1
  - github:1.29.0
  - kubernetes:1.5.2
  - pipeline-utility-steps:2.0.2
  - script-security:1.43
  - slack:2.3
  - thinBackup:1.9
  - workflow-aggregator:2.5
  Memory: 500Mi
  ServiceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
  ServiceType: ClusterIP
rbac:
  install: true
```

```bash
helm delete jenkins --purge

kubectl delete ns jenkins
```

## Creating Charts

```bash
# Merge the latest `vfarcic/go-demo-3` into the fork, or delete it and create a new one

cd ../go-demo-3

helm create my-app
```

```
Creating my-app
```

```bash
helm dependency update my-app
```

```
No requirements found in /Users/vfarcic/IdeaProjects/go-demo-3/my-app/charts.
```

```bash
helm package my-app
```

```
Successfully packaged chart and saved it to: /Users/vfarcic/IdeaProjects/go-demo-3/my-app-0.1.0.tgz
```

```bash
helm lint my-app
```

```
==> Linting my-app
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

```bash
helm install ./my-app-0.1.0.tgz \
    --name my-app
```

```
NAME:   my-app
LAST DEPLOYED: Thu May 24 13:43:17 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
my-app  ClusterIP  100.65.227.236  <none>       80/TCP   1s

==> v1beta2/Deployment
NAME    DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
my-app  1        1        1           0          1s

==> v1/Pod(related)
NAME                     READY  STATUS             RESTARTS  AGE
my-app-7f4d66bf86-dns28  0/1    ContainerCreating  0         1s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=my-app,release=my-app" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

```bash
helm delete my-app --purge
```

```
release "my-app" deleted
```

```bash
rm -rf my-app

rm -rf my-app-0.1.0.tgz
```

```bash
ls -l helm helm/go-demo-3

TODO: Output

cat helm/go-demo-3/Chart.yaml

TODO: Output

cat helm/go-demo-3/LICENSE

TODO: Output

cat helm/go-demo-3/README.md

TODO: Output

cat helm/go-demo-3/values.yaml

TODO: Output

ls -l helm/go-demo-3/templates/

TODO: Output

cat helm/go-demo-3/templates/NOTES.txt

TODO: Output

cat helm/go-demo-3/templates/deployment.yaml

TODO: Output

# The rest of the files are following the same logic

helm lint helm/go-demo-3
```

```
==> Linting helm/go-demo-3
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

```bash
helm package helm/go-demo-3 -d helm

# Useful if publishing
```

## Installing

```bash
helm inspect values helm/go-demo-3
```

```yaml
replicaCount: 3
dbReplicaCount: 3
image:
  tag: latest
  dbTag: 3.3
ingress:
  enabled: true
  host: acme.com
service:
  # Change to NodePort if ingress.enable=false
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
    memory: "200Mi"
    cpu: 0.2
  requests:
    memory: "100Mi"
    cpu: 0.1
dbPersistence:
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 2Gi
```

```bash
# If AWS with kops
HOST=go-demo-3.$(kubectl \
    -n ingress-nginx \
    get svc ingress-nginx \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}").xip.io

# If Docker for Mac/Windows
HOST="go-demo-3.127.0.0.1.xip.io"

# If minikube
HOST="go-demo-3.$(minikube ip).xip.io"

echo $HOST
```

```
jenkins.192.168.99.100.xip.io
```

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set ingress.host=$HOST
```

```
TODO: from kops
```

```bash
kubectl -n go-demo-3 \
    rollout status deployment go-demo-3
```

```
Waiting for rollout to finish: 0 of 3 updated replicas are available...
Waiting for rollout to finish: 1 of 3 updated replicas are available...
Waiting for rollout to finish: 2 of 3 updated replicas are available...
deployment "go-demo-3" successfully rolled out
```

```bash
curl http://$HOST/demo/hello
```

```
hello, world!
```

```bash
kubectl -n go-demo-3 \
    describe deployment go-demo-3
```

```
Name:                   go-demo-3
Namespace:              go-demo-3
CreationTimestamp:      Fri, 25 May 2018 03:18:18 +0200
Labels:                 app=go-demo-3
                        chart=go-demo-3-0.0.1
                        heritage=Tiller
                        release=go-demo-3
Annotations:            deployment.kubernetes.io/revision=1
Selector:               app=go-demo-3,release=go-demo-3
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=go-demo-3
           release=go-demo-3
  Containers:
   api:
    Image:  vfarcic/go-demo-3:latest
    Port:   <none>
    Limits:
      cpu:     200m
      memory:  20Mi
    Requests:
      cpu:      100m
      memory:   10Mi
    Liveness:   http-get http://:8080/demo/hello delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/demo/hello delay=0s timeout=1s period=1s #success=1 #failure=3
    Environment:
      DB:    go-demo-3-db
    Mounts:  <none>
  Volumes:   <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   go-demo-3-5764f6465c (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set go-demo-3-5764f6465c to 3
```

```bash
helm upgrade -i \
    go-demo-3 helm/go-demo-3 \
    --namespace go-demo-3 \
    --set image.tag=1.0 \
    --reuse-values
```

```
TODO: Output from kops
```

```bash
kubectl -n go-demo-3 \
    describe deployment go-demo-3
```

```
Name:                   go-demo-3
Namespace:              go-demo-3
CreationTimestamp:      Thu, 24 May 2018 13:58:46 +0200
Labels:                 app=go-demo-3
                        chart=go-demo-3-0.0.1
                        heritage=Tiller
                        release=go-demo-3
Annotations:            deployment.kubernetes.io/revision=2
Selector:               app=go-demo-3,release=go-demo-3
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=go-demo-3
           release=go-demo-3
  Containers:
   api:
    Image:  vfarcic/go-demo-3:1.0
    Port:   <none>
    Limits:
      cpu:     200m
      memory:  20Mi
    Requests:
      cpu:      100m
      memory:   10Mi
    Liveness:   http-get http://:8080/demo/hello delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/demo/hello delay=0s timeout=1s period=1s #success=1 #failure=3
    Environment:
      DB:    go-demo-3-db
    Mounts:  <none>
  Volumes:   <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   go-demo-3-7bccf8b78f (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  3m    deployment-controller  Scaled up replica set go-demo-3-6f9bf6687c to 3
  Normal  ScalingReplicaSet  28s   deployment-controller  Scaled up replica set go-demo-3-7bccf8b78f to 1
  Normal  ScalingReplicaSet  25s   deployment-controller  Scaled down replica set go-demo-3-6f9bf6687c to 2
  Normal  ScalingReplicaSet  25s   deployment-controller  Scaled up replica set go-demo-3-7bccf8b78f to 2
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled down replica set go-demo-3-6f9bf6687c to 1
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled up replica set go-demo-3-7bccf8b78f to 3
  Normal  ScalingReplicaSet  20s   deployment-controller  Scaled down replica set go-demo-3-6f9bf6687c to 0
```

```bash
kubectl -n go-demo-3 \
    rollout status deployment go-demo-3
```

```
deployment "go-demo-3" successfully rolled out
```

```bash
curl http://$HOST/demo/hello
```

```
hello, world!
```

## What Now?

```bash
helm delete go-demo-3 --purge

kubectl delete ns go-demo-3
```