# stg / 07_elasticache — ElastiCache（既定 redis）+ cache-sg。
# 依存: 01_network のみ。
# Why: modules/elasticache は allowed_security_group_ids を for_each でさばくため、
#      クライアント SG を跨スタックで渡さず空リストにし、ingress は VPC CIDR 許可で開ける
#      （06_efs と同じ扱い。検証用途として十分）。
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

module "elasticache" {
  source = "../../../modules/elasticache"

  env          = var.env
  project_name = var.project_name

  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                 = local.private_subnet_ids
  allowed_security_group_ids = []

  engine                 = var.elasticache_engine
  engine_version         = var.elasticache_engine_version
  node_type              = var.elasticache_node_type
  num_cache_nodes        = var.elasticache_num_cache_nodes
  parameter_group_family = var.elasticache_parameter_group_family
  port                   = var.elasticache_port
}

resource "aws_security_group_rule" "cache_ingress_vpc" {
  type              = "ingress"
  from_port         = var.elasticache_port
  to_port           = var.elasticache_port
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr]
  security_group_id = module.elasticache.security_group_id
  description       = "stg: from within VPC"
}
