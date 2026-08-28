# stg / 03_compute_ec2 — public サブネットの EC2 + web-sg。
# 依存: 01_network, 00_iam。
# web-sg は本スタックで直接管理し、ingress は admin_cidr_blocks に絞る。
data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.iam
  })
}

locals {
  name = "${var.project_name}-${var.env}"
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "stg web/EC2"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags        = { Name = "${local.name}-web-sg" }
}

resource "aws_security_group_rule" "web_ingress" {
  for_each = toset(["22", "80", "443"])

  type              = "ingress"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "admin access :${each.value}"
}

resource "aws_security_group_rule" "web_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.egress_cidr_blocks
  security_group_id = aws_security_group.web.id
  description       = "all"
}

module "ec2" {
  source = "../../../modules/ec2"

  env                     = var.env
  project_name            = var.project_name
  ec2_instance_count      = var.ec2_instance_count
  ec2_instance_type       = var.ec2_instance_type
  key_path                = var.ec2_key_path
  subnet_id               = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  security_groups         = [aws_security_group.web.id]
  iam_instance_profile    = data.terraform_remote_state.iam.outputs.iam_instance_profile
  disable_api_termination = var.ec2_disable_api_termination
}
