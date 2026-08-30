#!/usr/bin/env bash
# ============================================================
# test-workflow-entry.sh — workflow-entry.sh（作業の入口ガード）のユニットテスト
# ============================================================
# .claude/docs/10_spec/ワークフロー入口ガード.md のテストシナリオを検証する。
# 一時ディレクトリをプロジェクトルートに見立てて stdin に JSON を与え、
# exit code / stderr / stdout を検証する。
#
# 使い方: bash .claude/hooks/tests/test-workflow-entry.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 検証対象は WF_ENTRY_SCRIPT で差し替えられる（本番フックを書き換える前に新版を検証するため）
ENTRY="${WF_ENTRY_SCRIPT:-$(cd "${SCRIPT_DIR}/.." && pwd)/workflow-entry.sh}"
SESSION="testsession"

TMP=$(mktemp -d)
ERRF=$(mktemp)
trap 'rm -rf "${TMP}" "${ERRF}"' EXIT
TICKETS="${TMP}/wip/10_tickets"
mkdir -p "${TMP}/.claude/hooks" "${TICKETS}/00_todo" "${TICKETS}/10_doing" "${TICKETS}/20_done"

if command -v cygpath >/dev/null 2>&1; then
    TMPW=$(cygpath -m "${TMP}")
else
    TMPW="${TMP}"
fi

PASS=0
FAIL=0

# ---------- 入力 JSON ----------
# prompt は / で始まり得るため、MSYS のパス変換（/foo → C:/Program Files/Git/foo）を無効にして jq に渡す
prompt_json() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" jq -n --arg p "$1" --arg s "${SESSION}" '{hook_event_name: "UserPromptSubmit", session_id: $s, prompt: $p}'; }
skill_json()  { jq -n --arg k "$1" --arg s "${SESSION}" '{hook_event_name: "PostToolUse", tool_name: "Skill", session_id: $s, tool_input: {skill: $k}}'; }
tool_json()   { jq -n --arg t "$1" --arg s "${SESSION}" '{hook_event_name: "PreToolUse", tool_name: $t, session_id: $s, tool_input: {}}'; }

# ---------- 実行 ----------
run() { # $1=モード $2=stdin JSON。結果は R_EXIT / R_OUT / R_ERR
    R_OUT=$(CLAUDE_PROJECT_DIR="${TMPW}" WORKFLOW_ENFORCE="${ENFORCE:-1}" WORKFLOW_ENTRY_ENFORCE="${ENTRY_ENFORCE:-1}" \
        bash "${ENTRY}" "$1" 2>"${ERRF}" <<<"$2")
    R_EXIT=$?
    R_ERR=$(cat "${ERRF}")
}

check() { # $1=テストID $2=期待exit $3=含まれるべき文字列(空可) $4=含まれてはいけない文字列(空可)
    local id="$1" want_exit="$2" want="${3:-}" unwant="${4:-}"
    local combined="${R_ERR}${R_OUT}"
    if [ "${R_EXIT}" -ne "${want_exit}" ]; then
        echo "FAIL ${id}: exit ${R_EXIT} (expected ${want_exit}) : ${combined}"
        FAIL=$((FAIL + 1)); return
    fi
    if [ -n "${want}" ] && ! grep -q -- "${want}" <<<"${combined}"; then
        echo "FAIL ${id}: 出力に '${want}' が無い : ${combined}"
        FAIL=$((FAIL + 1)); return
    fi
    if [ -n "${unwant}" ] && grep -q -- "${unwant}" <<<"${combined}"; then
        echo "FAIL ${id}: 出力に '${unwant}' が含まれる : ${combined}"
        FAIL=$((FAIL + 1)); return
    fi
    echo "PASS ${id}"
    PASS=$((PASS + 1))
}

state_file() { echo "${TMP}/.claude/hooks/.state/${SESSION}.entry"; }
clear_state() { rm -rf "${TMP}/.claude/hooks/.state"; }

# ---------- TE001: 状態ファイルが無い（フック導入直後）と書き込み系は WF101 ----------
clear_state
run guard "$(tool_json Edit)"
check TE001 2 "WF101"
run guard "$(tool_json Bash)"
check TE001b 2 "WF101"

# ---------- TE002: プロンプト受信 → additionalContext で宣言を促す ----------
run prompt "$(prompt_json "README の誤字を直して")"
check TE002 0 '"additionalContext"'
check TE002b 0 "WF-ENTRY"
check TE002c 0 "workflow-light-task"
grep -q '^prompt_seq=1$' "$(state_file)" && echo "PASS TE002d" && PASS=$((PASS + 1)) || { echo "FAIL TE002d: prompt_seq が 1 でない"; FAIL=$((FAIL + 1)); }

# TE003: プロンプト直後（未宣言）の書き込み系は WF101
run guard "$(tool_json Write)"
check TE003 2 "WF101"
run guard "$(tool_json EnterPlanMode)"
check TE003b 2 "WF101"
run guard "$(tool_json Agent)"
check TE003c 2 "WF101"

# ---------- TE004: 入口スキルの読み込みを記録 → 許可 ----------
run record "$(skill_json workflow-light-task)"
check TE004 0 "" "WF"
run guard "$(tool_json Edit)"
check TE004b 0 "" "WF"
run guard "$(tool_json Bash)"
check TE004c 0 "" "WF"
grep -q '^workflow=workflow-light-task$' "$(state_file)" && echo "PASS TE004d" && PASS=$((PASS + 1)) || { echo "FAIL TE004d: workflow が記録されていない"; FAIL=$((FAIL + 1)); }

# ---------- TE005: 入口以外のスキル読み込みは宣言にならない ----------
clear_state
run prompt "$(prompt_json "issue 作って")"
run record "$(skill_json task-gh-issue)"
run guard "$(tool_json Edit)"
check TE005 2 "WF101"
run record "$(skill_json ticket-driven-workflow)"
run guard "$(tool_json Edit)"
check TE005b 2 "WF101"
# Skill 以外のツールの PostToolUse は無視する
run record "$(jq -n --arg s "${SESSION}" '{tool_name: "Edit", session_id: $s, tool_input: {skill: "workflow-light-task"}}')"
run guard "$(tool_json Edit)"
check TE005c 2 "WF101"

# ---------- TE006: 新しいプロンプトで宣言はリセットされる ----------
clear_state
run prompt "$(prompt_json "1 回目")"
run record "$(skill_json workflow-issue-mr-driven)"
run guard "$(tool_json Edit)"
check TE006 0 "" "WF"
run prompt "$(prompt_json "続けて")"
check TE006b 0 "前回の宣言: workflow-issue-mr-driven"
run guard "$(tool_json Edit)"
check TE006c 2 "WF101"
check TE006d 2 "前回の宣言: workflow-issue-mr-driven"
run record "$(skill_json workflow-issue-mr-driven)"
run guard "$(tool_json Edit)"
check TE006e 0 "" "WF"

# ---------- TE007: /<入口スキル> によるスラッシュ起動は宣言扱い ----------
clear_state
run prompt "$(prompt_json "/workflow-light-task README の誤字を直して")"
check TE007 0 "スラッシュ起動"
run guard "$(tool_json Edit)"
check TE007b 0 "" "WF"
# 複数行プロンプトでも 1 行目で判定する
run prompt "$(prompt_json "/workflow-issue-mr-driven
ログインのバグを直したい")"
run guard "$(tool_json Edit)"
check TE007c 0 "" "WF"
# 入口以外のスラッシュコマンドは宣言にならない
run prompt "$(prompt_json "/task-gh-issue バグ報告")"
run guard "$(tool_json Edit)"
check TE007d 2 "WF101"
# 名前の前方一致（/workflow-light-task-foo）は宣言にならない
run prompt "$(prompt_json "/workflow-light-task-foo x")"
run guard "$(tool_json Edit)"
check TE007e 2 "WF101"

# ---------- TE008: セッション単位で独立 ----------
clear_state
run prompt "$(prompt_json "a")"
run record "$(skill_json workflow-light-task)"
SESSION=othersession
run guard "$(tool_json Edit)"
check TE008 2 "WF101"
SESSION=testsession
run guard "$(tool_json Edit)"
check TE008b 0 "" "WF"

# ---------- TE009: 緊急脱出 ----------
clear_state
ENTRY_ENFORCE=0 run guard "$(tool_json Edit)"
check TE009 0 "" "WF"
ENFORCE=0 run guard "$(tool_json Edit)"
check TE009b 0 "" "WF"

# ---------- TE010: 壊れた状態ファイルは初期化扱い（未宣言） ----------
clear_state
mkdir -p "${TMP}/.claude/hooks/.state"
echo "garbage" >"$(state_file)"
run guard "$(tool_json Edit)"
check TE010 2 "WF101"
run prompt "$(prompt_json "x")"
check TE010b 0 "プロンプト #1"

# ---------- TE011: 不明なモードはブロックしない（フック設定ミスで作業を止めない） ----------
run bogus "$(tool_json Edit)"
check TE011 0 "不明なモード"

# ---------- TE012: 10_doing にチケットがあれば宣言不要（workflow-issue-mr-driven の継続） ----------
clear_state
echo "---" >"${TICKETS}/10_doing/001-investigation-a.md"
run prompt "$(prompt_json "続けて")"
check TE012 0 "継続中"
run guard "$(tool_json Edit)"
check TE012b 0 "" "WF101"
run guard "$(tool_json Bash)"
check TE012c 0 "" "WF101"
rm -f "${TICKETS}/10_doing/"*.md

# ---------- TE013: 00_todo にだけチケットがあっても継続 ----------
echo "---" >"${TICKETS}/00_todo/002-implementation-b.md"
run guard "$(tool_json Edit)"
check TE013 0 "" "WF101"
rm -f "${TICKETS}/00_todo/"*.md

# ---------- TE014: 20_done だけ / .gitkeep だけでは継続しない ----------
echo "---" >"${TICKETS}/20_done/001-investigation-a.md"
run guard "$(tool_json Edit)"
check TE014 2 "WF101"
run prompt "$(prompt_json "x")"
check TE014b 0 "宣言すること" "継続中"
rm -f "${TICKETS}/20_done/"*.md
echo "" >"${TICKETS}/10_doing/.gitkeep"
run guard "$(tool_json Edit)"
check TE014c 2 "WF101"
rm -f "${TICKETS}/10_doing/.gitkeep"

echo ""
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
