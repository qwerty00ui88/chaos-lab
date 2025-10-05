variable "name" {
  description = "Base name used for tagging VPC resources."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "private_subnets" {
  description = "Map of private subnets to create (key = logical name)."
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "public_subnets" {
  description = "Map of public subnets (key = logical name)."
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}

variable "create_interface_endpoints" {
  description = "Whether to create interface VPC endpoints for core AWS services."
  type        = bool
  default     = true
}

variable "create_s3_gateway_endpoint" {
  description = "Whether to create a gateway VPC endpoint for S3."
  type        = bool
  default     = false
}
