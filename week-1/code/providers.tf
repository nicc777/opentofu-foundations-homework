terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
    random = {
      source = "ContentSquare/random"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      environment = "dev"
      project     = "opentofu-foundations"
    }
  }

}
