output "instance_id" {
  description = "ID of the dashboard EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the dashboard EC2 instance"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS name of the dashboard EC2 instance"
  value       = aws_instance.this.public_dns
}

output "security_group_id" {
  description = "Security group ID associated with the dashboard EC2 host"
  value       = aws_security_group.dashboard.id
}
