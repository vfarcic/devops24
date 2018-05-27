## Monocular

```bash
helm repo add monocular \
    https://kubernetes-helm.github.io/monocular

helm inspect values monocular/monocular
```

```yaml
# Default values for monocular.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
api:
  replicaCount: 2
  image:
    repository: bitnami/monocular-api
    tag: v0.7.0
    pullPolicy: Always
  service:
    name: monocular-api
    type: NodePort
    externalPort: 80
    internalPort: 8081
    annotations: {}
      # foo.io/bar: "true"
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  livenessProbe:
    initialDelaySeconds: 180
  auth:
    signingKey:
    github:
      clientID:
      clientSecret:
  config:
    repos:
      # Official repositories
      - name: stable
        url: https://kubernetes-charts.storage.googleapis.com
        source: https://github.com/kubernetes/charts/tree/master/stable
      - name: incubator
        url: https://kubernetes-charts-incubator.storage.googleapis.com
        source: https://github.com/kubernetes/charts/tree/master/incubator
      # Add your own repository
      #- name: my-repo-name
      #  url: my-repository-url
      #  source: my-repository-source
    cors:
      allowed_origins:
        - ""
        # e.g. UI served on a different domain
        # - http://monocular.local
      allowed_headers:
        - "content-type"
        - "x-xsrf-token"
    # Enable Helm deployment integration
    releasesEnabled: true
    tillerNamespace: kube-system
    # Cache refresh interval in sec.
    cacheRefreshInterval: 3600
ui:
  replicaCount: 2
  image:
    repository: bitnami/monocular-ui
    tag: v0.7.0
    pullPolicy: Always
  service:
    name: monocular-ui
    type: NodePort
    externalPort: 80
    internalPort: 8080
    annotations: {}
      # foo.io/bar: "true"
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  # ui-config populate
  googleAnalyticsId: UA-XXXXXX-X
  appName: Monocular
  # API served on same-domain at /api path using Nginx Ingress controller
  backendHostname: /api
  # e.g. API served on a different domain
  # backendHostname: http://monocular-api.local

prerender:
  replicaCount: 1
  image:
    repository: migmartri/prerender
    tag: latest
    pullPolicy: Always
  cacheEnabled: true
  service:
    name: prerender
    type: NodePort
    externalPort: 80
    internalPort: 3000
  resources:
    requests:
      cpu: 100m
      memory: 128Mi

ingress:
  enabled: true
  hosts:
  # Wildcard
  -
  # - monocular.local

  ## Ingress annotations
  ##
  annotations:
    ## Nginx ingress controller (default)
    nginx.ingress.kubernetes.io/rewrite-target: /
    kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: 'true'
    ## Traefik ingress controller
    # traefik.frontend.rule.type: PathPrefixStrip
    # kubernetes.io/ingress.class: traefik

  ## Ingress TLS configuration
  ## Secrets must be manually created in the namespace
  ##
  # tls:
  #   secretName: monocular.local-tls
```

```bash
# If NOT minishift
HOST="monocular.$LB_IP.xip.io"

# If minishift
HOST="monocular-monocular-monocular-ui.$(minishift ip).nip.io"

helm install monocular/monocular \
    --namespace monocular \
    --name monocular \
    --set ingress.hosts={$HOST}
```

```
NAME:   monocular
LAST DEPLOYED: Sat May 26 02:06:21 2018
NAMESPACE: monocular
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                            DATA  AGE
monocular-monocular-api-config  1     0s
monocular-monocular-ui-config   1     0s
monocular-monocular-ui-vhost    1     0s

==> v1/PersistentVolumeClaim
NAME               STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
monocular-mongodb  Bound   pvc-9f1c09b2-6078-11e8-a5ae-025000000001  8Gi       RWO           hostpath      0s

==> v1/Service
NAME                           TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)       AGE
monocular-mongodb              ClusterIP  10.102.136.157  <none>       27017/TCP     0s
monocular-monocular-api        NodePort   10.103.35.161   <none>       80:30055/TCP  0s
monocular-monocular-prerender  NodePort   10.102.84.163   <none>       80:32324/TCP  0s
monocular-monocular-ui         NodePort   10.106.202.182  <none>       80:32496/TCP  0s

==> v1beta1/Deployment
NAME                           DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
monocular-mongodb              1        1        1           0          0s
monocular-monocular-api        2        2        2           0          0s
monocular-monocular-prerender  1        1        1           0          0s
monocular-monocular-ui         2        2        2           0          0s

==> v1beta1/Ingress
NAME                 HOSTS  ADDRESS  PORTS  AGE
monocular-monocular  *      80       0s

==> v1/Pod(related)
NAME                                           READY  STATUS             RESTARTS  AGE
monocular-mongodb-75989ffc56-7gkxp             0/1    ContainerCreating  0         0s
monocular-monocular-api-94595c774-5rxx5        0/1    Pending            0         0s
monocular-monocular-api-94595c774-jnqxk        0/1    Pending            0         0s
monocular-monocular-prerender-cdc9449bf-z8klq  0/1    Pending            0         0s
monocular-monocular-ui-5d76576945-tf6hz        0/1    Pending            0         0s
monocular-monocular-ui-5d76576945-vtjrt        0/1    Pending            0         0s

==> v1/Secret
NAME               TYPE    DATA  AGE
monocular-mongodb  Opaque  2     0s


NOTES:
The Monocular chart sets up an Ingress to serve the API and UI on the same
domain. You can get the address to access Monocular from this Ingress endpoint:

  $ kubectl get ingress monocular-monocular

Visit https://github.com/kubernetes-helm/monocular for more information.

**IMPORTANT**: Releases are enabled, which will allow anybody with access to the running instance to create, list and delete any Helm release existing in your cluster.
This feature is aimed for internal, behind the firewall deployments of Monocular, please plan accordingly. To disable this, re-install Monocular setting api.config.releasesEnabled=false.


Monocular expects tiller-deploy to be found in namespace kube-system
```

```bash
kubectl -n monocular get all
```

```
NAME                                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/monocular-mongodb               1         1         1            1           6m
deploy/monocular-monocular-api         2         2         2            0           6m
deploy/monocular-monocular-prerender   1         1         1            1           6m
deploy/monocular-monocular-ui          2         2         2            2           6m
NAME                                         DESIRED   CURRENT   READY     AGE
rs/monocular-mongodb-75989ffc56              1         1         1         6m
rs/monocular-monocular-api-94595c774         2         2         0         6m
rs/monocular-monocular-prerender-cdc9449bf   1         1         1         6m
rs/monocular-monocular-ui-5d76576945         2         2         2         6m
NAME                                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/monocular-mongodb               1         1         1            1           6m
deploy/monocular-monocular-api         2         2         2            0           6m
deploy/monocular-monocular-prerender   1         1         1            1           6m
deploy/monocular-monocular-ui          2         2         2            2           6m
NAME                                         DESIRED   CURRENT   READY     AGE
rs/monocular-mongodb-75989ffc56              1         1         1         6m
rs/monocular-monocular-api-94595c774         2         2         0         6m
rs/monocular-monocular-prerender-cdc9449bf   1         1         1         6m
rs/monocular-monocular-ui-5d76576945         2         2         2         6m
NAME                                               READY     STATUS    RESTARTS   AGE
po/monocular-mongodb-75989ffc56-7gkxp              1/1       Running   0          6m
po/monocular-monocular-api-94595c774-5rxx5         0/1       Running   2          6m
po/monocular-monocular-api-94595c774-jnqxk         0/1       Running   2          6m
po/monocular-monocular-prerender-cdc9449bf-z8klq   1/1       Running   0          6m
po/monocular-monocular-ui-5d76576945-tf6hz         1/1       Running   0          6m
po/monocular-monocular-ui-5d76576945-vtjrt         1/1       Running   0          6m
NAME                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
svc/monocular-mongodb               ClusterIP   10.102.136.157   <none>        27017/TCP      6m
svc/monocular-monocular-api         NodePort    10.103.35.161    <none>        80:30055/TCP   6m
svc/monocular-monocular-prerender   NodePort    10.102.84.163    <none>        80:32324/TCP   6m
svc/monocular-monocular-ui          NodePort    10.106.202.182   <none>        80:32496/TCP   6m
```

```bash
kubectl -n monocular \
    rollout status \
    deploy monocular-monocular-api

# It'll take a while until all the charts are downloaded

kubectl -n monocular get ing

ADDR=$(kubectl -n monocular \
    get ing monocular-monocular \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"):8080
```