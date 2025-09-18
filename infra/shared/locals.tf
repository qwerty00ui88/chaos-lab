// Shared naming conventions appear here.
locals {
  tags = {
    Project     = "chaos-lab"
    Environment = var.environment
  }
}
