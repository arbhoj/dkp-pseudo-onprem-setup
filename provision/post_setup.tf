resource "local_file" "post_setup_sh" {
  filename = "post_setup.sh"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 700 post_setup.sh"
  }
  content = <<EOF
ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")} 'bash -s' < provision/auto_full.sh $1

EOF
}
