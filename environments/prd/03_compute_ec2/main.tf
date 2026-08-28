# prd / 03_compute_ec2 — public サブネットの EC2。
# 依存: 01_network, 00_iam。
# 通常運用は use_database_security_groups=true で 02_database の web-sg を流用する。
# use_database_security_groups=false のときだけ本スタックで web-sg をインライン作成する
# （旧 modules/sg フォールバックのインライン化。ingress は最小権限のまま source_cidr_blocks）。
# efs / elasticache の output は 03 経由で参照できるよう passthrough している（prd 固有）。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.iam
  })
}

data "terraform_remote_state" "database" {
  count = var.use_database_security_groups ? 1 : 0

  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.database
  })
}

data "terraform_remote_state" "efs" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.efs
  })
}

data "terraform_remote_state" "elasticache" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.elasticache
  })
}

locals {
  name          = "${var.project_name}-${var.env}"
  create_web_sg = var.use_database_security_groups ? 0 : 1

  source_cidr_blocks = distinct(var.source_cidr_blocks)
  target_cidr_blocks = distinct(var.target_cidr_blocks)

  web_security_group_id = var.use_database_security_groups ? data.terraform_remote_state.database[0].outputs.public_security_group_id : aws_security_group.web[0].id
}

# --- moved: modules/sg フォールバック（use_database_security_groups=false）→ インライン ---
# 通常運用（=true）では state に存在しないため、この move は不活性。
moved {
  from = module.security_group[0].aws_security_group.web_public[0]
  to   = aws_security_group.web[0]
}
moved {
  from = module.security_group[0].aws_security_group_rule.ingress_allow_http[0]
  to   = aws_security_group_rule.web_ingress_http[0]
}
moved {
  from = module.security_group[0].aws_security_group_rule.ingress_allow_https[0]
  to   = aws_security_group_rule.web_ingress_https[0]
}
moved {
  from = module.security_group[0].aws_security_group_rule.ingress_allow_ssh[0]
  to   = aws_security_group_rule.web_ingress_ssh[0]
}
moved {
  from = module.security_group[0].aws_security_group_rule.egress_all[0]
  to   = aws_security_group_rule.web_egress[0]
}

resource "aws_security_group" "web" {
  count = local.create_web_sg

  name   = "${local.name}-web-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name      = "${local.name}-web-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "web_ingress_http" {
  count = local.create_web_sg

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web[0].id
  description       = "Allow HTTP"
}

resource "aws_security_group_rule" "web_ingress_https" {
  count = local.create_web_sg

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web[0].id
  description       = "Allow HTTPS"
}

resource "aws_security_group_rule" "web_ingress_ssh" {
  count = local.create_web_sg

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web[0].id
  description       = "Allow SSH"
}

resource "aws_security_group_rule" "web_egress" {
  count = local.create_web_sg

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.web[0].id
  description       = "All"
}

module "ec2" {
  source             = "../../../modules/ec2"
  env                = var.env
  project_name       = var.project_name
  ec2_instance_count = var.ec2_instance_count
  ec2_instance_type  = var.ec2_instance_type
  key_path           = var.ec2_key_path

  subnet_id               = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  security_groups         = [local.web_security_group_id]
  iam_instance_profile    = data.terraform_remote_state.iam.outputs.iam_instance_profile
  disable_api_termination = var.ec2_disable_api_termination
}
