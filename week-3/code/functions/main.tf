provider "go" {
  go = file("./lib.go")
}

variable "currency_selection" {
  type        = string
  description = "The currency selection for exchange rate conversion"
  default     = "Canada-Dollar"
}

variable "user_input" {
  type        = list(any)
  description = "User supplied list of strings"
  default     = ["e", "c", "a", "b"]
}

variable "user_input_sort_ascending" {
  type    = bool
  default = true
}

locals {
  // Note: Function name is all lowercase. No camel casing here.
  exchange_rate_record = provider::go::exchangerate({
    currencies = var.currency_selection
  })
  cat_fact_record = provider::go::catfact({
    max_length = "128"
  })
  user_data                         = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
                  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
                  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
                  -e WORDPRESS_DB_NAME=xxxxxxxxxxxxxxx \
                  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
              EOF
  exchange_rate_env_string          = "  -e EXCHANGE_RATE=${local.exchange_rate_record.exchangeRate} \\"
  exchange_rate_currency_env_string = "  -e EXCHANGE_RATE_CURRENCY=${var.currency_selection} \\"
  cat_fact_env_string               = "  -e CAT_FACT=${local.cat_fact_record.fact} \\"
  sorted_user_input                 = var.user_input_sort_ascending ? sort(var.user_input) : reverse(sort(var.user_input))
  user_input_final_string           = join(",", local.sorted_user_input)
  user_input_env_string             = "  -e USER_INPUT=${local.user_input_final_string} \\"
  split_user_data                   = split("\n", tostring(local.user_data))
  parsed_user_data                  = [slice(local.split_user_data, 0, 9), local.user_input_env_string, local.exchange_rate_env_string, local.exchange_rate_currency_env_string, local.cat_fact_env_string, local.split_user_data[10]]
  joined_user_data                  = join("\n", flatten(local.parsed_user_data))
}


output "data" {
  value = local.joined_user_data
}