open "https://$IP"

TOKEN=[...]

curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/digitalocean-secret.yaml \
    | sed -e  "s@<DigitalOcean token>@$TOKEN@g" \
    | kubectl apply -f -

kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/rbac/clusterrole.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/rbac/clusterrolebinding.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/rbac/role.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/rbac/rolebinding.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/rbac/serviceaccount.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/digitalocean-provisioner.yaml

curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/digitalocean-flexplugin-deploy.yaml \
    | sed -e  "s@<flex volume plugin dir, default: /usr/libexec/kubernetes/kubelet-plugins/volume/exec/>@/usr/libexec/kubernetes/kubelet-plugins/volume/exec/@g" \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/digitalocean/manifests/sc.yaml \
    | sed -e  "s@<digitalocean zone: ex fra1>@nyc1@g" \
    | kubectl apply -f -

#######################
# Destroy the cluster #
#######################

