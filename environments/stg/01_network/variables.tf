variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "cidr_block_vpc" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_1a" {
  type    = string
  default = "10.20.1.0/24"
}

variable "public_subnet_1c" {
  type    = string
  default = "10.20.2.0/24"
}

variable "private_subnet_1a" {
  type    = string
  default = "10.20.3.0/24"
}

variable "private_subnet_1c" {
  type    = string
  default = "10.20.4.0/24"
}

variable "route_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}
