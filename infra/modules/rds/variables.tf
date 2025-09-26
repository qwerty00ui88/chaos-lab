variable "identifier" {
  description = "RDS instance identifier."
  type        = string
}

variable "engine" {
  description = "Database engine (e.g., mysql, postgres)."
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database engine version."
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "chaoslab"
}

variable "username" {
  description = "Master username."
  type        = string
}

variable "password" {
  description = "Master password."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the instance."
  type        = list(string)
}

variable "backup_retention_period" {
  description = "Backup retention in days."
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Preferred maintenance window."
  type        = string
  default     = "sun:17:00-sun:19:00"
}

variable "backup_window" {
  description = "Preferred backup window."
  type        = string
  default     = "01:00-03:00"
}

variable "tags" {
  description = "Tags applied to RDS resources."
  type        = map(string)
  default     = {}
}
