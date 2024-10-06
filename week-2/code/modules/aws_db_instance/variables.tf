variable "name_prefix" {
  description = "Identifier for the database instance"
  type        = string
}

variable "instance_class" {
  description = "Instance class for the DB instance"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = contains(["db.t3.micro", "db.t3.small"], var.instance_class)
    error_message = "The provided instance type is not allowed"
  }
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 100
    error_message = "Values must be from 20 to 100 (inclusive)"
  }
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "mariadb"

  validation {
    condition     = can(regex("^mariadb$", var.engine))
    error_message = "Only MariaDB engine is supported"
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "10.6"

  validation {
    condition     = can(regex("^10.6$", var.engine_version))
    error_message = "Only engine version 10.6 is supported at the moment"
  }
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the database instance"
  type        = map(string)
  default     = {}
}

variable "backup_retention_period" {
  description = "The days to retain backups for. Must be between 0 and 35. Default is 3."
  type        = number
  default     = 3

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period < 36
    error_message = "Values must be from 0 to 35 (inclusive)"
  }
}

variable "availability_zone" {
  description = "The availability zone"
  type        = string

  validation {
    condition     = can(regex("^\\w+\\-\\w+\\-\\w+$", var.availability_zone))
    error_message = "Failed basic validation"
  }
}

variable "db_scurity_group_id" {
  description = "A security group ID"
  type        = string
}

variable "db_subnet_group_name" {
  description = "A name of the DB subnet group"
  type        = string
}

variable "subnet_ids" {
  type        = set(string)
  description = "A set of subnet IDs"

  validation {
    condition     = alltrue([for sn in var.subnet_ids : can(regex("^subnet\\-\\w+$", sn))])
    error_message = "Expected a subnet string to start with the string 'subnet-'"
  }
}