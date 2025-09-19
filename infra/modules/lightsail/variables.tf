variable "name" {
  description = "Lightsail instance name"
  type        = string
}

variable "availability_zone" {
  description = "Lightsail availability zone (e.g., ap-northeast-2a)"
  type        = string
}

variable "blueprint_id" {
  description = "Lightsail blueprint ID (e.g., ubuntu_22_04)"
  type        = string
  default     = "ubuntu_22_04"
}

variable "bundle_id" {
  description = "Lightsail bundle ID (e.g., nano_2_0)"
  type        = string
  default     = "nano_2_0"
}

variable "key_pair_name" {
  description = "Existing Lightsail key pair name (optional)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Cloud-init script to bootstrap the instance"
  type        = string
  default     = ""
}

variable "enable_static_ip" {
  description = "Whether to allocate and attach a static IP"
  type        = bool
  default     = true
}

variable "public_ports" {
  description = "List of public ports to expose"
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
    }
  ]
}

variable "tags" {
  description = "Tags to apply to Lightsail resources"
  type        = map(string)
  default     = {}
}
