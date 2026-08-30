#!/usr/bin/env bash
# ============================================================
# test-work-boundary-fallback.sh — work-boundary.sh の gh CLI 不在時フォールバックのユニットテスト
# ============================================================
# .claude/docs/10_spec/チケット駆動ワークフロー.md「--external（gh CLI 不在時のフォールバック）」を検証する。
# 実 git リポジトリ（一時ディレクトリ + bare リモート）を組み立て、gh を含まない PATH で
# work-boundary.sh を実行し、request/complete/reply の新フラグの挙動を確認する。
#
# 使い方: bash .claude/hooks/tests/test-work-boundary-fallback.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WB="${WB_SCRIPT:-$(cd "${SCRIPT_DIR}/.." && pwd)/work-boundary.sh}"

TMP=$(mktemp -d)
BARE=$(mktemp -d)
trap 'rm -rf "${TMP}" "${BARE}"' EXIT

PASS=0
FAIL=0

# ---------- gh を含まない PATH の組み立て ----------
# このテストは「gh が使えない環境」を検証するためのものなので、ホストに gh が
# 入っていても入っていなくても常に gh 不在を再現できるよう、必要なツールだけを
# 集めた PATH を組み立てて実行する。
NOGH_BIN="${TMP}/.bin"
mkdir -p "${NOGH_BIN}"
for tool in bash sh env git jq cat sed grep tr date mktemp paste sort comm tail head rm mkdir cut wc printf true false expr basename dirname readlink; do
    p=$(command -v "${tool}" 2>/dev/null) || continue
    ln -sf "${p}" "${NOGH_BIN}/${tool}"
done
NOGH_PATH="${NOGH_BIN}"

# ---------- リポジトリの組み立て ----------
mkdir -p "${TMP}/wip/10_tickets/00_todo" "${TMP}/wip/10_tickets/10_doing" "${TMP}/wip/10_tickets/20_done"
PATH="${NOGH_PATH}" git -C "${TMP}" init -q -b main
PATH="${NOGH_PATH}" git -C "${TMP}" config user.email test@example.com
PATH="${NOGH_PATH}" git -C "${TMP}" config user.name test
PATH="${NOGH_PATH}" git init -q --bare "${BARE}"
PATH="${NOGH_PATH}" git -C "${TMP}" remote add origin "${BARE}"

write_ticket() { # $1=相対パス $2=type
    mkdir -p "$(dirname "${TMP}/$1")"
    printf -- '---\ntype: %s\nstatus: done\ndepends_on: []\n---\n\n# dummy\n' "$2" >"${TMP}/$1"
}

write_ticket wip/10_tickets/20_done/001-investigation-a.md investigation
write_ticket wip/10_tickets/00_todo/002-implementation-b.md implementation
PATH="${NOGH_PATH}" git -C "${TMP}" add -A
PATH="${NOGH_PATH}" git -C "${TMP}" commit -q -m init
PATH="${NOGH_PATH}" git -C "${TMP}" push -q -u origin main

run() { # $1=サブコマンド以降の引数（配列でなく文字列展開）。結果は R_EXIT / R_OUT / R_ERR
    local errf
    errf=$(mktemp)
    R_OUT=$(PATH="${NOGH_PATH}" CLAUDE_PROJECT_DIR="${TMP}" bash "${WB}" "$@" 2>"${errf}")
    R_EXIT=$?
    R_ERR=$(cat "${errf}")
    rm -f "${errf}"
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

review_state_now() {
    run status
    printf '%s' "${R_OUT}" | jq -r '.review_state // "none"'
}

# ---------- TF01: --external に --comment-url が無い ----------
run request --external --pr 99
check TF01 2 "comment-url"

# ---------- TF02: --local と --external の同時指定 ----------
run request --local --external --pr 99 --comment-url http://example.invalid/x
check TF02 2 "同時に指定できません"

# ---------- TF03: gh 不在で --external を付けずに request（--pr のみ） ----------
# gh が PATH に無いため gh pr comment 相当の呼び出しが失敗し、WF013 で止まる
run request --pr 99
check TF03 2 "gh pr comment"

# ---------- TF04: request --external --pr <N> --comment-url <url> ----------
run request --external --pr 99 --comment-url "https://github.com/o/r/pull/99#issuecomment-12345"
check TF04 0 '"review_state": "requested"'
[ "$(review_state_now)" = "requested" ] && { echo "PASS TF04b"; PASS=$((PASS + 1)); } \
    || { echo "FAIL TF04b: review_state が requested になっていない"; FAIL=$((FAIL + 1)); }

# ---------- TF05: complete --external に --report-file が無い ----------
run complete --external
check TF05 2 "report-file"

# ---------- TF06: complete --external --report-file（CHANGES_REQUESTED） ----------
REPORT_CR="${TMP}/report-cr.json"
printf '%s' '{"review_decision":"CHANGES_REQUESTED","unresolved_threads":[],"comment_ids":[],"inline_ids":[],"new_comments":[],"new_reviews":[],"new_inline":[]}' >"${REPORT_CR}"
run complete --external --report-file "${REPORT_CR}"
check TF06 2 "CHANGES_REQUESTED"
[ "$(review_state_now)" = "requested" ] && { echo "PASS TF06b"; PASS=$((PASS + 1)); } \
    || { echo "FAIL TF06b: CHANGES_REQUESTED で状態が進んでしまった"; FAIL=$((FAIL + 1)); }

# ---------- TF07: complete --external --report-file（未解決スレッドあり） ----------
REPORT_UNRESOLVED="${TMP}/report-unresolved.json"
printf '%s' '{"review_decision":"APPROVED","unresolved_threads":[{"id":"c1","url":"http://x"},{"id":"c2","url":"http://y"}],"comment_ids":[],"inline_ids":[],"new_comments":[],"new_reviews":[],"new_inline":[]}' >"${REPORT_UNRESOLVED}"
run complete --external --report-file "${REPORT_UNRESOLVED}"
check TF07 2 "未解決のスレッド"

# ---------- TF08: --local/--external の不一致（request は external、complete は local） ----------
run complete --local
check TF08 2 "一致しません"

# ---------- TF09: complete --external --report-file（正常） ----------
REPORT_OK="${TMP}/report-ok.json"
printf '%s' '{"review_decision":"APPROVED","unresolved_threads":[],"comment_ids":["1"],"inline_ids":["2"],"new_comments":[{"id":"1","author":"reviewer","createdAt":"2026-01-01T00:00:00Z","url":"http://x","body":"looks good"}],"new_reviews":[{"author":"reviewer","state":"APPROVED","submittedAt":"2026-01-01T00:00:00Z","body":"lgtm"}],"new_inline":[]}' >"${REPORT_OK}"
run complete --external --report-file "${REPORT_OK}"
check TF09 0 '"review_state": "completed"'
[ "$(review_state_now)" = "completed" ] && { echo "PASS TF09b"; PASS=$((PASS + 1)); } \
    || { echo "FAIL TF09b: review_state が completed になっていない"; FAIL=$((FAIL + 1)); }

# ---------- TF10: reply は gh 不在時に使わない案内で止まる ----------
run reply 123 "対応しました"
check TF10 2 "MCP ツール"

echo "----------------------------------------"
echo "PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
