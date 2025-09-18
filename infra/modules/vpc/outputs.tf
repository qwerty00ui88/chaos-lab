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

output "security_group_ids" {
  description = "Security group IDs for ALB, EKS nodes, and RDS."
  value = {
    alb       = aws_security_group.alb.id
    eks_nodes = aws_security_group.eks_nodes.id
    rds       = aws_security_group.rds.id
  }
}
