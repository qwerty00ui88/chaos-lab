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

variable "public_subnets" {
  description = "Map describing public subnets across AZs."
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "public-a" = {
      cidr = "10.0.10.0/24"
      az   = "ap-northeast-2a"
    }
    "public-b" = {
      cidr = "10.0.11.0/24"
      az   = "ap-northeast-2b"
    }
  }
}

variable "enable_lightsail" {
  description = "Whether to provision the Lightsail dashboard instance."
  type        = bool
  default     = true
}

variable "lightsail_az" {
  description = "Lightsail availability zone"
  type        = string
  default     = "ap-northeast-2a"
}

variable "lightsail_blueprint_id" {
  description = "Lightsail blueprint ID"
  type        = string
  default     = "ubuntu_22_04"
}

variable "lightsail_bundle_id" {
  description = "Lightsail bundle ID"
  type        = string
  default     = "nano_2_0"
}

variable "lightsail_key_pair_name" {
  description = "Existing Lightsail key pair name for SSH (optional)"
  type        = string
  default     = null
}

variable "lightsail_allowed_ports" {
  description = "Public ports exposed on the Lightsail instance"
  type = list(object({
    from     = number
    to       = number
    protocol = string
  }))
  default = [
    {
      from     = 80
      to       = 80
      protocol = "tcp"
    },
    {
      from     = 443
      to       = 443
      protocol = "tcp"
    }
  ]
}

variable "lightsail_terraform_version" {
  description = "Terraform CLI version installed on Lightsail"
  type        = string
  default     = "1.7.5"
}

variable "lightsail_kubectl_version" {
  description = "kubectl version (e.g., v1.30.0)"
  type        = string
  default     = "v1.30.0"
}

variable "lightsail_ecr_registry" {
  description = "Default ECR registry URL for dashboard containers"
  type        = string
  default     = ""
}

variable "lightsail_ecr_repository_prefix" {
  description = "ECR repository prefix for dashboard images"
  type        = string
  default     = "chaos-lab"
}

variable "lightsail_eks_cluster_name" {
  description = "EKS cluster name used by dashboard"
  type        = string
  default     = "chaos-lab-dev"
}
