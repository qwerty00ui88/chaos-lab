variable "region" {
  description = "AWS region for deployments."
  type        = string
}

variable "aws_profile" {
  description = "Named AWS CLI profile for Terraform authentication."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name tag applied to shared resources."
  type        = string
  default     = "dev"
}
