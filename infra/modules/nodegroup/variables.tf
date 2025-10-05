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

variable "security_group_id" {
  description = "Security group ID to associate with the worker nodes."
  type        = string
}

variable "ami_type" {
  description = "AMI type for the node group. Used to find the AMI ID if not provided."
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

variable "node_labels" {
  description = "Optional node labels to apply during bootstrap."
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Optional taints to register with during bootstrap (format: key=value:effect)."
  type        = list(string)
  default     = []
}

variable "kubelet_extra_args" {
  description = "Additional arguments to pass to kubelet via bootstrap script."
  type        = string
  default     = ""
}
