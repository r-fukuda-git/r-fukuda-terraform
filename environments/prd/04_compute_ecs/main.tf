# prd / 04_compute_ecs — ECS Fargate 常駐 Service + ALB + alb-sg / ecs-sg。
# 依存: 01_network, 00_iam, 03_ecr。
# SG は本スタックで直接管理する（旧 modules/sg の create_ecs_and_alb_security_groups=true 相当を
# インライン化）。ingress は最小権限のまま: ALB は source_cidr_blocks、ECS は ALB からのみ許可。
# Why: SG のアドレスは modules/sg → root へ moved 済みなので plan は state move のみ。
#      aws_security_group に description を設定しない（旧 modules/sg も未設定。設定すると再作成）。
# Note: private サブネットの Fargate がイメージを取得できるよう 03_ecr（VPC エンドポイント）を併用する。
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

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecr
  })
}

locals {
  name   = "${var.project_name}-${var.env}"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  source_cidr_blocks = distinct(var.source_cidr_blocks)
  target_cidr_blocks = distinct(var.target_cidr_blocks)
}

# --- moved: modules/sg（create_ecs_and_alb_security_groups=true）→ インライン ---
moved {
  from = module.security_group.aws_security_group.alb[0]
  to   = aws_security_group.alb
}
moved {
  from = module.security_group.aws_security_group.ecs_sg[0]
  to   = aws_security_group.ecs
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_http_alb[0]
  to   = aws_security_group_rule.alb_ingress_http
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_https_alb[0]
  to   = aws_security_group_rule.alb_ingress_https
}
moved {
  from = module.security_group.aws_security_group_rule.egress_all_alb[0]
  to   = aws_security_group_rule.alb_egress
}
moved {
  from = module.security_group.aws_security_group_rule.ingress_allow_alb_to_ecs[0]
  to   = aws_security_group_rule.ecs_ingress_from_alb
}
moved {
  from = module.security_group.aws_security_group_rule.egress_all_ecs[0]
  to   = aws_security_group_rule.ecs_egress
}

resource "aws_security_group" "alb" {
  name   = "${local.name}-alb-sg"
  vpc_id = local.vpc_id

  tags = {
    Name      = "${local.name}-alb-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP to ALB"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS to ALB"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "All"
}

resource "aws_security_group" "ecs" {
  name   = "${local.name}-ecs-sg"
  vpc_id = local.vpc_id

  tags = {
    Name      = "${local.name}-ecs-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.ecs_container_port
  to_port                  = var.ecs_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow traffic from ALB"
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.ecs.id
  description       = "All"
}

module "ecs" {
  source       = "../../../modules/ecs"
  env          = var.env
  project_name = var.project_name

  ecr_repository_url     = data.terraform_remote_state.ecr.outputs.ecr_repository_url
  service_image_tag      = var.ecs_image_tag
  service_container_port = var.ecs_container_port
  service_host_port      = var.ecs_container_port
  service_desired_count  = var.ecs_desired_count
  service_task_cpu       = var.ecs_task_cpu
  service_task_memory    = var.ecs_task_memory

  execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn
  task_role_arn      = data.terraform_remote_state.iam.outputs.ecs_task_role_arn
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id

  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c
  ]
  public_subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_public_id_1a,
    data.terraform_remote_state.network.outputs.subnet_public_id_1c
  ]

  security_group_ids     = [aws_security_group.ecs.id]
  alb_security_group_ids = [aws_security_group.alb.id]

  health_check_path = var.ecs_health_check_path
}
