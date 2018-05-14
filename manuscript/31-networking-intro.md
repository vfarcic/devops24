## TODO

- [-] Code (neerajkothari)
- [-] Code review (vfarcic)
- [ ] Write (neerajkothari)
- [X] Text review (vfarcic)
- [ ] Diagrams (neerajkothari)
- [-] Gist (neerajkothari)
- [ ] Review the title (neerajkothari)
- [ ] Proofread (vfarcic)
- [ ] Add to Book.txt (vfarcic)
- [ ] Publish on LeanPub.com (vfarcic)

# Kubernetes Networking

T> Networking is the backbone of distributed applications. Without dynamically created software defined networks and service discovery, distributed applications would not be able to find each others.

Kubernetes has pluggable architecure. Team behind it (probably) made a right decision to keep networking (just as almost everything else) as pluggable modules. Each organization is free to choose the type of networking that suits specific goals. Choosing the correct type is one of the critical decisions we need to make when setting up a Kubernetes cluster.

One of the main benefits behind architecture like Kubernetes' is that anyone can develop a module and plug it in. As a result, we got a myriad of projects (some open source and some enterprise) we can choose from. Having a choice is both a blessing and a curse. We can choose the pieces we want, but we need to spend a considerable time exploring which option suits us better. That is, unless we choose to use one of the opinionated distributions that already come with (mostly) predefined modules and ways of operating the cluster.

We'll focus on providing you with the information about some of the most commonly used networking solutions. The objective is to prepare you so that you can navigate the maze. You won't get the experience with every networking solution available in the market. That would be impossible. There are too many available. Still, our hope is that you will gain knowledge about those that are gaining the most attention. Even if none of those we'll explore ends up being your choice, you will know what to look for and how to evaluate networking providers.

Kubernetes' approache to the communication problem in the container world is using components like Services, Ingress, kubeDNS, etc. For Pod-to-Pod communication Kubernetes doesn't dictate how networking is implemented. However, it does impose some basic requirements which providers need to fullfil.

At its core, Kubernetes networking model guarantees a few things. They are as follows.

* All Pods can communicate with all other pods without NAT.
* All nodes can communicate with all pods (and vice-versa) without NAT.
* The IP that a Pod sees is the same IP others can use to communicate with it.

Currently, Kubernetes provides networking using either *kubenet* or *Container Network Interface (CNI)* plugins. The latter is used as an interface between network providers and Kubernetes networking.

Kubernetes' default networking driver is kubenet. It is a very basic networking plugin typically useful for single node environments or in cloud with routing rules. It has limited features and it is often not a good option for vast majority of implementations, especially when running bigger clusters. As an example, kubenet used in AWS is limited to 50 nodes. Such a limitation is imposed by the limits of routing tables. While fifty nodes is more than many smaller companies need, the moment we decide to scale over that number, we need to start thinking about other solution.

Even if you do run your cluster in, let's say, AWS, and you do not need more than fifty nodes, you will still find kubenet limiting when compared with some other solutions. Even if the limitation in the maximum number of nodes is not enough and you discover that you do not need the additional features, there is still the fact that Kubernetes roadmap plans to move away from kubenet. If it deprecated in favour of CNI.

Considering all that, we'll skip exploring kubenet and focus on CNI.

## What Is Container Network Interface (CNI)?

Container Network Interface (CNI) consists of a specification and libraries which can be used for writing plugins. It also container a few basic plugins. CNI is a very simple specification which concerns only with network connectivity of containers and removing networking resources when containers are deleted.

CNI specs were originally developed by CoreOS for [rkt](https://coreos.com/rkt) project and are now managed by [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/) under the [ContainerNetworking team](https://github.com/containernetworking). It has two branches. The first one is in charge of defining CNI specifications, while the second branch is working on plugins reference implementation of CNI specs.

CNI and container runtimes are intricately tied together. Container runtime creates network namespace and hands it over to a set of CNI plugin(s) which setup interfaces, iptables, routing, etc.

CNI plugins are categorized into two groups. The main plugins are responsible for setting up a network interface into the container network namespace as well as assigning IP to the interface and setting the routes. The routes are set up by invoking appropriate IPAM plugin which determines the interface IP/subnet, gateway and routes, and returns that information to the *main* plugin which applies them.

![Figure 1-1: Basic CNI diagram](images/cni-basic.png)

ContainerNetworking team created several basic plugins as reference implementations. We going to use some of those later. If you are impatient, please visit [containernetworking/plugins](https://github.com/containernetworking/plugins) repository for more info.

The steps that follow describe how a Pod gets its network.

1. User supplies network configuration file which contains plugin type and IP.
2. Kubelet works with CNI plugins on each host in kubernetes cluster. It creates Pod namespace with pause container. Pause container is created for each Pod. It serves network namespace to other containers in the Pod.
3. Kubelet has CNI library which invokes CNI main plugin and hands over namespace and other network information.
4. CNI plugin sets network elements like interfaces, iptables, routing, etc. for Pod and host network namespace.
5. CNI main plugin invokes IPAM plugin for IP allocation and IPAM returns IP information in json format to the main plugin.
6. The main plugin uses the information obtained from the IPAM plugin to configure network interface.
7. The main plugin updates API server with network information for the Pod.

![Figure 1-2: CNI Plugin Flow](images/cni-flow.png)

The most commonly used networking options can be grouped into *Overlay*, *Layer 2*, and *Layer 3* solutions. Some third-party providers are even extending the core networking features. A good example is NetworkPolicy which can be defined only through a few networking solutions.

Choosing the right networking is one of the essential tasks. The choice should be based on a few criteria which we'll explore through practical examples.

First things first. We cannot explore networking through hands-on examples without having a cluster. So, our first task will be to create one.
