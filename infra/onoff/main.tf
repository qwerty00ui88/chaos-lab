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

data "terraform_remote_state" "static" {
  backend = "local"

  config = {
    path = "../states/static.tfstate"
  }
}

locals {
  static_outputs = data.terraform_remote_state.static.outputs

  subnet_ids_map  = try(local.static_outputs.private_subnet_ids_map, {})
  security_groups = try(local.static_outputs.security_group_ids, {})

  node_subnet_ids = compact([
    try(local.subnet_ids_map["private-node-a"], null),
    try(local.subnet_ids_map["private-node-b"], null)
  ])

  db_subnet_ids = compact([
    try(local.subnet_ids_map["private-db-a"], null),
    try(local.subnet_ids_map["private-db-b"], null)
  ])

  alb_subnet_ids = local.node_subnet_ids

  alb_security_group_id      = try(local.security_groups["alb"], null)
  eks_node_security_group_id = try(local.security_groups["eks_nodes"], null)
  rds_security_group_id      = try(local.security_groups["rds"], null)

  cluster_name   = var.enable_eks ? "${module.shared.project_name}-${var.environment}" : ""
  nodegroup_name = var.enable_nodegroup ? "${module.shared.project_name}-${var.environment}-ng" : ""
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
