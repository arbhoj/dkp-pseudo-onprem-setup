##As a convention USERID will be the current dir name
export USERID=${PWD##*/}

export CLUSTER_NAME=$USERID-dka100

terraform -chdir=provision init

terraform -chdir=provision apply -auto-approve -var-file ../$USERID.tfvars
if [ $? -eq 0 ]; then
./provision/post_setup.sh $1
else
  echo "!!!Something went wrong with the provisioning process. Please fix that and retry!!!"
fi
