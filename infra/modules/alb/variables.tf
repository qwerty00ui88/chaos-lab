variable "name" {
  description = "Base name for ALB resources."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where the ALB will be placed."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the ALB."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group."
  type        = string
}

variable "listener_port" {
  description = "Port for the ALB listener."
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Protocol for the ALB listener (HTTP or HTTPS)."
  type        = string
  default     = "HTTP"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (optional)."
  type        = string
  default     = ""
}

variable "target_port" {
  description = "Port on the target group."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path for the target group."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
