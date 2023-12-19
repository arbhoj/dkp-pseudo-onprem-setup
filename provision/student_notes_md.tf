resource "local_file" "dkp_2_install_md" {
  filename = "dkp_2_install.md"

  depends_on = [aws_instance.registry]

  provisioner "local-exec" {
    command = "chmod 644 dkp_2_install.md"
  }
  content = <<EOF
# Student Handbook ${var.cluster_name}

## Cluster Details

Bootstrap Node:
```
${aws_instance.registry[0].public_ip}
```

Control Plane Nodes:

```
%{ for index, cp in aws_instance.control_plane ~}
${cp.private_ip}
%{ endfor ~}
```

Worker Nodes:
```
%{ for index, wk in aws_instance.worker ~}
${wk.private_ip}
%{ endfor ~}
```

Control Plane LoadBalancer:
```
${aws_elb.konvoy_control_plane.dns_name} 
```

ssh-key:
```
${trimprefix(var.ssh_private_key_file, "../")}
```

Connect to the bootstrap server as all the lab exercises will be run from there.

```
echo "${data.local_file.key_file.content}" > ${trimprefix(var.ssh_private_key_file, "../")}
chmod 600 ${trimprefix(var.ssh_private_key_file, "../")}
ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")}
```

EOF
}
