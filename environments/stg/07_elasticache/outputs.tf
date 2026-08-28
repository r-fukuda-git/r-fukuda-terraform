output "configuration_endpoint" {
  value = module.elasticache.configuration_endpoint
}

output "cluster_id" {
  value = module.elasticache.cluster_id
}

output "security_group_id" {
  value = module.elasticache.security_group_id
}
