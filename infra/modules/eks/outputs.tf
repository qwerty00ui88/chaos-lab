output "name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "endpoint" {
  description = "EKS cluster API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "certificate_authority" {
  description = "EKS cluster certificate authority data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_issuer" {
  description = "OIDC issuer URL for the cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  value       = aws_iam_role.cluster.arn
}

output "cluster_security_group_id" {
  description = "Security group ID associated with the EKS control plane."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
