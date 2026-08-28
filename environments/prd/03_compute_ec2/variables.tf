variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.small"
}

variable "ec2_instance_count" {
  type    = number
  default = 1
}

variable "ec2_key_path" {
  type        = string
  description = "公開鍵のパス（terraform.tfvars で設定）"
}

variable "ec2_disable_api_termination" {
  type    = bool
  default = false
}

# web-sg（use_database_security_groups=false 時のみ作成）の ingress 元
variable "source_cidr_blocks" {
  type = list(string)
}

# web-sg の egress 先
variable "target_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "use_database_security_groups" {
  type        = bool
  description = "true の場合、02_database で作成済みの web-sg を利用し、本スタックでは SG を作成しない"
  default     = true
}
