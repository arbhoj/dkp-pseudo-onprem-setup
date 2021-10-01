resource "null_resource" "custom_ansible_format_disks_playbook" {
  provisioner "local-exec" {
    command = "while [[ $CONNECTED != 'yes' ]];do CONNECTED=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 centos@${aws_instance.registry[0].public_ip} -i ${var.ssh_private_key_file} echo yes 2>&1);done; ansible-playbook -i inventory.yaml ./../ansible/format_disks.yaml"

 }
  depends_on = [
    null_resource.custom_ansible_registry_playbook,
  ]
} 
