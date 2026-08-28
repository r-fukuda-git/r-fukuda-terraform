# stg / 06_efs — EFS + マウントターゲット + efs-sg。
# 依存: 01_network のみ。
# Why: modules/efs は allowed_security_group_ids を for_each でさばくため、
#      クライアント SG を跨スタックで渡さず空リストにし、ingress は VPC CIDR 許可で開ける
#      （07_elasticache と同じ扱い。検証用途として十分）。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

locals {
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
  private_subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c,
  ]
}

module "efs" {
  source = "../../../modules/efs"

  env          = var.env
  project_name = var.project_name

  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                 = local.private_subnet_ids
  allowed_security_group_ids = []

  expected_storage_gb = var.efs_expected_storage_gb
  performance_mode    = var.efs_performance_mode
  throughput_mode     = var.efs_throughput_mode
}

resource "aws_security_group_rule" "efs_ingress_vpc" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr]
  security_group_id = module.efs.security_group_id
  description       = "stg: NFS from within VPC"
}
