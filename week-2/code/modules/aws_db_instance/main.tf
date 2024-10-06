
resource "aws_db_subnet_group" "this" {
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids
  tags = {
    Name = var.db_subnet_group_name
  }
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name_prefix}-db"
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  engine                  = var.engine
  engine_version          = var.engine_version
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  skip_final_snapshot     = true
  backup_retention_period = var.backup_retention_period
  availability_zone       = var.availability_zone
  vpc_security_group_ids  = [var.db_scurity_group_id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = true
  tags                    = var.tags
}



