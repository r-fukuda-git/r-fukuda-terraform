# stg / 01_network_nat — プライベートサブネットに NAT Gateway 経由の egress を追加。
# 依存: 01_network。private の Fargate が公開レジストリからイメージ取得する等で必要。
# 03_ecr（VPC エンドポイント）と併用する必要はない（どちらか一方で足りる）。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

module "nat_gateway" {
  source = "../../../modules/nat_gateway"

  env                    = var.env
  project_name           = var.project_name
  public_subnet_id       = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  private_route_table_id = data.terraform_remote_state.network.outputs.private_route_table_id
  route_cidr_block       = var.route_cidr_block
}
