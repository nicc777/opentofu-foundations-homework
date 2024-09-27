
variable "name_prefix" {
  type        = string
  description = "A name prefix for all resources created by this module."
}

variable "image" {
  type = object({
    name = string
    tag  = string
  })

  description = "Docker image to run in the EC2 instance."
  default = {
    name = "nginx"
    tag  = "latest"
  }
}

# If you want to connect to the database, you can add your IP address here and run the following command:
# docker run -it --rm mariadb mariadb -u admin -p --skip-ssl -h <RDS_HOSTNAME>
variable "enable_public_mariadb_access" {
  description = "A list of CIDR blocks to permit public MariaDB access. Set to your IP CIDR block to enable (https://www.whatismyip.com/)"
  type        = list(string)
  default     = []
}

variable "trusted_cidrs_for_wordpress_access" {
  # Use Environment variable with:
  # $ export TF_VAR_trusted_cidrs_for_wordpress_access="`dig +short txt ch whoami.cloudflare @1.0.0.1 | tr -d '\"' | awk '{print $1\"/32\"}'`"
  description = "A trusted CIDR's to allow HTTP access to the WordPress server."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_keypair_name" {
  description = "The SSH keypair name for SSH access to the instance"
  type        = string
}
