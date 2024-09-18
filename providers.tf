terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.43.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-west-1"
  access_key = var.acces_key
  secret_key = var.secret_key
  default_tags {
    tags = var.tags
  }
}

