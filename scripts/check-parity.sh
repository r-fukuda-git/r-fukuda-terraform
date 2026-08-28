#!/usr/bin/env bash
# prd / stg の各スタックの .tf が一致しているかを検査する。
#   - 差分があるファイルが .parity-exceptions に載っていなければ FAIL
#   - .parity-exceptions に載っているのに実際は一致 / 存在しない行があれば FAIL（リストの陳腐化防止）
# env 差は backend.hcl と terraform.tfvars のみに閉じる、という運用の番人。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

exceptions_file=".parity-exceptions"
prd_root="environments/prd"
stg_root="environments/stg"

# 除外リスト（コメント・空行を除く）。bash 3.2 でも動くよう mapfile は使わない
exceptions=()
while IFS= read -r line; do
  [ -n "${line}" ] && exceptions+=("${line}")
done < <(grep -vE '^[[:space:]]*(#|$)' "${exceptions_file}" | sed 's/[[:space:]]*$//')

in_exceptions() {
  local needle="$1"
  local e
  [ "${#exceptions[@]}" -eq 0 ] && return 1
  for e in "${exceptions[@]}"; do
    [ "${e}" = "${needle}" ] && return 0
  done
  return 1
}

diffs=()          # 差分あり & 除外なし → 違反
undeclared_ok=()  # 除外に載っているが実際は一致 or 不在 → 陳腐化
matched_exc=()    # 差分あり & 除外あり（想定どおり）

while IFS= read -r stack_dir; do
  stack="$(basename "${stack_dir}")"
  [ -d "${stg_root}/${stack}" ] || continue
  while IFS= read -r prd_file; do
    rel="${stack}/$(basename "${prd_file}")"
    stg_file="${stg_root}/${stack}/$(basename "${prd_file}")"
    if [ ! -f "${stg_file}" ]; then
      if in_exceptions "${rel}"; then matched_exc+=("${rel} (stg 側なし)"); else diffs+=("${rel} (stg 側にファイルなし)"); fi
      continue
    fi
    if diff -q "${prd_file}" "${stg_file}" >/dev/null 2>&1; then
      if in_exceptions "${rel}"; then undeclared_ok+=("${rel}"); fi
    else
      if in_exceptions "${rel}"; then matched_exc+=("${rel}"); else diffs+=("${rel}"); fi
    fi
  done < <(find "${stack_dir}" -maxdepth 1 -name '*.tf' -type f | sort)
done < <(find "${prd_root}" -maxdepth 1 -mindepth 1 -type d | sort)

# 除外リストに載っているが prd 側に存在しないパス
if [ "${#exceptions[@]}" -gt 0 ]; then
  for e in "${exceptions[@]}"; do
    stack="${e%%/*}"; base="${e##*/}"
    [ -f "${prd_root}/${stack}/${base}" ] || undeclared_ok+=("${e} (prd 側なし)")
  done
fi

status=0
if [ "${#matched_exc[@]}" -gt 0 ]; then
  echo "== 既知の差分（.parity-exceptions で除外中、${#matched_exc[@]} 件）=="
  printf '  - %s\n' "${matched_exc[@]}"
fi
if [ "${#undeclared_ok[@]}" -gt 0 ]; then
  echo "== 陳腐化した除外行（一致済み or 不在。.parity-exceptions から削除すること、${#undeclared_ok[@]} 件）=="
  printf '  - %s\n' "${undeclared_ok[@]}"
  status=1
fi
if [ "${#diffs[@]}" -gt 0 ]; then
  echo "== 未宣言の差分（prd と stg で .tf が不一致。揃えるか .parity-exceptions に追記、${#diffs[@]} 件）=="
  printf '  - %s\n' "${diffs[@]}"
  status=1
fi

if [ "${status}" -eq 0 ]; then
  echo "parity OK（除外 ${#matched_exc[@]} 件、未宣言の差分なし）"
fi
exit "${status}"
