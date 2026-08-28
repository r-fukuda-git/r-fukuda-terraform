variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "main_deploy_branches" {
  type        = list(string)
  description = "GitHub branches allowed to assume the deploy role (refs/heads/<branch>)"
  default     = ["main"]
}

variable "create_oidc_provider" {
  type        = bool
  description = "true でこの module が OIDC プロバイダを作成する。false なら既存プロバイダを data 参照（同一アカウント内の 2 環境目向け）"
  default     = true
}

variable "ecr_repository_arn" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ECS taskRoleArn (application role) to allow PassRole from GitHub Actions"
}
