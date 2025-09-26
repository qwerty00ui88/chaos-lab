variable "name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "EKS control plane version."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane endpoints."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Additional security groups for the control plane."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all EKS resources."
  type        = map(string)
  default     = {}
}
