resource "local_file" "auto_konvoy_sh" {
  filename = "auto_konvoy.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 auto_konvoy.sh"
  }
  content = <<EOF
if [ $# -ne 0 ]; then
  if [ $1 = "konvoy" ] || [ $1 = "kommander" ]; then
    ##Commented KIB as it runs as a part of the deployment process
    ###Build Server######
    ###Run the following from the konvoy-image builder dir https://github.com/mesosphere/konvoy-image-builder
    #echo -e "\nRunning Konvoy image builder"

    #cd /home/centos/konvoy-image-builder
    ##To handle change introduced in v1.3.1 of image builder. 
    ##Extract konvoy image builder version 
    #export kib_ver=${substr(var.konvoy_image_builder_version,3,1)} 
    #echo "KIB Version: $${kib_ver}"
    #if [ $${kib_ver} -ge 3 ]; then
    #  echo -e "\n./konvoy-image provision --inventory-file /home/centos/provision/inventory.yaml"
    #  ./konvoy-image provision --inventory-file /home/centos/provision/inventory.yaml
    #else
    #  echo -e "\n./konvoy-image provision --inventory-file /home/centos/provision/inventory.yaml  images/generic/flatcar.yaml" 
    #  ./konvoy-image provision --inventory-file /home/centos/provision/inventory.yaml  images/generic/${var.node_os}.yaml
    #fi
    #####################
    ###Deploy DKP Cluster#####
    ###Run these from the directory where DKP binary has been downloaded
    cd /home/centos
    #First create a bootstrap cluster
    echo -e "\n\nCreating bootstrap server"
    echo -e "\n./dkp create bootstrap"
    ./dkp create bootstrap
    
    #Once bootstrap cluster is created add the secret containing the private key to connect to the hosts
    echo -e "\n\nCreate secret to hold ssh keys"
    echo -e "\nkubectl create secret generic ${var.cluster_name}-ssh-key --from-file=ssh-privatekey=/home/centos/${trimprefix(var.ssh_private_key_file, "../")}"
    kubectl create secret generic ${var.cluster_name}-ssh-key --from-file=ssh-privatekey=/home/centos/${trimprefix(var.ssh_private_key_file, "../")}
    
    #Create the pre-provisioned inventory resources
    echo -e "\n\nCreate preprovisioned inventory"
    echo -e "\nkubectl apply -f /home/centos/provision/${var.cluster_name}-preprovisioned_inventory.yaml"
    kubectl apply -f /home/centos/provision/${var.cluster_name}-preprovisioned_inventory.yaml
    
    #Create the manifest files for deploying the konvoy to the cluster
    #Note if deploying a flatcar cluster then add the --os-hint=flatcar flag like this:
    echo -e "\n\nCreate manifest to deploy cluster"
    if [ ${var.node_os} == "flatcar" ]; then
      echo -e "\n./dkp create cluster preprovisioned --cluster-name ${var.cluster_name} --control-plane-endpoint-host ${aws_elb.konvoy_control_plane.dns_name} --os-hint=flatcar --control-plane-replicas 1 --worker-replicas ${var.worker_node_count} --dry-run -o yaml > deploy-dkp-${var.cluster_name}.yaml"
      ./dkp create cluster preprovisioned --cluster-name ${var.cluster_name} --control-plane-endpoint-host ${aws_elb.konvoy_control_plane.dns_name} --os-hint=flatcar --control-plane-replicas 1 --worker-replicas 4 --dry-run -o yaml > deploy-dkp-${var.cluster_name}.yaml
    else    
      echo -e "\n./dkp create cluster preprovisioned --cluster-name ${var.cluster_name} --control-plane-endpoint-host ${aws_elb.konvoy_control_plane.dns_name} --control-plane-replicas 1 --worker-replicas 4 --dry-run -o yaml > deploy-dkp-${var.cluster_name}.yaml"
      ./dkp create cluster preprovisioned --cluster-name ${var.cluster_name} --control-plane-endpoint-host ${aws_elb.konvoy_control_plane.dns_name} --control-plane-replicas 1 --worker-replicas 4 --dry-run -o yaml > deploy-dkp-${var.cluster_name}.yaml
    fi
    ##Update all occurances of cloud-provider="" to cloud-provider=aws
    echo -e "\n\nSet cloud-provider to aws"
    echo -e "\nsed -i 's/cloud-provider\:\ \"\"/cloud-provider\:\ \"aws\"/' deploy-dkp-${var.cluster_name}.yaml"
    sed -i 's/cloud-provider\:\ \"\"/cloud-provider\:\ \"aws\"/' deploy-dkp-${var.cluster_name}.yaml
    #sed -i 's/konvoy.d2iq.io\/csi\:\ local-volume-provisioner/konvoy.d2iq.io\/csi\:\ aws-ebs/' deploy-dkp-${var.cluster_name}.yaml
    #sed -i 's/konvoy.d2iq.io\/provider\:\ preprovisioned/konvoy.d2iq.io\/provider\:\ aws/' deploy-dkp-student1-dkp.yaml
    ####TEMP FIX FOR 2.1 BUG##### 
    sed -i 's/\.\/run\/kubeadm\/konvoy-set-kube-proxy-configuration.sh/\/tmp\/konvoy-set-kube-proxy-configuration.sh/g' deploy-dkp-${var.cluster_name}.yaml
    sed -i 's/\/run\/kubeadm\/konvoy-set-kube-proxy-configuration.sh/\/tmp\/konvoy-set-kube-proxy-configuration.sh/g' deploy-dkp-${var.cluster_name}.yaml
    #head -n -3 deploy-${var.cluster_name}.yaml > tmp.yaml && mv tmp.yaml deploy-${var.cluster_name}.yaml
    ##Now apply the deploy manifest to the bootstrap cluster
    echo -e "\n\nDeploy the cluster"
    echo -e "\nkubectl apply -f deploy-dkp-${var.cluster_name}.yaml" 
    kubectl apply -f deploy-dkp-${var.cluster_name}.yaml
    
    ##Run the following command to wait till the control plane is in ready state
    echo -e "\n\nWait for cluster to be ready" 
    kubectl wait --for=condition=ControlPlaneReady "clusters/${var.cluster_name}" --timeout=20m

    ##Wait 30 seconds and then delete any pod that is not in completed or ready state. This is to handle some core pods that get stuck in crash loop status
    sleep 30
    while IFS= read -r namespace_and_pod; do kubectl delete pods --force -n $namespace_and_pod 2>&1 | grep -iv 'warning'; done < <(kubectl get pods -A --no-headers | egrep -iv 'running|completed' | awk {'printf ("%s\t%s\n",$1,$2)'}) 
    
    ##After 5 minutes or so if there is no critical error in the above, run the following command to get the admin kubeconfig of the provisioned DKP cluster
    echo -e "\n\nGet kubeconfig of the deployed cluster" 
    echo -e "\n./dkp get kubeconfig -c ${var.cluster_name} > admin.conf"
    ./dkp get kubeconfig -c ${var.cluster_name} > admin.conf
    chmod 600 admin.conf
    
    ##Set admin.conf as the current KUBECONFIG
    echo -e "\n\nSet the downloaded kubeconfig as the current KUBECONFIG"
    echo -e "\nexport KUBECONFIG=$(pwd)/admin.conf"  
    export KUBECONFIG=$(pwd)/admin.conf
    
    ##Deploy awsebs if mayastor is not enabled
    if [ ${var.deploy_mayastor} == false ]; then
      echo -e "\n\n Deploy awsebscsiprovisioner" 
      helm repo add d2iq-stable https://mesosphere.github.io/charts/stable
      helm repo update
      helm install awsebscsiprovisioner d2iq-stable/awsebscsiprovisioner --version 0.5.0 --values awsebscsiprovisioner_values.yaml 
    fi
    ##Mark localvolumeprovisioner as non-default sc
    echo "Unset localvolumeprovisioner as default provisioner"
    kubectl patch sc localvolumeprovisioner -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
  
    echo -e "\n\nKonvoy cluster deployed"
    echo -e "\nConnect to the bootstrap server and export admin.conf as the KUBECONFIG"
    echo -e "\nexport KUBECONFIG=$(pwd)/admin.conf"
    echo -e "\nCheck if all the nodes are in ready state"
    echo -e "\nkubectl get nodes"
  fi
else
    echo -e "\n\nJust doing a base environment setup. Use instructions to build and deploy konvoy/kommander"
    echo -e "\nFollow the instructions here for the steps to deploy cluster"
    echo -e "\nhttp://${aws_instance.registry[0].public_ip}/dkp_2_install.md"
    echo -e "\nSSH Details: ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")}"
fi
exit
EOF
}
