variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "multi_az" {
  type = bool
}

variable "subnet_ids" {
  type = list(string)
}

variable "deletion_protection" {
  type = bool
}

variable "backup_window" {
  type = string
}

variable "maintenance_window" {
  type = string
}

variable "backup_retention_period" {
  type = number
}

variable "skip_final_snapshot" {
  type        = bool
  description = "false の場合、削除時に final_snapshot_identifier でスナップショットを作成する"
  default     = false
}

variable "final_snapshot_identifier" {
  type        = string
  default     = null
  description = "skip_final_snapshot=false 時のスナップショット名。未指定時は {project}-{env}-rds-final"
}

variable "copy_tags_to_snapshot" {
  type    = bool
  default = true
}

variable "delete_automated_backups" {
  type        = bool
  default     = false
  description = "インスタンス削除時に自動バックアップも削除するか"
}

variable "master_user_secret_kms_key_id" {
  type        = string
  default     = null
  description = "RDS 管理シークレット用 KMS キー ID。null の場合は aws/secretsmanager を使用"
}

variable "rds_parameters" {
  type = map(string)
  default = {
    "character_set_server" = "utf8mb4"
    "slow_query_log"       = "1"
    "long_query_time"      = "2.0"
  }
}

# 以下 5 つはエンジン非依存にするための変数。
# Why: default は現行の MySQL 8.4 固定値と同一にし、これらを渡さない既存呼び出し
#      （environments/prd/02_database）の plan を変えないため。
variable "parameter_group_family" {
  type        = string
  default     = "mysql8.4"
  description = "DB パラメータグループの family（例: mysql8.0 / postgres16 / mariadb10.11）"
}

variable "major_engine_version" {
  type        = string
  default     = "8.4"
  description = "オプショングループの major_engine_version。MySQL/MariaDB のみ使用"
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = ["error", "general", "slowquery"]
  description = "CloudWatch Logs にエクスポートするログ種別。PostgreSQL は [\"postgresql\", \"upgrade\"]"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "storage_type" {
  type    = string
  default = "gp3"
}
