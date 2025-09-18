output "vpc_id" {
  description = "VPC ID provisioned by the static stack."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_ids_map" {
  description = "Map of private subnet IDs keyed by logical name."
  value       = module.vpc.private_subnet_ids_map
}

output "security_group_ids" {
  description = "Security group IDs for ALB, EKS nodes, and RDS."
  value       = module.vpc.security_group_ids
}
