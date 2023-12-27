resource "local_file" "dkp_2_install_md" {
  filename = "labs/docs/dkp_2_install.md"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 644 labs/docs/dkp_2_install.md"
  }
  content = <<EOT
# DKP Enablement - Pre-Provisioned ${var.cluster_name}

The goal of this module is to provide a self paced, hands on enablement experience on DKP (D2iQ Kubernetes Platform) by walking through the process of building a fully functional DKP cluster from scratch using the pre-provisioned CAPI (Cluster API) provider and form a solid foundation on not just DKP but also Cluster API.

Let's begin by reviewing the environment details and connecting to the bootstrap/jump server using the connection details below. The required nodes and a Control Plane load-balancer have already been provisioned for lab exercises.
> Note: Only the bootstrap/jumpbox node has a public IP and it already has all the required CLIs installed.

## Cluster Details

Bootstrap Node:
```
${aws_instance.registry[0].public_ip}
```

Control Plane Nodes:

```
%{ for index, cp in aws_instance.control_plane ~}
${cp.private_ip}
%{ endfor ~}
```

Worker Nodes:
```
%{ for index, wk in aws_instance.worker ~}
${wk.private_ip}
%{ endfor ~}
```

Control Plane LoadBalancer:
```
${aws_elb.konvoy_control_plane.dns_name} 
```

ssh-key:
```
${trimprefix(var.ssh_private_key_file, "../")}
```

## Connection Details
Connect to the bootstrap server as all the lab exercises will be run from there.

```
echo "${data.local_file.key_file.content}" > ${trimprefix(var.ssh_private_key_file, "../")}

chmod 600 ${trimprefix(var.ssh_private_key_file, "../")}

ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")}
```

Once on the bootstrap server run the following command to check things are working correctly
```
dkp version
```

## Setup Instructions and Guide 
Follow the steps below to build a DKP Management Cluster in a [pre-provisioned](https://docs.d2iq.com/dkp/2.6/what-is-pre-provisioned) environment.
Since DKP uses Cluster API (CAPI) to manage the lifecycle of Kubernetes clusters across all infrastructure, please watch the `What is CAPI` and `Why use CAPI` sections of ths [Intro to Kubernetes Cluster API](https://www.youtube.com/watch?v=U3ta48nmm4Y) video. We will be using other portions of this video as we step through this lab so only watch those sections for now.

> Note: This is the only CAPI provisioner where the actual node lifecycle is not managed by CAPI. It only manages the lifecycle of a kubernetes cluster on top of pre-provisioned nodes. Hence the name Cluster API Pre-provisioned.  

### Step 1: Create Bootstrap Cluster

Cluster API requires a CAPI enabled kubernetes cluster to exist for running its components that will build other kubernetes clusters. This is known as the Management Cluster in CAPI terminology. What this means is that we need a working kubernetes cluster before we can start building clusters with CAPI. So what do we do as this is a chicken and egg situation? We build a single node kubernetes cluster with all the CAPI components deployed in a Docker instance (aka KIND - Kubernetes IN Docker) running on a server that can reach whatever provider/target we need connectivity to. This is known as the Bootstrap CAPI cluster. This is a temporary cluster and once the real Management cluster (or Self Managed Cluster - i.e. kubernetes cluster running it's own CAPI resources) is spun up, all the CAPI resources are migrated to it and the bootstrap cluster is deleted. 

Run the following command to build a CAPI enabled bootstrap bootstrap cluster

```
dkp create bootstrap
```

While the CAPI enabled bootstrap cluster is being deployed, start watching the `CAPI Components` section of the [Intro to Kubernetes Cluster API](https://www.youtube.com/watch?v=U3ta48nmm4Y) video. 

Use the following documentation link for additional details on the bootstrap cluster and to get acquainted with DKP documentation. 
<https://docs.d2iq.com/dkp/2.6/pre-provisioned-bootstrap-cluster>

Once the bootstrap cluster is deployed, observe how it runs a single container inside the local docker instance on the bootstrap/jumpbox node
```
docker ps | grep boot
```
The kubeconfig of the kubernetes cluster is stored in `~/.kube/config` (i.e. the default kubeconfig location)

Explore the resources in the bootstrap cluster using the following commands and try to corelate the information in the video and what you see in this cluster. This bootstrap cluster is the temporary CAPI Management cluster used to build the first management cluster.

```
kubectl get no # To see that a single node KIND (Kubernetes IN Docker) cluster was deployed

kubectl get po -A # Note the core CAPI and infrastructure specific pods. capa is for AWS, capz if for azure, capg is for google cloud, capv is for VMware vSphere, capvcd is for VMware VCD and lastly cappp (the provider we are using in this lab) is for pre-provisioned infrastructure

kubectl get crd | grep cluster # Take a note of the various CRDs created for generic capi components like kubeadm and machine/machinedeployments and infrastructure specific CRDs like awsmachines, azuremachines etc.

kubectl get crd | grep pre # Review CRDs specific to the provisioner being used in this lab

```


### Step 2: Define Infrastructure

Since this is a pre-provisioned environment, we begin by defining the node pools (control plane and worker node pools) with the respective ip addresses and connection details for the nodes in these pools. The output of this step is a `preprovisioned_inventory.yaml` file which is passed as an input to the `--pre-provisioned-inventory-file` flag in the cluster build command, which is the next step.

First define the cluster name, node IPs, ssh user and ssh key secret name by setting environment variables as shown below.
> Feel free to change the cluster name to something else.

```
export CLUSTER_NAME=${var.cluster_name}
%{ for index, cp in aws_instance.control_plane ~}
export CONTROL_PLANE_${index}_ADDRESS=${cp.private_ip}
%{ endfor ~}
%{ for index, wk in aws_instance.worker ~}
export WORKER_${index}_ADDRESS=${wk.private_ip}
%{ endfor ~}
export SSH_USER=${var.ssh_username}
export SSH_PRIVATE_KEY_SECRET_NAME="$CLUSTER_NAME-ssh-key"
```

As a best practice, verify that the variables have been set correctly

```
echo CLUSTER_NAME=$CLUSTER_NAME &&
%{ for index, cp in aws_instance.control_plane ~}
echo CONTROL_PLANE_${index}_ADDRESS=$CONTROL_PLANE_${index}_ADDRESS &&
%{ endfor ~}
%{ for index, wk in aws_instance.worker ~}
echo WORKER_${index}_ADDRESS=$WORKER_${index}_ADDRESS &&
%{ endfor ~}
echo SSH_USER=$SSH_USER &&
echo SSH_PRIVATE_KEY_SECRET_NAME=$SSH_PRIVATE_KEY_SECRET_NAME

```


Now run the following to generate the preprovisioned_inventory.yaml file to define the inventory (similar to ansible inventory) for control plane and for worker nodes
> Note: Use the following document link as reference and note the changes made to modify the default number of nodes in each inventory.
> <https://docs.d2iq.com/dkp/2.6/pre-prov-define-infrastructure>

```
cat <<EOF > preprovisioned_inventory.yaml
---
apiVersion: infrastructure.cluster.konvoy.d2iq.io/v1alpha1
kind: PreprovisionedInventory
metadata:
  name: $CLUSTER_NAME-control-plane
  namespace: default
  labels:
    cluster.x-k8s.io/cluster-name: $CLUSTER_NAME
    clusterctl.cluster.x-k8s.io/move: ""
spec:
  hosts:
    # Create as many of these as needed to match your infrastructure
    # Note that the command line parameter --control-plane-replicas determines how many control plane nodes will actually be used.
    #
    - address: $CONTROL_PLANE_0_ADDRESS
  sshConfig:
    port: 22
    # This is the username used to connect to your infrastructure. This user must be root or
    # have the ability to use sudo without a password
    user: $SSH_USER
    privateKeyRef:
      # This is the name of the secret you created in the previous step. It must exist in the same
      # namespace as this inventory object.
      name: $SSH_PRIVATE_KEY_SECRET_NAME
      namespace: default
---
apiVersion: infrastructure.cluster.konvoy.d2iq.io/v1alpha1
kind: PreprovisionedInventory
metadata:
  name: $CLUSTER_NAME-md-0
  namespace: default
  labels:
    cluster.x-k8s.io/cluster-name: $CLUSTER_NAME
    clusterctl.cluster.x-k8s.io/move: ""
spec:
  hosts:
    - address: $WORKER_0_ADDRESS
    - address: $WORKER_1_ADDRESS
    - address: $WORKER_2_ADDRESS
    - address: $WORKER_3_ADDRESS
  sshConfig:
    port: 22
    user: $SSH_USER
    privateKeyRef:
      name: $SSH_PRIVATE_KEY_SECRET_NAME
      namespace: default
EOF
```

### Step 3: Create DKP Base Kubernetes Cluster

For this step, run the following command to build the manifests of the cluster and then apply it to the bootstrap cluster in order to trigger the build. Note the use of flags like `--control-plane-replicas` and `--worker-node-replicas`. The default values for these is 3 and 4 respectively.

> Note: As demonstrated in the following command, it is best practice to generate the resource manifest first using the `--dry-run -o yaml` flags and then deploy it to the cluster using `kubectl create -f`  

```
dkp create cluster preprovisioned --cluster-name $${CLUSTER_NAME} --control-plane-endpoint-host ${aws_elb.konvoy_control_plane.dns_name} --control-plane-replicas 1 --worker-replicas 4 --pre-provisioned-inventory-file preprovisioned_inventory.yaml --ssh-private-key-file ${var.cluster_name} --dry-run -o yaml > deploy-$${CLUSTER_NAME}.yaml

```

> Note:
> - Since this is a lab setup, only a single node has been provisioned for control plane but a load-balancer has been provisioned to demonstrate that capability. So, either use the control-plane ip or the load-balancer dns name ${aws_elb.konvoy_control_plane.dns_name} as a value for the `--control-plane-endpoint-host` flag. Please read [this](https://docs.d2iq.com/dkp/2.6/pre-provisioned-define-control-plane-endpoint-1) for more details.
> - In many on-prem environments including vSphere based environments where no external load-balancer (e.g. F5) is present, kube-vip is used to serve as the load-balancer for the control plane. Please read [this](https://docs.d2iq.com/dkp/2.6/pre-provisioned-built-in-virtual-ip) for more details on kube-vip.

> For more details reference the following documentation link and also try running `dkp create cluster preprovisioned -h` to see other flags supported by this command
><https://docs.d2iq.com/dkp/2.6/pre-provisioned-create-a-new-cluster>
> Note that the above documentation link also uses `--self-managed` flag in the `dkp create cluster preprovisioned` command example. This flag automatically deploys capi-components to the new cluster and then moves all the cluster specific capi resources to the new cluster to make it `Self Managed` (i.e. the cluster will host its own CAPI resources and manage itself)




This will create the following:
- A secret named `$CLUSTER_NAME-ssh-key` containing the private ssh key passed via the `--ssh-private-key-file` flag (Note: The corresponding public key is already added to the pre-provisioned nodes as a part of this lab prep)
- The `preprovisionedinventory` resources as defined in the `preprovisioned_inventory.yaml` file created in the last step
- The `deploy-$${CLUSTER_NAME}.yaml` file containing all the resource manifests for building the cluster.

Now take time to carefully review the contents of deploy-$${CLUSTER_NAME}.yaml, as a good understanding of the various resources and parameters defined in this file are really important to understand how CAPI works. watch the `Custom resources` section of [this](https://www.youtube.com/watch?v=U3ta48nmm4Y) video to get a better understanding the role each resource plays in defining and building the cluster.

Finally build the cluster by deploying the generated cluster specific CAPI resource manifests to the Bootstrap cluster like this:
> Note: Some resources like machines and preprovisioned machines will be created dynamically when the build is triggered by running the following command.

```
kubectl create -f deploy-$${CLUSTER_NAME}.yaml
```

### Step 4: Observe the Cluster getting deployed

> There is no particular order in which these commands should be run. They are used to observe the status of a CAPI based cluster build and follow the same pattern for all infrastructures (Except the kib job which is only run automatically as a part of the pre-provisioned cluster build. For all other infrastructures it has to be run manually as a pre-task to build CAPI enabled base images/AMIs. Click [here](https://docs.d2iq.com/dkp/2.6/konvoy-image-builder-cli) to learn more about KiB) 
Once the cluster deployment has been triggered observe the different components in the bootstrap cluster (i.e. the temp Management cluster). 

#### - Cluster Deployment Status

Run the following command to view the Cluster Deployment Status

```
dkp describe cluster -c $${CLUSTER_NAME}
```

The output looks something like this
```
NAME                                                               READY  SEVERITY  REASON                           SINCE  MESSAGE                                                      
Cluster/dkp-lab-01-dkp                                             False  Warning   ScalingUp                        14s    Scaling up control plane to 1 replicas (actual 0)            
├─ClusterInfrastructure - PreprovisionedCluster/dkp-lab-01-dkp                                                                                                                           
├─ControlPlane - KubeadmControlPlane/dkp-lab-01-dkp-control-plane  False  Warning   ScalingUp                        14s    Scaling up control plane to 1 replicas (actual 0)            
│ └─Machine/dkp-lab-01-dkp-control-plane-fvvsq                     False  Info      KIBRunning                       11s    1 of 2 completed                                             
└─Workers                                                                                                                                                                                
  └─MachineDeployment/dkp-lab-01-dkp-md-0                          False  Warning   WaitingForAvailableMachines      15s    Minimum availability requires 3 replicas, current 0 available
    ├─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-478bb           False  Info      WaitingForControlPlaneAvailable  14s    0 of 2 completed                                             
    ├─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-ldmdk           False  Info      WaitingForControlPlaneAvailable  13s    0 of 2 completed                                             
    ├─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-qphzv           False  Info      WaitingForControlPlaneAvailable  13s    0 of 2 completed                                             
    └─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-r99f7           False  Info      WaitingForControlPlaneAvailable  14s    0 of 2 completed 
```

As shown in the sample output above, this command shows the overall cluster build progress and it is good to keep an eye on it. So open a new Terminal window; ssh to the bootstrap server using ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")}; run the last command prefixed with `watch` and move the window to one side of the terminal to keep watching the updates.

```
watch dkp describe cluster -c $${CLUSTER_NAME}
```
> Note:
> A CAPI based cluster build follows the standard kubernetes build sequence, where:
> - The first control plane is built first
> - Once the first control plane is ready, the second control plane and all worker node builds are triggered
> - After the second control plane is ready, the third control plane is triggered an so on (Control Planes are always built serially) 

#### - [KiB](https://docs.d2iq.com/dkp/2.6/konvoy-image-builder-cli) Job logs

For pre-provisioned clusters KiB (Konvoy Image Builder) jobs (one for each node, starting with the first ControlPlane node defined in the preprovisionedinventory resource ) run automatically for each node as a part of the CAPI process as it is a pre-requisite for CAPI to initialize and join clusters using `kubeadm`. So, as soon a pre-provisioned cluster build is triggered, it will almost immediately create a kubernetes job that will run KiB against the first control plane node. The logs of the job can be viewed like any other kubernetes job. 

```
kubectl logs -f job/<job-name>
```

Look for any errors and ensure that the job completes successfully. If it fails, troubleshoot and fix the error(s). 

The KiB jobs for the rest of the nodes defined in the preprovisionedinventory resource will be triggered in the build sequence defined in the last section.

At a high level, the KiB job runs an ansible playbook to deploy all the required artifacts to the target nodes and prepares them to join a kubernetes cluster via the CAPI process. We call this making the nodes/images/amis CAPI compatible for a particular DKP/kubernetes version. It does things like deploying and configuring binaries for containerd, kubelet, kubeadm etc. 

Once a KiB job has been run successfully against a node, it is ready to join a kubernetes cluster via CAPI which uses `kubeadm` to bootstrap a node.      

> Note: For non pre-provisioned environments where the lifecyle of the nodes is also managed by CAPI, the KiB process is has to be triggered manually and it uses `packer` to create a reusable base image/ami for a specific DKP version. Thus the KiB version is unique for every DKP version. Click [this](https://docs.d2iq.com/dkp/2.6/konvoy-image-builder) link to learn more about KiB; view the compatibility for DKP versions; and get the download link for each version. We will cover KiB in more detail in it's own enablement lab.  


#### - Logs of the different CAPI controllers

CAPI controllers (like most kubernetes controllers) run a control loop. i.e. Unlike a traditional automation tool that runs from start to finish and stops, these controllers continuously watch the desired state specified in it's corresponding Resource's `spec` and attempt to match the real `state` to match that spec. So if an error occurs they will retry after some time. Giving, admins the opportunity to view the error in the logs and apply the remediation without re-triggering the automation in most cases.   

As covered in the `CAPI components` section of the [Intro to Kubernetes Cluster API](https://www.youtube.com/watch?v=U3ta48nmm4Y) video, CAPI has various controllers. Some of these are generic and some are specific to the environment/provider being used. For pre-provisioned clusters the environment specific controller is `cappp-controller-manager`, which runs as a deployment in the `cappp-system` namespace.
Unlike dynamic infrastructure providers that also provision VMs/instances, this provider uses a list of pre-provisioned nodes defined in the `preprovisionedinventory` resources (discussed in detail in previous sections) and processes preprovisionedmachine resources out of that list. 

To view the logs of this controller run the following command

```
kubectl logs -f -n cappp-system deploy/cappp-controller-manager
```

Observe the logs to understand what is going on and look for any errors and fix accordingly. 

Similarly, also observe the logs of the following generic (non provider/environment specific) CAPI controller manager deployments:
- `capi-controller-manager`  in the `capi-system` namespace - This is the core capi controller. 
- `capi-kubeadm-control-plane-controller-manager` in the `capi-kubeadm-control-plane-system` namespace - The controller that watches and acts on the `KubeadmControlPlane` resources and manages the kubernetes Control Plane.
- `capi-kubeadm-bootstrap-controller-manager` in the `capi-kubeadm-bootstrap-system` namespace - The controller that is responsible for generating the `kubeadmconfig` resource for each machine/node. 

#### - Other Dynamically created Resources
As mentioned in earlier sections, some of the resources are dynamically created by the CAPI cluster creation process. 
Some of the important ones to note are:
- MachineSet
- Machine
- <Provider>Machine (i.e. PreprovisionedMachine)

Try to map the relationship of these resources to the other resources defined in the `Custom Resources` section of the [Intro to Kubernetes Cluster API](https://www.youtube.com/watch?v=U3ta48nmm4Y) video. 

### Step 5: Confirm cluster has been build successfully
The `dkp describe cluster -c $${CLUSTER_NAME}` command will return something like this when the cluster has been built successfully
```
NAME                                                               READY  SEVERITY  REASON  SINCE  MESSAGE
Cluster/dkp-lab-01-dkp                                             True                     5h24m         
├─ClusterInfrastructure - PreprovisionedCluster/dkp-lab-01-dkp                                            
├─ControlPlane - KubeadmControlPlane/dkp-lab-01-dkp-control-plane  True                     5h24m         
│ └─Machine/dkp-lab-01-dkp-control-plane-fvvsq                     True                     5h24m         
└─Workers                                                                                                 
  └─MachineDeployment/dkp-lab-01-dkp-md-0                          True                     5h20m         
    ├─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-478bb           True                     5h20m         
    ├─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-ldmdk           True                     5h20m         
    ├─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-qphzv           True                     5h20m         
    └─Machine/dkp-lab-01-dkp-md-0-68449b46d7x8cq8b-r99f7           True                     5h20m   
```
If the cluster is not ready after 15-20 minutes have passed since the build was triggered, look at the logs and the resources described in the previous sections to figure out what is going on and if something has failed. 

### Step 6: Get cluster's kubeconfig and Connect to deployed cluster
Get cluster's kubeconfig; set that as the current config; and verify connectivity via kubectl

```
dkp get kubeconfig -c $${CLUSTER_NAME} > $${CLUSTER_NAME}.conf

export KUBECONFIG=$(pwd)/$${CLUSTER_NAME}.conf

kubectl get no
```
Open the kubeconfig file and observe its contents

### Step 7: Configure MetalLB

> Note: Metallb in Layer2 mode works well for non-prod environments but for any environment running serious workload we highly recommend using an external load-balancer like F5. Here is the [link to a blog post](https://eng.d2iq.com/blog/auto-provisioning-kubernetes-loadbalancer-services-with-f5/) to automate provisioning of VIPs in F5 when a service of type LoadBalancer is created in a kubernetes cluster.  

In on-prem environments where there is no cloud or external load-balancer (like F5), MetalLB is used to provision a kubernetes service of type LoadBalancer. It is deployed automatically for a pre-provisioned CAPI cluster via ClusterResourceSets but not configured (look at metallb ClusterResourceSet in deploy-$${CLUSTER_NAME}.yaml file for more details)
The simplest way to configure MetalLB is in layer2 mode shown below. The other option is BGP mode but that is an advanced topic and out of scope for this lab. Please read the [MetalLB documentation](https://metallb.universe.tf/concepts) for more details. 
Apply this to the newly created cluster (Note: Alternatively, this could have been bundled in the metallb Configmap which is at the bottom of the deploy-$${CLUSTER_NAME}.yaml file and baked into the deployment). 

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
%{ for index, wk in aws_instance.worker ~}
      - ${wk.private_ip}/32
%{ endfor ~}
EOF
```

> Note: Since this is a lab and these IPs are routable, we have reused worker node IPs as the IPs to provision a kubernetes service of type LoadBalancer. In a real deployment, these will have to be unique IPs in the same subnet as the worker nodes. Please read [MetalLB documentation](https://metallb.universe.tf/concepts/layer2/) for more details on limitations of this approach.  

Validate this by creating a service of type LoadBalancer and curling it from within the bootstrap cluster
```
kubectl run test --image nginx:alpine
kubectl expose po/test --type LoadBalancer --port 80
```
Ensure that the `EXTERNAL-IP` field of the service is provisioned with an IP from the list provided in the metallb configmap just deployed to the cluster.

```
kubectl get svc 
```
The output should be something like
```
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
kubernetes   ClusterIP      10.96.0.1       <none>         443/TCP        6h23m
test         LoadBalancer   10.104.213.54   ${aws_instance.worker[0].private_ip}   80:31607/TCP   6s
```

Now grab the `External-IP` of the test service just created and do a curl to see if that works. 
```
curl ${aws_instance.worker[0].private_ip} 
```

Cleanup as IPs are precious resources
```
kubectl delete po,svc test --force
```

### Step 8: Validate PersistentVolumes 
The default csi for a pre-provisioned cluster is localvolumeprovisioner. View the localvolumeprovisioner ClusterResourceSet in the deploy-$${CLUSTER_NAME}.yaml file for more details on how this component is deployed to the new cluster. It is a static provisioner and requires disks to be mounted to `/mnt/disks` on the worker nodes to serve them as `PersistentVolumes` in the kubernetes cluster.  

The disks have been pre-carved and mounted for this lab using the `best practice` of `naming the the mounts in an ascending order proportional to the size of the disk`. e.g. 10000nnn - Small (11G) 11000nnn - Medium (35G) 11100nnn - Large (105G). This is a simple logic to prevent a very small kubernetes PersistentVolumeClaim from binding to a large kubernetes PersistentVolume. This is because when a PersitentVolumeClaim is created, `localvolumeprovisioner` looks for a suitable disk (i.e. >= the size requested) starting from a free mount that comes first in the ascending order sorted by the name of the mount. The script in this [git repo](https://github.com/arbhoj/LVP-ConfigureDisks) was used to configure this. 

Run the following command to ensure localvolumeprovisioner is the default storageclass
```
kubectl get sc
```
Output should be like this
```
NAME                               PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
localvolumeprovisioner (default)   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  6h54m
```
Run the following command to ensure PersistentVolumes were created correctly 
```
kubectl get pv
```
Output should be something like this
```
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS             REASON   AGE
local-pv-13432a1    10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-178e5d32   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-18fe56a2   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-1e306c7a   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-23b0069b   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-25f0dd77   102Gi      RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-27adc0a5   102Gi      RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-2b8a5be3   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-2ec3c2d7   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-2f5410dd   102Gi      RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-3339f4dc   102Gi      RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-4766dd21   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-488c0188   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-49b0fc4b   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-747ecf20   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-75fbf9c8   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-7d24346b   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-9827d507   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-a429ed00   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-b23ef8f0   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-b8fa24f9   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-caf05cc4   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-d338663e   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-d890889c   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-ddd1ab09   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-e82cca39   10Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-f263afa9   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
local-pv-f73f3db6   34Gi       RWO            Delete           Available           localvolumeprovisioner            6h52m
```
### Step 9: Deploy CAPI Components
In this step we deploy CAPI components to the newly created cluster. It is important to do this now because it also deploys Cert-Manager (One of the pre-requisites for the Kommander component that will be deployed later)

Run the following command to deploy CAPI Components. 
> Note: This is a subset of the `dkp create bootstrap` command and only deploys the components to an existing kubernetes cluster instead of building a new KIND cluster. 
```
dkp create capi-components 
```

### Step 10: (Optional) Move the CAPI Resources
Optionally move the CAPI resources (cluster, kubeadmcontrolplane, machinedeployments, clusterresourcesets etc.) from the bootstrap cluster to the new cluster. This makes the new cluster Self Managed.

Run the following command to move CAPI resources from one kubernetes cluster to another
>Note: This can be re-run to move the resources back from the new cluster to the bootstrap cluster or another CAPI cluster running same version of CAPI components. Run `dkp move capi-resources -h` to explore other flags for this command.  
```
dkp move capi-resources --from-kubeconfig ~/.kube/config --to-kubeconfig $${CLUSTER_NAME}.conf
```
### Step 11: Deploy Kommander
Once all steps upto `Step 9` have been completed, we are ready to deploy Kommander, the DKP component that installs and configures `Addons` (like logging, monitoring etc.) and `Management` capabilities on top of the DKP base kubernetes cluster.

#### - Generate Kommander config file
The kommander config file contains the options to customize the installation to:
- Enable/Disable addons
- Customize the values passed to configure the addons (This translates to the values.yaml overrides for the helm chart deploying the addon); and
- To change other kommander configurations like enable airgapped mode; set custom domain name and certs etc.   

Refer to [this documentation link](https://docs.d2iq.com/dkp/2.6/dkp-install-configuration) for more details and examples on Kommander customizations.  

Run the following command to generate the kommander customization file with default settings (i.e. settings that will be applied if the kommander installation was done without using the `--installer-config` flag). 
```
dkp install kommander --init > kommander-config.yaml
```

This contents of the `kommander-config.yaml` generated by the last command will look like this
```
apiVersion: config.kommander.mesosphere.io/v1alpha1
kind: Installation
apps:
  ai-navigator-app:
    enabled: true
  dex:
    enabled: true
  dex-k8s-authenticator:
    enabled: true
  dkp-insights-management:
    enabled: true
  gatekeeper:
    enabled: true
  gitea:
    enabled: true
  grafana-logging:
    enabled: true
  grafana-loki:
    enabled: true
  kommander:
    enabled: true
  kommander-ui:
    enabled: true
  kube-prometheus-stack:
    enabled: true
  kubefed:
    enabled: true
  kubernetes-dashboard:
    enabled: true
  kubetunnel:
    enabled: true
  logging-operator:
    enabled: true
  prometheus-adapter:
    enabled: true
  reloader:
    enabled: true
  rook-ceph:
    enabled: true
  rook-ceph-cluster:
    enabled: true
  traefik:
    enabled: true
  traefik-forward-auth-mgmt:
    enabled: true
  velero:
    enabled: true
ageEncryptionSecretName: sops-age
clusterHostname: ""
```

Notice all the addons that are enabled by default. It's these addons and their integration with each other that make the DKP cluster production ready.

Now, since we are deploying to a pre-provisioned environment using `localvolumeprovisioner` (that can't do dynamic volume provisioning), one of the things we will have to change is the `rook-ceph-cluster` install config as by default it need's a dynamic volume provisioner (such as aws-ebs-csi) to provision block storage for it's OSDs. To do this, update the `rook-ceph-cluster` section in `kommander-config.yaml` to look like this:
```
  rook-ceph-cluster:
      enabled: true
      values: |
        cephClusterSpec:
          storage:
            storageClassDeviceSets: []
            useAllDevices: true
            useAllNodes: true
``` 
> Note: The above means any raw device on any node will be added to the rook-ceph-cluster. There is optionally a `deviceFilter` field that can be used to limit the devices that can be added to the cluster. Read the documentation in [this link](https://docs.d2iq.com/dkp/2.6/pre-provisioned-install-kommander) for more details.


With the changes saved to the `kommander-config.yaml` file let's move to the next section to install kommander.

#### - Run the kommander install command
Now run the kommander install command passing the `kommander-config.yaml` config file to the `--installer-config` flag
```
dkp install kommander --installer-config kommander-config.yaml
```

This can take upto 20 minutes to install

#### - Observe Flux & Other Resources getting deployed
While the kommander install command is running, open another terminal window; SSH to the bootstrap node 
```
ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")}
```
Set the `$${CLUSTER_NAME}` environment variable to the cluster that is being built; and set the `KUBECONFIG` environment variable to point to the this cluster
```
export KUBECONFIG=$(pwd)/$${CLUSTER_NAME}.conf
``` 

Now run the following commands to watch the components getting deployed. These can be used to troubleshoot an install if something goes wrong. 

> Note: It might take a few for them to show up, so if a particular command returns a not found error, try again after a few.
```
kubectl get ns # Watch for new namespaces getting created
kubectl get po -A | grep git # Watch for the gitea pod getting deployed # This is the pod serving the internal git repository that Kommander leverages to deploy payload to all the clusters.
kubectl get po -n kommander-flux # The Flux namespace and it's corresponding PODs
kubectl get apps -A # List of application resources defined in Kommander
kubectl get appdeployments # List of instances of the Kommander applications that the kommander application controller should deploy
kubectl get gitrepo -A # List the Kommander git repo that contains the payload to be deployed for the. This references the locally (gitea) hosted git repo
kubectl get ks -A # List all the Flux Kustomization resources 
kubectl get helmrepo -A # List of all the Kommander helm repos
kubectl get hr -A # List all the Flux HelmRelease resources. Typically you would watch the output of this command to closely watch the progress of kommander install and to watch for any errors in case a dependency was not met. 
```
> As evident from the list of commands above, the kommander installation is broken in two parts: 
> - The first part deploys a git repository (using gitea) and bootstraps Flux CD; and 
> - The second part deploys the resources defined in the git repository using Flux CD
> Both Cluster API and Flux CD are core components of DKP 

#### - Accessing the DKP Dashboard
Once the kommander installation completes, run the following command to get the url and the admin credentials to access the kommander dashboard
```
dkp open dashboard
```
The output of the above command will look something like this:
```
Username: pensive_jemison
Password: hfdZ2K0uSyanIwScBSP7KSaVpvnv4wd7pr0tgEVH3DCdAevCcsC4N4nydGUMTad3
URL: https://10.0.241.128/dkp/kommander/dashboard

exec: "xdg-open": executable file not found in $PATH
```

Since the only Public IP in this setup, is the bootstrap server's IP. We need to tunnel to it in order to access the dkp dashboard url directly from the web browser.   

For Mac users, use sshuttle as shown below to tunnel to the bootstrap node and then access the dkp dashboard from the web browser.

> Note: Run the following locally on the Mac and not on the bootstrap node.
```
# Install
pip3 install sshuttle

# Connect
eval `ssh-agent`
ssh-add ${trimprefix(var.ssh_private_key_file, "../")} 
sudo sshuttle -r  centos@${aws_instance.registry[0].public_ip} 10.0.0.0/16 # Note: Change the subnet if needed to match the subnet of private IPs being connected to 
```

For Windows users, use ssh dynamic port forwarding (SOCKS proxy) with a tool like MobaXterm as shown below.
![mobaxterm_tunnel](./images/mobaxterm_tunnel.png)
Then from firefox setup a `SOCKS5 v5`proxy as shown below and finally access the DKP dashboard link
![firefox_proxy](./images/firefox_proxy5_settings.png)

Here is what the DKP dashboard should look like after logging in.
![DKP_Dashboard](./images/DKP_Dashboard.png)

### Step 12: Explore Kommander 
Now take a moment to open all the application dahboards that are deployed and configured by default. Specifically `Grafana`, which has many rich dashboard configured out of the box.
> Note: Without a license the dashboard has all it's fleet management features disabled. 

These can be accessed by clicking on the `Cluster` nav-bar item as shown below.
![Dashboards](./images/dashboards.png)

Well, that's it for this module. We started from scratch and built a fully functional production ready cluster in this session. In the next module we will focus on DKP Enterprise and more Fleet Management Capabilities.

EOT
}
