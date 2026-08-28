data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix     = "${var.project_name}-${var.env}"
  github_repo_sub = "repo:${var.github_owner}/${var.github_repository}"

  # Why: OIDC プロバイダは AWS アカウント単位で 1 つしか作れない。prd で作成済みの
  #      ものを stg など 2 つ目の環境から流用するため、create_oidc_provider=false で
  #      data 参照に切り替える。true（既定）なら従来どおり resource を作成する。
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github_actions[0].arn : data.aws_iam_openid_connect_provider.existing[0].arn
}

# Why: count 追加でアドレスが [0] 付きに変わる。作成済み prd/05_cicd で
#      state 上の provider を作り直させないための移設宣言。
moved {
  from = aws_iam_openid_connect_provider.github_actions
  to   = aws_iam_openid_connect_provider.github_actions[0]
}

data "tls_certificate" "github_actions" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.github_actions[0].certificates[0].sha1_fingerprint,
  ]

  tags = {
    Name = "${local.name_prefix}-github-actions-oidc"
  }
}

data "aws_iam_openid_connect_provider" "existing" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_actions_main_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for branch in var.main_deploy_branches : "${local.github_repo_sub}:ref:refs/heads/${branch}"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_main" {
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid    = "ECSDeploy"
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PassExecutionRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      var.ecs_task_execution_role_arn,
      var.ecs_task_role_arn,
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions_main" {
  name               = "${local.name_prefix}-github-actions-main"
  assume_role_policy = data.aws_iam_policy_document.github_actions_main_assume.json

  tags = {
    Name = "${local.name_prefix}-github-actions-main"
  }
}

resource "aws_iam_role_policy" "github_actions_main" {
  name   = "${local.name_prefix}-github-actions-main"
  role   = aws_iam_role.github_actions_main.id
  policy = data.aws_iam_policy_document.github_actions_main.json
}
