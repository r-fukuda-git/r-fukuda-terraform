output "web_security_group_id" {
  value = aws_security_group.web.id
}

# modules/ec2 は aws_instance を count で並べるため、以下はリストを返す
output "ec2_public_ips" {
  value = module.ec2.ec2_public_ip
}

output "ec2_instance_ids" {
  value = module.ec2.ec2_instance_id
}
