output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this[0].id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = [aws_instance.this.*.public_ip]
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}

output "private_key" {
  value = var.enable_ssh ? tls_private_key.ssh[0].private_key_pem : ""
  sensitive = true
}

