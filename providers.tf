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
  default_tags {
    tags = var.tags
  }
}
