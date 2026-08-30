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

echo
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
