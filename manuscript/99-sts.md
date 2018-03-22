**DO NOT REVIEW THIS JUST YET**

## Chapter

- [ ] Code
- [ ] Write
- [ ] Compare with Swarm
- [ ] Text Review
- [ ] Diagrams
- [ ] Code Review
- [ ] Gist
- [ ] Review the title
- [ ] Proofread
- [ ] Add to slides
- [ ] Publish on TechnologyConversations.com
- [ ] Add to Book.txt
- [ ] Publish on LeanPub.com

# StatefulSets

## Using StatefulSets To Deploy Stateful Applications

Using Deployments for stateful applications served us well when combined with PersistentVolumes. Still, there is a better way to run such applications.

```bash
# TODO: sts_start

# TODO: sts2

# TODO: sts3

# TODO: sts

cat sts/jenkins.yml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: jenkins
  namespace: jenkins
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /jenkins
        backend:
          serviceName: jenkins
          servicePort: 8080

---

apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  selector:
    app: jenkins
  ports:
  - name: http
    port: 8080
  - name: jnlp
    port: 50000

---

apiVersion: apps/v1beta2
kind: StatefulSet
metadata:
  name: jenkins
  namespace: jenkins
spec:
  selector:
    matchLabels:
      app: jenkins
  serviceName: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: vfarcic/jenkins
        env:
        - name: JENKINS_OPTS
          value: --prefix=/jenkins
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: jenkins-creds
          mountPath: /run/secrets
        resources:
          limits:
            memory: 2Gi
            cpu: 1
          requests:
            memory: 1Gi
            cpu: 0.5
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins
      - name: jenkins-creds
        secret:
          secretName: jenkins-creds
      securityContext:
        fsGroup: 1000
  volumeClaimTemplates:
  - metadata:
      name: jenkins-home
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

```bash
kubectl apply \
    -f sts/jenkins.yml \
    --record
```

```
namespace "jenkins" configured
ingress "jenkins" configured
service "jenkins" configured
statefulset "jenkins" created
```

```bash
kubectl --namespace jenkins \
    get sts
```

```
NAME    DESIRED CURRENT AGE
jenkins 1       1       3m
```

```bash
kubectl --namespace jenkins \
    get pvc
```

```
NAME                   STATUS VOLUME  CAPACITY ACCESS MODES STORAGECLASS AGE
jenkins-home-jenkins-0 Bound  pvc-... 1Gi      RWO          gp2          4m
```

```bash
kubectl --namespace jenkins \
    get pv
```

```
NAME    CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM                          STORAGECLASS REASON AGE
pvc-... 1Gi      RWO          Delete         Bound  jenkins/jenkins-home-jenkins-0 gp2                 5m
```

```bash
open "http://$CLUSTER_DNS/jenkins"
```

## What Now?

```bash
kubectl delete ns jenkins
```

```
namespace "jenkins" deleted
```

```bash
kops delete cluster \
    --name $NAME \
    --yes
```

```
...
Deleted kubectl config for devops23.k8s.local

Deleted cluster: "devops23.k8s.local"
```

```bash
aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
