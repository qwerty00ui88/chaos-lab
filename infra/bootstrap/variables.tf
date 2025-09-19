variable "region" {
  description = "AWS region where the backend resources will live."
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use."
  type        = string
  default     = "default"
}

variable "state_bucket_name" {
  description = "S3 bucket name that will store Terraform state files."
  type        = string
  default     = "chaos-lab-terraform-state"
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
  default     = "chaos-lab-terraform-locks"
}

variable "tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default = {
    Project = "chaos-lab"
    Managed = "terraform"
  }
}
