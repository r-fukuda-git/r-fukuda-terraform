output "vpc_id" {
  value = module.networking.vpc_id
}

# Why: 下流スタック（02_database / 06_efs / 07_elasticache）はデータ層 SG の
#      ingress を VPC CIDR 許可で開けるため、CIDR 文字列そのものを出力する。
#      modules/networking は CIDR を出力しないので var を直接返す。
output "vpc_cidr" {
  value = var.cidr_block_vpc
}

output "subnet_public_id_1a" {
  value = module.networking.subnet_public_id_1a
}

output "subnet_public_id_1c" {
  value = module.networking.subnet_public_id_1c
}

output "subnet_private_id_1a" {
  value = module.networking.subnet_private_id_1a
}

output "subnet_private_id_1c" {
  value = module.networking.subnet_private_id_1c
}

output "private_route_table_id" {
  value = module.networking.private_route_table_id
}

output "internet_gateway_id" {
  value = module.networking.internet_gateway_id
}
