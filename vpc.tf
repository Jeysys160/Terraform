resource "aws_vpc" "vpc_terraform" {
    cidr_block = var.oregon_cidr
    # cidr_block = lookup(var.oregon_cidr,terraform.workspace)
    tags = {
      Name = "VPC_TERRAFORM-${local.sufix}"
      env = "Dev"
    }
}

resource "aws_subnet" "public_subnet_primaria" {
  vpc_id = aws_vpc.vpc_terraform.id
  cidr_block = var.subnets[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet_temp-${local.sufix}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc_terraform.id
  cidr_block = var.subnets[1]
  tags = {
    Name = "Private Subnet_1-${local.sufix}"
  }
  depends_on = [ 
    aws_subnet.public_subnet_primaria
    ]
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_terraform.id

  tags = {
    Name = "ig vpc-${local.sufix}"
  }
}

resource "aws_route_table" "public_crt" {
  vpc_id = aws_vpc.vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public crt-${local.sufix}"
  }
}

resource "aws_route_table_association" "crt_public_subnet" {
  subnet_id      = aws_subnet.public_subnet_primaria.id
  route_table_id = aws_route_table.public_crt.id
}

resource "aws_security_group" "sg_public_ec2" {
  name = "Public Instance SG"
  description = "Allow SSH and all egress traffic"
  vpc_id = aws_vpc.vpc_terraform.id

  dynamic "ingress" {
    for_each = var.ingress_ports_list
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = [ var.sg_ingress_cidr ]
    }
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public Instance SG-${local.sufix}"
  }

}