variable "region" {
  description = "AWS region for the static infrastructure stack."
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform."
  type        = string
  default     = null
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
      cidr = "10.0.3.0/24"
      az   = "ap-northeast-2a"
    }
    "private-node-b" = {
      cidr = "10.0.4.0/24"
      az   = "ap-northeast-2b"
    }
    "private-db-a" = {
      cidr = "10.0.5.0/24"
      az   = "ap-northeast-2a"
    }
    "private-db-b" = {
      cidr = "10.0.6.0/24"
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
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-2a"
    }
    "public-b" = {
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-2b"
    }
  }
}

variable "enable_dashboard_instance" {
  description = "Whether to provision the EC2 dashboard instance."
  type        = bool
  default     = true
}

variable "dashboard_instance_type" {
  description = "Instance type for the dashboard EC2 host."
  type        = string
  default     = "t3.small"
}

variable "dashboard_key_pair_name" {
  description = "Existing EC2 key pair name for SSH (optional)."
  type        = string
  default     = null
}

variable "dashboard_allowed_cidrs" {
  description = "CIDR blocks allowed to access the dashboard host."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "dashboard_terraform_version" {
  description = "Terraform CLI version installed on the dashboard host"
  type        = string
  default     = "1.7.5"
}

variable "dashboard_kubectl_version" {
  description = "kubectl version (e.g., v1.30.0)"
  type        = string
  default     = "v1.30.0"
}

variable "dashboard_ecr_registry" {
  description = "Default ECR registry URL for dashboard containers"
  type        = string
  default     = ""
}

variable "dashboard_ecr_repository_prefix" {
  description = "ECR repository prefix for dashboard images"
  type        = string
  default     = "chaos-lab"
}

variable "dashboard_eks_cluster_name" {
  description = "EKS cluster name used by dashboard"
  type        = string
  default     = "chaos-lab-dev"
}

variable "dashboard_repo_url" {
  description = "Git repository URL containing dashboard deployment assets"
  type        = string
  default     = ""
}

variable "dashboard_repo_branch" {
  description = "Git branch checked out on the dashboard host"
  type        = string
  default     = "main"
}

variable "dashboard_clone_path" {
  description = "Absolute path where the dashboard repository should be cloned"
  type        = string
  default     = "/opt/chaos-dashboard/app"
}

variable "dashboard_compose_path" {
  description = "Path to the docker-compose file (relative to clone path unless absolute)"
  type        = string
  default     = "deploy/dashboard/docker-compose.yml"
}

variable "dashboard_terraform_client_tag" {
  description = "Container image tag for the terraform-client service"
  type        = string
  default     = "latest"
}

variable "dashboard_chaos_injector_tag" {
  description = "Container image tag for the chaos-injector service"
  type        = string
  default     = "latest"
}

variable "dashboard_log_streamer_tag" {
  description = "Container image tag for the log-streamer service"
  type        = string
  default     = "latest"
}

variable "dashboard_frontend_tag" {
  description = "Container image tag for the dashboard frontend service"
  type        = string
  default     = "latest"
}

variable "dashboard_create_instance_profile" {
  description = "Whether to create an IAM instance profile for the dashboard EC2 host"
  type        = bool
  default     = true
}

variable "dashboard_instance_profile_name" {
  description = "Existing IAM instance profile name to use when not creating a new one"
  type        = string
  default     = null
}

variable "dashboard_iam_managed_policy_arns" {
  description = "Additional IAM managed policy ARNs to attach to the dashboard instance role"
  type        = list(string)
  default     = []
}

variable "dashboard_terraform_state_bucket" {
  description = "S3 bucket storing Terraform state that the dashboard host must access"
  type        = string
  default     = "chaos-lab-terraform-state"
}

variable "dashboard_terraform_lock_table" {
  description = "DynamoDB table used for Terraform state locking that the dashboard host must access"
  type        = string
  default     = "chaos-lab-terraform-locks"
}
