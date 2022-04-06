##As a convention USERID will be the current dir name
export USERID=${PWD##*/}

export CLUSTER_NAME=$USERID-dkp
if test -f "$CLUSTER_NAME"; then
    echo "$CLUSTER_NAME key already exists. Skipping..."
else
    echo "Generating key pair $CLUSTER_NAME and $CLUSTER_NAME.pub"
##Generate ssh keys for the cluster
ssh-keygen -q -t rsa -N '' -f $CLUSTER_NAME <<<y 2>&1 >/dev/null
cp $CLUSTER_NAME provision/$CLUSTER_NAME
fi

if test -f "$USERID.tfvars"; then
    echo "$USERID.tfvars already exists. Skipping..."
else
    echo "Generating $USERID.tfvars"
##Generate tfvars file
cat <<EOF > $USERID.tfvars
tags = {
  "owner" : "$USER",
  "expiration" : "32h"
}
control_plane_count = 3
worker_node_count = 4
aws_region = "us-west-2"
aws_availability_zones = ["us-west-2c"]
node_ami = "ami-0686851c4e7b1a8e1"
registry_ami = "ami-0686851c4e7b1a8e1"
#For Flatcar# ansible_python_interpreter = "/opt/bin/python"
#For RHEL# /usr/libexec/platform-python
ssh_username = "centos"
node_os = "centos"
deploy_mayastor = false
dkp_version = "v2.2.0-rc.9"
create_iam_instance_profile = true
cluster_name = "$CLUSTER_NAME"
ssh_private_key_file = "../$CLUSTER_NAME"
ssh_public_key_file = "../$CLUSTER_NAME.pub"
create_extra_worker_volumes = true
extra_volume_size = 250
EOF
fi

terraform -chdir=provision init
