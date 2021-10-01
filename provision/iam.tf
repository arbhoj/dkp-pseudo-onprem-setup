data "aws_region" "current" {}

locals {
  ec2_service_principal = substr(data.aws_region.current.name, 0, 3) == "cn-" ? "ec2.amazonaws.com.cn" : "ec2.amazonaws.com"
  node_policy_name      = "${local.cluster_name}-node-policy"
  node_role_name        = "${local.cluster_name}-node-role"
  node_profile_name     = "${local.cluster_name}-node-profile"
}

# Define IAM role to create external volumes on AWS
resource "aws_iam_instance_profile" "node_profile" {
  name  = "${local.cluster_name}-node-profile"
  role  = aws_iam_role.node_role[count.index].name
  count = var.create_iam_instance_profile ? 1 : 0

  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags  
}

resource "aws_iam_role_policy" "agent_policy" {
  name  = local.node_policy_name
  role  = aws_iam_role.node_role[count.index].id
  count = var.create_iam_instance_profile ? 1 : 0

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "KubernetesCloudProvider",
            "Action": [
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:CreateVolume",
              "ec2:DeleteVolume",
              "ec2:AttachVolume",
              "ec2:DetachVolume",
              "ec2:DescribeVolumes",
              "ec2:DescribeVolumeStatus",
              "ec2:DescribeVolumeAttribute",
              "ec2:ModifyVolume",
              "ec2:DescribeVolumesModifications",
              "ec2:CreateSnapshot",
              "ec2:CopySnapshot",
              "ec2:DeleteSnapshot",
              "ec2:DescribeSnapshots",
              "ec2:DescribeSnapshotAttribute",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:CreateRoute",
              "ec2:CreateSecurityGroup",
              "ec2:DeleteSecurityGroup",
              "ec2:DeleteRoute",
              "ec2:DescribeRouteTables",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:ModifyInstanceAttribute",
              "ec2:RevokeSecurityGroupIngress",
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
              "elasticloadbalancing:AttachLoadBalancerToSubnets",
              "elasticloadbalancing:ConfigureHealthCheck",
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:CreateLoadBalancerListeners",
              "elasticloadbalancing:CreateLoadBalancerPolicy",
              "elasticloadbalancing:DeleteLoadBalancer",
              "elasticloadbalancing:DeleteLoadBalancerListeners",
              "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
              "elasticloadbalancing:DescribeLoadBalancerAttributes",
              "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeTags",
              "elasticloadbalancing:DetachLoadBalancerFromSubnets",
              "elasticloadbalancing:ModifyLoadBalancerAttributes",
              "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
              "elasticloadbalancing:RemoveTags",
              "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role" "node_role" {
  name  = local.node_role_name
  count = var.create_iam_instance_profile ? 1 : 0

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "${local.ec2_service_principal}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
