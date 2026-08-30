#!/usr/bin/env bash
# ============================================================
# test-work-boundary.sh — work-boundary.sh status の境界判定のユニットテスト
# ============================================================
# .claude/docs/10_spec/フェーズ別ワークスキル.md のテストシナリオ
# TC036（計画 → 実施でワーク境界）/ TC037（実施 → 次の計画でワーク境界）と、
# 同 type が続くときは境界でないこと（TC036b）を検証する。
# 一時ディレクトリをプロジェクトルートに見立て、wip/10_tickets/ にチケットを置いて
# `status` の JSON 出力を検証する（git / gh は使わない）。
#
# 使い方: bash .claude/hooks/tests/test-work-boundary.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 検証対象は WB_SCRIPT で差し替えられる
WB="${WB_SCRIPT:-$(cd "${SCRIPT_DIR}/.." && pwd)/work-boundary.sh}"

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

if command -v cygpath >/dev/null 2>&1; then
    TMPW=$(cygpath -m "${TMP}")
else
    TMPW="${TMP}"
fi

PASS=0
FAIL=0

TICKETS="${TMP}/wip/10_tickets"
mkdir -p "${TICKETS}/00_todo" "${TICKETS}/10_doing" "${TICKETS}/20_done" "${TMP}/.claude/hooks"

reset_tickets() {
    rm -f "${TICKETS}"/00_todo/*.md "${TICKETS}"/10_doing/*.md "${TICKETS}"/20_done/*.md
}

write_ticket() { # $1=dir(00_todo|10_doing|20_done) $2=filename $3=type
    cat >"${TICKETS}/$1/$2" <<EOF
---
type: $3
status: todo
depends_on: []
---

# dummy
EOF
}

run_status() { # 結果は R_OUT / R_EXIT
    R_OUT=$(CLAUDE_PROJECT_DIR="${TMPW}" bash "${WB}" status 2>/dev/null)
    R_EXIT=$?
}

check_field() { # $1=テストID $2=jq フィルタ $3=期待値
    local id="$1" filter="$2" want="$3" got
    if [ "${R_EXIT}" -ne 0 ]; then
        echo "FAIL ${id}: exit ${R_EXIT} : ${R_OUT}"
        FAIL=$((FAIL + 1)); return
    fi
    got=$(printf '%s' "${R_OUT}" | jq -r "${filter}" 2>/dev/null | tr -d '\r')
    if [ "${got}" != "${want}" ]; then
        echo "FAIL ${id}: ${filter} = '${got}' (expected '${want}') : ${R_OUT}"
        FAIL=$((FAIL + 1)); return
    fi
    echo "PASS ${id} (${filter} = ${want})"
    PASS=$((PASS + 1))
}

# ---------- TC036: 計画 → 実施でワーク境界 ----------
reset_tickets
write_ticket 20_done 001-overall-plan-全体計画.md overall-plan
write_ticket 20_done 002-investigation-plan-調査計画.md investigation-plan
write_ticket 00_todo 003-investigation-現状調査.md investigation
write_ticket 00_todo 004-investigation-制約調査.md investigation
write_ticket 00_todo 005-design-plan-設計計画.md design-plan
run_status
check_field TC036 '.at_boundary' true
check_field TC036 '.last_done_type' investigation-plan
check_field TC036 '.todo_head_type' investigation
check_field TC036 '.todo_same_type | length' 0

# ---------- TC036b: 同 type の実施チケットが続く間は境界でない ----------
reset_tickets
write_ticket 20_done 002-investigation-plan-調査計画.md investigation-plan
write_ticket 20_done 003-investigation-現状調査.md investigation
write_ticket 00_todo 004-investigation-制約調査.md investigation
write_ticket 00_todo 005-design-plan-設計計画.md design-plan
run_status
check_field TC036b '.at_boundary' false
check_field TC036b '.todo_head_type' investigation
check_field TC036b '.todo_same_type[0]' 004-investigation-制約調査.md

# ---------- TC037: 実施 → 次の計画でワーク境界 ----------
reset_tickets
write_ticket 20_done 003-investigation-現状調査.md investigation
write_ticket 20_done 004-investigation-制約調査.md investigation
write_ticket 00_todo 005-design-plan-設計計画.md design-plan
run_status
check_field TC037 '.at_boundary' true
check_field TC037 '.last_done_type' investigation
check_field TC037 '.todo_head_type' design-plan

# ---------- TC037b: 全体計画 → 最初の計画チケットで境界（type にハイフンが含まれても判定できる） ----------
reset_tickets
write_ticket 20_done 001-overall-plan-全体計画.md overall-plan
write_ticket 00_todo 002-ai-asset-design-plan-設計計画.md ai-asset-design-plan
run_status
check_field TC037b '.at_boundary' true
check_field TC037b '.last_done_type' overall-plan
check_field TC037b '.todo_head_type' ai-asset-design-plan

echo
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
