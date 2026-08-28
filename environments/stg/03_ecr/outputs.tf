output "ecr_repository_url" {
  description = "docker login / image URI base"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecr_repository_arn" {
  value = module.ecr.repository_arn
}

output "vpc_endpoint_security_group_id" {
  value = var.create_vpc_endpoints ? module.vpc_endpoints_ecs[0].endpoint_security_group_id : null
}
