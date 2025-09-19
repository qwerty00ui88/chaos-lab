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
  lightsail_user_data = var.enable_lightsail ? templatefile(
    "../modules/lightsail/templates/user_data.sh.tpl",
    {
      terraform_version     = var.lightsail_terraform_version
      kubectl_version       = var.lightsail_kubectl_version
      aws_region            = var.region
      ecr_registry          = var.lightsail_ecr_registry
      ecr_repository_prefix = var.lightsail_ecr_repository_prefix
      eks_cluster_name      = var.lightsail_eks_cluster_name
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

  name            = "${module.shared.project_name}-${var.environment}"
  cidr_block      = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  tags            = module.shared.default_tags
}

module "lightsail_dashboard" {
  count = var.enable_lightsail ? 1 : 0

  source = "../modules/lightsail"

  name              = "${module.shared.project_name}-${var.environment}-dashboard"
  availability_zone = var.lightsail_az
  blueprint_id      = var.lightsail_blueprint_id
  bundle_id         = var.lightsail_bundle_id
  key_pair_name     = var.lightsail_key_pair_name
  enable_static_ip  = true
  public_ports      = var.lightsail_allowed_ports
  user_data         = local.lightsail_user_data
  tags              = module.shared.default_tags
}
