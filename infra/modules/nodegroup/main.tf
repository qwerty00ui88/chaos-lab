locals {
  base_tags = merge(var.tags, {
    Component = "eks-nodegroup"
  })
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${data.aws_eks_cluster.cluster.version}/amazon-linux-2/recommended/image_id"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-${var.name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.base_tags, {
    Role = "node"
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.key
  role       = aws_iam_role.node.name
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.cluster_name}-${var.name}-"

  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = var.instance_types[0]

  user_data = base64encode(templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    cluster_name       = var.cluster_name
    cluster_ca         = data.aws_eks_cluster.cluster.certificate_authority[0].data
    cluster_endpoint   = data.aws_eks_cluster.cluster.endpoint
    node_labels        = var.node_labels
    node_taints        = var.node_taints
    kubelet_extra_args = var.kubelet_extra_args
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  capacity_type   = var.capacity_type

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node
  ]
}
