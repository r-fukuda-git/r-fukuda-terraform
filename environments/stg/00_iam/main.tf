# stg / 00_iam — EC2 インスタンスプロファイルと ECS タスクロール群。
# 依存なし。EC2 か ECS を立てるシナリオで先に apply しておく。
module "iam" {
  source = "../../../modules/iam"

  env          = var.env
  project_name = var.project_name
}
