variable "name" {
  description = "Name prefix for the EC2 dashboard instance."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where the dashboard instance will be placed."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group attachment."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the dashboard host."
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access the dashboard (HTTP/HTTPS/SSH)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "user_data" {
  description = "Bootstrap script rendered for the dashboard host."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Base tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "create_instance_profile" {
  description = "Whether to create an IAM instance profile with ECR/SSM access for the dashboard host."
  type        = bool
  default     = true
}

variable "instance_profile_name" {
  description = "Existing IAM instance profile name to attach when not creating one."
  type        = string
  default     = null

  validation {
    condition     = var.create_instance_profile || var.instance_profile_name != null
    error_message = "instance_profile_name must be provided when create_instance_profile is false."
  }
}

variable "iam_managed_policy_arns" {
  description = "Additional IAM managed policy ARNs to attach when creating the instance profile."
  type        = list(string)
  default     = []

  validation {
    condition     = var.create_instance_profile || length(var.iam_managed_policy_arns) == 0
    error_message = "iam_managed_policy_arns can only be set when create_instance_profile is true."
  }
}

variable "terraform_state_bucket" {
  description = "Name of the S3 bucket storing Terraform state that the dashboard host must access."
  type        = string
  default     = null
}
