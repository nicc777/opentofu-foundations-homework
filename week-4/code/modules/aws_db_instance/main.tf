data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

resource "aws_db_instance" "this" {
  identifier             = var.name_prefix
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  vpc_security_group_ids = [aws_security_group.this.id]
  skip_final_snapshot    = true

  tags = var.tags

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-wordpress"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "${var.name_prefix}-wordpress_server_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_cidr_access" {
  count             = var.source_security_group_id != "" && var.source_security_group_id != null ? 0 : 1
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
  description       = "DB access from VPC CIDR"
}

resource "aws_security_group_rule" "ingress" {
  count                    = var.source_security_group_id != "" && var.source_security_group_id != null ? 1 : 0
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "user_cidr_access" {
  for_each          = length(var.ingress_cidr_blocks) > 0 ? { for idx, val in var.ingress_cidr_blocks : idx => val } : {}
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
  description       = "DB access from user supplied CIDR block ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow egress to ANY"
}

