# 短命コマンドの集約。誤一括 apply を避けるため、スタック間の順序付きチェーンは持たない（順序は README 参照）。

ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

ENV ?= prd
STACK ?=
EXTRA_ARGS ?=

# init-all の走査順（README の apply 順に合わせる）
STACKS := 00_iam 01_network 01_network_nat 02_database 03_compute_ec2 03_ecr 04_compute_ecs 04_compute_ecs_task 05_cicd 06_efs 07_elasticache

# stg（prd と同じ番号付き独立スタック構成。スタック集合も prd と同一）
STACKS_STG := 00_iam 01_network 01_network_nat 02_database 03_compute_ec2 03_ecr 04_compute_ecs 04_compute_ecs_task 05_cicd 06_efs 07_elasticache

# これらのゴールだけ STACK 必須（make 単体では MAKECMDGOALS が空になり得るためホワイトリスト方式）
NEEDS_STACK := init plan apply destroy validate providers

ifneq ($(filter $(NEEDS_STACK),$(MAKECMDGOALS)),)
ifeq ($(STACK),)
$(error STACK を指定してください。例: make plan STACK=01_network / make init STACK=bootstrap)
endif
endif

ifneq ($(STACK),)
ifeq ($(STACK),bootstrap)
TF_DIR := $(ROOT)/bootstrap
TF_INIT_BACKEND :=
else
TF_DIR := $(ROOT)/environments/$(ENV)/$(STACK)
TF_INIT_BACKEND := -backend-config=backend.hcl
endif
endif

.DEFAULT_GOAL := help

.PHONY: help list fmt fmt-check init init-bootstrap init-all init-all-stg plan apply destroy validate providers

help:
	@echo "共通変数: ENV=$(ENV)（prd / stg を切替） EXTRA_ARGS='...'（plan/apply/destroy に付与）"
	@echo ""
	@echo "  make list                         スタック名一覧（prd / stg）"
	@echo "  make fmt | make fmt-check         再帰 fmt / fmt 検査のみ"
	@echo "  make init-bootstrap               bootstrap のみ init（backend.hcl なし）"
	@echo "  make init-all                     bootstrap 後に prd 全スタックを順に init"
	@echo "  make init-all-stg                 stg 全スタックを順に init"
	@echo "  make init|plan|apply|destroy|validate STACK=<name> [ENV=prd|stg]"
	@echo "       prd: bootstrap | 00_iam | 01_network | 01_network_nat | 02_database |"
	@echo "                03_compute_ec2 | 03_ecr | 04_compute_ecs | 04_compute_ecs_task | 05_cicd |"
	@echo "                06_efs | 07_elasticache"
	@echo "       stg: prd と同じスタック名（00_iam 〜 07_elasticache、04_compute_ecs_task / 05_cicd 含む）"
	@echo "  make providers STACK=<name> [ENV=stg]   terraform providers（ロック確認用）"
	@echo ""
	@echo "  例: make plan STACK=01_network ENV=stg"
	@echo "      apply 順序は README「検証環境 (stg)」を参照"

list:
	@echo "-- prd --"
	@echo bootstrap
	@echo $(STACKS) | tr ' ' '\n'
	@echo "-- stg --"
	@echo $(STACKS_STG) | tr ' ' '\n'

fmt:
	cd "$(ROOT)" && terraform fmt -recursive

fmt-check:
	cd "$(ROOT)" && terraform fmt -check -recursive

init-bootstrap:
	cd "$(ROOT)/bootstrap" && terraform init $(EXTRA_ARGS)

init-all: init-bootstrap
	@set -e; for s in $(STACKS); do $(MAKE) init STACK=$$s EXTRA_ARGS="$(EXTRA_ARGS)"; done

init-all-stg:
	@set -e; for s in $(STACKS_STG); do $(MAKE) init STACK=$$s ENV=stg EXTRA_ARGS="$(EXTRA_ARGS)"; done

init:
	cd "$(TF_DIR)" && terraform init $(TF_INIT_BACKEND) $(EXTRA_ARGS)

plan:
	cd "$(TF_DIR)" && terraform plan $(EXTRA_ARGS)

apply:
	cd "$(TF_DIR)" && terraform apply $(EXTRA_ARGS)

destroy:
	cd "$(TF_DIR)" && terraform destroy $(EXTRA_ARGS)

validate:
	cd "$(TF_DIR)" && terraform validate $(EXTRA_ARGS)

providers:
	cd "$(TF_DIR)" && terraform providers $(EXTRA_ARGS)
