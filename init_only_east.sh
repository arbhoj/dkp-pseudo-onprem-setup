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
worker_node_count = 4
aws_region = "us-west-2"
aws_availability_zones = ["us-east-1c"]
node_ami = "ami-048e383eb95db98c4"
registry_ami = "ami-00e87074e52e6c9f9"
ansible_python_interpreter = "/opt/bin/python"
ssh_username = "core"
node_os = "flatcar"
deploy_mayastor = false
konvoy_image_builder_version = "v1.0.0"
kommander_version = "v2.0.0"
dkp_version = "v2.0.0"
create_iam_instance_profile = true
cluster_name = "$CLUSTER_NAME"
ssh_private_key_file = "../$CLUSTER_NAME"
ssh_public_key_file = "../$CLUSTER_NAME.pub"
create_extra_worker_volumes = true
extra_volume_size = 10
EOF
fi

terraform -chdir=provision init
