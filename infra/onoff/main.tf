terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "shared" {
  source = "../shared"

  region      = var.region
  aws_profile = var.aws_profile
  environment = var.environment
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = module.shared.default_tags
  }
}

provider "kubernetes" {
  alias = "eks"

  host                   = local.fluent_bit_kube_host
  cluster_ca_certificate = local.fluent_bit_kube_ca != "" ? base64decode(local.fluent_bit_kube_ca) : null

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region",
      var.region,
      "--cluster-name",
      local.fluent_bit_cluster_name
    ]
  }
}

provider "helm" {
  alias = "eks"

  kubernetes = {
    host                   = local.fluent_bit_kube_host
    cluster_ca_certificate = local.fluent_bit_kube_ca != "" ? base64decode(local.fluent_bit_kube_ca) : null
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--region",
        var.region,
        "--cluster-name",
        local.fluent_bit_cluster_name
      ]
    }
  }
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "static" {
  backend = "s3"

  config = {
    bucket = "chaos-lab-terraform-state"
    key    = "static/terraform.tfstate"
    region = var.region
  }
}

locals {
  static_outputs = data.terraform_remote_state.static.outputs

  subnet_ids_map  = try(local.static_outputs.private_subnet_ids_map, {})
  security_groups = try(local.static_outputs.security_group_ids, {})

  private_subnet_ids = try(local.static_outputs.private_subnet_ids, [])
  public_subnet_ids  = try(local.static_outputs.public_subnet_ids, [])

  node_subnets_from_map = compact([
    try(local.subnet_ids_map["private-node-a"], null),
    try(local.subnet_ids_map["private-node-b"], null)
  ])

  db_subnets_from_map = compact([
    try(local.subnet_ids_map["private-db-a"], null),
    try(local.subnet_ids_map["private-db-b"], null)
  ])

  node_subnet_ids = length(local.node_subnets_from_map) > 0 ? local.node_subnets_from_map : local.private_subnet_ids

  db_subnet_ids = length(local.db_subnets_from_map) > 0 ? local.db_subnets_from_map : local.private_subnet_ids

  alb_subnet_ids = length(local.public_subnet_ids) > 0 ? local.public_subnet_ids : local.node_subnet_ids

  alb_security_group_id      = try(local.security_groups["alb"], null)
  eks_node_security_group_id = try(local.security_groups["eks_nodes"], null)
  rds_security_group_id      = try(local.security_groups["rds"], null)

  cluster_name    = var.enable_eks ? "${module.shared.project_name}-${var.environment}" : ""
  nodegroup_name  = var.enable_nodegroup ? "${module.shared.project_name}-${var.environment}-ng" : ""
  eks_oidc_issuer = var.enable_eks ? try(module.eks[0].oidc_issuer, "") : ""

  fluent_bit_cluster_name = var.enable_eks ? try(module.eks[0].name, "") : ""
  fluent_bit_kube_host    = local.fluent_bit_cluster_name != "" ? try(module.eks[0].endpoint, "") : ""
  fluent_bit_kube_ca      = local.fluent_bit_cluster_name != "" ? try(module.eks[0].certificate_authority, "") : ""
}

module "eks" {
  count = var.enable_eks ? 1 : 0

  source = "../modules/eks"

  name               = local.cluster_name
  cluster_version    = var.eks_version
  subnet_ids         = local.node_subnet_ids
  security_group_ids = local.alb_security_group_id == null ? [] : [local.alb_security_group_id]
  tags               = module.shared.default_tags
}

module "nodegroup" {
  count = var.enable_nodegroup ? 1 : 0

  depends_on = [module.eks]

  source = "../modules/nodegroup"

  cluster_name   = module.eks[0].name
  name           = local.nodegroup_name
  subnet_ids     = local.node_subnet_ids
  ami_type       = var.node_ami_type
  instance_types = var.node_instance_types
  desired_size   = var.node_desired_size
  min_size       = var.node_min_size
  max_size       = var.node_max_size
  capacity_type  = var.node_capacity_type
  tags           = module.shared.default_tags
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_eks ? 1 : 0

  url             = local.eks_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]
}

resource "aws_iam_policy" "fluent_bit_logs" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  name        = "${module.shared.project_name}-${var.environment}-fluent-bit-logs"
  description = "CloudWatch Logs access for Fluent Bit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "${module.shared.project_name}-${var.environment}-logs"}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "fluent_bit" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  name = "${module.shared.project_name}-${var.environment}-fluent-bit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(local.eks_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:${var.fluent_bit_namespace}:${var.fluent_bit_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  role       = aws_iam_role.fluent_bit[0].name
  policy_arn = aws_iam_policy.fluent_bit_logs[0].arn
}

module "alb" {
  count = var.enable_alb ? 1 : 0

  source = "../modules/alb"

  name              = "${module.shared.project_name}-${var.environment}"
  subnet_ids        = local.alb_subnet_ids
  security_group_id = local.alb_security_group_id
  vpc_id            = local.static_outputs.vpc_id
  listener_port     = var.alb_listener_port
  listener_protocol = var.alb_listener_protocol
  certificate_arn   = var.alb_certificate_arn
  target_port       = var.alb_target_port
  health_check_path = var.alb_health_check_path
  tags              = module.shared.default_tags
}

module "rds" {
  count = var.enable_rds ? 1 : 0

  source = "../modules/rds"

  identifier              = "${module.shared.project_name}-${var.environment}-db"
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  db_name                 = var.rds_db_name
  username                = var.rds_username
  password                = var.rds_password
  multi_az                = var.rds_multi_az
  subnet_ids              = local.db_subnet_ids
  security_group_ids      = local.rds_security_group_id == null ? [] : [local.rds_security_group_id]
  backup_retention_period = var.rds_backup_retention_period
  maintenance_window      = var.rds_maintenance_window
  backup_window           = var.rds_backup_window
  tags                    = module.shared.default_tags
}

module "ecr_vpce" {
  count = var.enable_ecr_vpce ? 1 : 0

  source = "../modules/ecr_vpce"

  vpc_id            = local.static_outputs.vpc_id
  subnet_ids        = local.node_subnet_ids
  security_group_id = local.alb_security_group_id != null ? local.alb_security_group_id : local.eks_node_security_group_id
  region            = var.region
  tags              = module.shared.default_tags
}

module "fluent_bit" {
  count = var.enable_fluent_bit && var.enable_eks ? 1 : 0

  depends_on = [module.eks, module.nodegroup]

  source = "../modules/helm_fluent_bit"

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  iam_role_arn                 = aws_iam_role.fluent_bit[0].arn
  cloudwatch_log_group         = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "${module.shared.project_name}-${var.environment}-logs"
  cloudwatch_log_stream_prefix = var.cloudwatch_log_stream_prefix
  region                       = var.region
  namespace                    = var.fluent_bit_namespace
  service_account_name         = var.fluent_bit_service_account_name
}

module "cloudwatch_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  source = "../modules/cloudwatch_logs"

  name              = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "${module.shared.project_name}-${var.environment}-logs"
  retention_in_days = var.cloudwatch_log_retention_in_days
  stream_names      = var.cloudwatch_log_stream_names
  kms_key_id        = var.cloudwatch_log_kms_key_id
  tags              = module.shared.default_tags
}
