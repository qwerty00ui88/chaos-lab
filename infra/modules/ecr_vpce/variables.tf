variable "vpc_id" {
  description = "VPC ID where the VPC endpoints will be created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the interface endpoints."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group applied to the interface endpoints."
  type        = string
}

variable "region" {
  description = "AWS region (used to build service names)."
  type        = string
}

variable "tags" {
  description = "Tags applied to VPC endpoint resources."
  type        = map(string)
  default     = {}
}
