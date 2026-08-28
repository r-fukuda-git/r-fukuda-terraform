
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.project_name}-${var.env}-rds-sg"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.env}-rds-sg"
  }
}

resource "aws_db_parameter_group" "parameter_group" {
  name   = "${var.project_name}-${var.env}-rds-pg"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.rds_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = {
    Name = "${var.project_name}-${var.env}-rds-pg"
  }
}

# Why: option_group に count を付けたことでアドレスが [0] 付きに変わる。
#      既存の呼び出し（prd/02_database, engine=mysql）で state 上の
#      aws_db_option_group.option_group を作り直させないための移設宣言。
#      engine=postgres 等 count=0 の場合はこの move 後に破棄され、これも意図どおり。
moved {
  from = aws_db_option_group.option_group
  to   = aws_db_option_group.option_group[0]
}

resource "aws_db_option_group" "option_group" {
  # Why: PostgreSQL はオプショングループ非対応。MySQL/MariaDB のときだけ作成する
  count = contains(["mysql", "mariadb"], var.engine) ? 1 : 0

  name                 = "${var.project_name}-${var.env}-rds-og"
  engine_name          = var.engine
  major_engine_version = var.major_engine_version

  tags = {
    Name = "${var.project_name}-${var.env}-rds-og"
  }
}

resource "aws_db_instance" "instance" {
  identifier          = "${var.project_name}-${var.env}-rds"
  engine              = var.engine
  engine_version      = var.engine_version
  instance_class      = var.instance_class
  allocated_storage   = var.allocated_storage
  storage_type        = var.storage_type
  deletion_protection = var.deletion_protection
  storage_encrypted   = true

  db_name  = var.db_name
  username = var.username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id

  db_subnet_group_name = aws_db_subnet_group.subnet_group.name
  parameter_group_name = aws_db_parameter_group.parameter_group.name
  option_group_name    = length(aws_db_option_group.option_group) > 0 ? aws_db_option_group.option_group[0].name : null

  vpc_security_group_ids     = var.vpc_security_group_ids
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.project_name}-${var.env}-rds-final")
  copy_tags_to_snapshot      = var.copy_tags_to_snapshot
  delete_automated_backups   = var.delete_automated_backups
  auto_minor_version_upgrade = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = false // instance sizeによる

  apply_immediately = true

  tags = {
    Name = "${var.project_name}-${var.env}-rds"
  }
}

output "db_secret_arn" {
  value = aws_db_instance.instance.master_user_secret[0].secret_arn
}

output "db_instance_arn" {
  value = aws_db_instance.instance.arn
}

output "db_instance_endpoint" {
  value = aws_db_instance.instance.endpoint
}



