
# DKP 2.x Pseudo On Prem

The purpose of this project is to make it quick and easy to build pseudo-on-prem clusters for DKP on AWS. Although it can be used for any flavor the focus is on DKP 2.x.

Some example use cases for this project are:
- Enablement and spending more time working on 2.0 instead of installing it
- Quickly creating POC environments for a variety of use cases
- Build test cluster
- Build labs for DKP training  

## Design Considerations & Overview 

The idea was to not boil the ocean and quicky build something that fits common use cases, following the convention over configuration philosophy. As a result this deploys the following to either us-east-1 or us-west-2 and only supports deploying to one availability zone:
- A Bootstrap/Registry server with all the commonly used utilities preloaded including a docker registry that can be easily configured to simulate an air-gapped environment.
- 1 Instance for Control Plane Node
- 4 Instances for server as Worker Nodes with 10G extra storage which is formatted and mounted to /mnt/disks to demonstrate localvolumeprovisioner (this behavior might change in the future)
> Note: The Registry/Bootstrap server will always be centos. The kubernetes cluster instances are flatcar by default to provide everyone more exposure to flatcar. Currently these can be only be changed if you are deploying konvoy and kommander on your own and only using this to build the base infrastructure. The auto-deployment of konvoy and kommander is hardcoded to work only for flatcar (this will most likely change soon though as it is a simple fix but will require some more testing).  

## Pre-reqs 
1. Download the [DKP Release](https://github.com/mesosphere/konvoy2/releases) and extract the DKP binary directly under the $HOME dir on the server from where this will be run
2. Ansible 2.10.6 or greater
https://docs.ansible.com/ansible/2.9/installation_guide/intro_installation.html#installing-ansible-with-pip
3. Terraform version v0.15.4 or greater
https://www.terraform.io/downloads.html
4. AWS CLI Setup & Credentials. 
> Note: To simplify things set the region in `~/.aws/config` to match the region you will be deploying to.

## Usage

Once the pre-reqs have been satisfied clone this repository and rename the directory to the desired cluster name.
> Note: The directory name is used as the cluster name prefix.

Then run one of the following depending on the requirement:

- Build a pre-provisioned infrastraucture, ready to deploy DKP with a web hosted set of instructions. This is ideal for building training labs or to do custom builds

  Deploy to us-west-2
  ```
  ./deploy_cluster_west.sh
  ```
  Deploy to us-east-1

  ```
  ./deploy_cluster_east.sh
  ```

- Build a pre-provisioned infrastraucture and deploy konvoy on top of it. 

  Deploy to us-west-2
  ```
  ./deploy_cluster_west.sh konvoy
  ```
  Deploy to us-east-1

  ```
  ./deploy_cluster_east.sh konvoy
  ```

- Build a pre-provisioned infrastraucture and deploy konvoy & kommander on top of it.

  Deploy to us-west-2
  ```
  ./deploy_cluster_west.sh kommander
  ```
  Deploy to us-east-1

  ```
  ./deploy_cluster_east.sh kommander
  ```

- To reprint the cluster details
  ```
  ./reprint_output.sh
  ```

- Deprovision clusters

  ```
  ./delete_cluster.sh 
  ```

- To only generate ssh keys and tfvars file. In case you want to customize input variables before triggering the build.

  ```
  ./init_only.sh
  ```

That's pretty much it!! If you were looking for that `BIG EASY RED BUTTON` for DKP 2, this is it. Cheers!! 
