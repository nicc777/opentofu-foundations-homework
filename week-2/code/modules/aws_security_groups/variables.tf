variable "name_prefix" {
  description = "Name prefix for all the resources"
  type        = string
}

variable "resource_name" {
  description = "A name for the resource to be created"
  type        = string
}

variable "security_group_description" {
  description = "A short description of the purpose of this security group"
  type        = string
}

variable "aws_vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "trusted_ingress_cidr" {
  description = "A trusted CIDR (IPv4)"
  type        = string
  validation {
    condition     = length(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+\\/\\d+$", var.trusted_ingress_cidr)) > 0
    error_message = "Provide a valid CIDR for example 10.0.0.0/8 or 0.0.0.0/0 or for a single host 192.168.1.5/32"
  }
}

variable "ports" {
  type        = set(string)
#   default     = ["80","443","3306"]
  description = "A set of TCP ports"

  validation {
    condition     = alltrue([for port in var.ports : 0 <= tonumber(port) && tonumber(port) <= 65535])
    error_message = "TCP ports must be from 1 to 65535 (incluive)"
  }
}

