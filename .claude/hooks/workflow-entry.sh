#!/usr/bin/env bash
# ============================================================
# workflow-entry — 作業の入口ガード（ワークフロースキルの宣言を強制する）
# ============================================================
# 仕様: .claude/docs/10_spec/ワークフロー入口ガード.md
#
# ユーザーのプロンプトごとに、作業を始める前に「入口となるワークフロースキル」
# （WF_ENTRY_SKILLS のいずれか）が Skill ツールで読み込まれたことを機械的に確認する。
# 読み込まれていなければ書き込み系・実行系ツールを WF101 でブロックする。
#
# 使い方（settings.json から 3 つのタイミングで呼ぶ。第 1 引数がモード）:
#   prompt : UserPromptSubmit。プロンプト連番を進める（= 宣言をリセットする）。
#            プロンプトが /<入口スキル名> で始まる場合はスラッシュ起動として宣言扱いにする
#   record : PostToolUse（matcher: Skill）。入口スキルの読み込みを宣言として記録する
#   guard  : PreToolUse（matcher: Edit|Write|NotebookEdit|Bash|EnterPlanMode|Agent|Workflow）。
#            現在のプロンプトで未宣言かつ継続条件も満たさなければ exit 2（WF101）
#
# 継続条件: wip/10_tickets/00_todo/ または 10_doing/ にチケット（*.md）がある間は
# workflow-issue-mr-driven の作業が進行中とみなし、宣言の有無にかかわらず許可する
# （その間は workflow-guard.sh がチケットの type に基づいて統制している）。
#
# 状態ファイル: .claude/hooks/.state/<session_id>.entry（Git 管理外）
#   prompt_seq=<プロンプト連番>
#   workflow=<最後に宣言された入口スキル名>
#   declared_seq=<宣言時のプロンプト連番>
#   → declared_seq == prompt_seq のときだけ「宣言済み」
#
# 緊急脱出: WORKFLOW_ENFORCE=0（全ワークフローフック）または WORKFLOW_ENTRY_ENFORCE=0（このフックのみ）
# ============================================================
set -uo pipefail

# ---------- 設定 ----------
# 入口として認めるスキル。追加する場合はここと CLAUDE.md「作業の入口」を合わせて更新する
WF_ENTRY_SKILLS=("workflow-issue-mr-driven" "workflow-quick-request")
# 未完了チケットの置き場。ここに *.md があれば workflow-issue-mr-driven の継続中とみなす
WF_TICKET_ACTIVE_DIRS=("wip/10_tickets/00_todo" "wip/10_tickets/10_doing")
WF_STATE_DIR_REL=".claude/hooks/.state"
WF_RS=$'\x1e'

MODE="${1:-}"
WF_ROOT="${CLAUDE_PROJECT_DIR:-.}"
WF_ROOT="${WF_ROOT//\\//}"
WF_LOG_FILE="${WF_ROOT}/.claude/hooks/workflow.log"

# ---------- 緊急脱出 ----------
[ "${WORKFLOW_ENFORCE:-1}" = "0" ] && exit 0
[ "${WORKFLOW_ENTRY_ENFORCE:-1}" = "0" ] && exit 0

# ---------- 共通関数 ----------
# Windows ビルドの jq は CRLF を出力するため \r を除去する
wf_jq() {
    jq "$@" | tr -d '\r'
}

wf_log() {
    echo "$(date '+%Y-%m-%dT%H:%M:%S') [entry] $*" 2>/dev/null >>"${WF_LOG_FILE}" || true
}

# 入口スキル名の一覧を「a / b」形式で返す（メッセージ用）
wf_skills_str() {
    local s
    s=$(printf '%s / ' "${WF_ENTRY_SKILLS[@]}")
    printf '%s' "${s% / }"
}

# $1 が入口スキルなら 0
wf_is_entry_skill() {
    local s
    for s in "${WF_ENTRY_SKILLS[@]}"; do
        [ "$1" = "${s}" ] && return 0
    done
    return 1
}

# 未完了チケット（todo / doing の *.md）が 1 つでもあれば 0（継続中）。.gitkeep など非 Markdown は数えない
wf_tickets_active() {
    local d f
    for d in "${WF_TICKET_ACTIVE_DIRS[@]}"; do
        for f in "${WF_ROOT}/${d}"/*.md; do
            [ -e "${f}" ] && return 0
        done
    done
    return 1
}

# 状態ファイルの読み込み。無ければ「プロンプト 0、未宣言」
wf_load_state() {
    PROMPT_SEQ=0
    WORKFLOW=""
    DECLARED_SEQ=-1
    [ -f "${STATE_FILE}" ] || return 0
    local k v
    while IFS='=' read -r k v; do
        case "${k}" in
            prompt_seq)   PROMPT_SEQ="${v}" ;;
            workflow)     WORKFLOW="${v}" ;;
            declared_seq) DECLARED_SEQ="${v}" ;;
        esac
    done < <(tr -d '\r' <"${STATE_FILE}")
    # 数値でなければ壊れているとみなして初期化する
    [[ "${PROMPT_SEQ}" =~ ^[0-9]+$ ]] || PROMPT_SEQ=0
    [[ "${DECLARED_SEQ}" =~ ^-?[0-9]+$ ]] || DECLARED_SEQ=-1
}

# 状態ファイルの書き込み（一時ファイル経由で原子的に置き換える）
wf_save_state() {
    mkdir -p "$(dirname "${STATE_FILE}")" 2>/dev/null || return 0
    local tmp="${STATE_FILE}.tmp.$$"
    printf 'prompt_seq=%s\nworkflow=%s\ndeclared_seq=%s\n' "${PROMPT_SEQ}" "${WORKFLOW}" "${DECLARED_SEQ}" >"${tmp}" \
        && mv -f "${tmp}" "${STATE_FILE}"
}

wf_declared() {
    [ -n "${WORKFLOW}" ] && [ "${DECLARED_SEQ}" = "${PROMPT_SEQ}" ]
}

# ---------- 入力の読み込み ----------
INPUT=$(cat)
# prompt は複数行になり得るため、RS 区切りで NUL 終端まで読む
IFS="${WF_RS}" read -r -d '' TOOL SKILL PROMPT WF_SESSION_ID < <(
    wf_jq -r '[.tool_name // "", .tool_input.skill // "", .prompt // "", .session_id // ""] | join("")' <<<"${INPUT}"
    printf '\0'
)
WF_SESSION_ID=$(printf '%s' "${WF_SESSION_ID%$'\n'}" | tr -cd 'A-Za-z0-9_-')
[ -n "${WF_SESSION_ID}" ] || WF_SESSION_ID="unknown"
STATE_FILE="${WF_ROOT}/${WF_STATE_DIR_REL}/${WF_SESSION_ID}.entry"

wf_load_state

# ---------- モード別の処理 ----------
case "${MODE}" in
    # ===== UserPromptSubmit: 新しいプロンプト = 宣言のリセット =====
    prompt)
        PROMPT_SEQ=$((PROMPT_SEQ + 1))
        prev=""
        [ -n "${WORKFLOW}" ] && prev="（前回の宣言: ${WORKFLOW} @#${DECLARED_SEQ}）"

        # /<入口スキル名> で始まるプロンプトはスラッシュ起動。Skill ツールを経由しないためここで宣言扱いにする
        first_line=$(printf '%s' "${PROMPT}" | head -1 | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
        slash="${first_line#/}"
        slash="${slash%% *}"
        if [ "${first_line}" != "${slash}" ] && wf_is_entry_skill "${slash}"; then
            WORKFLOW="${slash}"
            DECLARED_SEQ="${PROMPT_SEQ}"
            wf_save_state
            wf_log "DECLARE(slash) #${PROMPT_SEQ} workflow=${WORKFLOW} session=${WF_SESSION_ID}"
            ctx="[WF-ENTRY] プロンプト #${PROMPT_SEQ}: /${WORKFLOW} によるスラッシュ起動を宣言として記録した。このスキルの手順に従って作業してよい。"
        elif wf_tickets_active; then
            wf_save_state
            wf_log "PROMPT #${PROMPT_SEQ} continue(ticket) session=${WF_SESSION_ID}"
            ctx="[WF-ENTRY] プロンプト #${PROMPT_SEQ}: wip/10_tickets/ に未完了チケットがあるため workflow-issue-mr-driven の継続中とみなす（入口の宣言は不要）。work-ticket-driven の手順に従い doing チケットの作業を続けること。別の依頼を始める場合は、チケットを完了（20_done）するか 00_todo に戻してから入口を宣言し直す。"
        else
            wf_save_state
            wf_log "PROMPT #${PROMPT_SEQ} session=${WF_SESSION_ID}"
            ctx="[WF-ENTRY] プロンプト #${PROMPT_SEQ}: 作業に着手する前に、Skill ツールで $(wf_skills_str) のいずれかを読み込んで入口を宣言すること${prev}。宣言はプロンプトごとに必要で、未宣言のまま Edit / Write / NotebookEdit / Bash / EnterPlanMode / Agent / Workflow を呼ぶと WF101 でブロックされる。判断基準は CLAUDE.md「作業の入口」を参照。"
        fi
        jq -n --arg ctx "${ctx}" \
            '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
        exit 0
        ;;

    # ===== PostToolUse (Skill): 入口スキルの読み込みを宣言として記録 =====
    record)
        [ "${TOOL}" = "Skill" ] || exit 0
        wf_is_entry_skill "${SKILL}" || exit 0
        WORKFLOW="${SKILL}"
        DECLARED_SEQ="${PROMPT_SEQ}"
        wf_save_state
        wf_log "DECLARE(skill) #${PROMPT_SEQ} workflow=${WORKFLOW} session=${WF_SESSION_ID}"
        exit 0
        ;;

    # ===== PreToolUse: 未宣言なら WF101 でブロック =====
    guard)
        if wf_declared; then
            exit 0
        fi
        if wf_tickets_active; then
            wf_log "CONTINUE(ticket) #${PROMPT_SEQ} tool=${TOOL} session=${WF_SESSION_ID}"
            exit 0
        fi
        wf_log "BLOCK WF101 #${PROMPT_SEQ} tool=${TOOL} last=${WORKFLOW:-none}@${DECLARED_SEQ} session=${WF_SESSION_ID}"
        {
            echo "[WF101] ワークフロー未宣言: このプロンプト（#${PROMPT_SEQ}）では、作業の入口となるスキルがまだ読み込まれていません"
            echo "対象ツール: ${TOOL}"
            if [ -n "${WORKFLOW}" ]; then
                echo "前回の宣言: ${WORKFLOW}（プロンプト #${DECLARED_SEQ}）。宣言はプロンプトごとに必要で、前回の宣言は引き継がれません（wip/10_tickets/ に未完了チケットがある間を除く）"
            fi
            echo "対処: 作業を始める前に Skill ツールで次のいずれかを呼び、その手順に従ってください: workflow-issue-mr-driven（機能追加・バグ修正など、issue と PR に紐づけて進める開発作業）/ workflow-quick-request（質問・説明・調査、typo やドキュメントの修正など、issue 化しない軽作業）。判断基準は CLAUDE.md「作業の入口」と workflow-quick-request の手順 0 を参照。ブロックを迂回しないでください。"
        } >&2
        exit 2
        ;;

    *)
        echo "workflow-entry: 不明なモード '${MODE}'（prompt | record | guard のいずれかを指定）" >&2
        exit 0
        ;;
esac
