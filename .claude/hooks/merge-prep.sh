#!/usr/bin/env bash
# ============================================================
# merge-prep — マージ前作業の実行と状態の記録（CLI）
# ============================================================
# 仕様: .claude/docs/10_spec/skill-work-ticket-driven.md「マージ前作業の判定と状態」
#       .claude/docs/10_spec/skill-workflow-issue-mr-driven.md「完了処理」
#
# 使い方:
#   bash .claude/hooks/merge-prep.sh status
#   bash .claude/hooks/merge-prep.sh reset-wip [--dry-run]
#   bash .claude/hooks/merge-prep.sh check-conflicts [--base <branch>]
#   bash .claude/hooks/merge-prep.sh notify-issue --body-file <path> [--issue N ...]
#   bash .claude/hooks/merge-prep.sh ready [--base <branch>]
#
# - 全ワーク done・最後のワークのレビュー完了後、draft PR を ready にする前の作業
#   （wip のリセット → default ブランチとの衝突判定 → 関連 issue へのコメント → draft 解除）を
#   このスクリプトが自ら実行し、証跡を wip/merge-prep.json に記録する（書き換える唯一の経路）
# - 前提未充足は exit 2 + stderr（[WF016]）。状態ファイルは書き換えない
#   （例外: check-conflicts の「衝突あり」は結果を記録したうえで exit 2）
# - permissionDecision: ask は使わない（ヘッドレス実行で「確認できないため拒否」にならない）
# ============================================================
set -uo pipefail
shopt -u patsub_replacement 2>/dev/null || true

# shellcheck source=.claude/hooks/workflow-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/workflow-lib.sh"

MP_ROOT="${CLAUDE_PROJECT_DIR:-.}"
MP_ROOT="${MP_ROOT//\\//}"
MP_STATE_REL="wip/merge-prep.json"
MP_STATE="${MP_ROOT}/${MP_STATE_REL}"
MP_REVIEW_REL="wip/10_tickets/review-state.json"
MP_WB="$(dirname "${BASH_SOURCE[0]}")/work-boundary.sh"
MP_PREFIX="Claude Code より:"
MP_GIT_MIN_MAJOR=2
MP_GIT_MIN_MINOR=38   # git merge-tree --write-tree が使える最小バージョン
WF_LOG_FILE="${MP_ROOT}/.claude/hooks/workflow.log"

mp_die() { # $1=概要 $2=未充足(改行区切り) $3=対処
    {
        printf '[WF016] マージ前作業の前提未充足: %s\n' "$1"
        [ -n "${2:-}" ] && printf '未充足: %s\n' "$(printf '%s' "$2" | paste -sd '/' - | sed 's,/, / ,g')"
        printf '対処: %s\n' "$3"
    } >&2
    wf_log "[merge-prep] WF016 $1"
    exit 2
}

mp_git() { git -C "${MP_ROOT}" "$@"; }
mp_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

mp_pr_number() {
    # gh api は失敗時にエラー JSON を stdout へ出すことがある（gh pr view の GraphQL 版は stderr のみ）。
    # 終了コードを確認せずに使うと、そのエラー JSON を PR 番号として扱ってしまう
    local out
    out=$(gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open" --jq '.[0].number // empty' 2>/dev/null) || return 0
    printf '%s' "${out}" | tr -d '\r'
}

# default ブランチ名: --base の指定 > refs/remotes/origin/HEAD > main
mp_base() {
    if [ -n "${1:-}" ]; then printf '%s' "$1"; return 0; fi
    local ref
    ref=$(mp_git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | tr -d '\r')
    if [ -n "${ref}" ]; then printf '%s' "${ref#origin/}"; else printf 'main'; fi
}

mp_git_supports_merge_tree() {
    local v major minor
    v=$(git --version 2>/dev/null | sed -E 's/^git version ([0-9]+)\.([0-9]+).*/\1 \2/')
    read -r major minor <<<"${v}"
    [[ "${major:-0}" =~ ^[0-9]+$ ]] && [[ "${minor:-0}" =~ ^[0-9]+$ ]] || return 1
    [ "${major}" -gt "${MP_GIT_MIN_MAJOR}" ] && return 0
    [ "${major}" -eq "${MP_GIT_MIN_MAJOR}" ] && [ "${minor}" -ge "${MP_GIT_MIN_MINOR}" ]
}

# ---------- リセット対象の列挙（リポジトリ相対、改行区切り） ----------
mp_artifacts() {
    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob
    local f
    for f in "${MP_ROOT}"/wip/00_overall_plan/*.md \
        "${MP_ROOT}"/wip/10_tickets/00_todo/*.md \
        "${MP_ROOT}"/wip/10_tickets/10_doing/*.md \
        "${MP_ROOT}"/wip/10_tickets/20_done/*.md \
        "${MP_ROOT}"/wip/20_plans/*.md \
        "${MP_ROOT}"/wip/30_reports/*.md \
        "${MP_ROOT}/${MP_REVIEW_REL}"; do
        [ -e "${f}" ] && printf '%s\n' "${f#"${MP_ROOT}"/}"
    done
    [ "${nullglob_was_set}" -eq 0 ] && shopt -u nullglob
    return 0
}

mp_json_list() { # 改行区切り → JSON 配列
    if [ -n "${1:-}" ]; then
        printf '%s\n' "$1" | wf_jq -R . | wf_jq -s -c .
    else
        printf '[]'
    fi
}

# ---------- 状態の計算 ----------
mp_compute() {
    PR=$(mp_pr_number)
    ARTIFACTS=$(mp_artifacts)
    MERGE_STATE="none"
    RECORD="null"
    if [ -f "${MP_STATE}" ]; then
        local st_pr st_state
        st_pr=$(wf_jq -r '.pr // ""' "${MP_STATE}" 2>/dev/null || true)
        st_state=$(wf_jq -r '.state // ""' "${MP_STATE}" 2>/dev/null || true)
        if [ -n "${PR}" ] && [ "${st_pr}" = "${PR}" ] && [ -n "${st_state}" ]; then
            MERGE_STATE="${st_state}"
            RECORD=$(tr -d '\r' <"${MP_STATE}")
        fi
    fi
    WB_STATUS=$(CLAUDE_PROJECT_DIR="${MP_ROOT}" bash "${MP_WB}" status 2>/dev/null) || WB_STATUS='{}'
    REVIEW_STATE=$(printf '%s' "${WB_STATUS}" | wf_jq -r '.review_state // "none"')
}

mp_status_json() {
    wf_jq -n --arg pr "${PR}" --arg ms "${MERGE_STATE}" --argjson arts "$(mp_json_list "${ARTIFACTS}")" \
        --arg rs "${REVIEW_STATE}" --argjson rec "${RECORD}" \
        '{pr: (if $pr == "" then null else ($pr | tonumber) end),
          merge_state: $ms,
          wip_artifacts: $arts,
          wip_clean: ($arts | length == 0),
          review_state: $rs,
          record: (if $ms == "none" then null else $rec end)}'
}

mp_dirty() { [ -n "$(mp_git status --porcelain 2>/dev/null)" ]; }

mp_pushed() {
    local head up
    head=$(mp_git rev-parse HEAD 2>/dev/null); up=$(mp_git rev-parse '@{u}' 2>/dev/null || true)
    [ -n "${up}" ] && [ "${head}" = "${up}" ]
}

mp_push() {
    mp_git push -q 2>&1 | tr -d '\r' >&2 || true
}

mp_commit_state() { # $1=commit message（状態ファイルだけをコミット）
    mp_git add -- "${MP_STATE_REL}" && mp_git commit -q -m "$1" -- "${MP_STATE_REL}"
}

# RECORD に jq フィルタを適用して状態ファイルへ書く。$1=filter、以降は jq の引数
mp_save() {
    local filter="$1"
    shift
    printf '%s' "${RECORD}" | wf_jq "$@" "${filter}" >"${MP_STATE}"
    RECORD=$(tr -d '\r' <"${MP_STATE}")
}

# default ブランチとの衝突判定。結果を CONFLICT_FILES / HAS_CONFLICT / BASE_REF / BASE_SHA / HEAD_SHA に設定
mp_merge_tree() { # $1=base branch
    local base="$1"
    mp_git fetch -q origin "${base}" >/dev/null 2>&1 \
        || mp_die "git fetch origin ${base} に失敗しました" "" "リモート origin とブランチ名（--base）を確認してから再実行してください。"
    BASE_REF="origin/${base}"
    mp_git rev-parse --verify -q "${BASE_REF}" >/dev/null \
        || mp_die "ベースブランチ ${BASE_REF} が見つかりません" "" "--base <branch> で default ブランチ名を指定してください。"
    BASE_SHA=$(mp_git rev-parse "${BASE_REF}")
    HEAD_SHA=$(mp_git rev-parse HEAD)
    local out status=0
    # `if ! cmd` の中で $? を読むと反転値になるため、cmd || status=$? の形で受ける
    out=$(mp_git -c core.quotepath=false merge-tree --write-tree --name-only --no-messages HEAD "${BASE_REF}" 2>&1 | tr -d '\r') || status=$?
    if [ "${status}" -gt 1 ]; then
        mp_die "git merge-tree が失敗しました（終了コード ${status}）" "${out}" "git のバージョン（2.38 以降）とリポジトリの状態を確認してください。"
    fi
    CONFLICT_FILES=""
    HAS_CONFLICT=false
    if [ "${status}" -eq 1 ]; then
        CONFLICT_FILES=$(printf '%s\n' "${out}" | tail -n +2 | sed '/^$/d')
        HAS_CONFLICT=true
    fi
}

# conflicts の記録を状態ファイルへ書く（衝突なしなら reset → checked）
mp_record_conflicts() { # $1=base
    mp_save '.conflicts = {at: $at, base: $base, base_sha: $bsha, head_sha: $hsha, files: $files, has_conflict: $hc}
             | .state = (if $hc then .state else (if .state == "reset" then "checked" else .state end) end)' \
        --arg at "$(mp_now)" --arg base "$1" --arg bsha "${BASE_SHA}" --arg hsha "${HEAD_SHA}" \
        --argjson files "$(mp_json_list "${CONFLICT_FILES}")" --argjson hc "${HAS_CONFLICT}"
    mp_commit_state "chore(merge-prep): check conflicts" \
        || mp_die "状態ファイルのコミットに失敗しました" "" "git の状態を確認してください。"
    mp_push
}

mp_conflict_remedy() { # $1=base
    printf 'git merge origin/%s で default ブランチを取り込み、衝突（%s）を解消してコミット・push した後に check-conflicts を再実行してください。git rebase は使わないでください（レビューコメントが紐づくコミットを書き換えないため）。解消方針が一意に決まらない衝突はユーザーに判断を仰いでください。' \
        "$1" "$(printf '%s' "${CONFLICT_FILES}" | paste -sd ',' -)"
}

# ---------- reset-wip ----------
mp_reset() {
    local dry_run=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run) dry_run=true; shift ;;
            *) mp_die "reset-wip の引数が不正です: $1" "" "reset-wip [--dry-run] の形式で実行してください。" ;;
        esac
    done
    mp_compute
    local doing_count todo_head last_done
    doing_count=$(printf '%s' "${WB_STATUS}" | wf_jq -r '.doing_count // 0')
    todo_head=$(printf '%s' "${WB_STATUS}" | wf_jq -r '.todo_head // ""')
    last_done=$(printf '%s' "${WB_STATUS}" | wf_jq -r '.last_done // ""')
    local fails=""
    [ "${doing_count}" = "0" ] || fails+="doing にチケットがあります（${doing_count} 枚）"$'\n'
    [ -z "${todo_head}" ] || fails+="todo にチケットが残っています（${todo_head}）"$'\n'
    [ -n "${last_done}" ] || fails+="done のチケットがありません（リセット対象のワークがありません）"$'\n'
    [ "${REVIEW_STATE}" = "completed" ] || fails+="最後のワークのレビューが completed ではありません（${REVIEW_STATE}）"$'\n'
    mp_dirty && fails+="未コミットの変更があります"$'\n'
    [ -n "${PR}" ] || fails+="現在のブランチに open な PR がありません"$'\n'
    [ -n "${fails}" ] && mp_die "reset-wip を実行できません" "${fails%$'\n'}" \
        "残りのチケットを完了し、最後のワークを work-boundary.sh request → complete で completed にしてから再実行してください。未コミットの変更はコミットし、PR が無ければ draft PR を作成してください。"

    local deleted_json count
    deleted_json=$(mp_json_list "${ARTIFACTS}")
    count=$(printf '%s' "${deleted_json}" | wf_jq 'length')
    if [ "${dry_run}" = true ]; then
        wf_jq -n --arg pr "${PR}" --argjson d "${deleted_json}" --argjson c "${count}" \
            '{dry_run: true, pr: ($pr | tonumber), deleted_count: $c, deleted: $d}'
        return 0
    fi

    # 最後のワークのレビュー完了の証跡を写す（review-state.json は削除されるため）
    local review='null' head_sha branch p
    if [ -f "${MP_ROOT}/${MP_REVIEW_REL}" ]; then
        review=$(wf_jq -c '{ticket: .ticket, work_type: .work_type, review_decision: (.complete.review_decision // null), completed_at: (.complete.at // null)}' \
            "${MP_ROOT}/${MP_REVIEW_REL}" 2>/dev/null || printf 'null')
    fi
    head_sha=$(mp_git rev-parse HEAD)
    branch=$(mp_git branch --show-current | tr -d '\r')
    while IFS= read -r p; do
        [ -n "${p}" ] && rm -f -- "${MP_ROOT}/${p}"
    done <<<"${ARTIFACTS}"

    wf_jq -n --arg pr "${PR}" --arg br "${branch}" --argjson review "${review}" \
        --arg at "$(mp_now)" --arg sha "${head_sha}" --argjson d "${deleted_json}" \
        '{version: 1, pr: ($pr | tonumber), branch: $br, state: "reset", review: $review,
          reset: {at: $at, head_sha: $sha, deleted: $d}, conflicts: null, notify: null, ready: null}' >"${MP_STATE}"
    mp_git add -A -- wip/ && mp_git commit -q -m "chore(merge-prep): reset wip" \
        || mp_die "リセット結果のコミットに失敗しました" "" "git の状態を確認してください。"
    mp_push
    wf_log "[merge-prep] reset-wip pr=${PR} deleted=${count}"
    wf_jq -n --arg pr "${PR}" --argjson d "${deleted_json}" --argjson c "${count}" \
        '{merge_state: "reset", pr: ($pr | tonumber), deleted_count: $c, deleted: $d}'
}

# ---------- check-conflicts ----------
mp_check() {
    local base_opt=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --base) base_opt="${2:-}"; shift 2 ;;
            *) mp_die "check-conflicts の引数が不正です: $1" "" "check-conflicts [--base <branch>] の形式で実行してください。" ;;
        esac
    done
    mp_compute
    local fails=""
    case "${MERGE_STATE}" in
        reset|checked|notified) ;;
        *) fails+="merge_state が reset / checked / notified ではありません（${MERGE_STATE}）"$'\n' ;;
    esac
    mp_dirty && fails+="未コミットの変更があります"$'\n'
    mp_git_supports_merge_tree || fails+="git merge-tree --write-tree が使えません（git ${MP_GIT_MIN_MAJOR}.${MP_GIT_MIN_MINOR} 以降が必要）"$'\n'
    [ -n "${fails}" ] && mp_die "check-conflicts を実行できません" "${fails%$'\n'}" \
        "先に reset-wip を実行してください（ready 済みなら不要です）。未コミットの変更はコミットしてください。"

    local base
    base=$(mp_base "${base_opt}")
    mp_merge_tree "${base}"
    mp_record_conflicts "${base}"
    if [ "${HAS_CONFLICT}" = true ]; then
        mp_die "check-conflicts で default ブランチとの衝突を検知しました（結果は記録済み）" \
            "default ブランチ ${base} と衝突しています: $(printf '%s' "${CONFLICT_FILES}" | paste -sd ',' -)" \
            "$(mp_conflict_remedy "${base}")"
    fi
    wf_log "[merge-prep] check-conflicts pr=${PR} base=${base} conflict=false"
    wf_jq -n --arg ms "$(printf '%s' "${RECORD}" | wf_jq -r '.state')" --arg base "${base}" --arg bsha "${BASE_SHA}" --arg hsha "${HEAD_SHA}" \
        '{merge_state: $ms, has_conflict: false, base: $base, base_sha: $bsha, head_sha: $hsha}'
}

# ---------- notify-issue ----------
mp_notify() {
    local body_file="" extra=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --body-file) body_file="${2:-}"; shift 2 ;;
            --issue) extra+=("${2:-}"); shift 2 ;;
            *) mp_die "notify-issue の引数が不正です: $1" "" "notify-issue --body-file <path> [--issue N ...] の形式で実行してください。" ;;
        esac
    done
    mp_compute
    local fails=""
    case "${MERGE_STATE}" in
        checked) ;;
        notified) fails+="既に notified です（二重投稿になります）"$'\n' ;;
        *) fails+="merge_state が checked ではありません（${MERGE_STATE}）"$'\n' ;;
    esac
    [ -n "${body_file}" ] && [ -s "${body_file}" ] || fails+="--body-file が指定されていないか空です"$'\n'
    mp_dirty && fails+="未コミットの変更があります"$'\n'
    # 通知先: PR 本文の Closes/Fixes/Resolves #N と --issue の和集合
    local targets=""
    if [ -n "${PR}" ]; then
        local pr_body
        # gh api 失敗時に stdout へ出るエラー JSON を本文として扱わないよう終了コードを確認する
        pr_body=$(gh api "repos/{owner}/{repo}/pulls/${PR}" --jq '.body // empty' 2>/dev/null) || pr_body=""
        targets=$(printf '%s' "${pr_body}" | tr -d '\r' \
            | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)[[:space:]]+#[0-9]+' | grep -oE '[0-9]+$' || true)
    fi
    local n
    for n in ${extra[@]+"${extra[@]}"}; do
        [[ "${n}" =~ ^[0-9]+$ ]] || fails+="--issue の値が数値ではありません（${n}）"$'\n'
        targets+=$'\n'"${n}"
    done
    targets=$(printf '%s\n' "${targets}" | sed '/^$/d' | sort -n -u)
    [ -n "${targets}" ] || fails+="通知先の issue がありません（PR 本文に Closes #N が無い）"$'\n'
    [ -n "${fails}" ] && mp_die "notify-issue を実行できません" "${fails%$'\n'}" \
        "check-conflicts を通してから、本文ファイルと通知先（--issue N）を指定して再実行してください。既に notified なら ready へ進んでください。"

    local tmp posted="" url
    tmp=$(mktemp)
    {
        printf '%s PR #%s のマージ前の完了報告です。\n' "${MP_PREFIX}" "${PR}"
        printf '<!-- merge-prep: notify pr=%s -->\n\n' "${PR}"
        cat "${body_file}"
    } >"${tmp}"
    while IFS= read -r n; do
        [ -n "${n}" ] || continue
        url=$(gh api "repos/{owner}/{repo}/issues/${n}/comments" -f body="@${tmp}" --jq '.html_url' 2>&1 | tr -d '\r' | tail -1)
        case "${url}" in
            http*issuecomment-*) posted+="${n}"$'\t'"${url}"$'\n' ;;
            *)
                rm -f "${tmp}"
                mp_die "issue ${n} へのコメント投稿に失敗しました" "${url}"$'\n'"投稿済み: $(printf '%s' "${posted}" | cut -f1 | paste -sd ',' -)" \
                    "gh の認証と issue 番号を確認してから再実行してください（投稿済みの issue を除くには --issue で未投稿分だけを指定します）。状態ファイルは変更していません。"
                ;;
        esac
    done <<<"${targets}"
    rm -f "${tmp}"

    local issues_json
    issues_json=$(printf '%s' "${posted}" | sed '/^$/d' | wf_jq -R 'split("\t") | {number: (.[0] | tonumber), comment_url: .[1]}' | wf_jq -s -c .)
    mp_save '.notify = {at: $at, issues: $issues} | .state = "notified"' --arg at "$(mp_now)" --argjson issues "${issues_json}"
    mp_commit_state "chore(merge-prep): notify issues" \
        || mp_die "状態ファイルのコミットに失敗しました" "" "git の状態を確認してください。"
    mp_push
    wf_log "[merge-prep] notify-issue pr=${PR} issues=$(printf '%s' "${issues_json}" | wf_jq -c '[.[].number]')"
    wf_jq -n --arg pr "${PR}" --argjson issues "${issues_json}" '{merge_state: "notified", pr: ($pr | tonumber), issues: $issues}'
}

# ---------- ready ----------
mp_ready() {
    local base_opt=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --base) base_opt="${2:-}"; shift 2 ;;
            *) mp_die "ready の引数が不正です: $1" "" "ready [--base <branch>] の形式で実行してください。" ;;
        esac
    done
    mp_compute
    local fails="" base
    base=$(mp_base "${base_opt}")
    [ "${MERGE_STATE}" = "notified" ] || fails+="merge_state が notified ではありません（${MERGE_STATE}）"$'\n'
    [ -z "${ARTIFACTS}" ] || fails+="wip に成果物が残っています: $(printf '%s' "${ARTIFACTS}" | paste -sd ',' -)"$'\n'
    mp_dirty && fails+="未コミットの変更があります"$'\n'
    mp_pushed || fails+="HEAD が push されていません（git push してください）"$'\n'
    [ -n "${PR}" ] || fails+="現在のブランチに open な PR がありません"$'\n'
    # 再検証: default ブランチが後から進んで衝突していないか（記録があるときだけ結果を更新する）
    if [ "${MERGE_STATE}" != "none" ] && ! mp_dirty; then
        mp_merge_tree "${base}"
        if [ "${HAS_CONFLICT}" = true ]; then
            mp_record_conflicts "${base}"
            fails+="default ブランチ ${base} と衝突しています: $(printf '%s' "${CONFLICT_FILES}" | paste -sd ',' -)"$'\n'
        fi
    fi
    [ -n "${fails}" ] && mp_die "ready を実行できません" "${fails%$'\n'}" \
        "先行するサブコマンド（reset-wip → check-conflicts → notify-issue）を順に実行し、未コミットはコミット・push してください。衝突がある場合は $(mp_conflict_remedy "${base}")"

    local out
    if ! out=$(gh pr ready "${PR}" 2>&1 | tr -d '\r'); then
        mp_die "gh pr ready ${PR} に失敗しました" "${out}" "gh の認証と PR の状態を確認してから再実行してください。状態ファイルは変更していません。"
    fi
    mp_save '.ready = {at: $at, head_sha: $sha} | .state = "ready"' --arg at "$(mp_now)" --arg sha "${HEAD_SHA}"
    mp_commit_state "chore(merge-prep): ready" \
        || mp_die "状態ファイルのコミットに失敗しました" "" "git の状態を確認してください。"
    mp_push
    wf_log "[merge-prep] ready pr=${PR}"
    wf_jq -n --arg pr "${PR}" '{merge_state: "ready", pr: ($pr | tonumber)}'
}

case "${1:-}" in
    status) mp_compute; mp_status_json ;;
    reset-wip) shift; mp_reset "$@" ;;
    check-conflicts) shift; mp_check "$@" ;;
    notify-issue) shift; mp_notify "$@" ;;
    ready) shift; mp_ready "$@" ;;
    *)
        printf 'usage: merge-prep.sh status | reset-wip [--dry-run] | check-conflicts [--base <branch>] | notify-issue --body-file <path> [--issue N ...] | ready [--base <branch>]\n' >&2
        exit 2
        ;;
esac
