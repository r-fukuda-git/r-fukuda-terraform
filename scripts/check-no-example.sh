#!/usr/bin/env bash
# *.example ファイルがリポジトリに存在しないことを保証する。
# backend.hcl / terraform.tfvars の雛形は README「使い方」と variables.tf に集約する方針。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

found="$(git ls-files '*.example')"
if [ -n "${found}" ]; then
  echo "*.example ファイルは禁止です:" >&2
  echo "${found}" | sed 's/^/  - /' >&2
  exit 1
fi
echo "no-example OK"
