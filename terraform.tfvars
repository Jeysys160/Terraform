oregon_cidr = "10.0.0.0/16"
# oregon_cidr = {
#   "prod" = "10.0.0.0/16"
#   "dev" = "172.16.0.0/16"
# }
# public_subnet = "10.0.0.0/24"
# private_subnet = "10.0.1.0/24"

subnets = [ "10.0.0.0/24", "10.0.1.0/24" ]

tags = {
  "env" = "dev"
  "Owner" = "Jeyson"
  "IAC" = "Terraform"
  "Project" = "cerberus"
  "region" = "California"
}

sg_ingress_cidr = "0.0.0.0/0"

ec2_specs = {
  "ami" = "ami-0298d169be5006679"
  "instance_type" = "t2.micro"
}

enable_monitoring = 0

ingress_ports_list = [ 22,80,443 ]