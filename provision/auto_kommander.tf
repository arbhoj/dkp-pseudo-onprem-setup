resource "local_file" "auto_kommander_sh" {
  filename = "auto_kommander.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 auto_kommander.sh"
  }
  content = <<EOF
if [ $# -ne 0 ]; then
  if [ $1 = "kommander" ]; then
      echo -e "\n\n Deploy Kommander"
      ##Set admin.conf as the current KUBECONFIG
      echo -e "\n\nSet the downloaded kubeconfig as the current KUBECONFIG"
      echo -e "\nexport KUBECONFIG=$(pwd)/admin.conf"
      export KUBECONFIG=$(pwd)/admin.conf
      ###Deploy Kommander#####
      export VERSION=${var.kommander_version}
      helm repo add kommander https://mesosphere.github.io/kommander/charts
      helm repo update
      helm install -n kommander --create-namespace kommander-bootstrap kommander/kommander-bootstrap --version=${var.kommander_version} --set certManager=$(kubectl get ns cert-manager > /dev/null 2>&1 && echo "false" || echo "true")
      echo -e "\n\nKommander helm chart deployed."
      echo -e "\nWaiting for helmreleases to be rolled out. Sleeping 10 minutes before checking status" 
      sleep 600
      echo -e "\nkubectl -n kommander wait --for condition=Released helmreleases --timeout 1s --all"  
      kubectl -n kommander wait --for condition=Released helmreleases --timeout 1s --all
      ./get_cluster_details.sh
      echo -e "\n\n"
  fi
fi
exit
EOF
}
