variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

# web-sg の ingress 元（SSH/HTTP/HTTPS を許可する管理元 IP）
variable "source_cidr_blocks" {
  type = list(string)
}

# web-sg の egress 先
variable "target_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# =============================================================================
# RDS — version / family / ログ種別 / ポートは未指定なら locals.tf の engine 既定表から解決する。
# =============================================================================
variable "rds_engine" {
  type        = string
  default     = "mysql"
  description = "mysql / mariadb / postgres"
}

variable "rds_engine_version" {
  type        = string
  default     = null
  description = "null なら engine ごとの既定（locals.tf）を使用"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "rds_db_name" {
  type    = string
  default = "wordpress"
}

variable "rds_username" {
  type    = string
  default = "admin"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_deletion_protection" {
  type    = bool
  default = false
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "rds_delete_automated_backups" {
  type    = bool
  default = true
}

variable "rds_backup_retention_period" {
  type    = number
  default = 7
}

variable "rds_backup_window" {
  type    = string
  default = "18:00-19:00"
}

variable "rds_maintenance_window" {
  type    = string
  default = "sat:20:00-sat:21:00"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_storage_type" {
  type    = string
  default = "gp3"
}

variable "rds_parameter_group_family" {
  type        = string
  default     = null
  description = "null なら engine 既定（locals.tf）"
}

variable "rds_major_engine_version" {
  type        = string
  default     = null
  description = "null なら engine 既定（locals.tf）。MySQL/MariaDB のみ意味を持つ"
}

variable "rds_enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = null
  description = "null なら engine 既定（locals.tf）"
}

variable "rds_parameters" {
  type        = map(string)
  default     = null
  description = "null なら engine 既定（locals.tf）"
}
