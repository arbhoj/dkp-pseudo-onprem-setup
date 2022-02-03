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
worker_node_count = 2
aws_region = "us-west-2"
aws_availability_zones = ["us-west-2c"]
node_os = "flatcar"
deploy_mayastor = false
#konvoy_image_builder_version = "v1.3.1"
kommander_version = "v2.1.1"
dkp_version = "v2.1.1"
##Flatcar-stable-3033.2.0-hvm-1716ad1c-deff-42e5-86bc-228658463d0e 
node_ami = "ami-0b701de195dd6374d"
registry_ami = "ami-0686851c4e7b1a8e1"
ansible_python_interpreter = "/opt/bin/python"
ssh_username = "core"
create_iam_instance_profile = true
cluster_name = "$CLUSTER_NAME"
ssh_private_key_file = "../$CLUSTER_NAME"
ssh_public_key_file = "../$CLUSTER_NAME.pub"
create_extra_worker_volumes = true
extra_volume_size = 10
EOF
fi

terraform -chdir=provision init

terraform -chdir=provision apply -auto-approve -var-file ../$USERID.tfvars
if [ $? -eq 0 ]; then
./provision/post_setup.sh $1
else
  echo "!!!Something went wrong with the provisioning process. Please fix that and retry!!!"
fi
