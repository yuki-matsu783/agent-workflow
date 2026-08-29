#!/usr/bin/env bash
# ============================================================
# workflow-diff-check — 許可パス外の差分検出とセッション記憶の記録
# ============================================================
# 発火タイミング: PostToolUse
# Matcher: Edit|Write|NotebookEdit|Bash
# 仕様: .claude/docs/10_spec/チケット駆動ワークフロー.md
#   - Edit/Write が実行された（= 未記載パスならユーザーが確認で承認した）パスを
#     セッション記憶に記録し、同セッション中は再確認しない
#   - 基準点（doing 移動時のコミット）以降の差分・未追跡ファイルを検出し、
#     deny または未承認の未記載パスがあれば additionalContext で復旧指示を返す
#   - 自動 revert は行わない（破壊的操作の禁止）。復旧は Claude が行う
#   - depends_on の先行チケット未完了も WF005 としてここで警告する
#   - doing チケットの type がコミット済みの値から変わっていれば WF008 として警告する
# ============================================================
set -uo pipefail

# shellcheck source=.claude/hooks/workflow-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/workflow-lib.sh"

wf_init  # 対象外（ENFORCE=0 / doing 0枚）ならここで exit 0

# WIP リミット違反・設定不正・状態不正のブロックは PreToolUse（workflow-guard）の責務。
# ここでは判定不能な状態として静かに抜ける
[ "${WF_WIP_VIOLATION}" -eq 1 ] && exit 0
[ "${WF_CONFIG_INVALID}" -eq 1 ] && exit 0
[ "${TYPE_INVALID}" -eq 1 ] && exit 0

INPUT=$(cat)
IFS="${WF_RS}" read -r -d '' TOOL FILE_PATH WF_SESSION_ID < <(
    wf_jq -r '[.tool_name // "", .tool_input.file_path // "", .session_id // ""] | join("\u001e")' <<<"${INPUT}"
    printf '\0'
)
WF_SESSION_ID=$(printf '%s' "${WF_SESSION_ID%$'\n'}" | tr -cd 'A-Za-z0-9_-')

context=""
append_context() {
    [ -n "${context}" ] && context="${context}
"
    context="${context}$1"
}

# ---------- セッション記憶の記録 ----------
# ツールが実行されたということは、未記載パスならユーザーが確認で承認したということ。
# ask_paths（毎回確認）は記録しない
case "${TOOL}" in
    Edit|Write|NotebookEdit)
        if [ -n "${FILE_PATH}" ]; then
            rel=$(wf_to_rel "${FILE_PATH}")
            wf_resolve "${rel}"
            [ "${WF_DECISION}" = "unlisted" ] && wf_session_remember "${rel}"
        fi
        ;;
esac

# ---------- 許可パス外の差分検出（WF-DIFF） ----------
violations=()
while IFS= read -r line; do
    [ -z "${line}" ] && continue
    path="${line:3}"
    # リネーム（R  old -> new）は移動先を対象にする
    case "${path}" in *" -> "*) path="${path##* -> }" ;; esac
    # 引用符付きパス（スペースを含む場合）の引用符を除去
    path="${path%\"}"
    path="${path#\"}"
    # フック自身のログとセッション記憶は常に無視する
    case "${path}" in
        .claude/hooks/workflow.log|"${WF_STATE_DIR_REL}"/*) continue ;;
    esac
    # 全体計画（plansDirectory）はプランモード＝ハーネスが生成するもの。
    # Claude の書き込みは guard が WF002 でブロックするため、差分として警告しない
    case "${path}" in wip/00_overall_plan/*) continue ;; esac
    # deny、または一度も承認されていない未記載パスの差分を違反とする
    wf_resolve "${path}"
    case "${WF_DECISION}" in
        deny|unlisted) violations+=("${path}") ;;
    esac
done <<<"$(git -C "${WF_ROOT}" -c core.quotepath=false status --porcelain --untracked-files=all 2>/dev/null)"

if [ ${#violations[@]} -gt 0 ]; then
    base=$(git -C "${WF_ROOT}" log -1 --grep='chore(ticket): start' --format=%H 2>/dev/null)
    [ -z "${base}" ] && base="HEAD"
    files=$(printf '%s, ' "${violations[@]}")
    append_context "[WF-DIFF] 許可されていないパスに差分があります: ${files%, }
基準コミット: ${base}
対処: 追跡済みファイルは git checkout ${base} -- <path> で基準コミットの状態に戻し、未追跡ファイルは削除してください。この変更がチケットの目的上どうしても必要な場合は、勝手に続行せず、チケットのフロントマター allowed_paths への追加をユーザーに提案してください。"
fi

# ---------- doing チケットの type 改変検知（WF008） ----------
# PreToolUse の WF008 が一次防御。ここはコミット済みの type と突き合わせる二次チェック
committed=$(git -C "${WF_ROOT}" show "HEAD:wip/ticket/doing/${TICKET}" 2>/dev/null || true)
if [ -n "${committed}" ]; then
    committed_type=$(wf_extract_type "${committed}")
    if [ -n "${committed_type}" ] && [ "${committed_type}" != "${TICKET_TYPE}" ]; then
        append_context "[WF008] チケット改変: ${TICKET} の type がコミット済みの値（${committed_type}）から ${TICKET_TYPE} に書き換えられています
対処: git checkout HEAD -- wip/ticket/doing/${TICKET} で元に戻してください。作業タイプの変更が必要な場合は、このチケットを完了または todo に戻し、適切な type の新しいチケットを作成してユーザーの合意を得てください。"
    fi
fi

# ---------- 依存違反の警告（WF005） ----------
deps_raw=$(wf_fm_get depends_on)
if [ -n "${deps_raw}" ] && [ "${deps_raw}" != "[]" ]; then
    unmet=()
    IFS=',' read -ra deps <<<"$(printf '%s' "${deps_raw}" | sed -E 's/^\[//; s/\]$//')"
    for dep in "${deps[@]}"; do
        dep=$(printf '%s' "${dep}" | sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//')
        [ -z "${dep}" ] && continue
        [ -f "${WF_ROOT}/wip/ticket/done/${dep}" ] || unmet+=("${dep}")
    done
    if [ ${#unmet[@]} -gt 0 ]; then
        unmet_str=$(printf '%s, ' "${unmet[@]}")
        append_context "[WF005] 依存違反: 先行チケットが未完了のまま ${TICKET} が doing にあります（未完了: ${unmet_str%, }）
対処: ${TICKET} を wip/ticket/todo/ に戻し、先行チケットを先に完了させるか、依存が不要になった場合は depends_on を修正してください。"
    fi
fi

if [ -n "${context}" ]; then
    wf_log "[diff-check] CONTEXT ticket=${TICKET} violations=${#violations[@]}"
    jq -n --arg ctx "${context}" \
        '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
fi

exit 0
