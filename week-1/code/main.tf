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

resource "aws_instance" "this" {
  ami                    = "ami-08578967e04feedea"
  vpc_security_group_ids = [aws_security_group.wordpress.id]

  # Free Tier: t2.micro 750 hours / month - 12 months
  instance_type               = "t2.micro"
  associate_public_ip_address = true

  tags = {
    Name = var.name_prefix
  }

  user_data = <<-EOF
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
  publicly_accessible    = length(var.enable_public_mariadb_access) != 0
  vpc_security_group_ids = [aws_security_group.mariadb.id]
  skip_final_snapshot    = true
}

resource "aws_security_group" "wordpress" {
  name        = "${var.name_prefix}-wordpress"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.trusted_cidrs_for_wordpress_access
  }

  # Needs to be able to get to docker hub to download images
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mariadb" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = concat([data.aws_vpc.default.cidr_block], var.enable_public_mariadb_access)
  }
}
