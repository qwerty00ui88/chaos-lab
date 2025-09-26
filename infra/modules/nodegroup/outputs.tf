output "name" {
  description = "EKS node group name."
  value       = aws_eks_node_group.this.node_group_name
}

output "arn" {
  description = "ARN of the node group."
  value       = aws_eks_node_group.this.arn
}

output "role_arn" {
  description = "IAM role ARN used by the node group."
  value       = aws_iam_role.node.arn
}
