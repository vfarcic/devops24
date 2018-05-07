## Comparing Kubernetes Platforms For Running Local Clusters

When running a local Kubernetes cluster, there are no big differences between Docker for Mac/Windows, minikube, and openshift. All three create a fully operational Kubernetes cluster.

Docker for Mac/Windows provides a very transparent experience. It's as if it's not even there. It runs in background. There are no commands to create or destroy the cluster. It feels like Kubernetes is running on top of our operating system.

We did experience a problem with ServiceAccounts in Docker for Mac/Windows. Even though RBAC is set up by default, we could use a sidecar container that communicated with Kube API. For most use cases, that is not a real problem. Docker for Mac/Windows is designed to be a single-user cluster that is accessible only to the owner of the laptop. RBAC (as ServiceAccounts) make sense only when running a "real" cluster used by many users and, consequently, many processes. Still, we might want to test our ServiceAccounts locally. We could not do that through Docker For Mac/Windows.

TODO: Trash Docker for Mac/Windows ServiceAccount

TODO: Docker for Mac/Windows provides no mechanism to specify k8s version

Another negative experience with Docker For Mac/Windows was installation of Ingress Controller. We had to follow the official instructions. With minikube, for example, we can simply execute `minikube addons enable ingress` to accomplish the same result. If we are to give a recommendation how to run a Kubernetes cluster locally to someone not interested diving deep into Kubernetes, minikube addons make everything much easier. On the other hand, hanving to install system level components like Ingress using kubectl (or Helm) make local cluster much more similar to "real" production. Still, that should not be a problem in case of minikube. Having addons does not mean that we cannot ignore them and run the same commands to, for example, install Ingress locally as we'd do in production.

Minishift is very similar to minikube. Both create a cluster with a single command. The only issue is that minishift does not support default storage class. As a workaround, we got a hundred volumes without a class name. The result is the same. In both cases we can create volume claims with storage class name. Still, it's a bit annoying that we have to see those hundred volumes knowing that minikube already has a more elegant solution.

If you're wondering which solution to use to create a Kubernetes cluster locally, I'd recommend Docker for Mac/Windows, unless you are running Linux. It does have a few issues I did not detect in minikube but they are minor and we can expect them to be fixed soon.

The only downside of Docker For Mac/Windows I can think of is that there is no Docker For Linux. If you're running Ubuntu or some other Linux distribution on your laptop, you'll have to switch to minikube or minishift. For everyone else, Docker for Mac/Windows is probably the best way to run a Kubernetes cluster. Unless, you're planning to use OpenShift as your production cluster. In that case, there is very little doubt that you should run minishift locally.

While OpenShift is great and it does bring additional value on top of "vanilla" Kubernetes, it also introduces controllers that are very specific to OpenShift. That in itself should not be a problem. If you want additional value in Kubernetes, that comes through new controllers. But, not everything in OpenShift brings additional value. Routes are a very good example. They replace Ingress without providing a tangible benefit. As a result, you are tied to a platform that has a valid alternative in form of a standard API. Ingress is the direction Kubernetes community decided to take for routing external requests. I can imagine that routes exist only for historical reasons. RedHat (and the community behind OpenShift) implemented them when Ingress did not exist. The problem is that we (Kubernetes community) moved on and choose Ingress as the preferable way to handle external routing. Yet, OpenShift continues to stick to Routes and, as the result, you have to use minishift for local clusters. Not being compatible with all the standards is the biggest downside of OpenShift. We can circumvent incompatibility problem by, for example, installing Ingress but that would only open Pandora's box. No OpenShift cluster I've seen did that.

What is the final recommendation? **Use Docker For Mac/Windows to run your cluster locally**. It is the most user-friendly solution that makes running a cluster as transparent as possible. If you are using Linux as the operating system on your laptop, minikube is the way to go. Minishift makes sense only if you chose to use OpenShift as the platform for running production clusters. Without it, you won't be able to create OpenShift-specific resources like Routes.

## Comparing Kubernetes Platforms For Running On-Prem Clusters

TODO: Write

TODO: OpenShift has too many inconsistencies compared with the "official" API.

## Comparing Kubernetes Platforms For Running Clusters In Cloud

TODO: Write

## Comparing Kubernetes Platforms For Running Managed Clusters

TODO: Write

## Random Stuff

OpenShift con: Slight differences in the security context
OpenShift con: Services accessible through Routes need to be `LoadBalancer` type.

minishift con: A hundred volumes instead of a dynamic StorageClass

GKE con: The default Ingress forces Services to publish NodePort making it incompatible with YAMLs created for other platforms

kops: requires understanding of things like AZs