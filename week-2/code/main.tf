terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      environment = "dev"
      project     = "opentofu-foundations"
    }
  }
}

# Get the default VPC
data "aws_vpc" "default" {
  filter {
    name = "isDefault"
    values = ["true"]
  }
}

# Get the secret
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = module.db_password.secret_id
}

# Get the available AZ's
data "aws_availability_zones" "available" {
  state = "available"
}

# Select a random AZ for our variable
resource "random_shuffle" "aws_availability_zone_name" {
  input        = data.aws_availability_zones.available.names
  result_count = 1
}

# Module for Database Instance
module "aws_db_instance" {
  source = "./modules/aws_db_instance"

  name_prefix = "week2-db"
  db_name     = "wordpress"
  username    = "admin"
  password    = data.aws_secretsmanager_secret_version.db_password.secret_string

  backup_retention_period = 1
  availability_zone = element(random_shuffle.aws_availability_zone_name.result, 0)

  db_scurity_group_id = module.db_security_group.security_group_id

  tags = {
    Owner = "YourName"
  }
}

# Module for EC2 Instance
module "aws_instance" {
  source = "./modules/aws_instance"

  name_prefix   = "week2-instance"
  ami           = "ami-08578967e04feedea" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  instance_scurity_group_id = module.wordpress_security_group.security_group_id

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=${module.aws_db_instance.endpoint} \
                  -e WORDPRESS_DB_USER=${module.aws_db_instance.username} \
                  -e WORDPRESS_DB_PASSWORD=${data.aws_secretsmanager_secret_version.db_password.secret_string} \
                  -e WORDPRESS_DB_NAME=${module.aws_db_instance.db_name} \
                  -p 80:80 ${var.image.name}:${var.image.tag}
              EOF

  tags = {
    Owner = "YourName"
  }
}

variable "image" {
  type = object({
    name = string
    tag  = string
  })

  default = {
    name = "wordpress"
    tag  = "latest"
  }
}


# Module for Database Security Group
module "db_security_group" {
  source = "./modules/aws_security_groups"

  # Main security group variables
  name_prefix = "week2"
  resource_name = "db"
  security_group_description = "Security group for Wordpress DB"
  aws_vpc_id = data.aws_vpc.default.id

  # Ingress rules
  ports = ["3306"]
  trusted_ingress_cidr = data.aws_vpc.default.cidr_block


}

# Module for Web Server Security Group
module "wordpress_security_group" {
  source = "./modules/aws_security_groups"

  # Main security group variables
  name_prefix = "week2"
  resource_name = "wordpress"
  security_group_description = "Security group for Wordpress Web Server"
  aws_vpc_id = data.aws_vpc.default.id

  # Ingress rules
  ports = ["22","80"]
  trusted_ingress_cidr = "0.0.0.0/0"

}

# Module for Web Server Security Group
module "db_password" {
  source = "./modules/aws_secrets_manager"

  secret_description = "Wordpress Database Password"
  secret_name = "wordpress-db-password"
  secret_length = 40

}

