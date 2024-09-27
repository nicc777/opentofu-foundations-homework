output "rds_endpoint" {
  description = "MariaDB RDS Endpoint"
  value       = aws_db_instance.this.endpoint
}

output "rds_username" {
  description = "MariaDB RDS Username"
  value       = "${random_pet.db_username.id}"
}
