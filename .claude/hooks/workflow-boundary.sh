#!/usr/bin/env bash
# ============================================================
# workflow-boundary — ワーク境界の統制とレビュー状態ファイルの保護
# ============================================================
# 発火タイミング: PreToolUse
# Matcher: Edit|Write|NotebookEdit|Bash
# 仕様: .claude/docs/10_spec/チケット駆動ワークフロー.md「ワーク境界の判定とレビュー状態」
#   - workflow-guard.sh とは独立に登録し、doing が空でも動く
#   - (a)(b) wip/10_tickets/review-state.json の直接書き換え（Edit/Write/NotebookEdit、
#           Bash の rm / sed -i / リダイレクト / git checkout -- 等）は常に WF012
#   - (f)    wip/merge-prep.json も同じく常に WF012（merge-prep.sh だけが書く）
#   - (e)    Bash の gh pr ready は doing・境界・レビュー状態を問わず常に WF015
#           （draft の解除は merge-prep.sh ready 経由のみ。同「マージ前作業の判定と状態」）
#   - (c)    doing が空で、ワーク境界かつレビュー未完了（review_state != completed）のとき、
#           次のワークのチケットを doing へ移す操作は WF011。
#           ただし直前の done と同じ type のチケット（差し戻し対応の追加チケット）は許可
#   - ask は使わず exit 2 のみ（ヘッドレス実行で「確認できないため拒否」にならない）
# ============================================================
set -uo pipefail
shopt -u patsub_replacement 2>/dev/null || true

# shellcheck source=.claude/hooks/workflow-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/workflow-lib.sh"

[ "${WORKFLOW_ENFORCE:-1}" = "0" ] && exit 0

WF_ROOT="${CLAUDE_PROJECT_DIR:-.}"
WF_ROOT="${WF_ROOT//\\//}"
WF_LOG_FILE="${WF_ROOT}/.claude/hooks/workflow.log"
WB_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/work-boundary.sh"
STATE_REL="wip/10_tickets/review-state.json"
MP_STATE_REL="wip/merge-prep.json"
DOING_REL="wip/10_tickets/10_doing"

INPUT=$(cat)
# command は複数行になり得るため NUL 終端で読む（workflow-guard.sh と同じ）
IFS="${WF_RS}" read -r -d '' TOOL FILE_PATH COMMAND < <(
    wf_jq -r '[.tool_name // "", .tool_input.file_path // "", .tool_input.command // ""] | join("")' <<<"${INPUT}"
    printf '\0'
)
COMMAND="${COMMAND%$'\n'}"

block() {
    local code="$1"
    shift
    printf '%s\n' "$@" >&2
    wf_log "[boundary] BLOCK ${code} tool=${TOOL} file=${FILE_PATH} cmd=${COMMAND:0:120}"
    exit 2
}

# ---------- (a)(b)(e)(f) 状態ファイルの保護と gh pr ready の拒否（常に適用） ----------
READONLY_RE='^(cat|head|tail|grep|rg|wc)([[:space:]]|$)|^git[[:space:]]+(status|log|diff|show)([[:space:]]|$)'
SCRIPT_RE='^bash[[:space:]]+\.claude/hooks/(work-boundary|merge-prep)\.sh([[:space:]]|$)'
PR_READY_RE='^gh[[:space:]]+pr[[:space:]]+ready([[:space:]]|$)'

wf012() { # $1=対象 $2=状態ファイル（review|merge）
    local file script subs
    if [ "$2" = "merge" ]; then
        file="${MP_STATE_REL}"; script="merge-prep.sh"; subs="reset-wip / check-conflicts / notify-issue / ready"
    else
        file="${STATE_REL}"; script="work-boundary.sh"; subs="request / complete"
    fi
    block WF012 \
        "[WF012] 状態ファイルの直接書き換え: ${file} は ${script} 以外から書き換えできません" \
        "対象: $1" \
        "対処: 状態は bash .claude/hooks/${script} のサブコマンド（${subs}）でのみ遷移します。状態を進めたい場合はそのサブコマンドを実行し、前提条件（[WF013] / [WF014] / [WF016]）が満たせないならユーザーに報告してください。ファイルを編集・削除・復元して状態を作らないでください。"
}

wf015() {
    block WF015 \
        "[WF015] マージ依頼の統制違反: gh pr ready は直接実行できません（draft の解除は merge-prep.sh ready 経由のみ）" \
        "対象: $1" \
        "対処: bash .claude/hooks/merge-prep.sh ready を実行してください。前提（reset-wip / check-conflicts / notify-issue の記録と再検証）が満たせず [WF016] で止まる場合は、未充足の条件を解消するか、ユーザーに報告してください。迂回して ready にしないでください。"
}

# クォート内の値が状態ファイル（review-state.json / merge-prep.json）のパスそのものかどうかを判定する。
# 該当すれば種別（review / merge）を stdout に出して 0 を返す。
# 例: "wip/10_tickets/review-state.json" や 'merge-prep.json' は該当。
# "review-state.json の扱い" のように他の文字列と混在する場合は非該当（パスとして使われていない）
wf_quoted_targets_state() {
    local seg="$1" q val
    while IFS= read -r q; do
        [ -z "${q}" ] && continue
        val="${q:1:-1}"
        case "${val}" in
            review-state.json|*/review-state.json) printf 'review'; return 0 ;;
            merge-prep.json|*/merge-prep.json) printf 'merge'; return 0 ;;
        esac
    done < <(printf '%s' "${seg}" | grep -oE "'[^']*'|\"[^\"]*\"")
    return 1
}

case "${TOOL}" in
    Edit|Write|NotebookEdit)
        REL=$(wf_to_rel "${FILE_PATH}")
        [ "${REL}" = "${STATE_REL}" ] && wf012 "${REL}" review
        [ "${REL}" = "${MP_STATE_REL}" ] && wf012 "${REL}" merge
        ;;
    Bash)
        while IFS= read -r seg; do
            seg=$(printf '%s' "${seg}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            [ -z "${seg}" ] && continue
            printf '%s' "${seg}" | grep -Eq "${PR_READY_RE}" && wf015 "${COMMAND:0:200}"

            # クォート内文字列は QUOTED に置換してから判定する（workflow-guard.sh の check_bash と同じ前処理。issue #29）。
            # 引用符内の文字列に状態ファイル名が含まれるだけの誤検知を防ぐ
            sanitized=$(printf '%s' "${seg}" | sed -E "s/'[^']*'/QUOTED/g; s/\"[^\"]*\"/QUOTED/g")
            printf '%s' "${sanitized}" | grep -Eq "${READONLY_RE}" && continue
            printf '%s' "${sanitized}" | grep -Eq "${SCRIPT_RE}" && continue

            # クォート外に状態ファイル名がそのまま書かれているケース
            case "${sanitized}" in
                *review-state.json*) wf012 "${COMMAND:0:200}" review ;;
                *merge-prep.json*) wf012 "${COMMAND:0:200}" merge ;;
            esac
            # パスそのものをクォートしたケース（クォート除去では消えてしまうため別途検出する）
            kind=$(wf_quoted_targets_state "${seg}") && wf012 "${COMMAND:0:200}" "${kind}"
        done <<<"$(printf '%s' "${COMMAND}" | sed -E 's/\|\||&&|;|\|/\n/g')"
        ;;
esac

# ---------- (c) ワーク境界の統制（doing が空のときだけ） ----------
STATUS=$(CLAUDE_PROJECT_DIR="${WF_ROOT}" bash "${WB_SCRIPT}" status 2>/dev/null) || exit 0
IFS="${WF_RS}" read -r -d '' DOING_COUNT AT_BOUNDARY REVIEW_STATE LAST_DONE LAST_DONE_TYPE TODO_HEAD TODO_HEAD_TYPE < <(
    wf_jq -r '[(.doing_count|tostring), (.at_boundary|tostring), .review_state, (.last_done // ""), (.last_done_type // ""), (.todo_head // ""), (.todo_head_type // "")] | join("")' <<<"${STATUS}"
    printf '\0'
)
TODO_HEAD_TYPE="${TODO_HEAD_TYPE%$'\n'}"

[ "${DOING_COUNT}" = "0" ] || exit 0
[ "${AT_BOUNDARY}" = "true" ] || exit 0
[ "${REVIEW_STATE}" != "completed" ] || exit 0

case "${REVIEW_STATE}" in
    requested) REMEDY="レビュー完了の連絡を受けてから bash .claude/hooks/work-boundary.sh complete を実行してください。連絡がまだなら応答を終えて待ってください" ;;
    *) REMEDY="git push してから bash .claude/hooks/work-boundary.sh request でレビューを依頼し、レビュー完了の連絡を待ってください（AskUserQuestion で待たず、応答を終えてください）" ;;
esac

wf011() {
    block WF011 \
        "[WF011] ワーク境界違反: ワーク ${LAST_DONE_TYPE} は完了していますが、レビューが ${REVIEW_STATE} のため次のワークに着手できません" \
        "直前の done: ${LAST_DONE}（type: ${LAST_DONE_TYPE}）／todo 先頭: ${TODO_HEAD:-（なし）}（type: ${TODO_HEAD_TYPE:-（なし）}）" \
        "対処: ${REMEDY}。同じ type（${LAST_DONE_TYPE}）の追加チケットで差し戻しに対応する場合はそのまま着手できます。"
}

# 移動元チケットの type が直前の done と同じなら同一ワークの継続（許可）
same_type_ticket() { # $1=リポジトリ相対パス
    local p="${WF_ROOT}/$1"
    [ -f "${p}" ] || return 1
    [ "$(wf_extract_type "$(cat "${p}")")" = "${LAST_DONE_TYPE}" ]
}

case "${TOOL}" in
    Write|Edit)
        REL=$(wf_to_rel "${FILE_PATH}")
        case "${REL}" in
            "${DOING_REL}"/*.md)
                if [ "${TOOL}" = "Write" ]; then
                    NEW_TYPE=$(wf_extract_type "$(wf_jq -r '.tool_input.content // ""' <<<"${INPUT}")")
                    [ "${NEW_TYPE}" = "${LAST_DONE_TYPE}" ] || wf011
                else
                    same_type_ticket "${REL}" || wf011
                fi
                ;;
        esac
        ;;
    Bash)
        while IFS= read -r seg; do
            seg=$(printf '%s' "${seg}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            [ -z "${seg}" ] && continue
            if printf '%s' "${seg}" | grep -Eq '^(git[[:space:]]+)?mv([[:space:]]|$)'; then
                # shellcheck disable=SC2206
                toks=(${seg})
                src=""; dst=""
                for t in "${toks[@]:1}"; do
                    case "${t}" in mv|-*) continue ;; esac
                    [ -z "${src}" ] && { src="${t//\\//}"; continue; }
                    dst="${t//\\//}"
                done
                case "${dst}" in
                    "${DOING_REL}"|"${DOING_REL}"/|"${DOING_REL}"/*)
                        same_type_ticket "${src}" || wf011
                        ;;
                esac
            fi
        done <<<"$(printf '%s' "${COMMAND}" | sed -E 's/\|\||&&|;|\|/\n/g')"
        ;;
esac

exit 0
