resource "local_file" "ansible_registry_inventory" {
  filename = "inventory_registry.yaml"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 644 inventory_registry.yaml"
  }
  content = <<EOF
all:
  vars:
    ansible_user: ${var.ssh_registry_username}
    ansible_ssh_private_key_file: ${trimprefix(var.ssh_private_key_file, "../")}
    ansible_python_interpreter: /usr/bin/python
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    konvoy_image_builder_version: ${var.konvoy_image_builder_version}
    dkp_version: ${var.dkp_version}
    kubectl_version: ${var.kubectl_version}
    cluster_name: ${var.cluster_name}
    kommander_version: ${var.kommander_version}
registry:
  hosts:
    ${aws_instance.registry[0].private_ip}:
      ansible_host: ${aws_instance.registry[0].public_ip}
      node_pool: registry
EOF
}
