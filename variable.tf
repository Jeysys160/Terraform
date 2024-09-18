variable "oregon_cidr" {
    description = "CIDR Oregon"
    type = string
}

# variable "public_subnet" {
#     description = "cidr public subnet"
#     type = string
# }

# variable "private_subnet" {
#     description = "cidr private subnet"
#     type = string
# }

variable "subnets" {
    description = "Lista de Subnet"
    type = list(string)
}

variable "tags" {
    description = "Tags del Proyecto"
    type = map(string)
}

variable "sg_ingress_cidr" {
  description = "CIDR for ingress CIDR"
  type = string
}

variable "ec2_specs" {
    description = "Parametros de la EC2"
    type = map(string)
}

variable "enable_monitoring" {
    description = "Habilita el despliegue de un servidor de monitoreo"
    type = number
}

variable "ingress_ports_list" {
  description = "Lista de puertos ingress"
  type = list(number)
}