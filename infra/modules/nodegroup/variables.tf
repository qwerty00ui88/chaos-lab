variable "cluster_name" {
  description = "Name of the EKS cluster to attach to."
  type        = string
}

variable "name" {
  description = "Node group name suffix."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where the node group will run."
  type        = list(string)
}

variable "ami_type" {
  description = "AMI type for the node group."
  type        = string
  default     = "AL2_x86_64"
}

variable "instance_types" {
  description = "EC2 instance types for the node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "desired_size" {
  description = "Desired node count."
  type        = number
  default     = 0
}

variable "min_size" {
  description = "Minimum node count."
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum node count."
  type        = number
  default     = 2
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "tags" {
  description = "Tags to apply to node group resources."
  type        = map(string)
  default     = {}
}
