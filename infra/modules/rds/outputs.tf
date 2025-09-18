output "endpoint" {
  description = "RDS endpoint address."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS endpoint port."
  value       = aws_db_instance.this.port
}

output "arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_subnet_group" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}
