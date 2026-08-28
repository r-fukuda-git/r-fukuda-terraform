variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

# alb-sg の ingress 元（ALB :80/:443 を許可する管理元 IP）
variable "source_cidr_blocks" {
  type = list(string)
}

# alb-sg / ecs-sg の egress 先
variable "target_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ecs_image_tag" {
  type        = string
  description = "ECR image tag for the ECS service (must exist in 03_ecr repository)"
  default     = "latest"
}

variable "ecs_container_port" {
  type    = number
  default = 8080
}

variable "ecs_desired_count" {
  type        = number
  description = "初回は ECR イメージ未 push のため 0。main-cd が 1 で起動する（module 側 ignore_changes）"
  default     = 0
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
  type        = string
  description = "ALB target group health check path"
  default     = "/"
}
