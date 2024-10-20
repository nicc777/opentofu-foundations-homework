variable "name_prefix" {
  description = "Name prefix for all the resources"
  type        = string
}

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = "OpenTofu Foundations internet access for EC2 instance"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "Allowed instance types are \"t2.micro\", \"t3.micro\"."
  }
}

variable "user_data" {
  description = "User data script to initialize the instance"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_ssh" {
  description = "Enable SSH access to the EC2 instance"
  type        = bool
  default     = true
}

variable "home_directory" {
  description = "Home directory which will be used to write out the SSH private key, if enable_ssh is set to true"
  type = string
  default = "/dev/null"
}

variable "trusted_cidr_for_ssh_access" {
  # Use Environment variable with:
  # $ export TF_VAR_trusted_cidr_for_ssh_access="`dig +short txt ch whoami.cloudflare @1.0.0.1 | tr -d '\"' | awk '{print $1\"/32\"}'`"
  description = "A trusted CIDR's to allow HTTP access to the WordPress server."
  type        = string
  default     = "0.0.0.0/0"
}
