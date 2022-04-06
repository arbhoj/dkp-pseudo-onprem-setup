resource "local_file" "auto_kommander_sh" {
  filename = "auto_kommander.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 auto_kommander.sh"
  }
  content = <<EOF
if [ $# -ne 0 ]; then
  if [ $1 = "kommander" ]; then

      ##Set admin.conf as the current KUBECONFIG
      echo -e "\n\nSet the downloaded kubeconfig as the current KUBECONFIG"
      echo -e "\nexport KUBECONFIG=$(pwd)/admin.conf"
      export KUBECONFIG=$(pwd)/admin.conf
      ###Deploy Kommander#####
      ##Install cert-manager
      echo -e "\nInstalling cert-manager"
      echo -e "\nhelm repo add jetstack https://charts.jetstack.io"
      helm repo add jetstack https://charts.jetstack.io
      echo -e "\nhelm repo update"
      helm repo update
      echo -e "\nkubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml"
      kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml
      echo -e "\nhelm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1" 
      helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1
      #export VERSION=${var.kommander_version}
      echo -e "\n\n Deploy Kommander"
      #helm repo add kommander https://mesosphere.github.io/kommander/charts
      #helm repo update
      #helm install -n kommander --create-namespace kommander-bootstrap kommander/kommander-bootstrap --version=${var.kommander_version} --set certManager=$(kubectl get ns cert-manager > /dev/null 2>&1 && echo "false" || echo "true")
      ./dkp install kommander
      echo -e "\n\nKommander base deployed."
      echo -e "\nWaiting for helmreleases to be rolled out. Sleeping 10 minutes before checking status" 
      sleep 600
      echo -e "\nkubectl -n kommander wait --for condition=Released helmreleases --timeout 1s --all"  
      kubectl -n kommander wait --for condition=Released helmreleases --timeout 1s --all
      echo -e "\n\n"
      ./get_cluster_details.sh
      echo -e "\n\n"
  fi
fi
exit
EOF
}
