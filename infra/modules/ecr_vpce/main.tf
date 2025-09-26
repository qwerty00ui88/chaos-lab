locals {
  base_tags = merge(var.tags, {
    Component = "ecr-vpce"
  })

  services = {
    api = "com.amazonaws.${var.region}.ecr.api"
    dkr = "com.amazonaws.${var.region}.ecr.dkr"
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.services

  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = merge(local.base_tags, {
    Service = each.key
  })
}
