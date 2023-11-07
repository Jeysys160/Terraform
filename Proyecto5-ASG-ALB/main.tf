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
resource "aws_vpc" "Project5" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Project5 - vpc"
  }
}
#---------------------------------------

#-------------------- SUB REDES PUBLICAS -------------
resource "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.Project5.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.Project5.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 2"
  }
}
#-----------------------------------------------------

#-------------------- SUB REDES PRIVADAS -------------
resource "aws_subnet" "PrivateSubnet1" {
  vpc_id = aws_vpc.Project5.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "PrivateSubnet2" {
  vpc_id = aws_vpc.Project5.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "Private Subnet 2"
  }
}
#-----------------------------------------------------

#---------------- INTERNET GATEWAY---------------------
resource "aws_internet_gateway" "ITGW" {
  vpc_id = aws_vpc.Project5.id
  tags = {
    Name = "INTERNET GATEWAY PROJECT 4"
  }
}
#-----------------------------------------------------

#----------------NAT GATEWAY - ELASTIC IP--------------------------------
resource "aws_eip" "one" {
  tags = {
    Name = "IP - ITG"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.one.id
  subnet_id = aws_subnet.PublicSubnet1.id
  tags = {
    Name = "NAT GATEWAY"
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
  vpc_id = aws_vpc.Project5.id

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
  vpc_id = aws_vpc.Project5.id
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
#---------------------------------------------------------------------


#-----------------SECURITY GROUP MAIN EC2----------------------------
resource "aws_security_group" "Sg-MainEc2" {
  name = "SG MAIN EC2"
  description = "SG PARA LA EC2 PRINCIPAL"
  vpc_id = aws_vpc.Project5.id
  ingress {
    description = "HTTP ALB"
    to_port = 80
    from_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.Sg-Alb.id]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG MAIN EC2"
  }
}
#----------------------------------------------------------------

#----------------------- MAIN EC2--------------------------------
resource "aws_instance" "Main-Ec2" {
  ami = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  key_name = "Terraform"
  iam_instance_profile = "SSMAgentRol"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nwi-mainec2.id
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl stop ufw
              sudo bash -c 'echo your very first web server 1 > /var/www/html/index.html'
              sudo mkdir /tmp/ssm
              cd /tmp/ssm
              wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
              sudo dpkg -i amazon-ssm-agent.deb
              sudo systemctl enable amazon-ssm-agent
              rm amazon-ssm-agent.deb
              EOF
  tags = {
    Name = "Main EC2"
  }
}

resource "aws_network_interface" "nwi-mainec2" {
  subnet_id = aws_subnet.PrivateSubnet1.id
  security_groups = [aws_security_group.Sg-MainEc2.id]
}
#--------------------------------------------------------------

#--------------------------SECIRUTY GROUP ALB---------------------------
resource "aws_security_group" "Sg-Alb" {
  name = "SG-ABL"
  description = "Security Group para el ALB"
  vpc_id = aws_vpc.Project5.id
  ingress {
    description = "HTTP"
    protocol = "tcp"
    to_port = 80
    from_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG - ABL"
  }
}
#--------------------------------------------------------------------

#----------------------- BALANCEADOR DE CARGA APP --------------------
resource "aws_lb" "alb" {
  name = "alb-app"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.Sg-Alb.id ]
  subnets = [aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id]
  tags = {
    Name = "ALB APP"
  }
}

resource "aws_lb_target_group" "target-group-webserver" {
  name = "tg-app"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.Project5.id
  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }
  tags = {
    Name = "Target Group App"
  }
}

resource "aws_lb_target_group_attachment" "tg-attach-ec2" {
  target_group_arn = aws_lb_target_group.target-group-webserver.arn
  target_id = aws_instance.Main-Ec2.id
  port = 80
}

resource "aws_lb_listener" "listener-lb" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group-webserver.arn
  }
}
#---------------------------------------------------------------------------

#--------------------------- AUTO SCALING GROUP------------------------------
resource "aws_launch_configuration" "asg-template" {
  name_prefix = "app"
  image_id = "ami-0e83be366243f524a"
  instance_type = "t2.micro"
  key_name = "Terraform"
  security_groups = [aws_security_group.Sg-MainEc2.id]
  user_data = <<-EOF
              #!/bin/bash
              sudo mkdir /tmp/ssm
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl stop ufw
              sudo bash -c 'echo your very first web server 2 > /var/www/html/index.html'
              EOF
}

resource "aws_autoscaling_group" "asg-group" {
  name = "asg-terraform"
  vpc_zone_identifier = [aws_subnet.PrivateSubnet1.id, aws_subnet.PrivateSubnet2.id]
  launch_configuration = aws_launch_configuration.asg-template.name
  min_size = 0
  max_size = 1
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true
  target_group_arns = [aws_lb_target_group.target-group-webserver.arn]
  tag {
    key = "Name"
    value = "Demo ASG - Terraform"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "policy-escalado" {
  name = "Scaling-CPU"
  autoscaling_group_name = aws_autoscaling_group.asg-group.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown = 300
  policy_type = "SimpleScaling"

}

resource "aws_autoscaling_policy" "policy-reduccion" {
  name = "Reduccion-CPU"
  autoscaling_group_name = aws_autoscaling_group.asg-group.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown = 300
  policy_type = "SimpleScaling"
}

#---------------------------------------------------------------------------------------------

#------------------------------ ALARMA DE CPU CLOUD WATCH CON EL ASG +1 ------------------------------
resource "aws_cloudwatch_metric_alarm" "alarma_cloudwatch" {
  alarm_name = "alarma-cpu-70%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 5
  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"
  threshold = 70
  period = 60
  statistic = "Average"
  alarm_description = "High CPU Utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.Main-Ec2.id
    #autoscaling_group_name = aws_autoscaling_group.asg-group.name
  }
  alarm_actions = [aws_autoscaling_policy.policy-escalado.arn]
}
#----------------------------------------------------------------------------------------------- 

#------------------------------ ALARMA DE CPU CLOUD WATCH CON EL ASG -1 ------------------------------
resource "aws_cloudwatch_metric_alarm" "alarma_cloudwatch-reduccion" {
  alarm_name = "alarma-cpu-40%"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 5
  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"
  threshold = 40
  period = 60
  statistic = "Average"
  alarm_description = "Normal CPU Utilization"
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.Main-Ec2.id
    #autoscaling_group_name = aws_autoscaling_group.asg-group.name
  }
  alarm_actions = [aws_autoscaling_policy.policy-reduccion.arn]
}
#-------------------------------------------------------------------------------------------