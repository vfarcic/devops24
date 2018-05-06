# Appendix A: Installing kubectl and Creating A Cluster With minikube {#appendix-a}

The text that follows provides the essential information you'll need to create a local Kubernetes cluster using minikube. This appendix contains a few sub-chapters from **The DevOps 2.3 Toolkit: Kubernetes**. Please refer to it for a more detailed information.

## Running Kubernetes Cluster Locally

Minikube creates a single-node cluster inside a VM on your laptop. While that is not ideal since we won't be able to demonstrate some of the features Kubernetes provides in a multi-node setup, it should be more than enough to explain most of the concepts behind Kubernetes. Later on, we'll move into a more production-like environment and explore the features that cannot be demonstrated in Minikube.

W> ## A note to Windows users
W>
W> Please run all the examples from *GitBash* (installed through *Git*). That way the commands you'll see throughout the book will be same as those that should be executed on *MacOS* or any *Linux* distribution. If you're using Hyper-V instead of VirtualBox, you may need to run the *GitBash* window as an Administrator.

Before we dive into Minikube installation, there are a few prerequisites we should set up. The first in line is `kubectl`.

## Installing kubectl

Kubernetes' command-line tool, `kubectl`, is used to manage a cluster and applications running inside it. We'll use `kubectl` a lot throughout the book, so we won't go into details just yet. Instead, we'll discuss its commands through examples that will follow shortly. For now, think of it as your interlocutor with a Kubernetes cluster.

Let's install `kubectl`.

I> All the commands from this chapter are available in the [02-minikube.sh](https://gist.github.com/77ca05f4d16125b5a5a5dc30a1ade7fc) Gist.

T> Feel free to skip the installation steps if you already have `kubectl`. Just make sure that it is version 1.8 or above.

If you are a **MacOS user**, please execute the commands that follow.

```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/darwin/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl
```

If you already have [Homebrew](https://brew.sh/) package manager installed, you can "brew" it with the command that follows.

```bash
brew install kubectl
```

If, on the other hand, you're a **Linux user**, the commands that will install `kubectl` are as follows.

```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl
```

Finally, **Windows users** should download the binary through the command that follows.

```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/windows/amd64/kubectl.exe
```

Feel free to copy the binary to any directory. The important thing is to add it to your `PATH`.

Let's check `kubectl` version and, at the same time, validate that it is working correctly. No matter which OS you're using, the command is as follows.

```bash
kubectl version
```

The output is as follows.

```
Client Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.0", GitCommit:"925c127ec6b946659ad0fd596fa959be43f0cc05", GitTreeState:"clean", BuildDate:"2017-12-15T21:07:38Z", GoVersion:"go1.9.2", Compiler:"gc", Platform:"darwin/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

That is a very ugly and unreadable output. Fortunately, `kubectl` can use a few different formats for its output. For example, we can tell it to output the command in `yaml` format

```bash
kubectl version --output=yaml
```

The output is as follows.

```
clientVersion:
  buildDate: 2017-12-15T21:07:38Z
  compiler: gc
  gitCommit: 925c127ec6b946659ad0fd596fa959be43f0cc05
  gitTreeState: clean
  gitVersion: v1.9.0
  goVersion: go1.9.2
  major: "1"
  minor: "9"
  platform: darwin/amd64

The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

That was a much better (more readable) output.

We can see that the client version is 1.9. At the bottom is the error message stating that `kubectl` could not connect to the server. That is expected since we did not yet create a cluster. That's our next step.

I> At the time of writing this book kubectl version was 1.9.0. Your version might be different when you install.

## Installing Minikube

Minikube supports several virtualization technologies. We'll use VirtualBox throughout the book since it is the only virtualization supported in all operating systems. If you do not have it already, please head to the [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads) page and get the version that matches your OS. Please keep in mind that for VirtualBox or HyperV to work, virtualization must be enabled in the BIOS. Most laptops should have it enabled by default.

Finally, we can install Minikube.

If you're using **MacOS**, please execute the command that follows.

```bash
brew cask install minikube
```

If, on the other hand, you prefer **Linux**, the command is as follows.

```bash
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

Finally, you will not get a command if you are a Windows user. Instead, download the latest release from of the [minikube-windows-amd64.exe](https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe) file, rename it to `minikube.exe`, and add it to your path.

We'll test whether Minikube works by checking its version.

```bash
minikube version
```

The output is as follows.

```
minikube version: v0.23.0
```

Now we're ready to give the cluster a spin.

## Creating A Local Kubernetes Cluster With Minikube

The folks behind Minikube made creating a cluster as easy as it can get. All we need to do is to execute a single command. Minikube will start a virtual machine locally and deploy the necessary Kubernetes components into it. The VM will get configured with Docker and Kubernetes via a single binary called localkube.

```bash
minikube start --vm-driver=virtualbox
```

W> ## A note to Windows users
W> 
W> You might experience problems with `virtualbox`. If that's the case, you might want to use `hyperv` instead. Open a Powershell Admin Window and execute the `Get-NetAdapter` command, noting the name of your network connection. Create a `hyperv` virtual switch `New-VMSwitch -name NonDockerSwitch -NetAdapterName Ethernet -AllowManagementOS $true` replacing `Ethernet` with your network connection name. Then create the Minikube vm: `minikube start --vm-driver=hyperv --hyperv-virtual-switch "NonDockerSwitch" --memory=4096`. Other minikube commands such as `minikube start`, `minikube stop` and `minikube delete` all work the same whether you're using VirutalBox or Hyper-V.

A few moments later, a new Minikube VM will be created and set up, and a cluster will be ready for use.

When we executed the `minikube start` command, it created a new VM based on the Minikube image. That image contains a few binaries. It has both [Docker](https://www.docker.com/) and [rkt](https://coreos.com/rkt/) container engines as well as *localkube* library. The library includes all the components necessary for running Kubernetes. We'll go into details of all those components later. For now, the important thing is that localkube provides everything we need to run a Kubernetes cluster locally.

![Figure 2-1: Minikube simplified architecture](images/ch02/minikube-simple.png)

Remember that this is a single-node cluster. While that is unfortunate, it is still the easiest way (as far as I know) to "play" with Kubernetes locally. It should do, for now. Later on, we'll explore ways to create a multi-node cluster that will be much closer to a production setup.

Let's take a look at the status of the cluster.

```bash
minikube status
```

The output is as follows.

```
minikube: Running
cluster: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.99.100
```

Minikube is running, and it initialized a Kubernetes cluster. It even configured `kubectl` so that it points to the newly created VM.

You won't see much UI in this book. I believe that a terminal is the best way to operate a cluster. More importantly, I am convinced that one should master a tool through its commands first. Later on, once we feel comfortable and understand how the tool works, we can choose to use a UI on top of it. We'll explore the Kubernetes UI in one of the later chapters. For now, I'll let you have a quick glimpse of it.

```bash
minikube dashboard
```

Feel free to explore the UI but don't take too long. You'll only get confused with concepts that we did not yet study. Once we learn about pods, replica-sets, services, and a myriad of other Kubernetes components, the UI will start making much more sense.

![Figure 2-2: Kubernetes dashboard](images/ch02/dashboard.png)

Another useful Minikube command is `docker-env`.

```bash
minikube docker-env
```

The output is as follows.

```
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/vfarcic/.minikube/certs"
export DOCKER_API_VERSION="1.23"
# Run this command to configure your shell:
# eval $(minikube docker-env)
```

If you worked with Docker Machine, you'll notice that the output is the same. Both `docker-machine env` and `minikube docker-env` serve the same purpose. They output the environment variables required for a local Docker client to communicate with a remote Docker server. In this case, that Docker server is the one inside a VM created by Minikube. I assume that you already have Docker installed on your laptop. If that's not the case, please go to the [Install Docker](https://docs.docker.com/engine/installation/) page and follow the instructions for your operating system. Once Docker is installed, we can connect the client running on your laptop with the server in the Minikube VM.

```bash
eval $(minikube docker-env)
```

We evaluated (created) the environment variables provided through the `minikube docker-env` command. As a result, every command we send to our local Docker client will be executed on the Minikube VM. We can test that easily by, for example, listing all the running containers on that VM.

```bash
docker container ls
```

The containers listed in the output are those required by Kubernetes. We can, in a way, consider them system containers. We won't discuss each of them. As a matter of fact, we won't discuss any of them. At least, not right away. All you need to know, at this point, is that they make Kubernetes work.

Since almost everything in that VM is a container, pointing the local Docker client to the service inside it should be all you need (besides `kubectl`). Still, in some cases, you might want to SSH into the VM.

```bash
minikube ssh

docker container ls

exit
```

We entered into the Minikube VM, listed containers, and got out. There's no reason to do anything else beyond showing that SSH is possible, even though you probably won't use it.

What else is there to verify? We can, for example, confirm that `kubectl` is also pointing to the Minikube VM.

```bash
kubectl config current-context
```

The output should be a single word, `minikube`, indicating that `kubectl` is configured to talk to Kubernetes inside the newly created cluster.

As an additional verification, we can list all the nodes of the cluster.

```bash
kubectl get nodes
```

The output is as follows.

```
NAME     STATUS ROLES  AGE VERSION
minikube Ready  <none> 31m v1.8.0
```

It should come as no surprise that there is only one node, conveniently called `minikube`.

If you are experienced with Docker Machine or Vagrant, you probably noticed the similar pattern. Minikube commands are almost exactly the same as those from Docker Machine which, on the other hand, are similar to those from Vagrant.

We can do all the common things we would expect from a virtual machine. For example, we can stop it.

```bash
minikube stop
```

We can start it again.

```bash
minikube start
```

We can delete it.

```bash
minikube delete
```

One interesting feature is the ability to specify which Kubernetes version we'd like to use.

Since Kubernetes is still a young project, we can expect quite a lot of changes at a rapid pace. That will often mean that our production cluster might not be running the latest version. On the other hand, we should strive to have our local environment as close to production as possible (within reason).

We can list all the available versions with the command that follows.

```bash
minikube get-k8s-versions
```

The output, limited to the first few lines, is as follows.

```
The following Kubernetes versions are available:
        - v1.9.0
        - v1.8.0
        - v1.7.5
        - v1.7.4
        - v1.7.3
        - v1.7.2
        - v1.7.0
        ...
```

Now that we know which versions are available, we can create a new cluster based on, let's say, Kubernetes v1.7.0.

```basdh
minikube start \
    --vm-driver=virtualbox \
    --kubernetes-version="v1.7.0"

kubectl version --output=yaml
```

We created a new cluster and output versions of the client and the server.

The output of the latter command is as follows.

```
clientVersion:
  buildDate: 2017-10-24T19:48:57Z
  compiler: gc
  gitCommit: bdaeafa71f6c7c04636251031f93464384d54963
  gitTreeState: clean
  gitVersion: v1.8.2
  goVersion: go1.8.3
  major: "1"
  minor: "8"
  platform: darwin/amd64
serverVersion:
  buildDate: 2017-10-04T09:25:40Z
  compiler: gc
  gitCommit: d3ada0119e776222f11ec7945e6d860061339aad
  gitTreeState: dirty
  gitVersion: v1.7.0
  goVersion: go1.8.3
  major: "1"
  minor: "7"
  platform: linux/amd64
```

If you focus on the `serverVersion` section, you'll notice that the `major` version is `1` and the `minor` is `7`.

## What Now?

We are finished with a short introduction to Minikube. Actually, this might be called a long introduction as well. We use it to create a single-node Kubernetes cluster, launch the UI, do common VM operations like stop, restart, and delete, and so on. There's not much more to it. If you are familiar with Vagrant or Docker Machine, the principle is the same, and the commands are very similar.

Before we leave, we'll destroy the cluster. The next chapter will start fresh. That way, you can execute commands from any chapter at any time.

```bash
minikube delete
```

That's it. The cluster is no more.
