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

locals {
  dashboard_user_data = var.enable_dashboard_instance ? templatefile(
    "../modules/ec2_dashboard/templates/user_data.sh.tpl",
    {
      terraform_version      = var.dashboard_terraform_version
      kubectl_version        = var.dashboard_kubectl_version
      aws_region             = var.region
      ecr_registry           = var.dashboard_ecr_registry
      ecr_repository_prefix  = var.dashboard_ecr_repository_prefix
      eks_cluster_name       = var.dashboard_eks_cluster_name
      dashboard_repo_url     = var.dashboard_repo_url
      dashboard_repo_branch  = var.dashboard_repo_branch
      dashboard_clone_path   = var.dashboard_clone_path
      dashboard_compose_path = var.dashboard_compose_path
      terraform_client_tag   = var.dashboard_terraform_client_tag
      chaos_injector_tag     = var.dashboard_chaos_injector_tag
      log_streamer_tag       = var.dashboard_log_streamer_tag
      frontend_tag           = var.dashboard_frontend_tag
    }
  ) : ""
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = module.shared.default_tags
  }
}

module "vpc" {
  source = "../modules/vpc"

  name                       = "${module.shared.project_name}-${var.environment}"
  cidr_block                 = var.vpc_cidr
  private_subnets            = var.private_subnets
  public_subnets             = var.public_subnets
  tags                       = module.shared.default_tags
  create_interface_endpoints = false
  create_s3_gateway_endpoint = false
}

module "dashboard_instance" {
  count = var.enable_dashboard_instance ? 1 : 0

  source = "../modules/ec2_dashboard"

  name                    = "${module.shared.project_name}-${var.environment}-dashboard"
  subnet_id               = module.vpc.public_subnet_ids[0]
  vpc_id                  = module.vpc.vpc_id
  instance_type           = var.dashboard_instance_type
  key_name                = var.dashboard_key_pair_name
  allowed_cidrs           = var.dashboard_allowed_cidrs
  user_data               = local.dashboard_user_data
  create_instance_profile = var.dashboard_create_instance_profile
  instance_profile_name   = var.dashboard_instance_profile_name
  iam_managed_policy_arns = var.dashboard_iam_managed_policy_arns
  tags                    = module.shared.default_tags
}
