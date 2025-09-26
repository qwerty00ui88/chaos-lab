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

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_ids_map" {
  description = "Map of public subnet IDs keyed by logical name."
  value       = module.vpc.public_subnet_ids_map
}

output "security_group_ids" {
  description = "Security group IDs for ALB, EKS nodes, and RDS."
  value       = module.vpc.security_group_ids
}

output "dashboard_public_ip" {
  description = "Public IP address of the dashboard EC2 host"
  value       = var.enable_dashboard_instance ? module.dashboard_instance[0].public_ip : null
}

output "dashboard_instance_id" {
  description = "Instance ID of the dashboard EC2 host"
  value       = var.enable_dashboard_instance ? module.dashboard_instance[0].instance_id : null
}
