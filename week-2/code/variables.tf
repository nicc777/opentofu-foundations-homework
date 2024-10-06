variable "name_prefix" {
  description = "A prefix used for naming resources"
  type        = string
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

