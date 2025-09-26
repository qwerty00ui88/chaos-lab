output "endpoint_ids" {
  description = "Map of VPC endpoint IDs keyed by service type."
  value       = { for key, endpoint in aws_vpc_endpoint.this : key => endpoint.id }
}

output "network_interface_ids" {
  description = "Map of network interface IDs for each endpoint."
  value       = { for key, endpoint in aws_vpc_endpoint.this : key => endpoint.network_interface_ids }
}
