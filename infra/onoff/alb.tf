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