resource "local_file" "pre_delete_sh" {
  filename = "pre_delete.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 pre_delete.sh"
  }
  content = <<EOF
ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} 'bash -s' < ./provision/delete_lb_svc.sh
EOF
}
