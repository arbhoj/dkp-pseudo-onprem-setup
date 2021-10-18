##As a convention USERID will be the current dir name
export USERID=${PWD##*/}
export CLUSTER_NAME=$USERID-dkp
echo Are you sure you want to delete the cluster? Enter cluster name $CLUSTER_NAME to confirm deletion:
read CONFIRM
if [[ $CONFIRM == $CLUSTER_NAME ]]; 
then
   echo Deleting Cluster $CLUSTER_NAME
   echo "First deleteing any services of type loadbalancer"
   ./provision/pre_delete.sh 
   terraform -chdir=provision/ destroy --auto-approve -var-file ../$USERID.tfvars
else
   echo "Skipping"
fi
