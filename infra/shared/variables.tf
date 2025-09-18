variable "region" {
  description = "AWS region used across stacks."
  type        = string
}

variable "environment" {
  description = "Environment name tag applied to shared resources."
  type        = string
  default     = "dev"
}
