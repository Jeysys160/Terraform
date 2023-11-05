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
#------------------VPC------------------
resource "aws_vpc" "Project4" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Project4 - vpc"
  }
}
#---------------------------------------

#-------------------- SUB REDES PUBLICAS -------------
resource "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.Project4.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.Project4.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "PublicSubnet3" {
  vpc_id = aws_vpc.Project4.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 3"
  }
}
#-----------------------------------------------------

#-------------------- SUB REDES PRIVADAS -------------
resource "aws_subnet" "PrivateSubnet1" {
  vpc_id = aws_vpc.Project4.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "PrivateSubnet2" {
  vpc_id = aws_vpc.Project4.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_subnet" "PrivateSubnet3" {
  vpc_id = aws_vpc.Project4.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-2c"
  tags = {
    Name = "Private Subnet 3"
  }
}
#-----------------------------------------------------

#---------------- INTERNET GATEWAY---------------------
resource "aws_internet_gateway" "ITGW" {
  vpc_id = aws_vpc.Project4.id
  tags = {
    Name = "INTERNET GATEWAY PROJECT 4"
  }
}
#-----------------------------------------------------

#-----------------NAT GATEWAY--------------------------------
#resource "aws_network_interface" "nwproject1" {
#  subnet_id       = aws_subnet.PublicSubnet1.id
#  security_groups = [aws_security_group.SgWebServer.id]
#  tags = {
#    Name = "Interface EC2"
#  }
#}

resource "aws_eip" "one" {
#  vpc = true
#  network_interface         = aws_network_interface.nwproject1.id
#  depends_on = [aws_internet_gateway.ITGW]
  tags = {
    Name = "IP - ITG"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.one.id
  subnet_id = aws_subnet.PublicSubnet1.id
  
  tags = {
    Name = "NAT GW"
  }
}

resource "aws_route" "NGWG-Table" {
  route_table_id = aws_route_table.RouteTablePrivate.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw.id
}

#--------------------------------------------------------------

#---------------- ROUTE TABLE PUBLIC----------------------------
resource "aws_route_table" "RouteTablePublic" {
  vpc_id = aws_vpc.Project4.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ITGW.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
#----------------------------------------------------------

#---------------- PRIVATE TABLE PRIVATE----------------------------
resource "aws_route_table" "RouteTablePrivate" {
  vpc_id = aws_vpc.Project4.id
  tags = {
    Name = "Private Route Table"
  }
}
#------------------------------------------------------------------

#---- ASOCIAR SUBREDES PUBLICAS EN LA TABLA DE ENRUTAMIENTO PUBLICA---
resource "aws_route_table_association" "AssociationPublic1" {
  subnet_id = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.RouteTablePublic.id
}

resource "aws_route_table_association" "AssociationPublic2" {
  subnet_id = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.RouteTablePublic.id 
}

resource "aws_route_table_association" "AssociationPublic3" {
  subnet_id = aws_subnet.PublicSubnet3.id
  route_table_id = aws_route_table.RouteTablePublic.id 
}
#--------------------------------------------------------------------

#---- ASOCIAR SUBREDES PRIVADAS EN LA TABLA DE ENRUTAMIENTO PUBLICA---
resource "aws_route_table_association" "AssociationPrivate1" {
  subnet_id = aws_subnet.PrivateSubnet1.id
  route_table_id = aws_route_table.RouteTablePrivate.id
}

resource "aws_route_table_association" "AssociationPrivate2" {
  subnet_id = aws_subnet.PrivateSubnet2.id
  route_table_id = aws_route_table.RouteTablePrivate.id
}

resource "aws_route_table_association" "AssociationPrivate3" {
  subnet_id = aws_subnet.PrivateSubnet3.id
  route_table_id = aws_route_table.RouteTablePrivate.id
}
#---------------------------------------------------------------------

#------------------GRUPO DE SEGURIDAD BASTION HOST---------------------
resource "aws_security_group" "SgBationHost" {
  name = "SG_BASTIONHOST"
  description = "SG_BASTIONHOST"
  vpc_id = aws_vpc.Project4.id

  ingress {
    description = "SSH Jeyson"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["190.248.178.85/32"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG BASTION HOST"
  }
}
#------------------------------------------------------------------------

#---------------------- EC2 BASTION HOST---------------------------------
resource "aws_instance" "BastionHost" {
  ami = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  key_name = "PruebaTerraform"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nwbastionhost.id
  }
  tags = {
    Name = "BASTION"
  }

}

resource "aws_network_interface" "nwbastionhost" {
  subnet_id       = aws_subnet.PublicSubnet1.id
  security_groups = [aws_security_group.SgBationHost.id]

}
#---------------------------------------------------------------------

#-----------------------GRUPO DE SEGURIDAD WEB SERVER------------------
resource "aws_security_group" "SgWebServer" {
  name = "SG_WEBSERVER"
  description = "SG_WEBSERVER"
  vpc_id = aws_vpc.Project4.id
  ingress {
    description = "SSH BASTION HOST"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.SgBationHost.id]
  }

  ingress {
    description = "HTTP ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.SgAlb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG ERB SERVER"
  }
}
#--------------------------------------------------------------------------

#---------------------------- EC2 WEB SERVER------------------------------
resource "aws_instance" "WebServer" {
  ami = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  key_name = "Terraform"
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nwWebServer.id
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
    Name = "WEB SERVER"
  }
}

resource "aws_network_interface" "nwWebServer" {
  subnet_id = aws_subnet.PrivateSubnet1.id
  security_groups = [aws_security_group.SgWebServer.id]
}
#---------------------------------------------------------------------------

#--------------------------- GRUPO DE SEGURIDAD ALB ------------------------
resource "aws_security_group" "SgAlb" {
  name = "SG-ALB"
  description = "SG-ALB"
  vpc_id = aws_vpc.Project4.id
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG ALB"
  }
}
#-----------------------------------------------------------------------------

#---------------------------- ALB -------------------------------------------
resource "aws_lb" "alb" {
  name = "alb-webserver"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.SgAlb.id]
  subnets = [aws_subnet.PublicSubnet1.id,aws_subnet.PublicSubnet2.id, aws_subnet.PublicSubnet3.id]

  tags = {
    Name = "ALB WEB SERVER"
  }
}

resource "aws_lb_target_group" "target-group-webserver" {
  name = "tg-webserver"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.Project4.id

  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }

  stickiness {
    type = "lb_cookie"
    cookie_duration = 28800 #8 Horas
  }

  tags = {
    Name = "TARGET GROUP WEB SERVER"
  }
}

resource "aws_lb_target_group_attachment" "ec2_target" {
  target_group_arn = aws_lb_target_group.target-group-webserver.arn
  target_id = aws_instance.WebServer.id
  port = 80
}

resource "aws_lb_listener" "rule_alb" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group-webserver.arn
  }
}
#-----------------------------------------------------------------------------

#-------------------------GRUPO DE SEGURIDAD RDS---------------------------
resource "aws_security_group" "rdsmysql" {
  name = "SG-RDS"
  description = "SG-RDS"
  vpc_id = aws_vpc.Project4.id
  ingress {
    description = "MYSQL"
    from_port = 3306
    to_port = 3306
    security_groups = [aws_security_group.SgWebServer.id]
    protocol = "tcp"
  }

  tags = {
    Name = "SG RDS"
  }
}
#---------------------------------------------------------------------------


#-----------------------------RDS----------------------------------------
resource "aws_db_instance" "rdsmysql" {
  allocated_storage = 10
  storage_type = "gp2"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  username = "terraform"
  password = "terraform2023*"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rdsmysql.id]
  multi_az = false
  tags = {
    Name = "RDS TERRAFORM"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "my-db-subnet-group"
  subnet_ids = [ aws_subnet.PrivateSubnet1.id, aws_subnet.PrivateSubnet2.id ]
  tags = {
    Name = "DB Subnet Group"
  }
}
#---------------------------------------------------------------------------