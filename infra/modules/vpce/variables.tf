variable "vpc_id" {
  description = "The ID of the VPC where endpoints will be created."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for interface endpoints."
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "A list of route table IDs for gateway endpoints."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with interface endpoints."
  type        = list(string)
  default     = []
}

variable "interface_services" {
  description = "A list of service names for which to create INTERFACE endpoints."
  type        = list(string)
  default     = []
}

variable "gateway_services" {
  description = "A list of service names for which to create GATEWAY endpoints."
  type        = list(string)
  default     = []
}

variable "private_dns_map" {
  description = "Per-service Private DNS toggle (default true)"
  type        = map(bool)
  default     = {}
}

variable "tags" {
  description = "A map of tags to apply to the resources."
  type        = map(string)
  default     = {}
}
