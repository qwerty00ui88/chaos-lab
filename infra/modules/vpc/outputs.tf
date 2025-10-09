output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnet_ids_map" {
  description = "Map of private subnet IDs keyed by logical name."
  value       = { for key, subnet in aws_subnet.private : key => subnet.id }
}

output "private_subnet_arns_map" {
  description = "Map of private subnet ARNs keyed by logical name."
  value       = { for key, subnet in aws_subnet.private : key => subnet.arn }
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "public_subnet_ids_map" {
  description = "Map of public subnet IDs keyed by logical name."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "security_group_ids" {
  description = "Security group IDs for ALB, EKS nodes, VPC endpoints, and RDS."
  value = {
    alb       = aws_security_group.alb.id
    eks_nodes = aws_security_group.eks_nodes.id
    vpce      = aws_security_group.vpce.id
    rds       = aws_security_group.rds.id
  }
}

output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = [aws_route_table.private.id]
}

output "public_route_table_id" {
  description = "ID of the public route table if created, otherwise null."
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "vpce_subnet_ids" {
  description = "List of private subnet IDs for VPC endpoints, one per AZ."
  value       = local.vpce_subnet_ids
}
