module "ecr_vpce" {
  count = var.enable_ecr_vpce ? 1 : 0

  source = "../modules/ecr_vpce"

  vpc_id            = local.static_outputs.vpc_id
  subnet_ids        = local.node_subnet_ids
  security_group_id = local.alb_security_group_id != null ? local.alb_security_group_id : local.eks_node_security_group_id
  region            = var.region
  tags              = module.shared.default_tags
}