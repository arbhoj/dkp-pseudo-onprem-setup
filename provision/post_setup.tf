resource "local_file" "post_setup_sh" {
  filename = "post_setup.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 post_setup.sh"
  }
  content = <<EOF

#Wait for all nodes to be ready
while [[ $CONNECTED0 != 'yes' ]];do
  CONNECTED0=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.control_plane[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} echo yes 2>&1)
echo ready_node1: $CONNECTED0
done
while [[ $CONNECTED1 != 'yes' ]];do 
  CONNECTED1=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} echo yes 2>&1)
echo ready_node1: $CONNECTED1
done
while [[ $CONNECTED2 != 'yes' ]];do
  CONNECTED2=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[1].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} echo yes 2>&1)
echo ready_node2: $CONNECTED2
done
while [[ $CONNECTED3 != 'yes' ]];do 
  CONNECTED3=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[2].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} echo yes 2>&1)
echo ready_node3: $CONNECTED3
done
while [[ $CONNECTED4 != 'yes' ]];do
  CONNECTED4=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[3].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} echo yes 2>&1)
echo ready_node4: $CONNECTED4
done

if [ $? -eq 0 ]; then
  #Deploy Base and Optionally Konvoy
  ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} 'bash -s' < provision/auto_konvoy.sh $1
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
