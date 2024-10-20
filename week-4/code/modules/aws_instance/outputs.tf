output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}

output "private_key" {
  value = var.enable_ssh ? tls_private_key.ssh[0].private_key_pem : ""
  sensitive = true
}

