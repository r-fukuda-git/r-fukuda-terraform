# stg / 04_compute_ecs — ECS Fargate 常駐 Service + ALB + alb-sg / ecs-sg。
# 依存: 01_network, 00_iam。ecs_use_ecr=true のときのみ 03_ecr にも依存。
# Note: private サブネットの Fargate がイメージを取得できるよう、
#       01_network_nat か 03_ecr（VPC エンドポイント）のどちらかを併用すること。
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
  count = var.ecs_use_ecr ? 1 : 0

  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecr
  })
}

locals {
  name       = "${var.project_name}-${var.env}"
  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  image_repo = var.ecs_use_ecr ? data.terraform_remote_state.ecr[0].outputs.ecr_repository_url : var.ecs_image_repo
  private_subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c,
  ]
  public_subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_public_id_1a,
    data.terraform_remote_state.network.outputs.subnet_public_id_1c,
  ]
}

# -----------------------------------------------------------------------------
# Security Groups（本スタックで直接管理）
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "stg ALB"
  vpc_id      = local.vpc_id
  tags        = { Name = "${local.name}-alb-sg" }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "HTTP to ALB"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.egress_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "all"
}

resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs-sg"
  description = "stg ECS task"
  vpc_id      = local.vpc_id
  tags        = { Name = "${local.name}-ecs-sg" }
}

resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.ecs_container_port
  to_port                  = var.ecs_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
  description              = "from ALB"
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.egress_cidr_blocks
  security_group_id = aws_security_group.ecs.id
  description       = "all"
}

# -----------------------------------------------------------------------------
# ECS
# -----------------------------------------------------------------------------
module "ecs" {
  source = "../../../modules/ecs"

  env          = var.env
  project_name = var.project_name

  execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn
  task_role_arn      = data.terraform_remote_state.iam.outputs.ecs_task_role_arn

  ecr_repository_url = local.image_repo
  service_image_tag  = var.ecs_image_tag

  service_container_port = var.ecs_container_port
  service_host_port      = var.ecs_container_port
  service_desired_count  = var.ecs_desired_count
  service_task_cpu       = var.ecs_task_cpu
  service_task_memory    = var.ecs_task_memory
  health_check_path      = var.ecs_health_check_path

  subnet_ids             = local.private_subnet_ids
  public_subnet_ids      = local.public_subnet_ids
  security_group_ids     = [aws_security_group.ecs.id]
  alb_security_group_ids = [aws_security_group.alb.id]
  vpc_id                 = local.vpc_id
}
