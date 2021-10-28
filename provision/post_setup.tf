resource "local_file" "post_setup_sh" {
  filename = "post_setup.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 post_setup.sh"
  }
  content = <<EOF

#Wait for all nodes to be ready
for worker_node in %{ for index, wk in aws_instance.worker ~}${wk.public_ip} %{ endfor ~};do
  while [[ $CONNECTED0 != 'yes' ]];do
    CONNECTED0=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@$worker_node -i ${trimprefix(var.ssh_private_key_file, "../")} echo yes 2>&1)
  echo ready_node1: $CONNECTED0
  done
done

if [ $? -eq 0 ]; then
  #Deploy Base and Optionally Konvoy
  ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} 'bash -s' < provision/auto_konvoy.sh $1
  provision/get_kubeconfig.sh $1
fi

if [ $? -eq 0 ]; then
  #Deploy Mayastor if selected 
  if [[ (${var.deploy_mayastor} == true )  && ( $1 = "konvoy"  || $1 = "kommander" ) ]]; then
    echo "Deploying and configuring Mayastor"
    ansible-playbook -i provision/inventory.yaml ansible/openebs_setup.yaml --key-file ${trimprefix(var.ssh_private_key_file, "../")}
  fi 
fi

if [ $? -eq 0 ]; then
  #Deploy Kommander if selected
  ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} 'bash -s' < provision/auto_kommander.sh $1
fi
EOF
}
