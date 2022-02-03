resource "local_file" "capi_inventory" {
  filename = "${var.cluster_name}-preprovisioned_inventory.yaml"

  depends_on = [aws_instance.worker]

  provisioner "local-exec" {
    command = "chmod 644 ${var.cluster_name}-preprovisioned_inventory.yaml"
  }
  content = <<EOF
apiVersion: infrastructure.cluster.konvoy.d2iq.io/v1alpha1
kind: PreprovisionedInventory
metadata:
  name: ${var.cluster_name}-control-plane
  labels:
    cluster.x-k8s.io/cluster-name: ${var.cluster_name}
spec:
  hosts:
    # Create as many of these as needed to match your infrastructure
%{ for index, cp in aws_instance.control_plane ~}
  - address: ${cp.private_ip}
%{ endfor ~}
  sshConfig:
    port: 22
    # This is the username used to connect to your infrastructure. This user must be root or
    # have the ability to use sudo without a password
    user: ${var.ssh_username}
    privateKeyRef:
      # This is the name of the secret you created in the previous step. It must exist in the same
      # namespace as this inventory object.
      name: ${var.cluster_name}-ssh-key
      namespace: default
---
apiVersion: infrastructure.cluster.konvoy.d2iq.io/v1alpha1
kind: PreprovisionedInventory
metadata:
  name: ${var.cluster_name}-md-0
spec:
  hosts:
%{ for index, wk in aws_instance.worker ~}
  - address: ${wk.private_ip}
%{ endfor ~}
  sshConfig:
    port: 22
    user: ${var.ssh_username}
    privateKeyRef:
      name: ${var.cluster_name}-ssh-key
      namespace: default
EOF
}
