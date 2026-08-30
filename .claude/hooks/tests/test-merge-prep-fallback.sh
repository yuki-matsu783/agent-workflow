#!/usr/bin/env bash
# ============================================================
# test-merge-prep-fallback.sh — merge-prep.sh の gh CLI 不在時フォールバックのユニットテスト
# ============================================================
# .claude/docs/10_spec/チケット駆動ワークフロー.md「gh CLI 不在時のフォールバック」を検証する。
# 実 git リポジトリ（一時ディレクトリ + bare リモート）を組み立て、gh を含まない PATH で
# merge-prep.sh を実行し、--pr / notify-issue --external / ready --external の挙動を確認する。
#
# 使い方: bash .claude/hooks/tests/test-merge-prep-fallback.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MP="${MP_SCRIPT:-$(cd "${SCRIPT_DIR}/.." && pwd)/merge-prep.sh}"

TMP=$(mktemp -d)
BARE=$(mktemp -d)
# --pr-body-file 等に渡す一時ファイルは TMP（git の作業ツリー）の外に置く。
# TMP 内に置くと未追跡ファイルとして mp_dirty（git status --porcelain）に検知されてしまうため。
EXTDIR=$(mktemp -d)
trap 'rm -rf "${TMP}" "${BARE}" "${EXTDIR}"' EXIT

PASS=0
FAIL=0

# ---------- gh を含まない PATH の組み立て（test-work-boundary-fallback.sh と同じ方針） ----------
NOGH_BIN="${TMP}/.bin"
mkdir -p "${NOGH_BIN}"
for tool in bash sh env git jq cat sed grep tr date mktemp paste sort comm tail head rm mkdir cut wc printf true false expr basename dirname readlink find xargs du; do
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

# work-boundary.sh の review-state.json を直接組み立てる（completed / via: local）。
# ここは実リポジトリの WF012 保護の対象外（テスト用の使い捨て TMP リポジトリのため）。
HEAD_SHA_PLACEHOLDER="0000000000000000000000000000000000000000"
cat >"${TMP}/wip/10_tickets/review-state.json" <<EOF
{"version":1,"ticket":"001-investigation-a.md","work_type":"investigation","state":"completed","local":true,"via":"local","pr":null,"head_sha":"${HEAD_SHA_PLACEHOLDER}","request":{"comment_id":null,"url":null,"at":"2026-01-01T00:00:00Z"},"complete":{"at":"2026-01-01T00:00:00Z","review_decision":"APPROVED","comment_ids":[],"inline_ids":[]}}
EOF

PATH="${NOGH_PATH}" git -C "${TMP}" add -A
PATH="${NOGH_PATH}" git -C "${TMP}" commit -q -m init
PATH="${NOGH_PATH}" git -C "${TMP}" push -q -u origin main

run() { # $@=merge-prep.sh へ渡す引数。結果は R_EXIT / R_OUT / R_ERR
    local errf
    errf=$(mktemp)
    R_OUT=$(PATH="${NOGH_PATH}" CLAUDE_PROJECT_DIR="${TMP}" bash "${MP}" "$@" 2>"${errf}")
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

# ---------- MF01: status --pr <N>（gh 不在でも PR 番号を明示指定すれば動く） ----------
run status --pr 501
check MF01 0 '"pr": 501'

# ---------- MF02: reset-wip --dry-run --pr <N> ----------
run reset-wip --dry-run --pr 501
check MF02 0 '"dry_run": true'

# ---------- MF03: reset-wip --pr <N>（本実行。gh を一切呼ばずに完了する） ----------
run reset-wip --pr 501
check MF03 0 '"merge_state": "reset"'
[ ! -f "${TMP}/wip/10_tickets/review-state.json" ] && [ ! -f "${TMP}/wip/10_tickets/20_done/001-investigation-a.md" ] \
    && { echo "PASS MF03b"; PASS=$((PASS + 1)); } \
    || { echo "FAIL MF03b: wip の成果物が削除されていない"; FAIL=$((FAIL + 1)); }

# ---------- MF04: check-conflicts --pr <N>（gh を呼ばずに動く。衝突なし） ----------
run check-conflicts --pr 501
check MF04 0 '"has_conflict": false'

# ---------- MF05: ready --external --pr <N>（notify 前なので前提未充足） ----------
run ready --external --pr 501
check MF05 2 "notified ではありません"

# ---------- MF06: notify-issue --external の必須引数不足 ----------
run notify-issue --external --pr 501
check MF06 2 "pr-body-file"

# ---------- MF07: notify-issue --external の --posted 不一致（不足） ----------
PRBODY="${EXTDIR}/pr-body.md"
printf 'Closes #7\n' >"${PRBODY}"
run notify-issue --external --pr 501 --pr-body-file "${PRBODY}" --posted "8:https://github.com/o/r/issues/8#issuecomment-1"
check MF07 2 "一致しません"

# ---------- MF08: notify-issue --external（正常） ----------
run notify-issue --external --pr 501 --pr-body-file "${PRBODY}" --posted "7:https://github.com/o/r/issues/7#issuecomment-1"
check MF08 0 '"merge_state": "notified"'

# ---------- MF09: ready --external に --pr が無い ----------
run ready --external
check MF09 2 "external には --pr"

# ---------- MF10: ready --external --pr <N>（正常。gh pr ready を呼ばずに完了） ----------
run ready --external --pr 501
check MF10 0 '"merge_state": "ready"'

echo "----------------------------------------"
echo "PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
