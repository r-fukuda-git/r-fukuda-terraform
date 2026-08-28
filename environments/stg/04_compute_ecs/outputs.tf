output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}
