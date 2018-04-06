# Kubernetes Networking

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


## different Providers, some detail.
    
## Creating A Cluster

Let's start with some hands-on as we usually do in each chapter and call our old friend vagarnt. We will create local cluster with help of vagrant and virtualbox.  

```bash
vagrant up
```

This command will create three VMs,  one master and two nodes and each VM is provisioned with necessary components docker, kubeadmn, kubelet, kubectl via `bootstrap.sh` script so that we can create kubernetes cluster.

```bash
vagrant status
```
Check the status if all VMs are up. Output should look like below, 

```
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
```

```
NAME      STATUS     ROLES     AGE       VERSION
master    NotReady   master    6m        v1.10.0
node1     NotReady   <none>    2m        v1.10.0
node2     NotReady   <none>    1m        v1.10.0
```

It showing all nodes not ready because `kube-dns` pod is in pending state because we haven't installed pod network yet. 


Next step, we going to create pod network with provider Flannel. Flannel establishes an overlay network using VXLAN that helps to connect containers across multiple hosts. The flannel manifest defines four things:

1. A ClusterRole and ClusterRoleBinding for role based access control (RBAC).
2. A service account for flannel to use.
3. A ConfigMap containing both a CNI configuration and a flannel configuration. The network in the flannel configuration should match the pod network CIDR. The backend is VXLAN.
4. A DaemonSet to deploy the flannel pod on each Node. 

When you run pods, they will be allocated IP addresses from the pod network CIDR. No matter which node those pods end up on, they will be able to communicate with each other.

```bash
curl https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml > flannel.yml

kubectl --kubeconfig ./admin.conf apply -f flannel.yml
```

To validate if network installed properly, 

```bash
kubectl --kubeconfig ./admin.conf get pods -n kube-system -l app=flannel
```

```
NAME                    READY     STATUS    RESTARTS   AGE
kube-flannel-ds-59hmh   1/1       Running   0          45s
kube-flannel-ds-v8m8f   1/1       Running   0          45s
kube-flannel-ds-zzkf7   1/1       Running   0          45s
```

Once pod network is established, all nodes in the cluster should be in the ready state. It may take some time. 

```bash
kubectl get nodes
```

```
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    8m        v1.10.0
node1     Ready     <none>    3m        v1.10.0
node2     Ready     <none>    3m        v1.10.0
```

## Testing kubernetes network

Now, we should be deploying some pods to see if kubernetes network working fine or not. We will use simple nginx deployment with 2 replicas.

```bash
kubectl --kubeconfig ./admin.conf apply -f nginx-deployment.yaml
```
```
deployment "nginx-deployment" created`
```

Below command will tell us if both pods are running and deployed on two different nodes.

```bash
kubectl --kubeconfig ./admin.conf get pods -o wide
```
```
NAME                                READY     STATUS    RESTARTS   AGE       IP           NODE
nginx-deployment-75675f5897-4dm42   1/1       Running   0          2m        10.244.1.2   node1
nginx-deployment-75675f5897-rfj56   1/1       Running   0          2m        10.244.3.3   node2
```

With the help of ping and curl we can test whether flannel was able to meet kubernetes network below requirements,

* All nodes can communicate with all pods (and vice-versa) without NAT

```bash
vagrant ssh node1

ping 10.244.1.2

PING 10.244.1.2 (10.244.1.2) 56(84) bytes of data.
64 bytes from 10.244.1.2: icmp_seq=1 ttl=64 time=0.054 ms
64 bytes from 10.244.1.2: icmp_seq=2 ttl=64 time=0.060 ms

ping 10.244.3.3

PING 10.244.3.3 (10.244.3.3) 56(84) bytes of data.

exit (from node1)
```

`ping` test tell us that pod deployed on node2 is not reachable from node1. 


* All pods can communicate with all other pods without NAT

Lets see if pod on node1 can reach to pod on node2.

```bash
kubectl --kubeconfig ./admin.conf exec -it nginx-deployment-75675f5897-4dm42 ping 10.244.3.3

PING 10.244.3.3 (10.244.3.3): 48 data bytes
60 bytes from 10.244.1.1: Destination Net Unreachable
```

### Trobuleshoot

We have problem somewhere and need to troubleshoot with some network tools. Remember, above in the chapter we mentioned that networking abstraction is good but you should not take it grantedly. Its important that you should have some networking expertise in your ream.

Make sure subnet is not conflicting,

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

Determining IP address of default interface
Using interface with name enp0s3 and address 10.0.2.15
Defaulting external address to interface address (10.0.2.15)
```

We have problem here, flannel decided to use enp0s3 instead of enp0s8 and enp0s3 is configured with same IP on all nodes for NATed external traffic. This is not the right interface we want to use with flannel. Vagrant creates two interfaces and flannel picked the first interface by default unless you provide configuration to flannel. 

### Fix the issue

Remove nginx deployment and flannel before we can apply the fix.

```
kubectl --kubeconfig ./admin.conf delete -f nginx-deployment.yaml
deployment "nginx-deployment" deleted

kubectl --kubeconfig ./admin.conf delete -f flannel.yml

kubectl --kubeconfig ./admin.conf get pods --all-namespaces

NAMESPACE     NAME                             READY     STATUS    RESTARTS   AGE
kube-system   etcd-master                      1/1       Running   0          1h
kube-system   kube-apiserver-master            1/1       Running   0          1h
kube-system   kube-controller-manager-master   1/1       Running   0          1h
kube-system   kube-dns-86f4d74b45-pkgzx        3/3       Running   0          1h
kube-system   kube-proxy-dwq2c                 1/1       Running   0          1h
kube-system   kube-proxy-jtdgc                 1/1       Running   0          1h
kube-system   kube-proxy-nrklx                 1/1       Running   0          1h
kube-system   kube-scheduler-master            1/1       Running   0          1h
```

We need to pass additional parameter to Flannel for interface enp0s8. flannel_fix.yml file has this fix as `--iface=enp0s8`. Lets recreate pod network and nginx.

```bash
kubectl --kubeconfig ./admin.conf apply -f flannel_fix.yml

kubectl --kubeconfig ./admin.conf get pods --all-namespaces -l app=flannel

NAMESPACE     NAME                    READY     STATUS    RESTARTS   AGE
kube-system   kube-flannel-ds-4mwc7   1/1       Running   0          35s
kube-system   kube-flannel-ds-fj8dg   1/1       Running   0          35s
kube-system   kube-flannel-ds-tjz4c   1/1       Running   0          35s

kubectl --kubeconfig ./admin.conf apply -f nginx-deployment.yaml
deployment "nginx-deployment" created

$ kubectl --kubeconfig ./admin.conf get pods -o wide

NAME                                READY     STATUS    RESTARTS   AGE       IP           NODE
nginx-deployment-75675f5897-46tfh   1/1       Running   0          12m       10.244.3.4   node2
nginx-deployment-75675f5897-rq75g   1/1       Running   0          12m       10.244.1.3   node1
```

* All nodes can communicate with all pods (and vice-versa) without NAT

```bash
vagrant ssh node1

ping 10.244.1.3

PING 10.244.1.3 (10.244.1.3) 56(84) bytes of data.
64 bytes from 10.244.1.3: icmp_seq=1 ttl=64 time=0.137 ms

ping 10.244.3.4

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

## May be one more provider example 

## Network policy