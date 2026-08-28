output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_secret_arn" {
  value       = module.rds.db_secret_arn
  description = "マスターユーザーのパスワードが入った Secrets Manager シークレット ARN"
}

output "rds_engine_resolved" {
  value = "${local.rds_engine_key} ${local.rds_engine_version} (family ${local.rds_parameter_group_family}, port ${local.rds_port})"
}
