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

variable "subnet_prefix" {
  description = "cidr block for the subnet"
  #default
  type = string
}

#1. Crear VPC
resource "aws_vpc" "project1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "PROJECT1"
  }
}

#2. Crear Internet Gateway
resource "aws_internet_gateway" "igwproject1" {
  vpc_id = aws_vpc.project1.id
  tags = {
    Name = "ITG-PROJECT1"
  }
}

#3. Crear tabla enrutamiento
resource "aws_route_table" "RouteTable" {
  vpc_id = aws_vpc.project1.id

  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igwproject1.id
  }

  tags = {
    Name = "Route Table Project1"
  }
}

#4. Crear subred 
resource "aws_subnet" "publicsubnet1" {
  vpc_id = aws_vpc.project1.id
  cidr_block = var.subnet_prefix
  availability_zone = "us-east-2a"

  tags = {
    Name = "Public Subnet 1 - Project1"
  }
}

#5. Asociar subred con tabla de enrutamiento
resource "aws_route_table_association" "association" {
  subnet_id = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.RouteTable.id
}

#6. crear un grupo de seguridad que permita 22, 80 y 443
resource "aws_security_group" "securitygroup" {
  name        = "SG PRUEBA"
  description = "SG PRUEBA"
  vpc_id      = aws_vpc.project1.id
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
    Name = "SG-PROJECT1"
  }
}

#7. crear una network interface
resource "aws_network_interface" "nwproject1" {
  subnet_id       = aws_subnet.publicsubnet1.id
  security_groups = [aws_security_group.securitygroup.id]

}

#8. asignar una IP elastica a la network interface 
resource "aws_eip" "one" {
  vpc = true
  network_interface         = aws_network_interface.nwproject1.id
  depends_on = [aws_internet_gateway.igwproject1]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}

#9. Crear un ubuntu server e instalar apache
resource "aws_instance" "WebServer" {
  ami = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "PruebaTerraform"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nwproject1.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl stop ufw
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "Web Server"
  }
}