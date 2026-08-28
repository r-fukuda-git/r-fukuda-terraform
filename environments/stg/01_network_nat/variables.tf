variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "route_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}
