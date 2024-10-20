output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.aws_instance.public_ip
}

output "db_endpoint" {
  description = "Endpoint of the database instance"
  value       = module.aws_db_instance.endpoint
}

output "private_key" {
  value = var.enable_ssh ? module.aws_instance.private_key : ""
  sensitive = true
}
