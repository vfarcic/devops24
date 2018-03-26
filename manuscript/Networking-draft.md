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
    
## Create cluster

### Explain kubeadmn and advantages

### Use Flannel

### Something went wrong, Troubleshoot

## May be one more provider example 

## Network policy