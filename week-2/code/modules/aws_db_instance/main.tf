
resource "aws_db_instance" "this" {
  identifier              = var.name_prefix
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  engine                  = var.engine
  engine_version          = var.engine_version
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  vpc_security_group_ids  = [var.db_scurity_group_id]  ###
  skip_final_snapshot     = true

  backup_retention_period = var.backup_retention_period
  availability_zone       = var.availability_zone

  tags = var.tags
}



