cd k8s-specs

git pull

cd cluster

vagrant up

vagrant status

vagrant ssh master

sudo kubeadm init --apiserver-advertise-address 10.100.198.200

#To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You can now join any number of machines by running the following on each node
as root:

#Your token values will be different, so copy join command from your init output 
kubeadm join 10.100.198.200:6443 --token q0xiub.nxs5ux9tjqn9rnb2 --discovery-token-ca-cert-hash sha256:80348065b7738e44b350068f8ab8d551fe5799f1acda2f132775cebb2544e4d2

sudo cp /etc/kubernetes/admin.conf /vagrant

exit

vagrant ssh node1

sudo su -

#Your token values will be different, so copy join command from your init output
kubeadm join 10.100.198.200:6443 --token q0xiub.nxs5ux9tjqn9rnb2 --discovery-token-ca-cert-hash sha256:80348065b7738e44b350068f8ab8d551fe5799f1acda2f132775cebb2544e4d2

exit

vagrant ssh node2

sudo su -

#Your token values will be different, so copy join command from your init output
kubeadm join 10.100.198.200:6443 --token q0xiub.nxs5ux9tjqn9rnb2 --discovery-token-ca-cert-hash sha256:80348065b7738e44b350068f8ab8d551fe5799f1acda2f132775cebb2544e4d2

exit

kubectl --kubeconfig ./admin.conf get nodes

vagrant destroy -f
