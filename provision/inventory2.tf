resource "local_file" "ansible_inventory_2" {
  filename = "inventory2.yaml"

  depends_on = [aws_instance.worker]

  provisioner "local-exec" {
    command = "chmod 644 inventory2.yaml"
  }
  content = <<EOF
all:
  vars:
    ansible_python_interpreter: ${var.ansible_python_interpreter}
    ansible_user: ${var.ssh_username}
    ansible_port: 22
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_ssh_private_key_file: ${trimprefix(var.ssh_private_key_file,"../")}
    registry_server: "${aws_instance.registry[0].private_ip}:5000" #Note: Use the private ip of the registry server
    cluster_name: ${var.cluster_name}
  hosts:
%{ for index, cp in aws_instance.control_plane ~}
    ${cp.private_ip}:
      node_pool: control
%{ endfor ~}
%{ for index, wk in aws_instance.worker ~}
    ${wk.private_ip}:
      node_pool: worker
%{ endfor ~}
EOF
}


