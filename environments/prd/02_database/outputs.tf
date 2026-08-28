# output 名は据え置き（03_compute_ec2 / 06_efs / 07_elasticache が名前で参照しているため）。
output "public_security_group_id" {
  value = aws_security_group.web.id
}

output "private_security_group_id" {
  value = aws_security_group.db.id
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
}

output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_engine_resolved" {
  value = "${local.rds_engine_key} ${local.rds_engine_version} (family ${local.rds_parameter_group_family}, port ${local.rds_port})"
}
