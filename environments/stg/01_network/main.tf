# stg / 01_network — stg 専用 VPC / サブネット / IGW / ルートテーブル。
# 依存なし。全シナリオの前提。基本は 1 回 apply して建てっぱなしにする。
# Why: VPC 帯は prd(192.168.0.0/16) と重ならない 10.20.0.0/16 にして誤接続を防ぐ。
module "networking" {
  source = "../../../modules/networking"

  env               = var.env
  project_name      = var.project_name
  cidr_block_vpc    = var.cidr_block_vpc
  route_cidr_block  = var.route_cidr_block
  public_subnet_1a  = var.public_subnet_1a
  public_subnet_1c  = var.public_subnet_1c
  private_subnet_1a = var.private_subnet_1a
  private_subnet_1c = var.private_subnet_1c
}
