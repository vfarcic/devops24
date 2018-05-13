cd k8s-specs

# Only if minishift
oc apply -f sa/jenkins-no-sa-oc.yml --record

# Only if NOT minishift
kubectl apply \
    -f sa/jenkins-no-sa.yml \
    --record

kubectl -n jenkins \
    rollout status sts jenkins

# Only if GKE
kubectl -n jenkins patch svc jenkins -p '{"spec":{"type": "NodePort"}}'

# Only if GKE
CLUSTER_DNS=$(kubectl -n jenkins \
    get ing jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Only if minishift
CLUSTER_DNS=$(minikube ip)

# Only if minikube
CLUSTER_DNS=jenkins-jenkins.$(minishift ip).nip.io

# Only if kops or Docker for Mac/Windows
CLUSTER_DNS=$(kubectl -n jenkins \
    get ing jenkins \
    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $CLUSTER_DNS

open "http://$CLUSTER_DNS/jenkins"

kubectl -n jenkins \
    exec jenkins-0 -it -- \
    cat /var/jenkins_home/secrets/initialAdminPassword

open "http://$CLUSTER_DNS/jenkins/pluginManager/available"

open "http://$CLUSTER_DNS/jenkins/configure"

kubectl delete ns jenkins

curl https://raw.githubusercontent.com/vfarcic/kubectl/master/Dockerfile

kubectl run kubectl \
    --image=vfarcic/kubectl \
    --restart=Never \
    sleep 10000

kubectl get pod kubectl \
    -o jsonpath="{.spec.serviceAccount}"

kubectl exec -it kubectl -- sh

cd /var/run/secrets/kubernetes.io/serviceaccount

ls -la

kubectl get pods

exit

kubectl delete pod kubectl

kubectl get sa

cat sa/view.yml

kubectl apply -f sa/view.yml --record

kubectl get sa

kubectl describe sa view

kubectl describe rolebinding view

cat sa/kubectl-view.yml

kubectl apply \
    -f sa/kubectl-view.yml \
    --record

kubectl describe pod kubectl

kubectl exec -it kubectl -- sh

kubectl get pods

kubectl run new-test \
    --image=alpine \
    --restart=Never \
    sleep 10000

exit

kubectl delete -f sa/kubectl-view.yml

cat sa/pods.yml

kubectl apply -f sa/pods.yml \
    --record

kubectl create ns test2

cat sa/kubectl-test1.yml

kubectl apply \
    -f sa/kubectl-test1.yml \
    --record

kubectl -n test1 exec -it kubectl -- sh

kubectl get pods

kubectl run new-test \
    --image=alpine \
    --restart=Never \
    sleep 10000

kubectl get pods

kubectl run new-test \
    --image=alpine sleep 10000

kubectl -n test2 get pods

exit

kubectl delete -f sa/kubectl-test1.yml

cat sa/pods-all.yml

kubectl apply -f sa/pods-all.yml \
    --record

kubectl apply \
    -f sa/kubectl-test2.yml \
    --record

kubectl -n test1 exec -it kubectl -- sh

kubectl -n test2 get pods

kubectl -n test2 \
    run new-test \
    --image=alpine \
    --restart=Never \
    sleep 10000

kubectl -n test2 get pods

exit

kubectl delete ns test1 test2

cat sa/jenkins.yml

# Only if minishift
oc apply -f sa/jenkins-oc.yml --record

# Only if NOT minishift
kubectl apply \
    -f sa/jenkins.yml \
    --record

# Only if GKE
kubectl -n jenkins patch svc jenkins -p '{"spec":{"type": "NodePort"}}'

kubectl -n jenkins \
    rollout status sts jenkins

open "http://$CLUSTER_DNS/jenkins"

kubectl -n jenkins \
    exec jenkins-0 -it -- \
    cat /var/jenkins_home/secrets/initialAdminPassword

open "http://$CLUSTER_DNS/jenkins/pluginManager/available"

open "http://$CLUSTER_DNS/jenkins/configure"

kubectl -n build get pods

kubectl -n build get pods

kubectl -n build get pods

kubectl delete ns jenkins build

cat sa/go-demo-3.yml

kubectl apply \
    -f sa/go-demo-3.yml \
    --record

kubectl -n go-demo-3 \
    get pods

kubectl -n go-demo-3 \
    logs db-0 -c db-sidecar

kubectl delete ns go-demo-3
