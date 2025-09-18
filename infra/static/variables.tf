variable "region" {
  description = "AWS region for the static infrastructure stack."
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform."
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment suffix for naming (e.g., dev, staging)."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Map describing private subnets across AZs."
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "private-node-a" = {
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-2a"
    }
    "private-node-b" = {
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-2b"
    }
    "private-db-a" = {
      cidr = "10.0.3.0/24"
      az   = "ap-northeast-2a"
    }
    "private-db-b" = {
      cidr = "10.0.4.0/24"
      az   = "ap-northeast-2b"
    }
  }
}
