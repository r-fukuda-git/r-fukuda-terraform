# stg / 02_database — RDS（engine 自由指定）+ db-sg。
# 依存: 01_network のみ。
# SG は本スタックで直接管理する。
# Why: 共有 modules/sg は DB ポート 3306 固定なので postgres(5432) で破綻する。
#      stg は engine ごとにポートが変わるため、ここで組み立てて prd 側 modules/sg を触らない。
#      ingress は VPC CIDR 許可（検証用途として十分。compute スタックへの依存を持たない）。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "stg RDS"
  vpc_id      = local.vpc_id
  tags        = { Name = "${local.name}-db-sg" }
}

resource "aws_security_group_rule" "db_ingress_vpc" {
  type              = "ingress"
  from_port         = local.rds_port
  to_port           = local.rds_port
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr]
  security_group_id = aws_security_group.db.id
  description       = "stg: engine port ${local.rds_port} from within VPC"
}

resource "aws_security_group_rule" "db_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.egress_cidr_blocks
  security_group_id = aws_security_group.db.id
  description       = "all"
}

module "rds" {
  source = "../../../modules/rds"

  env          = var.env
  project_name = var.project_name

  subnet_ids             = local.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  engine         = local.rds_engine_key
  engine_version = local.rds_engine_version
  instance_class = var.rds_instance_class
  db_name        = var.rds_db_name
  username       = var.rds_username

  parameter_group_family          = local.rds_parameter_group_family
  major_engine_version            = local.rds_major_engine_version
  enabled_cloudwatch_logs_exports = local.rds_enabled_cloudwatch_logs_exports
  rds_parameters                  = local.rds_parameters
  allocated_storage               = var.rds_allocated_storage
  storage_type                    = var.rds_storage_type

  multi_az                 = var.rds_multi_az
  deletion_protection      = var.rds_deletion_protection
  backup_window            = var.rds_backup_window
  maintenance_window       = var.rds_maintenance_window
  backup_retention_period  = var.rds_backup_retention_period
  skip_final_snapshot      = var.rds_skip_final_snapshot
  delete_automated_backups = var.rds_delete_automated_backups
}
