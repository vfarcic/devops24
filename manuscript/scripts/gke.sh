######################
# Create The Cluster #
######################

gcloud auth login

gcloud auth application-default login

ZONE=$(gcloud compute zones list \
    --filter "region:(us-east1)" \
    | awk '{print $1}' \
    | tail -n 1)

ZONES=$(gcloud compute zones list \
    --filter "region:(us-east1)" \
    | awk '{print $1}' \
    | tr '\n' ',')

MACHINE_TYPE=n1-standard-1

gcloud container clusters \
    create devops24 \
    --zone $ZONE \
    --node-locations $ZONES \
    --machine-type $MACHINE_TYPE \
    --enable-autoscaling \
    --max-nodes 3 \
    --min-nodes 3

kubectl create clusterrolebinding \
    cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/namespace.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/default-backend.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/configmap.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/tcp-services-configmap.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/udp-services-configmap.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/rbac.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml

kubectl patch deployment \
    -n ingress-nginx nginx-ingress-controller \
    --type='json' \
    --patch="$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/publish-service-patch.yaml)"

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/gce-gke/service.yaml

kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/patch-service-with-rbac.yaml

#######################
# Destroy the cluster #
#######################

gcloud container clusters \
    delete devops24 \
    --zone $ZONE \
    --quiet
