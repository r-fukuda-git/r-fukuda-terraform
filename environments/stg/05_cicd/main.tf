# stg / 05_cicd — GitHub Actions OIDC フェデレーション（デプロイロールのみ）。
# 依存: 00_iam, 03_ecr。
# Why: OIDC プロバイダは AWS アカウント単位で 1 つ。prd/05_cicd が作成済みなので、
#      ここでは create_oidc_provider=false でその既存プロバイダを data 参照する。
#      main_deploy_branches は現状 prd と同じ [main]。stg 専用ブランチに絞りたい場合は
#      terraform.tfvars で main_branch を変更する（operator 判断）。
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

module "github_actions_oidc" {
  source = "../../../modules/github_actions_oidc"

  env               = var.env
  project_name      = var.project_name
  github_owner      = var.github_owner
  github_repository = var.github_repository

  create_oidc_provider = false
  main_deploy_branches = [var.main_branch]

  ecr_repository_arn          = data.terraform_remote_state.ecr.outputs.ecr_repository_arn
  ecs_task_execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn
  ecs_task_role_arn           = data.terraform_remote_state.iam.outputs.ecs_task_role_arn
}
