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

# Get the available AZ's
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name     = "lab"
  region   = "us-west-2"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }
}

module "lab_vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  name               = local.name
  cidr               = local.vpc_cidr
  azs                = local.azs
  public_subnets     = cidrsubnets(local.vpc_cidr, 4, 4, 4)
  enable_nat_gateway = false
  enable_vpn_gateway = false
  tags               = local.tags
}

# Get the secret
data "aws_secretsmanager_secret_version" "db_password" {
  depends_on = [module.db_password]
  secret_id  = module.db_password.secret_id
}

# Select a random AZ for our variable
resource "random_shuffle" "aws_availability_zone_name" {
  input        = data.aws_availability_zones.available.names
  result_count = 1
}

# Module for Database Instance
resource "random_shuffle" "subnets" {
  # input        = values(data.aws_subnet.subnet)[*].id
  input        = module.lab_vpc.public_subnets
  result_count = 2
}

module "aws_db_instance" {
  depends_on = [ module.lab_vpc, module.db_security_group ]
  source                  = "git::https://github.com/nicc777/opentofu-foundations-homework.git//week-2/code/modules/aws_db_instance?ref=2.0.0"
  name_prefix             = "${var.name_prefix}"
  db_name                 = "wordpress"
  username                = "admin"
  password                = data.aws_secretsmanager_secret_version.db_password.secret_string
  backup_retention_period = 1
  availability_zone       = module.lab_vpc.azs[0]
  db_scurity_group_id     = module.db_security_group.security_group_id
  db_subnet_group_name    = "${var.name_prefix}-db-subnet-group"
  subnet_ids              = [random_shuffle.subnets.result[0], random_shuffle.subnets.result[1]]
  tags = {
    Owner = "YourName"
  }
}

# Module for EC2 Instance
module "aws_instance" {
  source                  = "git::https://github.com/nicc777/opentofu-foundations-homework.git//week-2/code/modules/aws_instance?ref=2.0.1"
  name_prefix               = "${var.name_prefix}-instance"
  ami                       = "ami-08578967e04feedea" # Amazon Linux 2 AMI
  instance_type             = "t2.micro"
  instance_scurity_group_id = module.wordpress_security_group.security_group_id
  subnet_id                 = module.lab_vpc.public_subnets[0]
  user_data                 = <<-EOF
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
    Owner = "Nico"
  }
}

# Module for Database Security Group
module "db_security_group" {
  source                     = "git::https://github.com/nicc777/opentofu-foundations-homework.git//week-2/code/modules/aws_security_groups?ref=2.0.0"
  name_prefix                = "week2"
  resource_name              = "db"
  security_group_description = "Security group for Wordpress DB"
  aws_vpc_id                 = module.lab_vpc.vpc_id
  ports                      = ["3306"]
  trusted_ingress_cidr       = module.lab_vpc.vpc_cidr_block


}

# Module for Web Server Security Group
module "wordpress_security_group" {
  source                     = "git::https://github.com/nicc777/opentofu-foundations-homework.git//week-2/code/modules/aws_security_groups?ref=2.0.0"
  name_prefix                = "week2"
  resource_name              = "wordpress"
  security_group_description = "Security group for Wordpress Web Server"
  aws_vpc_id                 = module.lab_vpc.vpc_id
  ports                      = ["22", "80"]
  trusted_ingress_cidr       = "0.0.0.0/0"

}

# Module for Web Server Security Group
module "db_password" {
  source             = "git::https://github.com/nicc777/opentofu-foundations-homework.git//week-2/code/modules/aws_secrets_manager?ref=2.0.0"
  secret_description = "Wordpress Database Password"
  secret_name        = "wordpress-db-password"
  secret_length      = 40

}

