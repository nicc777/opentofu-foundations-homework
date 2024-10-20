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