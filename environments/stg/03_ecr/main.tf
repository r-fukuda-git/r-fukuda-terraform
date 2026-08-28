# stg / 03_ecr — ECR リポジトリ + プライベートサブネット向け VPC エンドポイント。
# 依存: 01_network。
# Why: prd の 03_ecr と同じく VPC エンドポイントを同梱する。private の Fargate が
#      NAT なしで ECR pull / ログ出力できる。NAT を使う場合は 01_network_nat 側で足りる。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

module "ecr" {
  source = "../../../modules/ecr"

  env                  = var.env
  project_name         = var.project_name
  repository_suffix    = var.repository_suffix
  scan_on_push         = var.ecr_scan_on_push
  image_tag_mutability = var.image_tag_mutability
  lifecycle_policy     = var.lifecycle_policy
  force_delete         = var.ecr_force_delete # Why: stg は destroy 前提。イメージが残っていても消せるように
}

module "vpc_endpoints_ecs" {
  count  = var.create_vpc_endpoints ? 1 : 0
  source = "../../../modules/vpc_endpoints_ecs"

  env          = var.env
  project_name = var.project_name

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c,
  ]
  private_route_table_ids = [
    data.terraform_remote_state.network.outputs.private_route_table_id,
  ]
}
