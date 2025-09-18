locals {
  project_name = "chaos-lab"

  default_tags = {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
