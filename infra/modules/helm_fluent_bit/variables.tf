variable "namespace" {
  description = "Namespace to install Fluent Bit"
  type        = string
  default     = "aws-for-fluent-bit"
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "aws-for-fluent-bit"
}

variable "iam_role_arn" {
  description = "IAM role ARN attached via IRSA"
  type        = string
}

variable "cloudwatch_log_group" {
  description = "Target CloudWatch log group"
  type        = string
}

variable "cloudwatch_log_stream_prefix" {
  description = "Log stream prefix"
  type        = string
  default     = "svc-"
}

variable "region" {
  description = "AWS region"
  type        = string
}
