cd k8s-specs

git pull

cd basic

vagrant up

kubectl --kubeconfig ./admin.conf get nodes

kubectl --kubeconfig ./admin.conf apply -f nginx-deployment.yaml

kubectl --kubeconfig ./admin.conf get pods -o wide

vagrant ssh node1

ping 10.22.2.2

ping 10.22.3.3

exit

NODE1_POD_NAME=$(kubectl --kubeconfig ./admin.conf get pods -o json | jq -r '.items[] | select(.spec.nodeName=="node1") | [.metadata.name] | @tsv')

NODE2_POD_IP=$(kubectl --kubeconfig ./admin.conf get pods -o json | jq -r '.items[] | select(.spec.nodeName=="node2") | [.status.podIP] | @tsv')

kubectl --kubeconfig ./admin.conf exec -it $NODE1_POD_NAME ping $NODE2_POD_IP

vagrant destroy -f
