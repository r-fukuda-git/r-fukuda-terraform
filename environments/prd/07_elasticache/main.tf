# prd / 07_elasticache — ElastiCache（redis）+ cache-sg。
# 依存: 01_network, 02_database, 03_compute_ec2, 04_compute_ecs。
# Why: cache-sg の ingress は database/compute の各 SG からのみ許可する（SG 間参照で最小権限）。
#      stg のような VPC CIDR 全開放は採用しない。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

data "terraform_remote_state" "database" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.database
  })
}

data "terraform_remote_state" "compute_ec2" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.compute_ec2
  })
}

data "terraform_remote_state" "compute_ecs" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.compute_ecs
  })
}

module "elasticache" {
  source       = "../../../modules/elasticache"
  project_name = var.project_name
  env          = var.env

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c
  ]
  allowed_security_group_ids = compact([
    data.terraform_remote_state.database.outputs.public_security_group_id,
    data.terraform_remote_state.compute_ec2.outputs.web_security_group_id,
    data.terraform_remote_state.compute_ecs.outputs.ecs_security_group_id,
  ])

  engine          = var.engine
  engine_version  = var.engine_version
  node_type       = var.node_type
  num_cache_nodes = var.num_cache_nodes
  port            = var.port
}
