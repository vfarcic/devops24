# Kubernetes Networking (chapter 1)

T> Networking is backbone of distributed applications and come with different flavours.

kubernetes is pluggable architecure as we have learned in the previous book. Kubernetes team made right decision to keep networking as pluggable module as networking is implemented differently by different organizations. Networking is one of the critical building block of kubernetes cluster.

Kubernetes solves communication problem in different way for different components involved i.e services, ingress, etc. For pod-to-pod communication Kubernetes doesn't dictate how networking driver is implemented however it imposes basic requirements which providers need to full fill. Kubernetes networking model requires,

* All pods can communicate with all other pods without NAT
* All nodes can communicate with all pods (and vice-versa) without NAT
* The IP that a pod sees itself as is the same IP others see as it is 

Kubernetes default networking driver is kubenet. `kubenet` is very basic network plugin typically useful for single node environments or in cloud environment with routing rules. It has limited features and probably not good for vast majority of implementations, for example,In AWS you are limited to 50 nodes in the cluster as 50 is limit for routing tables. There are other networking drivers available through CNI (*Container Network Interface*) which is more practical. 

`CNI` has two branches, specification which is implemented by different networking providers and libraries. CNI is a standard plugin-based networking solution for application containers on Linux and not specific to kubernetes and it is managed by CNCF. 

Container runtimes creates new network namespace and handover it to set of network plugin(s) to setup interfaces, iptables, routing, etc. A plugin is responsible for setting up a network interface into the container network namespace (for example one end of veth) and modifying the host (attaching other end of veth into a bridge). It should then assign the IP to the interface and setup the routes by invoking appropriate IPAM plugin. The IPAM plugin is expected to determine the interface IP/subnet, Gateway and Routes and return this information to the "main" plugin to apply.
    
![Figure : Basic CNI diagram](images/cni-basic.png)

Below are possible networking implementation options through CNI which setup pod-to-pod communication full fulling Kubernetes requirements:

* layer 2 solution
* layer 3 solution
* overlay solution

How a container gets its network,


![Figure : CNI Plugin Flow](images/cni-flow.png)


1. User supplies network conf file to kubernetes which contains network type and IP related information.
2. Kubelet creates pod namespace with pause container. Pause container is created for each pod to serve network namespace to other containers in the pod.  
3. Kubelet has CNI library which invokes CNI main plugin and handover namespace and other network information like ADD or DELETE container to network.
4. CNI plugin setup network elements like interfaces, iptables, routing, etc. for pod and host network namespace.
5. CNI main plugin invokes IPAM plugin for IP allocation and IPAM returns IP information in json object to main plugin.
6. Main plugin uses this information to configure network interface.
7. Main plugin updates API server with network information for the pod.  


Despite all abstraction you should be wary of networking, It would be mistake if you don't have networking expertise who understand linux namespace, routing, iptables, networking virtualizations, etc.     

## Setup Network Using basic CNI plugins

In this section we going to use basic CNI plugins to setup pod network where pods can communicate across nodes. Let's setup a local kubernetes cluster.

Run the commands from `Create local cluster with kubadmn  (Appendix)` to build the kubernetes cluster. To initialize kubernetes master use below command instead,

```bash
sudo kubeadm init --apiserver-advertise-address 10.100.198.200
```

```bash
kubectl --kubeconfig ./admin.conf get nodes

NAME      STATUS     ROLES     AGE       VERSION
master    NotReady   master    5m        v1.10.0
node1     NotReady   <none>    2m        v1.10.0
node2     NotReady   <none>    1m        v1.10.0
```

It showing all nodes not ready because `kube-dns` pod is in pending state because we haven't installed pod network yet. 


<<write about standard plugins>>

```
{
	"cniVersion": "0.3.1",
	"name": "mynet",
	"type": "bridge",
	"bridge": "cni0",
	"isGateway": true,
	"ipMasq": true,
	"ipam": {
		"type": "host-local",
		"subnet": "${NODE_SUBNET}",
		"routes": [
			{ "dst": "0.0.0.0/0" }
		]
	}
}
```

Since basic CNI plugin can't find pod network range used by other host, We need to supply non-conflicting subnet range ourselves for each node. Below are different subnet values we will use for each node.

```
master -> 10.22.1.0/24
node1 -> 10.22.2.0/24
node2 -> 10.22.3.0/24
```

`Vagrantfile` has a `cni` provisioner to configure file 10-mynet.conf needed by basic CNI plugin. Lets use this provisioner,


```bash
CNI='true' vagrant provision --provision-with cni

==> master: Running provisioner: cni (shell)...
    master: 10.22.1.0/24
==> node1: Running provisioner: cni (shell)...
    node1: 10.22.2.0/24
==> node2: Running provisioner: cni (shell)...
    node2: 10.22.3.0/24
```

Now, if we check again all nodes should be in the ready state. 

```bash
kubectl --kubeconfig ./admin.conf get nodes

NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    6m        v1.10.1
node1     Ready     <none>    4m        v1.10.1
node2     Ready     <none>    3m        v1.10.1
```

## Testing pod network

Now, we should be deploying some pods to see if kubernetes network working fine or not. We will use simple nginx deployment with two replicas.

```bash
kubectl --kubeconfig ./admin.conf apply -f nginx-deployment.yaml

deployment "nginx-deployment" created`
```

Below command will tell us if both pods are running and deployed on two different nodes.

```bash
kubectl --kubeconfig ./admin.conf get pods -o wide

NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE
nginx-deployment-75675f5897-b4clx   1/1       Running   0          43s       10.22.3.3   node2
nginx-deployment-75675f5897-chm2r   1/1       Running   0          43s       10.22.2.2   node1
```

We also need to established cross nodes routes manually as basic CNI plugins don't provide this feature. `Vagrantfile` has a `route` provisioner to configure cross host routes. Lets use this provisioner,

```bash
CNI='true' vagrant provision --provision-with route

==> node1: Running provisioner: route (shell)...
    node1: configuring route...
    node1: 10.22.3.0/24 via 10.100.198.202 dev enp0s8
==> node2: Running provisioner: route (shell)...
    node2: configuring route...
    node2: 10.22.2.0/24 via 10.100.198.201 dev enp0s8
```

With the help of ping we can test whether bridge plugin was able to meet kubernetes network requirements,

* All nodes can communicate with all pods (and vice-versa) without NAT

```bash
vagrant ssh node1

ping 10.22.2.2  (same node)

PING 10.22.2.2 (10.22.2.2) 56(84) bytes of data.
64 bytes from 10.22.2.2: icmp_seq=1 ttl=64 time=0.054 ms

ping 10.22.3.3 (across node)

PING 10.22.3.3 (10.22.3.3) 56(84) bytes of data.
64 bytes from 10.22.3.3: icmp_seq=1 ttl=63 time=0.570 ms

exit (from node1)
```

`ping` test tell us that pods are reachable on same and across hosts.

* All pods can communicate with all other pods without NAT

Lets see if pod on node1 can reach to pod on node2.

```bash
kubectl --kubeconfig ./admin.conf exec -it nginx-deployment-75675f5897-chm2r ping 10.22.3.3

PING 10.22.3.3 (10.22.3.3): 48 data bytes
56 bytes from 10.22.3.3: icmp_seq=0 ttl=62 time=1.436 ms
```

## What now?

We have explored the standard plugin for pod network and performed various test. Lets delete the cluster,

```bash
vagrant destroy -f
```


# Setup Network Using Flannel (chapter 2)

Next step, we going to create pod network with provider Flannel. Flannel establishes an overlay network using VXLAN that helps to connect containers across multiple hosts. The flannel manifest defines four things:

1. A ClusterRole and ClusterRoleBinding for role based access control (RBAC).
2. A service account for flannel to use.
3. A ConfigMap containing both a CNI configuration and a flannel configuration. The network in the flannel configuration should match the pod network CIDR. The backend is VXLAN.
4. A DaemonSet to deploy the flannel pod on each Node. 

When you run pods, they will be allocated IP addresses from the pod network CIDR. No matter which node those pods end up on, they will be able to communicate with each other. Lets create pod network using `flannel.yml`,

```bash
kubectl --kubeconfig ./admin.conf apply -f flannel.yml
```

To validate if network installed properly, 

```bash
kubectl --kubeconfig ./admin.conf get pods -n kube-system -l app=flannel

NAME                    READY     STATUS    RESTARTS   AGE
kube-flannel-ds-59hmh   1/1       Running   0          45s
kube-flannel-ds-v8m8f   1/1       Running   0          45s
kube-flannel-ds-zzkf7   1/1       Running   0          45s
```

Once pod network is established, all nodes in the cluster should be in the ready state. It may take some time. 

```bash
kubectl --kubeconfig ./admin.conf get nodes

NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    8m        v1.10.0
node1     Ready     <none>    3m        v1.10.0
node2     Ready     <none>    3m        v1.10.0
```

## Testing pod network

Now, we should be deploying some pods to see if kubernetes network working fine or not. We will use simple nginx deployment with two replicas.

```bash
kubectl --kubeconfig ./admin.conf apply -f nginx-deployment.yaml

deployment "nginx-deployment" created`
```

Below command will tell us if both pods are running and deployed on two different nodes.

```bash
kubectl --kubeconfig ./admin.conf get pods -o wide

NAME                                READY     STATUS    RESTARTS   AGE       IP           NODE
nginx-deployment-75675f5897-4dm42   1/1       Running   0          2m        10.244.1.2   node1
nginx-deployment-75675f5897-rfj56   1/1       Running   0          2m        10.244.3.3   node2
```

With the help of ping and curl we can test whether flannel was able to meet kubernetes network requirements,

* All nodes can communicate with all pods (and vice-versa) without NAT

```bash
vagrant ssh node1

ping 10.244.1.2  (same node)

PING 10.244.1.2 (10.244.1.2) 56(84) bytes of data.
64 bytes from 10.244.1.2: icmp_seq=1 ttl=64 time=0.054 ms
64 bytes from 10.244.1.2: icmp_seq=2 ttl=64 time=0.060 ms

ping 10.244.3.3 (across node)

PING 10.244.3.3 (10.244.3.3) 56(84) bytes of data.

exit (from node1)
```

`ping` test tell us that pods are not reachable across host. We can ping pod deployed on node1 but not on node2. 

* All pods can communicate with all other pods without NAT

Lets see if pod on node1 can reach to pod on node2.

```bash
kubectl --kubeconfig ./admin.conf exec -it nginx-deployment-75675f5897-4dm42 ping 10.244.3.3

PING 10.244.3.3 (10.244.3.3): 48 data bytes
60 bytes from 10.244.1.1: Destination Net Unreachable
```

## Trobuleshoot

We have problem somewhere and need to troubleshoot with help of some networking tools. Remember, above in the chapter we mentioned that networking abstraction is good but you should not take it grantedly. It is important that you should have some networking expertise in your team.

Check if subnet is conflicting,

```bash
kubectl --kubeconfig ./admin.conf get pods -n kube-system -l app=flannel -o wide

NAME                    READY     STATUS    RESTARTS   AGE       IP               NODE
kube-flannel-ds-v8m8f   1/1       Running   0          1h        10.100.198.200   master
kube-flannel-ds-zzkf7   1/1       Running   0          1h        10.100.198.201   node1
kube-flannel-ds-59hmh   1/1       Running   0          1h        10.100.198.202   node2

kubectl --kubeconfig ./admin.conf exec -n kube-system kube-flannel-ds-v8m8f cat //run//flannel//subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24

kubectl --kubeconfig ./admin.conf exec -n kube-system kube-flannel-ds-zzkf7 cat //run//flannel//subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.1.1/24

kubectl --kubeconfig ./admin.conf exec -n kube-system kube-flannel-ds-59hmh cat //run//flannel//subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.3.1/24
```

No issue here, all nodes got different subnet. Next, check if routes configured properly,

```bash
kubectl --kubeconfig ./admin.conf exec -n kube-system kube-flannel-ds-zzkf7 -- route -n

Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG    0      0        0 enp0s3
10.0.2.0        0.0.0.0         255.255.255.0   U     0      0        0 enp0s3
10.100.198.0    0.0.0.0         255.255.255.0   U     0      0        0 enp0s8
10.244.0.0      10.244.0.0      255.255.255.0   UG    0      0        0 flannel.1
10.244.1.0      0.0.0.0         255.255.255.0   U     0      0        0 cni0
10.244.3.0      10.244.3.0      255.255.255.0   UG    0      0        0 flannel.1
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
```

Flannel configured routes properly, node2(10.244.3.0) traffic is being handle by flannel.1 interface. Next, lets capture traffic on  flannel.1 interface with tcmdump utility. Open another session to watch tcpdump.

```bash
vagrant ssh node1
ping 10.244.3.3

vagrant ssh node1

sudo tcpdump -i flannel.1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on flannel.1, link-type EN10MB (Ethernet), capture size 262144 bytes
20:55:02.971181 IP 10.244.1.0 > 10.244.3.3: ICMP echo request, id 5874, seq 1, length 64
```

The output from tcpdump suggest that flannel.1 interface is receiving traffic. Next, look at the flannel pod logs on node 1.


```bash
kubectl --kubeconfig ./admin.conf logs -n kube-system kube-flannel-ds-zzkf7

(removed lines for brevity, only top few lines)
Determining IP address of default interface
Using interface with name enp0s3 and address 10.0.2.15
Defaulting external address to interface address (10.0.2.15)
```

We have problem here, flannel decided to use enp0s3 instead of enp0s8 and enp0s3 is configured with same IP on all nodes for NATed external traffic. This is not the right interface we want to use with flannel. Vagrant creates two interfaces and flannel picked the first interface by default unless you provide configuration to flannel. 

## Fix the issue

We need to clean up, remove nginx deployment and flannel before we can apply the fix.

```
kubectl --kubeconfig ./admin.conf delete -f nginx-deployment.yaml

deployment "nginx-deployment" deleted

kubectl --kubeconfig ./admin.conf delete -f flannel.yml
```

We need to pass additional parameter to Flannel for interface enp0s8. `flannel_fix.yml` file has this fix as `--iface=enp0s8`. Lets recreate pod network and nginx.

```bash
kubectl --kubeconfig ./admin.conf apply -f flannel_fix.yml

kubectl --kubeconfig ./admin.conf get pods --all-namespaces -l app=flannel

NAMESPACE     NAME                    READY     STATUS    RESTARTS   AGE
kube-system   kube-flannel-ds-4mwc7   1/1       Running   0          35s
kube-system   kube-flannel-ds-fj8dg   1/1       Running   0          35s
kube-system   kube-flannel-ds-tjz4c   1/1       Running   0          35s

kubectl --kubeconfig ./admin.conf apply -f nginx-deployment.yaml

deployment "nginx-deployment" created

kubectl --kubeconfig ./admin.conf get pods -o wide

NAME                                READY     STATUS    RESTARTS   AGE       IP           NODE
nginx-deployment-75675f5897-46tfh   1/1       Running   0          12m       10.244.3.4   node2
nginx-deployment-75675f5897-rq75g   1/1       Running   0          12m       10.244.1.3   node1
```

Lets do our ping test again to validate kubernetes network requirement,

* All nodes can communicate with all pods (and vice-versa) without NAT

```bash
vagrant ssh node1

ping 10.244.1.3 (same node)

PING 10.244.1.3 (10.244.1.3) 56(84) bytes of data.
64 bytes from 10.244.1.3: icmp_seq=1 ttl=64 time=0.137 ms

ping 10.244.3.4 (across node)

PING 10.244.3.4 (10.244.3.4) 56(84) bytes of data.
64 bytes from 10.244.3.4: icmp_seq=1 ttl=63 time=0.403 ms

exit (from node1)
```

`ping` test tell us that now pod deployed on node2 is reachable from node1. 


* All pods can communicate with all other pods without NAT

Lets see if pod on node1 can reach to pod on node2.

```bash
$ kubectl --kubeconfig ./admin.conf exec -it nginx-deployment-75675f5897-rq75g ping 10.244.3.4

PING 10.244.3.4 (10.244.3.4): 48 data bytes
56 bytes from 10.244.3.4: icmp_seq=0 ttl=62 time=0.947 ms
```

This `ping` test tell us that now pod deployed on node2 is reachable from the pod deployed on node1. 

<<flannel diagram>>

## What now?

We have explored the Flannel plugin for pod network and performed various test. Lets delete the cluster,

```bash
vagrant destroy -f
```


# Network Policy using Calico (Chapter 3)

By default, there is no restriction on pods traffic in the kubernetes cluster which means all pods can communicate with each other. Kubernetes introduced since 1.7 new object type NetworkPolicy which applies traffic restrictions on a pod. By using NetworkPolicy you can apply restrictions on pods if you have multiple applications running in same cluster or multi layer architecure for example frontend pod should not have access to database pod. Network policies are implemented by network plugins but not all networking plugins supports network policy. So if you need this feature you need to select one of the networking plugin provider i.e. Calico, Romana, and Weave Net or you can choose two providers one for general networking for example Flannel and Calico for network policies. 

NetworkPolicy is defined in two parts, set of pods a policy apply to and other pods have access to this pod. NetworkPolicy also has some other features like egress restrictions, IP ranges, port restrictions, etc. 

Lets create kubernetes cluster using our `create local cluster with kubadmn guide`. You need to supply pod network when initializing kubernetes master, Use below command to initialize the master.

```bash
sudo kubeadm init --apiserver-advertise-address 10.100.198.200 --pod-network-cidr 192.168.0.0/16
```

Once cluster is setup we need create pod network. We going to use Calico since it provides both networking and network policies. We going to use one yaml file typical way of installing network in kubernetes. It has all the required components of Calico. 

```bash
kubectl --kubeconfig ./admin.conf apply -f calcio.yaml

configmap "calico-config" created
daemonset "calico-etcd" created
service "calico-etcd" created
daemonset "calico-node" created
deployment "calico-kube-controllers" created
clusterrolebinding "calico-cni-plugin" created
clusterrole "calico-cni-plugin" created
serviceaccount "calico-cni-plugin" created
clusterrolebinding "calico-kube-controllers" created
clusterrole "calico-kube-controllers" created
serviceaccount "calico-kube-controllers" created
```
This yaml file will create several kubenetes objects for Calico to work. Calico uses BIRD as routing daemon which runs on every host to propagate the routes. Lets check if all the pods are runing,

```bash
kubectl --kubeconfig ./admin.conf get pods -n kube-system

NAME                                      READY     STATUS    RESTARTS   AGE
calico-etcd-pr4zn                         1/1       Running   0          3m
calico-kube-controllers-5449fdfcd-hq45n   1/1       Running   0          3m
calico-node-49s5p                         2/2       Running   0          3m
calico-node-crc7p                         2/2       Running   0          3m
calico-node-dhrm2                         2/2       Running   0          3m
etcd-master                               1/1       Running   0          9m
kube-apiserver-master                     1/1       Running   0          9m
kube-controller-manager-master            1/1       Running   0          9m
kube-dns-86f4d74b45-zk9dh                 3/3       Running   0          43m
kube-proxy-nx577                          1/1       Running   0          8m
kube-proxy-qcxrl                          1/1       Running   0          43m
kube-proxy-tt5f7                          1/1       Running   0          9m
kube-scheduler-master                     1/1       Running   0          9m  
```

Once all the pods are runnning, lets create `go demo` app with database, we will not go in detail of go-demo app yaml as we are familiar with this app in previous books. We will be running 3 replicas of `go-demo-2-api` and one replica of `go-demo-2-db`.  

```bash
kubectl --kubeconfig ./admin.conf create -f go-demo-2.yml

deployment "go-demo-2-db" created
service "go-demo-2-db" created
deployment "go-demo-2-api" created
service "go-demo-2-api" created

kubectl --kubeconfig ./admin.conf get pods -o wide

NAME                             READY     STATUS    RESTARTS   AGE       IP                NODE
go-demo-2-api-558c6cbf6d-cqdfm   1/1       Running   2          1m        192.168.104.2     node2
go-demo-2-api-558c6cbf6d-kffd7   1/1       Running   0          1m        192.168.166.131   node1
go-demo-2-api-558c6cbf6d-v8hxc   1/1       Running   2          1m        192.168.104.1     node2
go-demo-2-db-5d98f87ff8-l7dch    1/1       Running   0          1m        192.168.166.130   node1
```

Once all go demo pods are running, we will test whether we can access these pods from some other pod to prove that there is not restriction on pod traffic. Lets create pod with busybox to access go demo pods. Below command will create busybox conatiner and launch you inside the container. We going to do ping test with go demo pods.

```bash
kubectl --kubeconfig ./admin.conf run busybox --rm -ti --image=busybox sh

# ping 192.168.104.1
PING 192.168.104.1 (192.168.104.1): 56 data bytes
64 bytes from 192.168.104.1: seq=0 ttl=62 time=1.144 ms

# ping 192.168.166.130
PING 192.168.166.130 (192.168.166.130): 56 data bytes
64 bytes from 192.168.166.130: seq=0 ttl=63 time=0.798 ms

exit (from busybox)
```

As you have seen we can ping both `app` and `db` pods from busybox that proves no restrictions on pods. Next, we going to restrict the traffic on all the pods in the cluster by default using `deny-all-policy.yaml`. This is actually best practice to deny traffic to start with and then add policy to allow traffic at each pod level in cluster. This way we will have explicit control on pod traffic. Below is `deny-all-policy.yaml` defintion, if we define empty selector as {} then all pods are selected and empty polciy as [] means all pods are not allowed to access each other.

```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all
spec:
  podSelector: {}
  ingress: []
```

```bash
kubectl --kubeconfig ./admin.conf apply -f deny-all-policy.yaml
networkpolicy "deny-all" created

kubectl --kubeconfig ./admin.conf get networkpolicy
NAME       POD-SELECTOR   AGE
deny-all   <none>         31s

kubectl --kubeconfig ./admin.conf run busybox --rm -ti --image=busybox sh

# ping -w 2 192.168.104.1
PING 192.168.104.1 (192.168.104.1): 56 data bytes
--- 192.168.104.1 ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss

# ping -w 2 192.168.166.130
PING 192.168.166.130 (192.168.166.130): 56 data bytes
--- 192.168.166.130 ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss

exit (from busybox)
```

Since we have `deny-all` network policy in place, now we can't ping same pods we tried earlier before policy. We now going to open traffic selectively. Our ingress traffic should look like below, 

![Figure : Ingress Policy](images/ingress-allow.png)

We will apply some labels on exisitng pods to understand the concept little bit easier. We will apply `tier=backend` to `api` pods and `tier=db` to `db` pod

```bash
$ kubectl --kubeconfig ./admin.conf label pods -l type=api tier=backend
pod "go-demo-2-api-558c6cbf6d-8l62g" labeled
pod "go-demo-2-api-558c6cbf6d-drwjl" labeled
pod "go-demo-2-api-558c6cbf6d-kdzh9" labeled

$ kubectl --kubeconfig ./admin.conf label pods -l type=db tier=db
pod "go-demo-2-db-5d98f87ff8-zdmdl" labeled

$ kubectl --kubeconfig ./admin.conf get pods --show-labels
NAME                             READY     STATUS    RESTARTS   AGE       LABELS
go-demo-2-api-558c6cbf6d-8l62g   1/1       Running   0          1h        language=go,pod-template-hash=1147276928,service=go-demo-2,tier=backend,type=api
go-demo-2-api-558c6cbf6d-drwjl   1/1       Running   3          1h        language=go,pod-template-hash=1147276928,service=go-demo-2,tier=backend,type=api
go-demo-2-api-558c6cbf6d-kdzh9   1/1       Running   2          1h        language=go,pod-template-hash=1147276928,service=go-demo-2,tier=backend,type=api
go-demo-2-db-5d98f87ff8-zdmdl    1/1       Running   0          1h        pod-template-hash=1854943994,service=go-demo-2,tier=db,type=db,vendor=MongoLabs
```

Below are two policy defintions, `backend-policy` applies to any pods which has label `tier=backend` and only allow traffic from pods which has label `tier=frontend`. `db-policy` applies to any pods which has label `tier=db` and only allow traffic from pods which has label `tier=backend`.  

```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend

---

kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      tier: db
  ingress: 
  - from:
    - podSelector:
        matchLabels:
          tier: backend

```

Lets apply these new policies to allow traffic to backend and db pods as shown in the diagram above.

```bash
kubectl --kubeconfig ./admin.conf apply -f go-demo-policy.yaml
networkpolicy "backend-policy" created
networkpolicy "db-policy" created
```

After policies are created we going to ping test from busybox again. This time we going to label it as `tier=frontend` so that backend pod can allow traffic from this pod. We will also ping db pod to test if traffic is allowed from this pod, as per policy it should not.

```bash
kubectl --kubeconfig ./admin.conf run busybox --rm -ti --labels="tier=frontend" --image=busybox sh

# ping -w 2 192.168.104.1
PING 192.168.104.1 (192.168.104.1): 56 data bytes
64 bytes from 192.168.104.1: seq=0 ttl=62 time=0.476 ms

# ping -w 2 192.168.166.130
PING 192.168.166.130 (192.168.166.130): 56 data bytes
--- 192.168.166.130 ping statistics ---
2 packets transmitted, 0 packets received, 100% packet loss

exit (from busybox)
```

Lets ping db pod from backend pod. You can choose any backend pod, 

```bash
kubectl --kubeconfig ./admin.conf exec -it go-demo-2-api-558c6cbf6d-v8hxc ping 192.168.166.130

PING 192.168.166.130 (192.168.166.130): 56 data bytes
64 bytes from 192.168.166.130: seq=0 ttl=62 time=0.690 ms
```

## What now?

We have explored the Calico plugin for pod network and network policy. Lets delete the cluster,

```bash
vagrant destroy -f
```



# Create local cluster with kubadmn  (Appendix)

Let's start with some hands-on as we usually do in each chapter and call our old friend vagarnt. We will create local cluster with help of vagrant and virtualbox.  

```bash
vagrant up
```

This command will create three VMs,  one master and two nodes and each VM is provisioned with necessary components docker, kubeadmn, kubelet, kubectl via `bootstrap.sh` script so that we can create kubernetes cluster. Check the status if all VMs are up.

```bash
vagrant status

master                    running (virtualbox)
node1                     running (virtualbox)
node2                     running (virtualbox)
```

We need to ssh in all machines and execute some commands to form kubernetes cluster. Let's start with master VM.

```bash
vagrant ssh master
```

There are several ways you can create a kubernetes cluster like the one we have seen in previous book with kops. In this chapter we will use `kubeadmn`. `kubeadmn` setup minimum viable cluster which makes it very simple. Below command initialized the master with control plane, etcd and API server. Since, we using flaneel as networking provider it require us to pass pod `pod-network-cidr`. We also passing master node IP we configured through vagrant. 

```bash
sudo kubeadm init --apiserver-advertise-address 10.100.198.200 --pod-network-cidr 10.244.0.0/16
```

This command creates all necessary config for kubernetes to function properly like keys, certificates, RBAC, pod manifest, etc and then kubelet create pods for control plane. This command may take few minutes as pulling the images. The output of above command as follows, removing most of the lines for sake of brevity.   

```
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 10.100.198.200:6443 --token q0xiub.nxs5ux9tjqn9rnb2 --discovery-token-ca-cert-hash sha256:80348065b7738e44b350068f8ab8d551fe5799f1acda2f132775cebb2544e4d2
```

Follow the instructions from the output of init command while you login on master VM. We need this to run kubectl commands. Also, copy the config file `admin.conf` to our laptop working directory to manage this cluster from our laptop. Vagarnt mount our local dir as `/vagrant` in VMs.

```bash
sudo cp /etc/kubernetes/admin.conf /vagrant

exit (from master)
```

Let's exit from the master VM. We need to ssh into each node VM and run the join command from the output of init command. In your case token will be different so copy from the output.

```bash
vagrant ssh node1

sudo su -

kubeadm join 10.100.198.200:6443 --token q0xiub.nxs5ux9tjqn9rnb2 --discovery-token-ca-cert-hash sha256:80348065b7738e44b350068f8ab8d551fe5799f1acda2f132775cebb2544e4d2

    This node has joined the cluster: (removed lines for brevity)

exit (from node1)

vagrant ssh node2

sudo su -

kubeadm join 10.100.198.200:6443 --token q0xiub.nxs5ux9tjqn9rnb2 --discovery-token-ca-cert-hash sha256:80348065b7738e44b350068f8ab8d551fe5799f1acda2f132775cebb2544e4d2

    This node has joined the cluster: (removed lines for brevity)

exit (from node2)
``` 

Now, validate if all nodes joined.

```bash
kubectl --kubeconfig ./admin.conf get nodes

NAME      STATUS     ROLES     AGE       VERSION
master    NotReady   master    6m        v1.10.0
node1     NotReady   <none>    2m        v1.10.0
node2     NotReady   <none>    1m        v1.10.0
```

It showing all nodes not ready because `kube-dns` pod is in pending state because we haven't installed pod network yet. 

