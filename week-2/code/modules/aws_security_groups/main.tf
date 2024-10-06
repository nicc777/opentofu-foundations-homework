resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-${var.resource_name}"
  description = var.security_group_description
  vpc_id      = var.aws_vpc_id
  tags = {
    Name = "sg-${var.name_prefix}-${var.resource_name}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "wordpress_allow_tcp_ipv4" {
  for_each          = var.ports
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.trusted_ingress_cidr
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "wordpress_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
