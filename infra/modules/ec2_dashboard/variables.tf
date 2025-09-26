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
