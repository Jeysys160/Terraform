terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
}

resource "aws_s3_bucket" "BucketPrueba" {
  bucket = "bucketterraformprueba"

  tags = {
    Name = "Bucket Prueba"
  }
}