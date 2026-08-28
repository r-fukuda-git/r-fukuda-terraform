# prd / 02_database — RDS（engine 自由指定）+ web-sg / db-sg。
# 依存: 01_network のみ。
# SG は本スタックで直接管理する（旧 modules/sg の create_web_and_db_security_groups=true 相当を
# インライン化）。ingress は最小権限のまま: db-sg は web-sg からのみ、web-sg は
# source_cidr_blocks からのみ許可する。
# Why: modules/sg は DB ポート 3306 固定。engine 可変化に備えてスタック内で組み立てる。
#      SG のアドレスは modules/sg → root へ moved 済みなので plan は state move のみ。
#      aws_security_group に description を設定しない（旧 modules/sg も未設定。設定すると
#      description が ForceNew のため SG 再作成になる）。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

# --- moved: modules/sg（create_web_and_db_security_groups=true）→ インライン ---
moved {
  from = module.security_group.aws_security_group.web_public[0]
  to   = aws_security_group.web
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_http[0]
  to   = aws_security_group_rule.web_ingress_http
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_https[0]
  to   = aws_security_group_rule.web_ingress_https
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_ssh[0]
  to   = aws_security_group_rule.web_ingress_ssh
}
moved {
  from = module.security_group.aws_security_group_rule.egress_all[0]
  to   = aws_security_group_rule.web_egress
}
moved {
  from = module.security_group.aws_security_group.db_private[0]
  to   = aws_security_group.db
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_web_sg[0]
  to   = aws_security_group_rule.db_ingress_from_web
}

# --- web-sg（EC2/踏み台向け。02_database が所有し 03_compute_ec2 へ output する） ---
resource "aws_security_group" "web" {
  name   = "${local.name}-web-sg"
  vpc_id = local.vpc_id

  tags = {
    Name      = "${local.name}-web-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "web_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTP"
}

resource "aws_security_group_rule" "web_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTPS"
}

resource "aws_security_group_rule" "web_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "Allow SSH"
}

resource "aws_security_group_rule" "web_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "All"
}

# --- db-sg（RDS 用。web-sg からのみ許可） ---
resource "aws_security_group" "db" {
  name   = "${local.name}-db-sg"
  vpc_id = local.vpc_id

  tags = {
    Name      = "${local.name}-db-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "db_ingress_from_web" {
  type                     = "ingress"
  from_port                = local.rds_port
  to_port                  = local.rds_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow WebSG"
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
