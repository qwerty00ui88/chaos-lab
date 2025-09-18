output "default_tags" {
  description = "Standard tag map applied to shared resources."
  value       = local.default_tags
}

output "project_name" {
  description = "Canonical project name for resource naming."
  value       = local.project_name
}
