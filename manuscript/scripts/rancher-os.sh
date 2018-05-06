######################
# Create The Cluster #
######################

open "https://cloud.digitalocean.com/settings/api/tokens"

# Create an SSH key named devop24

doctl auth init

doctl compute ssh-key list

# Copy the ID of the key

KEY_ID=[...]

KEY_PATH=[...]

IMAGE_ID=$(doctl compute \
    image list-distribution \
    -o json \
    | jq '.[] | select(.slug=="ubuntu-18-04-x64").id')

doctl compute droplet create rancher \
    --enable-private-networking \
    --image $IMAGE_ID \
    --size s-2vcpu-4gb \
    --region nyc1 \
    --ssh-keys $KEY_ID

IP=$(doctl compute droplet list \
    -o json | \
    jq -r '.[] | select(.name=="rancher").networks.v4[0].ip_address')

ssh -i $KEY_PATH root@$IP

apt update

apt install -y docker.io

sudo docker run -d \
    --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    rancher/server:preview

exit

open "https://$IP"

# Finish the setup
# Click *Add Cluster*
# Click *DigitalOcean*
# Type *devops24* as the *Cluster Name*
# Create a *Node Pool* with *Name Prefix* set to *master*, *Count* set to *3*, and *etcd* and *Control* checked.
# Click on *Add Node Template*, type the token, select *New York 1* as the *Region*, select *1 GB RAM, 30 GB Disk, 1 vCPUs* as *Droplet Size*, click the *Create* button
# Click the *Add Node Pool* button
# Create a *Node Pool* with *Name Prefix* set to *worker*, *Count* set to *3*, and *Worker* checked.
# Click on *Add Node Template*, type the token, select *New York 1* as the *Region*, select *2 GB RAM, 60 GB Disk, 2 vCPUs* as *Droplet Size*, click the *Create* button
# Click the *Create* button
# Wait until the cluster is created (everything is green)
# Click the *Kubeconfig File* button
# Click the *Copy to Clipboard* link

vim cluster/do-kube-config.yaml

# Paster the config and save the file

export KUBECONFIG=$PWD/cluster/do-kube-config.yaml

kubectl get nodes

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

