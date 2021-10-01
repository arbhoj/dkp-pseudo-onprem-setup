resource "local_file" "dkp_2_install_txt" {
  filename = "dkp_2_install.txt"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 644 dkp_2_install.txt"
  }
  content = <<EOF
###Build Server######
###Run the following from the konvoy-image builder dir https://github.com/mesosphere/konvoy-image-builder
cd /home/centos/konvoy-image-builder
./konvoy-image provision --inventory-file /home/centos/provision/inventory.yaml  images/generic/flatcar.yaml #Select a yaml depending on the operating system of the cluster

#####################

###Deploy DKP Cluster#####
###Run these from the directory where DKP binary has been downloaded
cd /home/centos
#First create a bootstrap cluster
./dkp create bootstrap

#Once bootstrap cluster is created add the secret containing the private key to connect to the hosts
kubectl create secret generic ${var.cluster_name}-ssh-key --from-file=ssh-privatekey=/home/centos/${trimprefix(var.ssh_private_key_file, "../")}

#Create the pre-provisioned inventory resources
kubectl apply -f /home/centos/provision/${var.cluster_name}-preprovisioned_inventory.yaml

#Create the manifest files for deploying the konvoy to the cluster
#Note if deploying a flatcar cluster then add the --os-hint=flatcar flag like this:
./dkp create cluster preprovisioned --cluster-name ${var.cluster_name} --control-plane-endpoint-host ${aws_elb.konvoy_control_plane.dns_name} --os-hint=flatcar --control-plane-replicas 1 --worker-replicas 4 --dry-run -o yaml > deploy-dkp-${var.cluster_name}.yaml

##Update all occurances of cloud-provider="" to cloud-provider=aws
sed -i 's/cloud-provider\:\ \"\"/cloud-provider\:\ \"aws\"/' deploy-dkp-${var.cluster_name}.yaml
sed -i 's/konvoy.d2iq.io\/csi\:\ local-volume-provisioner/konvoy.d2iq.io\/csi\:\ aws-ebs/' deploy-dkp-${var.cluster_name}.yaml
sed -i 's/konvoy.d2iq.io\/provider\:\ preprovisioned/konvoy.d2iq.io\/provider\:\ aws/' deploy-dkp-student1-dkp.yaml

##Now apply the deploy manifest to the bootstrap cluster
kubectl apply -f deploy-dkp-${var.cluster_name}.yaml

##Run the following commands to view the status of the deployment
./dkp describe cluster -c ${var.cluster_name}
kubectl logs -f -n cappp-system deploy/cappp-controller-manager

##After 5 minutes or so if there is no critical error in the above, run the following command to get the admin kubeconfig of the provisioned DKP cluster
./dkp get kubeconfig -c ${var.cluster_name} > admin.conf
chmod 600 admin.conf

##Set admin.conf as the current KUBECONFIG
export KUBECONFIG=$(pwd)/admin.conf

##Run the following to make sure all the nodes in the DKP cluster are in Ready state
kubectl get nodes

###Deploy Kommander#####
export VERSION=${var.kommander_version}
helm repo add kommander https://mesosphere.github.io/kommander/charts
helm repo update
helm install -n kommander --create-namespace kommander-bootstrap kommander/kommander-bootstrap --version=${var.kommander_version} --set certManager=$(kubectl get ns cert-manager > /dev/null 2>&1 && echo "false" || echo "true")
EOF
}
