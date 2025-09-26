variable "name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "retention_in_days" {
  description = "Log retention period"
  type        = number
  default     = 14
}

variable "stream_names" {
  description = "Optional set of log stream names to pre-create"
  type        = set(string)
  default     = []
}

variable "kms_key_id" {
  description = "Optional KMS key for encrypting the log group"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the log group"
  type        = map(string)
  default     = {}
}
