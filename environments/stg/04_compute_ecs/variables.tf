variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "ALB(80) の ingress を許可する管理元 CIDR"
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ecs_use_ecr" {
  type        = bool
  default     = false
  description = "true のとき 03_ecr の remote state からイメージ URL を取得する。false なら ecs_image_repo（公開イメージ）"
}

variable "ecs_image_repo" {
  type        = string
  default     = "public.ecr.aws/nginx/nginx"
  description = "ecs_use_ecr=false のとき使うイメージリポジトリ（タグを除く部分）"
}

variable "ecs_image_tag" {
  type    = string
  default = "latest"
}

variable "ecs_container_port" {
  type    = number
  default = 80 # Why: 既定の nginx イメージが listen するポート
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "ecs_task_cpu" {
  type    = number
  default = 256
}

variable "ecs_task_memory" {
  type    = number
  default = 512
}

variable "ecs_health_check_path" {
  type    = string
  default = "/"
}
