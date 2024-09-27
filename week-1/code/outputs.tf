output "rds_endpoint" {
  description = "MariaDB RDS Endpoint"
  value       = aws_db_instance.this.endpoint
}
