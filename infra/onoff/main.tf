terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

check "nodegroup_requires_eks" {
  assert {
    condition     = !(var.enable_nodegroup && !var.enable_eks)
    error_message = "enable_nodegroup=true requires enable_eks=true."
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
  profile = var.aws_profile != null && var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = module.shared.default_tags
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

  subnet_ids_map         = try(local.static_outputs.private_subnet_ids_map, {})
  security_groups        = try(local.static_outputs.security_group_ids, {})
  private_route_table_id = try(local.static_outputs.private_route_table_id, null)
  public_route_table_id  = try(local.static_outputs.public_route_table_id, null)
  vpc_id                 = try(local.static_outputs.vpc_id, null)

  private_subnet_ids = try(local.static_outputs.private_subnet_ids, [])
  public_subnet_ids  = try(local.static_outputs.public_subnet_ids, [])
  vpce_subnet_ids    = try(local.static_outputs.vpce_subnet_ids, [])

  node_subnets_from_map = compact([
    try(local.subnet_ids_map["private-node-a"], null),
    try(local.subnet_ids_map["private-node-b"], null)
  ])

  db_subnets_from_map = compact([
    try(local.subnet_ids_map["private-db-a"], null),
    try(local.subnet_ids_map["private-db-b"], null)
  ])

  node_subnet_ids = length(local.node_subnets_from_map) > 0 ? local.node_subnets_from_map : local.private_subnet_ids
  db_subnet_ids   = length(local.db_subnets_from_map) > 0 ? local.db_subnets_from_map : local.private_subnet_ids

  alb_subnet_ids = length(local.public_subnet_ids) > 0 ? local.public_subnet_ids : local.node_subnet_ids

  alb_security_group_id         = try(local.security_groups["alb"], null)
  eks_node_security_group_id    = try(local.security_groups["eks_nodes"], null)
  rds_security_group_id         = try(local.security_groups["rds"], null)
  eks_cluster_security_group_id = var.enable_eks ? try(module.eks[0].cluster_security_group_id, null) : null

  cluster_name   = var.enable_eks ? "${module.shared.project_name}-${var.environment}" : ""
  nodegroup_name = var.enable_nodegroup ? "${module.shared.project_name}-${var.environment}-ng" : ""

  eks_oidc_issuer = var.enable_eks ? try(module.eks[0].oidc_issuer, "") : ""

  eks_cluster_endpoint = var.enable_eks ? try(data.aws_eks_cluster.eks["main"].endpoint, "") : ""
  eks_cluster_ca_data  = var.enable_eks ? try(data.aws_eks_cluster.eks["main"].certificate_authority[0].data, "") : ""
  eks_cluster_token    = var.enable_eks ? try(data.aws_eks_cluster_auth.eks["main"].token, "") : ""

  fluent_bit_cluster_name = var.enable_eks ? try(data.aws_eks_cluster.eks["main"].name, local.cluster_name) : ""
  fluent_bit_kube_host    = local.eks_cluster_endpoint
  fluent_bit_kube_ca      = local.eks_cluster_ca_data
  fluent_bit_kube_token   = local.eks_cluster_token

  frontend_dist_path = "../../target-app/frontend/dist"
  frontend_files     = try(fileset(local.frontend_dist_path, "**/*"), [])
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".ico"  = "image/x-icon"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
  }
}

module "vpce" {
  source = "../modules/vpce"

  vpc_id             = local.vpc_id
  subnet_ids         = local.vpce_subnet_ids
  security_group_ids = [local.eks_node_security_group_id]
  tags               = module.shared.default_tags

  interface_services = var.enable_eks && var.enable_nodegroup ? ["logs"] : []
}

data "aws_eks_cluster" "eks" {
  for_each = var.enable_eks ? { main = module.eks[0].name } : {}

  name = each.value

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  for_each = var.enable_eks ? { main = module.eks[0].name } : {}

  name = each.value

  depends_on = [module.eks]
}

provider "kubernetes" {
  alias = "eks"

  host                   = local.fluent_bit_kube_host
  cluster_ca_certificate = local.fluent_bit_kube_ca != "" ? base64decode(local.fluent_bit_kube_ca) : null
  token                  = local.fluent_bit_kube_token != "" ? local.fluent_bit_kube_token : null
}

provider "helm" {
  alias = "eks"

  kubernetes = {
    host                   = local.fluent_bit_kube_host
    cluster_ca_certificate = local.fluent_bit_kube_ca != "" ? base64decode(local.fluent_bit_kube_ca) : null
    token                  = local.fluent_bit_kube_token != "" ? local.fluent_bit_kube_token : null
  }
}
