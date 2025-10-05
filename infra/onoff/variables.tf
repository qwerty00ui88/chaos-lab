variable "region" {
  description = "AWS region for toggle stack operations."
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

variable "enable_eks" {
  description = "Whether to create the EKS control plane."
  type        = bool
  default     = false
}

variable "enable_nodegroup" {
  description = "Whether to create the EKS managed node group."
  type        = bool
  default     = false
}

variable "enable_alb" {
  description = "Whether to create the Application Load Balancer."
  type        = bool
  default     = false
}

variable "enable_rds" {
  description = "Whether to create the RDS instance."
  type        = bool
  default     = false
}

variable "enable_ecr_vpce" {
  description = "Whether to create the ECR interface VPC endpoints."
  type        = bool
  default     = false
}

variable "enable_s3_gateway_endpoint" {
  description = "Whether to create an S3 gateway VPC endpoint for private subnets."
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Whether to create a CloudWatch log group for target application logs."
  type        = bool
  default     = false
}

variable "enable_fluent_bit" {
  description = "Deploy aws-for-fluent-bit via Helm when EKS is enabled."
  type        = bool
  default     = false
}

variable "enable_aws_load_balancer_controller" {
  description = "Deploy AWS Load Balancer Controller when EKS is enabled."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Optional name for the CloudWatch log group. Defaults to <project>-<env>-logs."
  type        = string
  default     = ""
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention period for CloudWatch logs."
  type        = number
  default     = 14
}

variable "cloudwatch_log_stream_names" {
  description = "Set of log stream names to pre-create for services."
  type        = set(string)
  default     = []
}

variable "cloudwatch_log_kms_key_id" {
  description = "Optional KMS key ARN for encrypting the log group."
  type        = string
  default     = null
}

variable "cloudwatch_log_stream_prefix" {
  description = "Prefix for CloudWatch log streams created by Fluent Bit"
  type        = string
  default     = "svc-"
}

variable "fluent_bit_namespace" {
  description = "Namespace to install Fluent Bit."
  type        = string
  default     = "aws-for-fluent-bit"
}

variable "fluent_bit_service_account_name" {
  description = "Service account name for Fluent Bit."
  type        = string
  default     = "aws-for-fluent-bit"
}

variable "eks_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.30"
}

variable "node_desired_size" {
  description = "Desired node count for the node group when enabled."
  type        = number
  default     = 0
}

variable "node_min_size" {
  description = "Minimum node count for the node group."
  type        = number
  default     = 0
}

variable "node_max_size" {
  description = "Maximum node count for the node group."
  type        = number
  default     = 3
}

variable "node_instance_types" {
  description = "Instance types for the node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_ami_type" {
  description = "AMI type for the node group."
  type        = string
  default     = "AL2_x86_64"
}

variable "target_app_image_tag" {
  description = "Docker image tag for the target application services."
  type        = string
  default     = "latest"
}

variable "ecr_repository_prefix" {
  description = "Prefix applied to ECR repositories for target app services (e.g., chaos-lab)."
  type        = string
  default     = "chaos-lab"
}

variable "alb_listener_port" {
  description = "Listener port for the ALB."
  type        = number
  default     = 80
}

variable "alb_listener_protocol" {
  description = "Listener protocol for the ALB (HTTP/HTTPS)."
  type        = string
  default     = "HTTP"
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)."
  type        = string
  default     = ""
}

variable "alb_target_port" {
  description = "Target group port."
  type        = number
  default     = 80
}

variable "alb_health_check_path" {
  description = "Health check path for the ALB target group."
  type        = string
  default     = "/"
}

variable "rds_engine" {
  description = "RDS engine type."
  type        = string
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "RDS engine version."
  type        = string
  default     = "8.0"
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage (GB)."
  type        = number
  default     = 20
}

variable "rds_db_name" {
  description = "Initial database name."
  type        = string
  default     = "chaoslab"
}

variable "rds_username" {
  description = "Master username for RDS."
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "Master password for RDS."
  type        = string
  sensitive   = true
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days."
  type        = number
  default     = 7
}

variable "rds_maintenance_window" {
  description = "Preferred maintenance window."
  type        = string
  default     = "sun:17:00-sun:19:00"
}

variable "rds_backup_window" {
  description = "Preferred backup window."
  type        = string
  default     = "01:00-03:00"
}
