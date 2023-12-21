terraform {
  required_version = ">= 0.12"
  required_providers {
    ct = {
      source  = "poseidon/ct"
      version = "0.7.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

locals {
  public_subnet_range        = var.vpc_cidr
  cluster_name               = var.cluster_name
}


provider "aws" {
  region                  = var.aws_region
  skip_metadata_api_check = var.skip_metadata_api_check
}

variable format_disks {
  description = "Flag to indicate whether disks have to be formatted"
  default = true
}

variable internal_lb {
  description = "Defines if the an internal lb needs to be created for control plane"
  default = "false"
}

variable konvoy_image_builder_version {
  description = "Version for konvoy image builder"
  default = "v1.0.0"   

}

variable dkp_version {
  description = "DKP version"
  default = "v2.0.0"

}

variable kommander_version {
  description = "Kommander version"
  default = "v2.0.0"

}

variable kubectl_version { 
  description = "Kubectl Version"
  default = "v1.26.0"

}

variable node_os {
  description = "OS of the nodes"
  default = "flatcar"
}

variable deploy_mayastor {
  description = "Whether to deploy and configure mayastor as the default storage provisioner"
  default = false

}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  default     = 1 
}

variable "worker_node_count" {
  description = "Number of control plane nodes"
  default     = 4
}

variable "aws_region" {
  description = "AWS region where to deploy the cluster"
  default     = "us-west-2"
}

variable "registry_ami" {
  description = "AMI to be used for registry server"
  default     = "ami-0686851c4e7b1a8e1"
}

variable "create_extra_worker_volumes" {
  description = "Whether to create extra volumes for worker nodes"
  default     = false
}

variable "create_extra_worker_volumes_rook" {
  description = "Whether to create extra volumes for worker nodes to be used by rook"
  default     = false
} 


variable "extra_volume_size" {
description = "Size of the extra volume that will be attached to all the worker nodes"
  default     = 500
}

variable "create_extra_control_volumes" {
  description = "Whether to create extra volumes for control nodes"
  default     = false
}

variable "skip_metadata_api_check" {
  description = "Prevents Terraform from authenticating via the Metadata API"
  default     = false
}

variable "ssh_private_key_file" {
  description = "Path to the SSH private key"
  default     = ""
}

variable "ssh_public_key_file" {
  description = "Path to the SSH public key"
  default = ""
}

variable "cluster_name" {
  description = "The name of the provisioned cluster"
}

data "aws_caller_identity" "current" {}

variable "ansible_python_interpreter" {
  description = "Ansible python interpreter path in the provisione image. This is used to generate the ansible inventory file"
  default     = "/usr/bin/python"
}

variable "inventory_path" {
  description = "Path where ansible inventory file will be generated"
  default     = "inventory.yaml"
}

variable "control_plane_image_id" {
  description = "[CONTROL_PLANE] AWS AMI image ID that will be used for the instances instead of the Mesosphere chosen default images"
  default     = ""
}

variable "control_plane_kms_key_id" {
  description = "[BASTION] AWS KMS key ID that will be used to encrypt-at-rest the storage"
  default     = ""
}

variable "control_plane_root_volume_size" {
  description = "[CONTROL_PLANE] The root volume size"
  default     = "80"
}

variable "control_plane_root_volume_type" {
  description = "[CONTROL_PLANE] The root volume type. Should be gp2 or io1"
  default     = "io1"
}

variable "control_plane_root_volume_iops" {
  description = "[CONTROL_PLANE] The root volume IOPS. An io1 volume can range in size from 4 GiB to 16 TiB. You can provision from 100 IOPS up to 64,000 IOPS per volume on Nitro-based Instances instances and up to 32,000 on other instances."
  default     = "1000"
}

variable "control_plane_imagefs_volume_enabled" {
  description = "[CONTROL_PLANE] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "control_plane_imagefs_volume_size" {
  description = "[CONTROL_PLANE] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "control_plane_imagefs_volume_type" {
  description = "[CONTROL_PLANE] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "control_plane_imagefs_volume_device" {
  description = "[CONTROL_PLANE] The device to mount the volume at."
  default     = "xvdb"
}


variable "worker_node_kms_key_id" {
  description = "[BASTION] AWS KMS key ID that will be used to encrypt-at-rest the storage"
  default     = ""
}

variable "worker_node_root_volume_size" {
  description = "[WORKER_NODE] The root volume size"
  default     = "100"
}

variable "worker_node_root_volume_type" {
  description = "[WORKER_NODE] The root volume type. Should be gp2 or io1"
  default     = "io1"
}

variable "worker_node_root_volume_iops" {
  description = "[WORKER_NODE] The root volume IOPS. An io1 volume can range in size from 4 GiB to 16 TiB. You can provision from 100 IOPS up to 64,000 IOPS per volume on Nitro-based Instances instances and up to 32,000 on other instances."
  default     = "1000"
}

variable "worker_node_imagefs_volume_enabled" {
  description = "[WORKER_NODE] Whether to have dedicated volume for imagefs"
  default     = false
}

variable "worker_node_imagefs_volume_size" {
  description = "[WORKER_NODE] The size for the dedicated imagefs volume"
  default     = "160"
}

variable "worker_node_imagefs_volume_type" {
  description = "[WORKER_NODE] The type for the dedicated imagefs volume. Should be gp2 or io1"
  default     = "gp2"
}

variable "worker_node_imagefs_volume_device" {
  description = "[WORKER_NODE] The device to mount the volume at."
  default     = "xvdb"
}


variable "create_iam_instance_profile" {
  default = "true"  
}

variable "aws_availability_zones" {
  type        = list
  description = "Availability zones to be used"
  default     = ["us-west-2c"]
}

variable "vpc_cidr" {
  description = "The CIDR used for vpc"
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Map of tags to add to all resources"
  type        = map
  default     = {}
}

variable "egress_cidr" {
  description = "The CIDR used in the egress security group"
  default     = "0.0.0.0/0"
}

variable "node_ami" {
  description = "The AMI for the bastion machine"
}

variable "ssh_username" {
  description = "The user for connecting to the instance over ssh"
  default = "centos"
}

variable "ssh_registry_username" {
  description = "The user for connecting to the instance over ssh"
  default = "centos"
}


resource "aws_key_pair" "konvoy" {
  key_name   = local.cluster_name
  public_key = file(var.ssh_public_key_file)
  tags = var.tags
}

data "local_file" "key_file" {
  filename = "${var.ssh_private_key_file}"
}

resource "aws_vpc" "konvoy_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-vpc"
      }
    )
  )}"
}

resource "aws_internet_gateway" "konvoy_gateway" {
  vpc_id = aws_vpc.konvoy_vpc.id

  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-gateway",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
      }
    )
  )}"
}

resource "aws_subnet" "konvoy_public" {
  vpc_id                  = aws_vpc.konvoy_vpc.id
  cidr_block              = local.public_subnet_range
  map_public_ip_on_launch = true
  availability_zone       = var.aws_availability_zones[0]

  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-subnet",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
      }
    )
  )}"

}

resource "aws_route_table" "konvoy_public_rt" {
  vpc_id = aws_vpc.konvoy_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.konvoy_gateway.id
  }
  lifecycle {
    ignore_changes = [ route, tags ]
  }

  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-routetable",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
      }
    )
  )}"
}

resource "aws_route_table_association" "konvoy_public_rta" {
  subnet_id      = aws_subnet.konvoy_public.id
  route_table_id = aws_route_table.konvoy_public_rt.id
}

resource "aws_security_group" "konvoy_ssh" {
  description = "Allow inbound SSH for Konvoy."
  vpc_id      = aws_vpc.konvoy_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${merge(
  var.tags,
  tomap({
      "Name": "${local.cluster_name}-sg-ssh"
    }
    )
  )}"
}

resource "aws_security_group" "registry" {
  description = "Open port 80 for registry server for serving notes"
  vpc_id      = aws_vpc.konvoy_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${merge(
  var.tags,
  tomap({
      "Name": "${local.cluster_name}-registry"
    }
    )
  )}"
}


resource "aws_security_group" "konvoy_private" {
  description = "Allow all communication between instances"
  vpc_id      = aws_vpc.konvoy_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = "${merge(
  var.tags,
  tomap({
      "Name": "${local.cluster_name}-sg-private",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
    }
    )
  )}"
}


resource "aws_security_group" "konvoy_elb" {
  description = "Security Group used by elb"
  vpc_id      = aws_vpc.konvoy_vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 9000
    to_port   = 9000
    protocol  = "tcp"
    self      = true
  }


  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = "${merge(
  var.tags,
  tomap({
      "Name": "${local.cluster_name}-sg-elb",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
    }
    )
  )}"
}



resource "aws_security_group" "konvoy_egress" {
  description = "Allow all egress communication."
  vpc_id      = aws_vpc.konvoy_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr]
  }

  tags = "${merge(
  var.tags,
  tomap({
      "Name": "${local.cluster_name}-sg-egress",
    }
    )
  )}"

}

resource "aws_instance" "control_plane" {
  count                       = var.control_plane_count
  vpc_security_group_ids      = [aws_security_group.konvoy_ssh.id, aws_security_group.konvoy_private.id, aws_security_group.konvoy_egress.id]
  subnet_id                   = aws_subnet.konvoy_public.id
  key_name                    = local.cluster_name
  ami                         = var.node_ami
  instance_type               = "m5.2xlarge"
  availability_zone           = var.aws_availability_zones[0]
  source_dest_check           = "false"
  associate_public_ip_address = "true"
  iam_instance_profile        = "${local.cluster_name}-node-profile"
  user_data                   = data.ct_config.custom_ignition[0].rendered 

  root_block_device {
    volume_size           = var.control_plane_root_volume_size
    volume_type           = var.control_plane_root_volume_type
    iops                  = contains(["io1", "io2"], var.control_plane_root_volume_type) ? var.control_plane_root_volume_iops : 0
    delete_on_termination = true

    encrypted  = var.control_plane_kms_key_id != "" ? true : false
    kms_key_id = var.control_plane_kms_key_id
  }


  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-control-plane-${count.index}",
      "konvoy/nodeRoles": "control_plane",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
      } 
    )
  )}"

  volume_tags = "${merge(
    var.tags,
    tomap({
      "konvoy/nodeRoles": "control_plane"
      }
    )
  )}"


  lifecycle {
    ignore_changes = [
      volume_tags,
    ]
  }


  provisioner "remote-exec" {
    inline = [
      "echo ok"
    ]

    connection {
      type = "ssh"
      user = var.ssh_username
      agent = true
      private_key = file(var.ssh_private_key_file)
      host = self.public_dns
      timeout = "15m"
    }
  }
  depends_on = [
    aws_key_pair.konvoy,
  ]
}

resource "aws_instance" "worker" {
  count                       = var.worker_node_count
  vpc_security_group_ids      = [aws_security_group.konvoy_ssh.id, aws_security_group.konvoy_private.id, aws_security_group.konvoy_egress.id]
  subnet_id                   = aws_subnet.konvoy_public.id
  key_name                    = local.cluster_name
  ami                         = var.node_ami
  instance_type               = "m5.2xlarge"
  availability_zone           = var.aws_availability_zones[0]
  source_dest_check           = "false"
  associate_public_ip_address = "true"
  iam_instance_profile        = "${local.cluster_name}-node-profile"
  user_data                   = data.ct_config.custom_ignition[0].rendered

  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-worker-node-${count.index}",
      "konvoy/nodeRoles": "worker_node",
      "kubernetes.io/cluster/${local.cluster_name}": "owned",
      "kubernetes.io/cluster": "${local.cluster_name}"
      }
    )
  )}"

  root_block_device {
    volume_size           = var.worker_node_root_volume_size
    volume_type           = var.worker_node_root_volume_type
    iops                  = contains(["io1", "io2"], var.worker_node_root_volume_type) ? var.worker_node_root_volume_iops : 0
    delete_on_termination = true

    encrypted  = var.worker_node_kms_key_id != "" ? true : false
    kms_key_id = var.worker_node_kms_key_id
  }  


  provisioner "remote-exec" {
    inline = [
      "echo ok"
    ]

    connection {
      type = "ssh"
      user = var.ssh_username
      agent = true
      host = self.public_dns
      private_key = file(var.ssh_private_key_file)
      timeout = "15m"
    }
  }

  lifecycle {
    ignore_changes = [
      volume_tags,
    ]
  }  
  depends_on = [
    aws_key_pair.konvoy,
  ]

}


resource "aws_ebs_volume" "worker_extra_volume" {
  count = var.create_extra_worker_volumes ? var.worker_node_count: 0
  availability_zone = var.aws_availability_zones[0]
  size= var.extra_volume_size
  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-worker-node-${count.index}",
      "konvoy/nodeRoles": "worker_node",
      }
    )
  )}"
}

resource "aws_ebs_volume" "worker_extra_volume_rook" {
  count = var.create_extra_worker_volumes_rook ? var.worker_node_count: 0
  availability_zone = var.aws_availability_zones[0]
  size= 40
  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-worker-node-${count.index}",
      "konvoy/nodeRoles": "worker_node",
      }
    )
  )}"
}


resource "aws_volume_attachment" "worker_extra_volume" {
  count = var.create_extra_worker_volumes ? var.worker_node_count: 0
  device_name  = "/dev/sdh"
  volume_id    = element(aws_ebs_volume.worker_extra_volume.*.id, count.index)
  instance_id  = element(aws_instance.worker.*.id, count.index)
  force_detach = true

  lifecycle {
    ignore_changes = [instance_id]
  }
}

resource "aws_volume_attachment" "worker_extra_volume_rook" {
  count = var.create_extra_worker_volumes_rook ? var.worker_node_count: 0
  device_name  = "/dev/sdi"
  volume_id    = element(aws_ebs_volume.worker_extra_volume_rook.*.id, count.index)
  instance_id  = element(aws_instance.worker.*.id, count.index)
  force_detach = true
  
  lifecycle {
    ignore_changes = [instance_id]
  }
} 

####Arvind Temp Single Node Test####
resource "aws_ebs_volume" "control_extra_volume" {
  count = var.create_extra_control_volumes ? var.control_plane_count: 0
  availability_zone = var.aws_availability_zones[0]
  size= var.extra_volume_size
  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-control-plane-${count.index}",
      "konvoy/nodeRoles": "control_plane",
      }
    )
  )}"
}

resource "aws_volume_attachment" "control_extra_volume" {
  count = var.create_extra_control_volumes ? var.control_plane_count: 0
  device_name  = "/dev/sdh"
  volume_id    = element(aws_ebs_volume.control_extra_volume.*.id, count.index)
  instance_id  = element(aws_instance.control_plane.*.id, count.index)
  force_detach = true

  lifecycle {
    ignore_changes = [instance_id]
  }
}
##########################################################

resource "aws_instance" "registry" {
  count                       = 1
  vpc_security_group_ids      = [aws_security_group.konvoy_ssh.id, aws_security_group.konvoy_private.id, aws_security_group.konvoy_egress.id, aws_security_group.registry.id]
  subnet_id                   = aws_subnet.konvoy_public.id
  key_name                    = local.cluster_name
  ami                         = var.registry_ami
  instance_type               = "m5.xlarge"
  availability_zone           = var.aws_availability_zones[0]
  source_dest_check           = "false"
  associate_public_ip_address = "true"
  
  tags = "${merge(
    var.tags,
    tomap({
      "Name": "${local.cluster_name}-registry"
      }
    )
  )}"

  root_block_device {
    volume_size           = 200
    volume_type           = var.worker_node_root_volume_type
    iops                  = contains(["io1", "io2"], var.worker_node_root_volume_type) ? var.worker_node_root_volume_iops : 0
    delete_on_termination = true

    encrypted  = var.worker_node_kms_key_id != "" ? true : false
    kms_key_id = var.worker_node_kms_key_id
  }


  provisioner "remote-exec" {
    inline = [
      "echo ok"
    ]

    connection {
      type = "ssh"
      user = var.ssh_registry_username
      agent = true
      host = self.public_dns
      private_key = file(var.ssh_private_key_file)
      timeout = "15m"
    }
  }

  lifecycle {
    ignore_changes = [
      volume_tags,
    ]
  }
  depends_on = [
    aws_key_pair.konvoy,
  ]
}


resource "aws_security_group" "konvoy_control_plane" {
  description = "Allow traffic to konvoy control plane"
  vpc_id      = aws_vpc.konvoy_vpc.id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
  var.tags,
  tomap({
      "Name": "${local.cluster_name}-cp"
    }
    )
  )}"

}

resource "aws_elb" "konvoy_control_plane" {
  internal                  = var.internal_lb
  security_groups           = [aws_security_group.konvoy_private.id, aws_security_group.konvoy_control_plane.id]
  subnets                   = [aws_subnet.konvoy_public.id]
  connection_draining       = true
  cross_zone_load_balancing = true


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTPS:6443/healthz"
    interval            = 10
  }

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  instances = aws_instance.control_plane.*.id

  tags = var.tags
}

data "ct_config" "custom_ignition" {
  count = 1
  content  = var.node_os == "flatcar" ? data.local_file.custom_ignition[0].content : ""
}

data "local_file" "custom_ignition" {
  count = 1
  filename = "${path.module}/cl/ignition_configs.yaml" 
}

output "kube_apiserver_address" {
  value = aws_elb.konvoy_control_plane.dns_name
}

output "control_plane_public_ips" {
  value = aws_instance.control_plane.*.public_ip
}

output "worker_public_ips" {
  value = aws_instance.worker.*.public_ip
}

output "registry_ip" {
  value = aws_instance.registry.*.public_ip
}

output "z_run_this" {

  value = <<EOF

#########################
## Cluster Details    ###
#########################
Bootstrap Node:
${aws_instance.registry[0].public_ip}

Control Plane Nodes:
%{ for index, cp in aws_instance.control_plane ~}
    ${cp.private_ip}
%{ endfor ~}

Worker Nodes:
%{ for index, wk in aws_instance.worker ~}
    ${wk.private_ip}
%{ endfor ~}

Control Plane LoadBalancer:
${aws_elb.konvoy_control_plane.dns_name}

ssh-key:
${trimprefix(var.ssh_private_key_file, "../")}

#########################
Notes: URL
http://${aws_instance.registry[0].public_ip}/dkp_2_install.md
#########################
Note: For Lab environment view the instructions in /home/centos/${local.cluster_name}-student-notes.txt on the registry/bootstrap server
ssh centos@${aws_instance.registry[0].public_ip} -i ${trimprefix(var.ssh_private_key_file, "../")}
#########################

EOF

}
