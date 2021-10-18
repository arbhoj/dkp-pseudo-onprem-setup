resource "null_resource" "custom_ansible_format_disks_playbook" {
  count = var.deploy_mayastor ? 0 : 1
  provisioner "local-exec" {
    command = "while [[ $CONNECTED1 != 'yes' ]];do CONNECTED1=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[0].public_ip} -i ${var.ssh_private_key_file} echo yes 2>&1);done;while [[ $CONNECTED2 != 'yes' ]];do CONNECTED2=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[1].public_ip} -i ${var.ssh_private_key_file} echo yes 2>&1);done;while [[ $CONNECTED3 != 'yes' ]];do CONNECTED3=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[2].public_ip} -i ${var.ssh_private_key_file} echo yes 2>&1);done;while [[ $CONNECTED4 != 'yes' ]];do CONNECTED4=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${var.ssh_username}@${aws_instance.worker[3].public_ip} -i ${var.ssh_private_key_file} echo yes 2>&1);done;ansible-playbook -i inventory.yaml ./../ansible/format_disks.yaml"

 }
  depends_on = [
    null_resource.custom_ansible_registry_playbook,
  ]
}
