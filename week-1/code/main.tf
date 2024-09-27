data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_secretsmanager_random_password" "this" {
  # RDS password has a max limit of 41 characters - https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html#RDS_Limits.Constraints
  password_length = 40
  exclude_punctuation = true
}

data "aws_secretsmanager_secret_version" "this" {
  depends_on = [
    aws_secretsmanager_secret_version.this
  ]
  secret_id = aws_secretsmanager_secret.this.id
}

resource "aws_iam_instance_profile" "this" {
  name = "wordpress_profile"
  role = aws_iam_role.this.name
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "wordpress_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_launch_template" "wordpress" {
  name = "wordpress-lt"
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  image_id = "ami-08578967e04feedea"
  instance_type = "t2.micro"
  key_name = var.ssh_keypair_name
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  network_interfaces {
    associate_public_ip_address = true
  }
  vpc_security_group_ids = [aws_security_group.wordpress.id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name_prefix}-wordpress"
    }
  }
  user_data = base64encode(
    <<-EOF
      #!/bin/bash
      yum update -y
      amazon-linux-extras install docker -y
      service docker start
      usermod -a -G docker ec2-user
      docker run -d \
        -e WORDPRESS_DB_HOST=${aws_db_instance.this.endpoint} \
        -e WORDPRESS_DB_USER=admin \
        -e WORDPRESS_DB_PASSWORD=${data.aws_secretsmanager_secret_version.this.secret_string} \
        -e WORDPRESS_DB_NAME=wordpress \
        -p 80:80 ${var.image.name}:${var.image.tag}
    EOF
  )
}

# Using the default VPC, ensure at least one public subnet has a tagged named "experimental" with a value of "1""
data "aws_subnet" "this" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name = "tag:experimental"
    values = [ "1" ]
  }
  
}

resource "aws_autoscaling_group" "this" {
  launch_template {
    id         = aws_launch_template.wordpress.id
    version    = "$Latest"
  }
  min_size    = 1
  max_size    = 1
  desired_capacity = 1
  vpc_zone_identifier = [data.aws_subnet.this.id]
}

resource "aws_secretsmanager_secret" "this" {
  name = "wordpress_master_db_password"
  description = "Master password for wordpress database"
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = data.aws_secretsmanager_random_password.this.random_password
}

resource "aws_db_instance" "this" {
  identifier = var.name_prefix

  ### Free Tier: db.t2.micro 750 hours / month - 12 months
  instance_class = "db.t3.micro" # Change to desired instance size

  # Free Tier: 20GB storage
  allocated_storage = 20 # Storage size in GB

  engine = "mariadb"
  # Wordpress 6 https://make.wordpress.org/hosting/handbook/compatibility/
  engine_version = "10.6"

  db_name  = "wordpress"
  username = "admin"

  password               = data.aws_secretsmanager_secret_version.this.secret_string
  publicly_accessible    = var.enable_public_mariadb_access
  vpc_security_group_ids = [aws_security_group.mariadb.id]
  skip_final_snapshot    = true
}

resource "aws_security_group" "wordpress" {
  name        = "${var.name_prefix}-wordpress"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "wordpress_server_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "wordpress_allow_http_ipv4" {
  security_group_id = aws_security_group.wordpress.id
  cidr_ipv4         = var.trusted_cidrs_for_wordpress_access
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "wordpress_allow_ssh_ipv4" {
  security_group_id = aws_security_group.wordpress.id
  cidr_ipv4         = var.trusted_cidrs_for_wordpress_access
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "wordpress_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.wordpress.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "mariadb" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "wordpress_db_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_maria_db_ipv4_app" {
  security_group_id = aws_security_group.mariadb.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_maria_db_ipv4_trusted" {
  count             = var.enable_public_mariadb_access ? 1 : 0
  security_group_id = aws_security_group.mariadb.id
  cidr_ipv4         = var.trusted_cidrs_for_wordpress_access
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rds_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.mariadb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
