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

module "vpc" {
  source = "../modules/vpc"

  name            = "${module.shared.project_name}-${var.environment}"
  cidr_block      = var.vpc_cidr
  private_subnets = var.private_subnets
  tags            = module.shared.default_tags
}
