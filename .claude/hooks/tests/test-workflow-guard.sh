#!/usr/bin/env bash
# ============================================================
# test-workflow-guard.sh — workflow-guard.sh の git add / git mv 判定のユニットテスト
# ============================================================
# .claude/docs/10_spec/チケット駆動ワークフロー.md の
# 「wip/10_tickets/** への git mv / git add は判定表を経由せず常に許可される」を検証する。
# 一時ディレクトリをプロジェクトルートに見立てて stdin に JSON を与え、
# exit code / stdout / stderr を検証する。
#
# 使い方: bash .claude/hooks/tests/test-workflow-guard.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 検証対象は WF_GUARD_SCRIPT で差し替えられる
GUARD="${WF_GUARD_SCRIPT:-$(cd "${SCRIPT_DIR}/.." && pwd)/workflow-guard.sh}"
SESSION="testsession"

TMP=$(mktemp -d)
ERRF=$(mktemp)
trap 'rm -rf "${TMP}" "${ERRF}"' EXIT

if command -v cygpath >/dev/null 2>&1; then
    TMPW=$(cygpath -m "${TMP}")
else
    TMPW="${TMP}"
fi

PASS=0
FAIL=0

TICKET_NAME="001-implementation-dummy.md"
DOING_DIR="${TMP}/wip/10_tickets/10_doing"
mkdir -p "${DOING_DIR}" "${TMP}/wip/10_tickets/00_todo" "${TMP}/wip/10_tickets/20_done" "${TMP}/.claude/hooks"

write_ticket() { # $1=type
    cat >"${DOING_DIR}/${TICKET_NAME}" <<EOF
---
type: $1
status: doing
depends_on: []
---

# dummy
EOF
}

write_types() { # $1=workflow-types.json の内容
    printf '%s' "$1" >"${TMP}/.claude/hooks/workflow-types.json"
}

cmd_json() { # $1=command
    jq -n --arg c "$1" --arg s "${SESSION}" \
        '{hook_event_name: "PreToolUse", tool_name: "Bash", session_id: $s, tool_input: {command: $c}}'
}

edit_json() { # $1=tool(Edit|Write) $2=リポジトリ相対パス
    jq -n --arg t "$1" --arg p "${TMPW}/$2" --arg s "${SESSION}" \
        '{hook_event_name: "PreToolUse", tool_name: $t, session_id: $s, tool_input: {file_path: $p, content: "x"}}'
}

# 実物の作業タイプ定義を読み込む（フェーズ別ワークスキル用 type の検証に使う）
use_real_types() {
    cp "${SCRIPT_DIR}/../workflow-types.json" "${TMP}/.claude/hooks/workflow-types.json"
}

run() { # $1=stdin JSON。結果は R_EXIT / R_OUT / R_ERR
    R_OUT=$(CLAUDE_PROJECT_DIR="${TMPW}" WORKFLOW_ENFORCE=1 bash "${GUARD}" 2>"${ERRF}" <<<"$1")
    R_EXIT=$?
    R_ERR=$(cat "${ERRF}")
}

check() { # $1=テストID $2=期待exit $3=含まれるべき文字列(空可)
    local id="$1" want_exit="$2" want="${3:-}"
    local combined="${R_ERR}${R_OUT}"
    if [ "${R_EXIT}" -ne "${want_exit}" ]; then
        echo "FAIL ${id}: exit ${R_EXIT} (expected ${want_exit}) : ${combined}"
        FAIL=$((FAIL + 1)); return
    fi
    if [ -n "${want}" ] && ! grep -q -- "${want}" <<<"${combined}"; then
        echo "FAIL ${id}: 出力に '${want}' が無い : ${combined}"
        FAIL=$((FAIL + 1)); return
    fi
    echo "PASS ${id}"
    PASS=$((PASS + 1))
}

write_ticket implementation

# ---------- TG001: global.allow_paths を空にしても git add wip/10_tickets/** は allow ----------
write_types '{"global": {"allow_paths": [], "deny_paths": [], "ask_paths": []}, "types": {"implementation": {"allow_paths": [], "deny_paths": [], "ask_paths": []}}}'
run "$(cmd_json "git add wip/10_tickets/10_doing/${TICKET_NAME}")"
check TG001 0

# ---------- TG002: global.allow_paths を空にしても git mv wip/10_tickets/** 同士は allow（回帰確認） ----------
run "$(cmd_json "git mv wip/10_tickets/10_doing/${TICKET_NAME} wip/10_tickets/20_done/${TICKET_NAME}")"
check TG002 0

# ---------- TG003: types.<type>.deny_paths に wip/10_tickets/** を指定しても git add は常に allow ----------
write_types '{"global": {"allow_paths": [], "deny_paths": [], "ask_paths": []}, "types": {"implementation": {"allow_paths": [], "deny_paths": ["wip/10_tickets/**"], "ask_paths": []}}}'
run "$(cmd_json "git add wip/10_tickets/10_doing/${TICKET_NAME}")"
check TG003 0

# ---------- TG004: wip/10_tickets/ 以外の未記載パスは従来どおり確認（WF009） ----------
write_types '{"global": {"allow_paths": [], "deny_paths": [], "ask_paths": []}, "types": {"implementation": {"allow_paths": [], "deny_paths": [], "ask_paths": []}}}'
run "$(cmd_json "git add src/main.ts")"
check TG004 0 'WF009'

# ============================================================
# フェーズ別ワークスキル用 type（.claude/docs/10_spec/フェーズ別ワークスキル.md TC032〜TC035・TC039）
# 実物の workflow-types.json を使い、type 定義の追加だけで許可範囲が成立することを検証する
# ============================================================
use_real_types

# ---------- TC032: design は docs/** を allow、.claude/** は global deny（WF002） ----------
write_ticket design
run "$(edit_json Edit docs/spec.md)"
check TC032a 0
run "$(edit_json Edit .claude/hooks/x.sh)"
check TC032b 2 'WF002'

# ---------- TC033: design-sync も同様 ----------
write_ticket design-sync
run "$(edit_json Edit docs/spec.md)"
check TC033a 0
run "$(edit_json Edit .claude/docs/x.md)"
check TC033b 2 'WF002'

# ---------- TC034: overall-plan は global deny の wip/00_overall_plan/** を type allow で貫通、src/** は未記載（WF009） ----------
write_ticket overall-plan
run "$(edit_json Write wip/00_overall_plan/plan.md)"
check TC034a 0
run "$(edit_json Write src/foo.ts)"
check TC034b 0 'WF009'

# ---------- TC035: 計画 type は wip/20_plans/** と wip/10_tickets/00_todo/**（global allow）に書ける。src/** は未記載（WF009） ----------
write_ticket investigation-plan
run "$(edit_json Write wip/20_plans/計画.md)"
check TC035a 0
run "$(edit_json Write wip/10_tickets/00_todo/003-investigation-x.md)"
check TC035b 0
run "$(edit_json Write src/foo.ts)"
check TC035c 0 'WF009'

# ---------- TC039: implementation に docs/** は無い（設計書の更新は設計反映ワークへ。WF009） ----------
write_ticket implementation
run "$(edit_json Edit docs/spec.md)"
check TC039 0 'WF009'

echo
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
