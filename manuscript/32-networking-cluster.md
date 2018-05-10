## TODO

- [ ] Code (neerajkothari)
- [ ] Code review (vfarcic)
- [ ] Write (neerajkothari)
- [ ] Text review (vfarcic)
- [ ] Diagrams (neerajkothari)
- [ ] Gist (neerajkothari)
- [ ] Review the title (neerajkothari)
- [ ] Proofread (vfarcic)
- [ ] Add to Book.txt (vfarcic)
- [ ] Publish on LeanPub.com (vfarcic)

# Create local cluster with kubadmn

Let's start with some hands-on as we usually do in each chapter and call our old friend vagarnt. We will create local cluster with help of vagrant and virtualbox. Lets pull the latest code from the [vfarcic/k8s-specs](https://github.com/vfarcic/k8s-specs) repository.

I> All the commands from this chapter are available in the [32-networking-cluster.sh](TODO: link) Gist.

```bash
cd k8s-specs

git pull

cd cluster

vagrant up
```

We will create three VMs, one master and two nodes and each VM is provisioned with necessary components docker, kubeadmn, kubelet, kubectl via `bootstrap.sh` script so that we can create kubernetes cluster. Check the status if all VMs are up.

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

There are several ways you can create a kubernetes cluster like the one we have seen in previous book with kops. In this chapter we will use `kubeadmn`. `kubeadmn` setup minimum viable cluster which makes it very simple. Below command initialized the master with control plane, etcd and API server. We passing master node IP we configured through vagrant. 

```bash
sudo kubeadm init --apiserver-advertise-address 10.100.198.200
```

This command will create all necessary config for kubernetes to function properly like keys, certificates, RBAC, pod manifest, etc and then kubelet on master node create pods for kubernetes control plane. This command may take few minutes as pulling the images. The output of above command as follows, removing most of the lines for sake of brevity.   

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

Follow the instructions from the output of `init` command while you login on master VM. We need this to run kubectl commands. Also, copy the config file `admin.conf` to our laptop working directory to manage this cluster from our laptop. Vagarnt mount our local dir as `/vagrant` in VMs.

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

It showing all nodes not ready because *kube-dns* pod is in pending state because we haven't installed pod network yet. Once we have networking in place in following chapters we will see these nodes in ready state.


## What now?

We have explored the local kubernetes cluster setup via kubeadmn. Lets delete the cluster,

```bash
vagrant destroy -f
```
