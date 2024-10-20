resource "random_id" "index" {
  byte_length = 2
}

data "aws_ami" "latest_amzn2_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_subnets" "current" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  subnet_ids_list = tolist(data.aws_subnets.current.ids)

  subnet_ids_random_index = random_id.index.dec % length(data.aws_subnets.current.ids)

  instance_subnet_id = local.subnet_ids_list[local.subnet_ids_random_index]

  security_group_rules = {
    "HTTP" = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "HTTP Access"
      map         = ""
    }
    "Allow all outbound traffic" = {
      type        = "egress"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "ANY egress"
      map         = ""
    }
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt"
  image_id      = data.aws_ami.latest_amzn2_ami.id
  instance_type = var.instance_type

  key_name = var.enable_ssh ? aws_key_pair.ssh[0].key_name : null

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = var.name_prefix
      }
    )
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.this.id]
  }

}

resource "aws_autoscaling_group" "this" {
  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [local.instance_subnet_id]
  instance_refresh {
    strategy = "Rolling"
    preferences {
      skip_matching = true
    }
    triggers = ["launch_template"]
  }
  tag {
    key                 = "project"
    value               = "${var.name_prefix}-wordpress"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-wordpress"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "${var.name_prefix}-wordpress_server_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each          = { for rule in local.security_group_rules : rule.map => rule if rule.type == "ingress" }
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.protocol
  to_port           = each.value.to_port
  description       = each.value.description
}

resource "aws_vpc_security_group_ingress_rule" "wordpress_allow_ssh_ipv4" {
  count             = var.enable_ssh ? 1 : 0
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.trusted_cidr_for_ssh_access
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "User enabled SSH access"
}

resource "aws_vpc_security_group_egress_rule" "wordpress_allow_all_traffic_ipv4" {
  for_each          = { for rule in local.security_group_rules : rule.map => rule if rule.type == "egress" }
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.protocol
  to_port           = each.value.to_port
  description       = each.value.description
}

resource "tls_private_key" "ssh" {
  count     = var.enable_ssh ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  count      = var.enable_ssh ? 1 : 0
  key_name   = "${var.name_prefix}-ssh-key"
  public_key = tls_private_key.ssh[0].public_key_openssh
}

resource "local_file" "private_key" {
  count    = var.enable_ssh ? 1 : 0
  content  = tls_private_key.ssh[0].private_key_pem
  filename = "${var.home_directory}/.ssh/opentofu_foundations_temporary_key.pem"
}

resource "null_resource" "set_permission" {
  count = var.enable_ssh ? 1 : 0
  provisioner "local-exec" {
    command = "chmod 0600 ${local_file.private_key[0].filename}"
  }
  depends_on = [local_file.private_key]
}

resource "aws_lb" "web_server_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = local.subnet_ids_list
}

resource "aws_lb_target_group" "web_server_target_group" {
  name     = "web-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_server_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_target_group.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.web_server_target_group.arn
}




