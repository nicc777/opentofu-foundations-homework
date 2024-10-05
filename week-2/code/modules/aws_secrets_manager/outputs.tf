output "secret_id" {
  description = "ID of the security group"
  value = aws_secretsmanager_secret.this.id
}
