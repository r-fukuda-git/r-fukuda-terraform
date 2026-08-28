variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "EC2(22/80/443) の ingress を許可する管理元 CIDR"
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_instance_count" {
  type    = number
  default = 1
}

variable "ec2_key_path" {
  type        = string
  description = "公開鍵のパス。terraform.tfvars で指定"
}

variable "ec2_disable_api_termination" {
  type    = bool
  default = false
}
