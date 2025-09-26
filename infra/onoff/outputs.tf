output "eks_cluster_name" {
  description = "Name of the EKS cluster (if enabled)."
  value       = var.enable_eks ? module.eks[0].name : null
}

output "eks_cluster_endpoint" {
  description = "API endpoint of the EKS cluster (if enabled)."
  value       = var.enable_eks ? module.eks[0].endpoint : null
}

output "eks_oidc_issuer" {
  description = "OIDC issuer URL for the EKS cluster (if enabled)."
  value       = var.enable_eks ? module.eks[0].oidc_issuer : null
}

output "nodegroup_name" {
  description = "Name of the node group (if enabled)."
  value       = var.enable_nodegroup ? module.nodegroup[0].name : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (if enabled)."
  value       = var.enable_alb ? module.alb[0].alb_dns_name : null
}

output "alb_target_group_arn" {
  description = "Target group ARN for the ALB (if enabled)."
  value       = var.enable_alb ? module.alb[0].target_group_arn : null
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance (if enabled)."
  value       = var.enable_rds ? module.rds[0].endpoint : null
}

output "ecr_vpc_endpoint_ids" {
  description = "Map of ECR VPC endpoint IDs (if enabled)."
  value       = var.enable_ecr_vpce ? module.ecr_vpce[0].endpoint_ids : null
}
