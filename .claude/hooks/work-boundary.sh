#!/usr/bin/env bash
# ============================================================
# work-boundary — ワーク境界の判定とレビュー状態の遷移（CLI）
# ============================================================
# 仕様: .claude/docs/10_spec/チケット駆動ワークフロー.md「ワーク境界の判定とレビュー状態」
#
# 使い方:
#   bash .claude/hooks/work-boundary.sh status
#   bash .claude/hooks/work-boundary.sh request [--body-file <path>] [--local]
#   bash .claude/hooks/work-boundary.sh complete [--local]
#   bash .claude/hooks/work-boundary.sh reply <inline_comment_id> <text>
#
# - 境界の判定は wip/10_tickets/ のファイル名の連番と frontmatter の type だけから決まる
# - レビュー状態 wip/10_tickets/review-state.json を書き換える唯一の経路。
#   request / complete は gh の実操作（コメント投稿・取得）を自ら行い、証跡を記録する
# - 前提未充足は exit 2 + stderr（[WF013] / [WF014]）。状態ファイルは書き換えない
# ============================================================
set -uo pipefail
shopt -u patsub_replacement 2>/dev/null || true

# shellcheck source=.claude/hooks/workflow-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/workflow-lib.sh"

WB_ROOT="${CLAUDE_PROJECT_DIR:-.}"
WB_ROOT="${WB_ROOT//\\//}"
WB_TICKETS="${WB_ROOT}/wip/10_tickets"
WB_STATE_REL="wip/10_tickets/review-state.json"
WB_STATE="${WB_ROOT}/${WB_STATE_REL}"
WB_PREFIX="Claude Code より:"
WF_LOG_FILE="${WB_ROOT}/.claude/hooks/workflow.log"

wb_die() { # $1=code $2=summary $3=未充足(改行区切り) $4=対処
    {
        printf '[%s] %s\n' "$1" "$2"
        [ -n "${3:-}" ] && printf '未充足: %s\n' "$(printf '%s' "$3" | paste -sd '/' - | sed 's,/, / ,g')"
        printf '対処: %s\n' "$4"
    } >&2
    wf_log "[boundary] ${1} ${2}"
    exit 2
}

# ---------- チケットの走査 ----------
wb_ticket_num() { # ファイル名の先頭の連番（数値でなければ空）
    local n="${1##*/}"
    n="${n%%-*}"
    [[ "${n}" =~ ^[0-9]+$ ]] && printf '%s' "${n}"
}

wb_ticket_type() { # $1=チケットのパス
    [ -f "$1" ] || return 0
    wf_extract_type "$(cat "$1")"
}

wb_compute() {
    DOING_COUNT=0
    LAST_DONE=""; LAST_DONE_TYPE=""
    TODO_HEAD=""; TODO_HEAD_TYPE=""
    TODO_SAME_TYPE=()
    AT_BOUNDARY=false
    REVIEW_STATE="none"
    STATE_JSON="null"
    [ -d "${WB_TICKETS}" ] || return 0

    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    local f n max=-1 min=-1
    for f in "${WB_TICKETS}"/10_doing/*.md; do DOING_COUNT=$((DOING_COUNT + 1)); done
    for f in "${WB_TICKETS}"/20_done/*.md; do
        n=$(wb_ticket_num "${f}"); [ -n "${n}" ] || continue
        if [ "$((10#${n}))" -gt "${max}" ]; then max=$((10#${n})); LAST_DONE="${f##*/}"; fi
    done
    for f in "${WB_TICKETS}"/00_todo/*.md; do
        n=$(wb_ticket_num "${f}"); [ -n "${n}" ] || continue
        if [ "${min}" -lt 0 ] || [ "$((10#${n}))" -lt "${min}" ]; then min=$((10#${n})); TODO_HEAD="${f##*/}"; fi
    done
    [ "${nullglob_was_set}" -eq 0 ] && shopt -u nullglob

    [ -n "${LAST_DONE}" ] && LAST_DONE_TYPE=$(wb_ticket_type "${WB_TICKETS}/20_done/${LAST_DONE}")
    [ -n "${TODO_HEAD}" ] && TODO_HEAD_TYPE=$(wb_ticket_type "${WB_TICKETS}/00_todo/${TODO_HEAD}")
    if [ -n "${LAST_DONE_TYPE}" ]; then
        shopt -s nullglob
        for f in "${WB_TICKETS}"/00_todo/*.md; do
            [ "$(wb_ticket_type "${f}")" = "${LAST_DONE_TYPE}" ] && TODO_SAME_TYPE+=("${f##*/}")
        done
        [ "${nullglob_was_set}" -eq 0 ] && shopt -u nullglob
    fi

    if [ "${DOING_COUNT}" -eq 0 ] && [ -n "${LAST_DONE}" ] \
        && { [ -z "${TODO_HEAD}" ] || [ "${TODO_HEAD_TYPE}" != "${LAST_DONE_TYPE}" ]; }; then
        AT_BOUNDARY=true
    fi

    if [ -f "${WB_STATE}" ]; then
        local st_ticket st_state
        st_ticket=$(wf_jq -r '.ticket // ""' "${WB_STATE}" 2>/dev/null || true)
        st_state=$(wf_jq -r '.state // ""' "${WB_STATE}" 2>/dev/null || true)
        if [ -n "${st_ticket}" ] && [ "${st_ticket}" = "${LAST_DONE}" ] && [ -n "${st_state}" ]; then
            REVIEW_STATE="${st_state}"
            STATE_JSON=$(tr -d '\r' <"${WB_STATE}")
        fi
    fi
}

wb_status_json() {
    local same='[]'
    if [ ${#TODO_SAME_TYPE[@]} -gt 0 ]; then
        same=$(printf '%s\n' "${TODO_SAME_TYPE[@]}" | wf_jq -R . | wf_jq -s -c .)
    fi
    wf_jq -n \
        --argjson doing "${DOING_COUNT}" \
        --arg ld "${LAST_DONE}" --arg ldt "${LAST_DONE_TYPE}" \
        --arg th "${TODO_HEAD}" --arg tht "${TODO_HEAD_TYPE}" \
        --argjson same "${same:-[]}" \
        --argjson ab "${AT_BOUNDARY}" \
        --arg rs "${REVIEW_STATE}" --argjson review "${STATE_JSON}" \
        '{doing_count: $doing,
          last_done: (if $ld == "" then null else $ld end),
          last_done_type: (if $ldt == "" then null else $ldt end),
          todo_head: (if $th == "" then null else $th end),
          todo_head_type: (if $tht == "" then null else $tht end),
          todo_same_type: $same,
          at_boundary: $ab,
          review_state: $rs,
          review: (if $rs == "none" then null else $review end)}'
}

# ---------- git / gh ----------
wb_git() { git -C "${WB_ROOT}" "$@"; }
wb_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

wb_pr_number() {
    gh pr view --json number -q .number 2>/dev/null | tr -d '\r'
}

wb_commit_state() { # $1=commit message
    wb_git add -- "${WB_STATE_REL}" || return 1
    wb_git commit -q -m "$1" -- "${WB_STATE_REL}" || return 1
}

# ---------- request ----------
wb_request() {
    local body_file="" local_mode=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --body-file) body_file="${2:-}"; shift 2 ;;
            --local) local_mode=true; shift ;;
            *) wb_die WF013 "レビュー依頼の前提未充足: 不明な引数 $1" "" "request [--body-file <path>] [--local] の形式で実行してください。" ;;
        esac
    done
    wb_compute
    local fails=""
    if [ "${AT_BOUNDARY}" != "true" ]; then
        if [ "${DOING_COUNT}" -gt 0 ]; then fails+="doing にチケットがあります（ワーク境界ではありません）"$'\n'
        elif [ -z "${LAST_DONE}" ]; then fails+="done のチケットがありません（ワーク境界ではありません）"$'\n'
        else fails+="ワーク境界ではありません（todo 先頭 ${TODO_HEAD} は直前の done と同じ type ${LAST_DONE_TYPE}）"$'\n'; fi
    fi
    [ "${REVIEW_STATE}" != "none" ] && fails+="既に ${REVIEW_STATE} です（${LAST_DONE}）"$'\n'
    [ -n "$(wb_git status --porcelain 2>/dev/null)" ] && fails+="未コミットの変更があります"$'\n'
    local pr=""
    if [ "${local_mode}" = false ]; then
        local head up
        head=$(wb_git rev-parse HEAD 2>/dev/null); up=$(wb_git rev-parse '@{u}' 2>/dev/null || true)
        [ -n "${up}" ] && [ "${head}" = "${up}" ] || fails+="HEAD が push されていません（git push してください）"$'\n'
        pr=$(wb_pr_number)
        [ -n "${pr}" ] || fails+="現在のブランチに open な PR がありません"$'\n'
    fi
    [ -n "${fails}" ] && wb_die WF013 "レビュー依頼の前提未充足: request を実行できません" "${fails%$'\n'}" \
        "未充足の条件を解消してから再実行してください。境界でない場合は次のチケットに着手してください。既に requested の場合はレビュー完了の連絡を待って complete を実行してください。"

    local comment_id="" comment_url="" head_sha
    head_sha=$(wb_git rev-parse HEAD)
    if [ "${local_mode}" = false ]; then
        local tmp
        tmp=$(mktemp)
        {
            printf '%s ワーク %s（%s）が完了しました。レビューをお願いします。\n' "${WB_PREFIX}" "${LAST_DONE_TYPE}" "${LAST_DONE}"
            printf '<!-- work-boundary: request ticket=%s -->\n\n' "${LAST_DONE}"
            [ -n "${body_file}" ] && [ -f "${body_file}" ] && cat "${body_file}"
        } >"${tmp}"
        comment_url=$(gh pr comment "${pr}" --body-file "${tmp}" 2>&1 | tr -d '\r' | tail -1)
        rm -f "${tmp}"
        case "${comment_url}" in
            http*issuecomment-*) comment_id="${comment_url##*issuecomment-}" ;;
            *) wb_die WF013 "レビュー依頼の前提未充足: gh pr comment に失敗しました" "${comment_url}" "gh の認証・PR の状態を確認してから再実行してください。状態ファイルは変更していません。" ;;
        esac
    fi

    wf_jq -n --arg t "${LAST_DONE}" --arg wt "${LAST_DONE_TYPE}" --argjson local "${local_mode}" \
        --arg pr "${pr}" --arg sha "${head_sha}" --arg cid "${comment_id}" --arg curl "${comment_url}" --arg at "$(wb_now)" \
        '{version: 1, ticket: $t, work_type: $wt, state: "requested", local: $local,
          pr: (if $pr == "" then null else ($pr | tonumber) end), head_sha: $sha,
          request: {comment_id: (if $cid == "" then null else $cid end), url: (if $curl == "" then null else $curl end), at: $at},
          complete: null}' >"${WB_STATE}"
    wb_commit_state "chore(review): request ${LAST_DONE}" \
        || wb_die WF013 "レビュー依頼の前提未充足: 状態ファイルのコミットに失敗しました" "" "git の状態を確認してください。"
    if [ "${local_mode}" = false ]; then
        wb_git push -q 2>&1 | tr -d '\r' >&2 || true
    fi
    wf_jq -n --arg t "${LAST_DONE}" --arg pr "${pr}" --arg url "${comment_url}" \
        '{review_state: "requested", ticket: $t, pr: (if $pr == "" then null else ($pr | tonumber) end), comment_url: (if $url == "" then null else $url end)}'
}

# ---------- complete ----------
wb_complete() {
    local local_mode=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --local) local_mode=true; shift ;;
            *) wb_die WF014 "レビュー完了の前提未充足: 不明な引数 $1" "" "complete [--local] の形式で実行してください。" ;;
        esac
    done
    wb_compute
    local fails=""
    [ "${REVIEW_STATE}" = "requested" ] || fails+="review_state が requested ではありません（${REVIEW_STATE}）"$'\n'
    local st_local="false" pr="" req_at=""
    if [ "${REVIEW_STATE}" != "none" ]; then
        st_local=$(printf '%s' "${STATE_JSON}" | wf_jq -r '.local // false')
        pr=$(printf '%s' "${STATE_JSON}" | wf_jq -r '.pr // ""')
        req_at=$(printf '%s' "${STATE_JSON}" | wf_jq -r '.request.at // ""')
        [ "${st_local}" = "${local_mode}" ] || fails+="--local の指定が request と一致しません（request は local=${st_local}）"$'\n'
    fi
    [ -n "${fails}" ] && wb_die WF014 "レビュー完了の前提未充足: complete を実行できません" "${fails%$'\n'}" \
        "requested でない場合は、境界なら request から始めてください。--local の指定は request と揃えてください。"

    local decision="" comment_ids="[]" inline_ids="[]" new_comments="[]" new_reviews="[]" new_inline="[]"
    if [ "${local_mode}" = false ]; then
        local prv inl
        prv=$(gh pr view "${pr}" --json reviewDecision,reviews,comments 2>/dev/null | tr -d '\r')
        [ -n "${prv}" ] || wb_die WF014 "レビュー完了の前提未充足: gh pr view に失敗しました" "PR #${pr} の情報を取得できません" "gh の認証・PR の状態を確認してから再実行してください。"
        inl=$(gh api "repos/{owner}/{repo}/pulls/${pr}/comments" 2>/dev/null | tr -d '\r')
        [ -n "${inl}" ] || inl="[]"
        decision=$(printf '%s' "${prv}" | wf_jq -r '.reviewDecision // ""')
        local unreplied
        unreplied=$(printf '%s' "${inl}" | wf_jq -r '. as $all | [.[] | select(.in_reply_to_id == null) | select(.id as $id | any($all[]; .in_reply_to_id == $id) | not)] | .[] | "\(.id) \(.path):\(.line // .original_line // "-")"')
        [ "${decision}" = "CHANGES_REQUESTED" ] && fails+="reviewDecision が CHANGES_REQUESTED です"$'\n'
        [ -n "${unreplied}" ] && fails+="返信の無いインラインスレッドがあります: $(printf '%s' "${unreplied}" | paste -sd ',' -)"$'\n'
        [ -n "${fails}" ] && wb_die WF014 "レビュー完了の前提未充足: complete を実行できません" "${fails%$'\n'}" \
            "CHANGES_REQUESTED なら指摘を同じ type の追加チケットで対応し、push 後に再度 request してください（または対応不要と合意できたらレビュアーに approve / dismiss を依頼してください）。未返信スレッドは bash .claude/hooks/work-boundary.sh reply <id> \"<対応内容>\" で返信してから再実行してください。"
        comment_ids=$(printf '%s' "${prv}" | wf_jq -c '[.comments[]?.id]')
        inline_ids=$(printf '%s' "${inl}" | wf_jq -c '[.[]?.id]')
        new_comments=$(printf '%s' "${prv}" | wf_jq -c --arg p "${WB_PREFIX}" --arg at "${req_at}" \
            '[.comments[]? | select((.body | startswith($p)) | not) | select(.createdAt >= $at) | {id, author: .author.login, createdAt, url, body}]')
        new_reviews=$(printf '%s' "${prv}" | wf_jq -c --arg at "${req_at}" \
            '[.reviews[]? | select(.submittedAt >= $at) | {author: .author.login, state, submittedAt, body}]')
        new_inline=$(printf '%s' "${inl}" | wf_jq -c --arg p "${WB_PREFIX}" --arg at "${req_at}" \
            '[.[]? | select((.body | startswith($p)) | not) | select(.created_at >= $at) | {id, path, line, in_reply_to_id, user: .user.login, url: .html_url, body}]')
    fi

    printf '%s' "${STATE_JSON}" | wf_jq --arg at "$(wb_now)" --arg d "${decision}" --argjson cids "${comment_ids}" --argjson iids "${inline_ids}" \
        '.state = "completed" | .complete = {at: $at, review_decision: $d, comment_ids: $cids, inline_ids: $iids}' >"${WB_STATE}"
    wb_commit_state "chore(review): complete ${LAST_DONE}" \
        || wb_die WF014 "レビュー完了の前提未充足: 状態ファイルのコミットに失敗しました" "" "git の状態を確認してください。"
    wf_jq -n --arg t "${LAST_DONE}" --arg d "${decision}" --argjson c "${new_comments}" --argjson r "${new_reviews}" --argjson i "${new_inline}" \
        '{review_state: "completed", ticket: $t, review_decision: $d, new_comments: $c, new_reviews: $r, new_inline: $i}'
}

# ---------- reply ----------
wb_reply() {
    local id="${1:-}" text="${2:-}"
    [ -n "${id}" ] && [ -n "${text}" ] || wb_die WF014 "レビュー完了の前提未充足: reply の引数が不足しています" "" "reply <inline_comment_id> <text> の形式で実行してください。"
    local pr
    pr=$(wb_pr_number)
    [ -n "${pr}" ] || wb_die WF014 "レビュー完了の前提未充足: 現在のブランチに open な PR がありません" "" "PR のあるブランチで実行してください。"
    gh api "repos/{owner}/{repo}/pulls/${pr}/comments/${id}/replies" -f body="${WB_PREFIX} ${text}" --jq '.html_url' | tr -d '\r' \
        || wb_die WF014 "レビュー完了の前提未充足: 返信の投稿に失敗しました" "" "コメント id と gh の認証を確認してください。"
}

case "${1:-}" in
    status) wb_compute; wb_status_json ;;
    request) shift; wb_request "$@" ;;
    complete) shift; wb_complete "$@" ;;
    reply) shift; wb_reply "$@" ;;
    *)
        printf 'usage: work-boundary.sh status | request [--body-file <path>] [--local] | complete [--local] | reply <id> <text>\n' >&2
        exit 2
        ;;
esac
