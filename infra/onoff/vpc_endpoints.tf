resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_s3_gateway_endpoint && local.vpc_id != null && local.private_route_table_id != null ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [local.private_route_table_id]

  tags = merge(module.shared.default_tags, {
    Component = "vpc-endpoint"
    Service   = "s3"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.node_subnet_ids
  security_group_ids  = [local.eks_node_security_group_id]
  private_dns_enabled = true

  tags = merge(module.shared.default_tags, {
    Component = "vpc-endpoint"
    Service   = each.value.service
  })
}
