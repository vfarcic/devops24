# Appendix B: Using Kubernetes Operations (kops) {#appendix-b}

The text that follows provides the essential information you'll need to create a Kubernetes cluster in AWS using kops. This appendix contains a few sub-chapters from [The DevOps 2.3 Toolkit: Kubernetes](https://amzn.to/2GvzDjy). Please refer to it for a more detailed information.

## Preparing For The Cluster Setup

We'll continue using the specifications from the `vfarcic/k8s-specs` repository, so the first thing we'll do is to go inside the directory where we cloned it, and pull the latest version.

I> All the commands from this appendix are available in the [99-appendix-b.sh](https://gist.github.com/49bccadae317379bef6f81b4e5985f84) Gist.

```bash
cd k8s-specs

git pull
```

I will assume that you already have an AWS account. If that's not the case, please head over to [Amazon Web Services](https://aws.amazon.com/) and sign-up.

I> If you are already proficient with AWS, you might want to skim through the text that follows and only execute the commands.

The first thing we should do is get the AWS credentials.

Please open [Amazon EC2 Console](https://console.aws.amazon.com/ec2/), click on your name from the top-right menu and select *My Security Credentials*. You will see the screen with different types of credentials. Expand the *Access Keys (Access Key ID and Secret Access Key)* section and click the *Create New Access Key* button. Expand the *Show Access Key* section to see the keys.

You will not be able to view the keys later on, so this is the only chance you'll have to *Download Key File*.

We'll put the keys as environment variables that will be used by the [AWS Command Line Interface (AWS CLI)](https://aws.amazon.com/cli/).

Please replace `[...]` with your keys before executing the commands that follow.

```bash
export AWS_ACCESS_KEY_ID=[...]

export AWS_SECRET_ACCESS_KEY=[...]
```

We'll need to install [AWS Command Line Interface (CLI)](https://aws.amazon.com/cli/) and gather info about your account.

If you haven't already, please open the [Installing the AWS Command Line Interface](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) page, and follow the installation method best suited for your OS.

T> ## A note to Windows users
T>
T> I found the most convenient way to get AWS CLI installed on Windows is to use [Chocolatey](https://chocolatey.org/).  Download and install Chocolatey, then run `choco install awscli` from an Administrator Command Prompt. Later on in the chapter, Chocolatey will be used to install jq.

Once you're done, we'll confirm that the installation was successful by outputting the version.

W> ## A note to Windows users
W>
W> You might need to reopen your *GitBash* terminal for the changes to the environment variable `PATH` to take effect.

```bash
aws --version
```

The output (from my laptop) is as follows.

```
aws-cli/1.11.15 Python/2.7.10 Darwin/16.0.0 botocore/1.4.72
```

Amazon EC2 is hosted in multiple locations worldwide. These locations are composed of regions and availability zones. Each region is a separate geographic area composed of multiple isolated locations known as availability zones. Amazon EC2 provides you the ability to place resources, such as instances, and data in multiple locations.

Next, we'll define the environment variable `AWS_DEFAULT_REGION` that will tell AWS CLI which region we'd like to use by default.

```bash
export AWS_DEFAULT_REGION=us-east-2
```

For now, please note that you can change the value of the variable to any other region, as long as it has at least three availability zones. We'll discuss the reasons for using `us-east-2` region and the need for multiple availability zones soon.

Next, we'll create a few Identity and Access Management (IAM) resources. Even though we could create a cluster with the user you used to register to AWS, it is a good practice to create a separate account that contains only the privileges we'll need for the exercises that follow.

First, we'll create an IAM group called `kops`.

```bash
aws iam create-group \
    --group-name kops
```

The output is as follows.

```json
{
    "Group": {
        "Path": "/",
        "CreateDate": "2018-02-21T12:58:47.853Z",
        "GroupId": "AGPAIF2Y6HJF7YFYQBQK2",
        "Arn": "arn:aws:iam::036548781187:group/kops",
        "GroupName": "kops"
    }
}
```

We don't care much for any of the information from the output except that it does not contain an error message thus confirming that the group was created successfully.

Next, we'll assign a few policies to the group thus providing the future users of the group with sufficient permissions to create the objects we'll need.

Since our cluster will consist of [EC2](https://aws.amazon.com/ec2) instances, the group will need to have the permissions to create and manage them. We'll need a place to store the state of the cluster so we'll need access to [S3](https://aws.amazon.com/s3). Furthermore, we need to add [VPCs](https://aws.amazon.com/vpc/) to the mix so that our cluster is isolated from prying eyes. Finally, we'll need to be able to create additional IAMs.

In AWS, user permissions are granted by creating policies. We'll need `AmazonEC2FullAccess`, `AmazonS3FullAccess`, `AmazonVPCFullAccess`, and `IAMFullAccess`.

The commands that attach the required policies to the `kops` group are as follows.

```bash
aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess \
    --group-name kops

aws iam attach-group-policy \
    --policy-arn arn:aws:iam::aws:policy/IAMFullAccess \
    --group-name kops
```

Now that we have a group with the sufficient permissions, we should create a user as well.

```bash
aws iam create-user \
    --user-name kops
```

The output is as follows.

```json
{
    "User": {
        "UserName": "kops",
        "Path": "/",
        "CreateDate": "2018-02-21T12:59:28.836Z",
        "UserId": "AIDAJ22UOS7JVYQIAVMWA",
        "Arn": "arn:aws:iam::036548781187:user/kops"
    }
}
```

Just as when we created the group, the contents of the output are not important, except as a confirmation that the command was executed successfully.

The user we created does not yet belong to the `kops` group. We'll fix that next.

```bash
aws iam add-user-to-group \
    --user-name kops \
    --group-name kops
```

Finally, we'll need access keys for the newly created user. Without them, we would not be able to act on its behalf.

```bash
aws iam create-access-key \
    --user-name kops >kops-creds
```

We created access keys and stored the output in the `kops-creds` file. Let's take a quick look at its content.

```bash
cat kops-creds
```

The output is as follows.

```json
{
    "AccessKey": {
        "UserName": "kops",
        "Status": "Active",
        "CreateDate": "2018-02-21T13:00:24.733Z",
        "SecretAccessKey": "...",
        "AccessKeyId": "..."
    }
}
```

Please note that I removed the values of the keys. I do not yet trust you enough with the keys of my AWS account.

We need the `SecretAccessKey` and `AccessKeyId` entries. So, the next step is to parse the content of the `kops-creds` file and store those two values as the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

In the spirit of full automation, we'll use [jq](https://stedolan.github.io/jq/) to parse the contents of the `kops-creds` file. Please download and install the distribution suited for your OS.

T> ## A note to Windows users
T>
T> Using Chocolatey, install `jq` from an Administrator Command Prompt via `choco install jq`.

```bash
export AWS_ACCESS_KEY_ID=$(\
    cat kops-creds | jq -r \
    '.AccessKey.AccessKeyId')

export AWS_SECRET_ACCESS_KEY=$(
    cat kops-creds | jq -r \
    '.AccessKey.SecretAccessKey')
```

We used `cat` to output contents of the file and combined it with `jq` to filter the input so that only the field we need is retrieved.

From now on, all the AWS CLI commands will not be executed by the administrative user you used to register to AWS, but as `kops`.

W> It is imperative that the `kops-creds` file is secured and not accessible to anyone but people you trust. The best method to secure it depends from one organization to another. No matter what you do, do not write it on a post-it and stick it to your monitor. Storing it in one of your GitHub repositories is even worse.

Next, we should decide which availability zones we'll use. So, let's take a look at what's available in the `us-east-2` region.

```bash
aws ec2 describe-availability-zones \
    --region $AWS_DEFAULT_REGION
```

The output is as follows.

```json
{
    "AvailabilityZones": [
        {
            "State": "available", 
            "RegionName": "us-east-2", 
            "Messages": [], 
            "ZoneName": "us-east-2a"
        }, 
        {
            "State": "available", 
            "RegionName": "us-east-2", 
            "Messages": [], 
            "ZoneName": "us-east-2b"
        }, 
        {
            "State": "available", 
            "RegionName": "us-east-2", 
            "Messages": [], 
            "ZoneName": "us-east-2c"
        }
    ]
}
```

As we can see, the region has three availability zones. We'll store them in an environment variable.

W> ## A note to Windows users
W> 
W> Please use `tr '\r\n' ', '` instead of `tr '\n' ','` in the command that follows.

```bash
export ZONES=$(aws ec2 \
    describe-availability-zones \
    --region $AWS_DEFAULT_REGION \
    | jq -r \
    '.AvailabilityZones[].ZoneName' \
    | tr '\n' ',' | tr -d ' ')

ZONES=${ZONES%?}

echo $ZONES
```

Just as with the access keys, we used `jq` to limit the results only to the zone names, and we combined that with `tr` that replaced new lines with commas. The second command removes the trailing comma.

The output of the last command that echoed the values of the environment variable is as follows.

```
us-east-2a,us-east-2b,us-east-2c
```

We'll discuss the reasons behind the usage of three availability zones later on. For now, just remember that they are stored in the environment variable `ZONES`.

The last preparation step is to create SSH keys required for the setup. Since we might create some other artifacts during the process, we'll create a directory dedicated to the creation of the cluster.

```bash
mkdir -p cluster

cd cluster
```

SSH keys can be created through the `aws ec2` command `create-key-pair`.

```bash
aws ec2 create-key-pair \
    --key-name devops23 \
    | jq -r '.KeyMaterial' \
    >devops23.pem
```

We created a new key pair, filtered the output so that only the `KeyMaterial` is returned, and stored it in the `devops.pem` file.

For security reasons, we should change the permissions of the `devops23.pem` file so that only the current user can read it.

```bash
chmod 400 devops23.pem
```

Finally, we'll need only the public segment of the newly generated SSH key, so we'll use `ssh-keygen` to extract it.

```bash
ssh-keygen -y -f devops23.pem \
    >devops23.pub
```

All those steps might look a bit daunting if this is your first contact with AWS. Nevertheless, they are pretty standard. No matter what you do in AWS, you'd need to perform, more or less, the same actions. Not all of them are mandatory, but they are good practice. Having a dedicated (non-admin) user and a group with only required policies is always a good idea. Access keys are necessary for any `aws` command. Without SSH keys, no one can enter into a server.

The good news is that we're finished with the prerequisites, and we can turn our attention towards creating a Kubernetes cluster.

## Creating A Kubernetes Cluster In AWS

We'll start by deciding the name of our soon to be created cluster. We'll choose to call it `devops23.k8s.local`. The latter part of the name (`.k8s.local`) is mandatory if we do not have a DNS at hand. It's a naming convention kops uses to decide whether to create a gossip-based cluster or to rely on a publicly available domain. If this would be a "real" production cluster, you would probably have a DNS for it. However, since I cannot be sure whether you do have one for the exercises in this book, we'll play it safe, and proceed with the gossip mode.

We'll store the name into an environment variable so that it is easily accessible.

```bash
export NAME=devops23.k8s.local
```

When we create the cluster, kops will store its state in a location we're about to configure. If you used Terraform, you'll notice that kops uses a very similar approach. It uses the state it generates when creating the cluster for all subsequent operations. If we want to change any aspect of a cluster, we'll have to change the desired state first, and then apply those changes to the cluster.

At the moment, when creating a cluster in AWS, the only option for storing the state are [Amazon S3](https://aws.amazon.com/s3) buckets. We can expect availability of additional stores soon. For now, S3 is our only option.

The command that creates an S3 bucket in our region is as follows.

```bash
export BUCKET_NAME=devops23-$(date +%s)

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --create-bucket-configuration \
    LocationConstraint=$AWS_DEFAULT_REGION
```

We created a bucket with a unique name and the output is as follows.

```json
{
    "Location": "http://devops23-1519993212.s3.amazonaws.com/"
}
```

For simplicity, we'll define the environment variable `KOPS_STATE_STORE`. Kops will use it to know where we store the state. Otherwise, we'd need to use `--store` argument with every `kops` command.

```bash
export KOPS_STATE_STORE=s3://$BUCKET_NAME
```

There's only one thing missing before we create the cluster. We need to install kops.

If you are a **MacOS user**, the easiest way to install `kops` is through [Homebrew](https://brew.sh/).

```bash
brew update && brew install kops
```

As an alternative, we can download a release from GitHub.

```bash
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-darwin-amd64

chmod +x ./kops

sudo mv ./kops /usr/local/bin/
```

If, on the other hand, you're a **Linux user**, the commands that will install `kops` are as follows.

```bash
wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64

chmod +x ./kops

sudo mv ./kops /usr/local/bin/
```

Finally, if you are a **Windows user**, you cannot install `kops`. At the time of this writing, its releases do not include Windows binaries. Don't worry. I am not giving up on you, dear *Windows user*. We'll manage to overcome the problem soon by exploiting Docker's ability to run any Linux application. The only requirement is that you have [Docker For Windows](https://www.docker.com/docker-windows) installed.

I already created a Docker image that contains `kops` and its dependencies. So, we'll create an alias `kops` that will create a container instead running a binary. The result will be the same.

The command that creates the `kops` alias is as follows. Execute it only if you are a **Windows user**.

```bash
mkdir config

alias kops="docker run -it --rm \
    -v $PWD/devops23.pub:/devops23.pub \
    -v $PWD/config:/config \
    -e KUBECONFIG=/config/kubecfg.yaml \
    -e NAME=$NAME -e ZONES=$ZONES \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e KOPS_STATE_STORE=$KOPS_STATE_STORE \
    vfarcic/kops"
```

We won't go into details of all the arguments the `docker run` command uses. Their usage will become clear when we start using `kops`. Just remember that we are passing all the environment variables we might use as well as mounting the SSH key and the directory where `kops` will store `kubectl` configuration.

We are, finally, ready to create a cluster. But, before we do that, we'll spend a bit of time discussing the requirements we might have. After all, not all clusters are created equal, and the choices we are about to make might severely impact our ability to accomplish the goals we might have.

The first question we might ask ourselves is whether we want to have high-availability. It would be strange if anyone would answer no. Who doesn't want to have a cluster that is (almost) always available? Instead, we'll ask ourselves what the things that might bring our cluster down are.

When a node is destroyed, Kubernetes will reschedule all the applications that were running inside it into the healthy nodes. All we have to do is to make sure that, later on, a new server is created and joined the cluster, so that its capacity is back to the desired values. We'll discuss later how are new nodes created as a reaction to failures of a server. For now, we'll assume that will happen somehow.

Still, there is a catch. Given that new nodes need to join the cluster, if the failed server was the only master, there is no cluster to join. All is lost. The part is where master servers are. They host the critical components without which Kubernetes cannot operate.

So, we need more than one master node. How about two? If one fails, we still have the other one. Still, that would not work.

Every piece of information that enters one of the master nodes is propagated to the others, and only after the majority agrees, that information is committed. If we lose majority (50%+1), masters cannot establish a quorum and cease to operate. If one out of two masters is down, we can get only half of the votes, and we would lose the ability to establish the quorum. Therefore, we need three masters or more. Odd numbers greater than one are "magic" numbers. Given that we won't create a big cluster, three should do.

With three masters, we are safe from a failure of any single one of them. Given that failed servers will be replaced with new ones, as long as only one master fails at the time, we should be fault tolerant and have high availability.

T> Always set an odd number greater than one for master nodes.

The whole idea of having multiple masters does not mean much if an entire data center goes down.

Attempts to prevent a data center from failing are commendable. Still, no matter how well a data center is designed, there is always a scenario that might cause its disruption. So, we need more than one data center. Following the logic behind master nodes, we need at least three. But, as with almost anything else, we cannot have any three (or more) data centers. If they are too far apart, the latency between them might be too high. Since every piece of information is propagated to all the masters in a cluster, slow communication between data centers would severely impact the cluster as a whole.

All in all, we need three data centers that are close enough to provide low latency, and yet physically separated, so that failure of one does not impact the others. Since we are about to create the cluster in AWS, we'll use availability zones (AZs) which are physically separated data centers with low latency.

T> Always spread your cluster between at least three data centers which are close enough to warrant low latency.

There's more to high-availability to running multiple masters and spreading a cluster across multiple availability zones. We'll get back to this subject later. For now, we'll continue exploring the other decisions we have to make.

Which networking shall we use? We can choose between *kubenet*, *CNI*, *classic*, and *external* networking.

The classic Kubernetes native networking is deprecated in favor of kubenet, so we can discard it right away.

The external networking is used in some custom implementations and for particular use cases, so we'll discard that one as well.

That leaves us with kubenet and CNI.

Container Network Interface (CNI) allows us to plug in a third-party networking driver. Kops supports [Calico](http://docs.projectcalico.org/v2.0/getting-started/kubernetes/installation/hosted/), [flannel](https://github.com/coreos/flannel), [Canal (Flannel + Calico)](https://github.com/projectcalico/canal), [kopeio-vxlan](https://github.com/kopeio/networking), [kube-router](https://github.com/kubernetes/kops/blob/master/docs/networking.md#kube-router-example-for-cni-ipvs-based-service-proxy-and-network-policy-enforcer), [romana](https://github.com/romana/romana), [weave](https://github.com/weaveworks/weave-kube), and [amazon-vpc-routed-eni](https://github.com/kubernetes/kops/blob/master/docs/networking.md#amazon-vpc-backend) networks. Each of those networks comes with pros and cons and differs in its implementation and primary objectives. Choosing between them would require a detailed analysis of each. We'll leave a comparison of all those for some other time and place. Instead, we'll focus on `kubenet`.

Kubenet is kops' default networking solution. It is Kubernetes native networking, and it is considered battle tested and very reliable. However, it comes with a limitation. On AWS, routes for each node are configured in AWS VPC routing tables. Since those tables cannot have more than fifty entries, kubenet can be used in clusters with up to fifty nodes. If you're planning to have a cluster bigger than that, you'll have to switch to one of the previously mentioned CNIs.

T> Use kubenet networking if your cluster is smaller than fifty nodes.

The good news is that using any of the networking solutions is easy. All we have to do is specify the `--networking` argument followed with the name of the network.

Given that we won't have the time and space to evaluate all the CNIs, we'll use kubenet as the networking solution for the cluster we're about to create. I encourage you to explore the other options on your own (or wait until I write a post or a new book).

Finally, we are left with only one more choice we need to make. What will be the size of our nodes? Since we won't run many applications, *t2.small* should be more than enough and will keep AWS costs to a minimum. *t2.micro* is too small, so we elected the second smallest among those AWS offers.

I> You might have noticed that we did not mention persistent volumes. We'll explore them in the next chapter.

The command that creates a cluster using the specifications we discussed is as follows.

```bash
kops create cluster \
    --name $NAME \
    --master-count 3 \
    --node-count 1 \
    --node-size t2.small \
    --master-size t2.small \
    --zones $ZONES \
    --master-zones $ZONES \
    --ssh-public-key devops23.pub \
    --networking kubenet \
    --kubernetes-version v1.8.4 \
    --authorization RBAC \
    --yes
```

We specified that the cluster should have three masters and one worker node. Remember, we can always increase the number of workers, so there's no need to start with more than what we need at the moment.

The sizes of both worker nodes and masters are set to `t2.small`. Both types of nodes will be spread across the three availability zones we specified through the environment variable `ZONES`. Further on, we defined the public key and the type of networking.

We used `--kubernetes-version` to specify that we prefer to run version `v1.8.4`. Otherwise, we'd get a cluster with the latest version considered stable by kops. Even though running latest stable version is probably a good idea, we'll need to be a few versions behind to demonstrate some of the features kops has to offer.

By default, kops sets `authorization` to `AlwaysAllow`. Since this is a simulation of a production-ready cluster, we changed it to `RBAC`, which we already explored in one of the previous chapters.

The `--yes` argument specifies that the cluster should be created right away. Without it, `kops` would only update the state in the S3 bucket, and we'd need to execute `kops apply` to create the cluster. Such two-step approach is preferable, but I got impatient and would like to see the cluster in all its glory as soon as possible.

The output of the command is as follows.

```
...
kops has set your kubectl context to devops23.k8s.local

Cluster is starting.  It should be ready in a few minutes.

Suggestions:
 * validate cluster: kops validate cluster
 * list nodes: kubectl get nodes --show-labels
 * ssh to the master: ssh -i ~/.ssh/id_rsa admin@api.devops23.k8s.local
The admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons: https://github.com/kubernetes/kops/blob/master/docs/addons.md
```

We can see that the `kubectl` context was changed to point to the new cluster which is starting, and will be ready soon. Further down are a few suggestions of the next actions. We'll skip them, for now.

W> ## A note to Windows users
W> 
W> Kops was executed inside a container. It changed the context inside the container that is now gone. As a result, your local `kubectl` context was left intact. We'll fix that by executing `kops export kubecfg --name ${NAME}` and `export KUBECONFIG=$PWD/config/kubecfg.yaml`. The first command exported the config to `/config/kubecfg.yaml`. That path was specified through the environment variable `KUBECONFIG` and is mounted as `config/kubecfg.yaml` on local hard disk. The latter command exports `KUBECONFIG` locally. Through that variable, `kubectl` is now instructed to use the configuration in `config/kubecfg.yaml` instead of the default one. Before you run those commands, please give AWS a few minutes to create all the EC2 instances and for them to join the cluster. After waiting and executing those commands, you'll be all set.

We'll use kops to retrieve the information about the newly created cluster.

```bash
kops get cluster
```

The output is as follows.

```
NAME               CLOUD ZONES
devops23.k8s.local aws   us-east-2a,us-east-2b,us-east-2c
```

This information does not tell us anything new. We already knew the name of the cluster and the zones it runs in.

How about `kubectl cluster-info`?

```bash
kubectl cluster-info
```

The output is as follows.

```
Kubernetes master is running at https://api-devops23-k8s-local-ivnbim-609446190.us-east-2.elb.amazonaws.com
KubeDNS is running at https://api-devops23-k8s-local-ivnbim-609446190.us-east-2.elb.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

We can see that the master is running as well as KubeDNS. The cluster is probably ready. If in your case KubeDNS did not appear in the output, you might need to wait for a few more minutes.

We can get more reliable information about the readiness of our new cluster through the `kops validate` command.

```bash
kops validate cluster
```

The output is as follows.

```
Using cluster from kubectl context: devops23.k8s.local

Validating cluster devops23.k8s.local

INSTANCE GROUPS
NAME              ROLE   MACHINETYPE MIN MAX SUBNETS
master-us-east-2a Master t2.small    1   1   us-east-2a
master-us-east-2b Master t2.small    1   1   us-east-2b
master-us-east-2c Master t2.small    1   1   us-east-2c
nodes             Node   t2.small    1   1   us-east-2a,us-east-2b,us-east-2c

NODE STATUS
NAME                 ROLE   READY
ip-172-20-120-133... master True
ip-172-20-34-249...  master True
ip-172-20-65-28...   master True
ip-172-20-95-101...  node   True

Your cluster devops23.k8s.local is ready
```

That is useful. We can see that the cluster uses four instance groups or, to use AWS terms, four auto-scaling groups (ASGs). There's one for each master, and there's one for all the (worker) nodes.

The reason each master has a separate ASG lies in need to ensure that each is running in its own availability zone (AZ). That way we can guarantee that failure of the whole AZ will affect only one master. Nodes (workers), on the other hand, are not restricted to any specific AZ. AWS is free to schedule nodes in any AZ that is available.

We'll discuss ASGs in more detail later on.

Further down the output, we can see that there are four servers, three with masters, and one with worker node. All are ready.

Finally, we got the confirmation that our `cluster devops23.k8s.local is ready`.

## Installing Ingress And Tiller (Server Side Helm)

To install Ingres, please execute the commands that follow.

```bash
kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

kubectl -n kube-ingress \
    rollout status \
    deployment ingress-nginx
```

## Destroying The Cluster

The appendix is almost finished, and we do not need the cluster anymore. We want to destroy it as soon as possible. There's no good reason to keep it running when we're not using it. But, before we proceed with the destructive actions, we'll create a file that will hold all the environment variables we used in this chapter. That will help us the next time we want to recreate the cluster.

```bash
echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export ZONES=$ZONES
export NAME=$NAME" \
    >kops
```

We echoed the variables with the values into the `kops` file, and now we can delete the cluster.

```bash
kops delete cluster \
    --name $NAME \
    --yes
```

The output is as follows.

```
...
Deleted kubectl config for devops23.k8s.local

Deleted cluster: "devops23.k8s.local"
```

Kops removed references of the cluster from our `kubectl` configuration and proceeded to delete all the AWS resources it created. Our cluster is no more. We can proceed and delete the S3 bucket as well.

```bash
aws s3api delete-bucket \
    --bucket $BUCKET_NAME
```
