#!/usr/bin/env bash
# ============================================================
# test-json-syntax.sh — リポジトリ内の JSON 設定・evals の構文チェック
# ============================================================
# .claude/hooks/workflow-types.json と .claude/skills/*/evals/evals.json を jq で解析し、
# 構文エラーと必須キー（types / skill_name・evals）の欠落を検出する。
# フックは workflow-types.json を毎回読み込むため、壊れていると WF007 で全ツールが止まる。
# evals.json は skill-creator の評価に使うため、壊れていると評価が走らない。
#
# 使い方: bash .claude/hooks/tests/test-json-syntax.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

PASS=0
FAIL=0

check_json() { # $1=テストID $2=ファイル $3=jq フィルタ（true を返せば合格）
    local id="$1" file="$2" filter="$3" out
    if [ ! -f "${file}" ]; then
        echo "FAIL ${id}: ${file} が無い"
        FAIL=$((FAIL + 1)); return
    fi
    if ! out=$(jq -e "${filter}" "${file}" 2>&1); then
        echo "FAIL ${id}: ${file} : ${out}"
        FAIL=$((FAIL + 1)); return
    fi
    echo "PASS ${id} (${file#"${ROOT}"/})"
    PASS=$((PASS + 1))
}

# ---------- TJ001: 作業タイプ定義 ----------
check_json TJ001 "${ROOT}/.claude/hooks/workflow-types.json" \
    '(.types | type) == "object" and (.types | length) > 0 and ([.types[] | has("allow_paths")] | all)'

# ---------- TJ002: settings.json ----------
check_json TJ002 "${ROOT}/.claude/settings.json" '(.hooks | type) == "object"'

# ---------- TJ003: 各スキルの evals.json ----------
shopt -s nullglob
n=0
for f in "${ROOT}"/.claude/skills/*/evals/evals.json; do
    n=$((n + 1))
    check_json "TJ003-${n}" "${f}" \
        '(.skill_name | type) == "string" and (.evals | type) == "array" and (.evals | length) > 0 and ([.evals[] | has("prompt") and has("expected_output")] | all)'
done
shopt -u nullglob
if [ "${n}" -eq 0 ]; then
    echo "FAIL TJ003: evals.json が 1 件も見つからない"
    FAIL=$((FAIL + 1))
fi

echo
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
