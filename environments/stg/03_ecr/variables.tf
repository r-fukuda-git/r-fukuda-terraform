variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repository_suffix" {
  type    = string
  default = "app"
}

variable "ecr_scan_on_push" {
  type    = bool
  default = true
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "lifecycle_policy" {
  type        = string
  description = "JSON lifecycle policy document; null disables lifecycle policy"
  default     = null
  nullable    = true
}

variable "ecr_force_delete" {
  type    = bool
  default = true
}

variable "create_vpc_endpoints" {
  type        = bool
  default     = true
  description = "false にすると ECR リポジトリのみ作成（NAT 経由で pull する場合など）"
}
