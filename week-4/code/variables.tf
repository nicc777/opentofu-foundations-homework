variable "enable_ssh" {
  description = "Enable SSH access to the EC2 instance"
  type        = bool
  default     = false
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