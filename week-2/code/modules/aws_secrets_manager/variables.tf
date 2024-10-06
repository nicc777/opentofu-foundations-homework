variable "secret_description" {
  description = "Description of the secret"
  type        = string
}

variable "secret_name" {
  description = "Name of the secret"
  type        = string
}

variable "secret_length" {
  description = "Name of the secret"
  type        = number
  default     = 256
}
