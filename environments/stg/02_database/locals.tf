locals {
  name = "${var.project_name}-${var.env}"

  # ---------------------------------------------------------------------------
  # RDS: engine ごとの既定値。変数で明示指定があればそちらを優先する。
  # Why: 単一 root 版 stg の locals.tf から移設。engine=postgres 等でも
  #      family / ログ種別 / ポートが自動で切り替わり、このスタック単体で apply が通る。
  # ---------------------------------------------------------------------------
  rds_engine_key = lower(var.rds_engine)

  rds_engine_defaults = {
    mysql = {
      engine_version                  = "8.0"
      parameter_group_family          = "mysql8.0"
      major_engine_version            = "8.0"
      enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
      port                            = 3306
      parameters                      = { character_set_server = "utf8mb4", slow_query_log = "1", long_query_time = "2.0" }
    }
    mariadb = {
      engine_version                  = "10.11"
      parameter_group_family          = "mariadb10.11"
      major_engine_version            = "10.11"
      enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
      port                            = 3306
      parameters                      = { character_set_server = "utf8mb4", slow_query_log = "1", long_query_time = "2.0" }
    }
    postgres = {
      engine_version                  = "16"
      parameter_group_family          = "postgres16"
      major_engine_version            = "16"
      enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
      port                            = 5432
      parameters                      = {}
    }
  }

  rds_defaults = lookup(local.rds_engine_defaults, local.rds_engine_key, local.rds_engine_defaults["mysql"])

  rds_engine_version                  = coalesce(var.rds_engine_version, local.rds_defaults.engine_version)
  rds_parameter_group_family          = coalesce(var.rds_parameter_group_family, local.rds_defaults.parameter_group_family)
  rds_major_engine_version            = coalesce(var.rds_major_engine_version, local.rds_defaults.major_engine_version)
  rds_enabled_cloudwatch_logs_exports = var.rds_enabled_cloudwatch_logs_exports != null ? var.rds_enabled_cloudwatch_logs_exports : local.rds_defaults.enabled_cloudwatch_logs_exports
  rds_parameters                      = var.rds_parameters != null ? var.rds_parameters : local.rds_defaults.parameters
  rds_port                            = local.rds_defaults.port

  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
  private_subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c,
  ]
}
