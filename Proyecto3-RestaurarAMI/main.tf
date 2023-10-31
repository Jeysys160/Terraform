terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "ReplicaPsono" {
  ami = "ami-0cb53176b1ccd9e77"
  instance_type = "t3a.small"
  availability_zone = "us-east-1d"
  key_name = "OTRS-AWS"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.psono.id
  }
  tags = {
    Name = "PSONO DESDE AMI"
  }
}

resource "aws_network_interface" "psono" {
  subnet_id       = "subnet-0a5670b3b6054d88d"
  security_groups = [aws_security_group.securitygroup.id]

}

resource "aws_security_group" "securitygroup" {
  name        = "SG PRUEBA PSONO"
  description = "SG PRUEBA PSONO"
  vpc_id      = "vpc-02a39e593bb635a26"
  ingress {
    description      = "Puerto SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description = "Puerto http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "puerto https"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG-PSONOPRUEBAS"
  }
}

