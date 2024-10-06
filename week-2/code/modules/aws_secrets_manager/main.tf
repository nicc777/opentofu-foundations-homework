resource "random_password" "this" {
  length  = var.secret_length
  special = false
}

resource "aws_secretsmanager_secret" "this" {
  name                           = var.secret_name
  description                    = var.secret_description
  recovery_window_in_days        = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = random_password.this.result
}
