resource "local_file" "get_kubeconfig" {
  filename = "get_kubeconfig.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 get_kubeconfig.sh"
  }
  content = <<EOF
scp -i ${trimprefix(var.ssh_private_key_file, "../")} centos@${aws_instance.registry[0].public_ip}:/home/centos/admin.conf ${var.cluster_name}-admin.conf
scp -i ${trimprefix(var.ssh_private_key_file, "../")} centos@${aws_instance.registry[0].public_ip}:/home/centos/admin.conf .
exit
EOF
}
