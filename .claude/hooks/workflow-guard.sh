#!/usr/bin/env bash
# ============================================================
# workflow-guard — チケット駆動ワークフローのフェーズ別許可判定
# ============================================================
# 発火タイミング: PreToolUse
# Matcher: Edit|Write|NotebookEdit|Bash|EnterPlanMode
# 仕様: .claude/docs/10_spec/チケット駆動ワークフロー.md
#   - doing チケットのフロントマター type を唯一の状態ソースとし、
#     type ごとの allow / deny / ask パスは .claude/hooks/workflow-types.json から動的に読む
#   - Edit/Write/NotebookEdit はパス判定（wf_resolve）:
#       allow → 許可 / deny → exit 2 / ask → 確認 / 未記載 → 警告付きで確認（承認後はセッション内で記憶）
#   - Bash は deny-by-default の allowlist。git add の対象パスは同じパス判定を適用
#   - doing チケット自身の type 書き換え（作業タイプの自己変更）は WF008 でブロック
#   - EnterPlanMode はチケット作業中は一律ブロック（プランモードは全体計画の合意専用）
#   - ブロック時は exit 2 + stderr、確認時は stdout JSON（permissionDecision: ask）
# ============================================================
set -uo pipefail
# 文字列置換（${var/pat/rep}）で置換文字列の & を特別扱いさせない（bash 5.2+）
shopt -u patsub_replacement 2>/dev/null || true

# shellcheck source=.claude/hooks/workflow-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/workflow-lib.sh"

wf_init  # 対象外（ENFORCE=0 / doing 0枚）ならここで exit 0

INPUT=$(cat)
# 入力の主要フィールドは jq 1 回でまとめて取り出す（プロセス起動コスト対策）。
# command は複数行になり得るため NUL 終端で読む
IFS="${WF_RS}" read -r -d '' TOOL FILE_PATH COMMAND WF_SESSION_ID < <(
    wf_jq -r '[.tool_name // "", .tool_input.file_path // "", .tool_input.command // "", .session_id // ""] | join("\u001e")' <<<"${INPUT}"
    printf '\0'
)
WF_SESSION_ID=$(printf '%s' "${WF_SESSION_ID%$'\n'}" | tr -cd 'A-Za-z0-9_-')

block() {
    local code="$1"
    shift
    printf '%s\n' "$@" >&2
    wf_log "[guard] BLOCK ${code} tool=${TOOL} file=${FILE_PATH} cmd=${COMMAND:0:120}"
    exit 2
}

# ユーザーに確認を求める（permissionDecision: ask）。理由は確認プロンプトに表示される
ask() {
    local code="$1"
    shift
    local reason
    reason=$(printf '%s\n' "$@")
    wf_log "[guard] ASK ${code} tool=${TOOL} file=${FILE_PATH} cmd=${COMMAND:0:120}"
    jq -n --arg r "${reason}" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
    exit 0
}

allow() {
    wf_log "[guard] ALLOW tool=${TOOL} file=${FILE_PATH} cmd=${COMMAND:0:120}"
    exit 0
}

# ---------- WF001: WIP リミット違反 ----------
if [ "${WF_WIP_VIOLATION}" -eq 1 ]; then
    ticket_files=$(printf '%s, ' "${WF_TICKETS[@]##*/}")
    block WF001 \
        "[WF001] WIPリミット違反: wip/10_tickets/10_doing/ にチケットが ${WF_COUNT} 枚あります（上限 1 枚）" \
        "対象: ${ticket_files%, }" \
        "対処: 現在作業中の 1 枚だけを doing に残し、他は wip/10_tickets/00_todo/（未着手に戻す）または wip/10_tickets/20_done/（完了済み）へ移動してから、元の操作をやり直してください。"
fi

# ---------- WF007: 設定不正（作業タイプ定義が読めない） ----------
if [ "${WF_CONFIG_INVALID}" -eq 1 ]; then
    # 復旧経路の保証: 設定ファイル自身と wip/10_tickets/ 配下への Edit は許可する
    case "${TOOL}" in
        Edit|Write|NotebookEdit)
            rel=$(wf_to_rel "${FILE_PATH}")
            case "${rel}" in "${WF_CONFIG_REL}"|wip/10_tickets/*) allow ;; esac
            ;;
    esac
    block WF007 \
        "[WF007] 設定不正: 作業タイプ定義 ${WF_CONFIG_REL} が存在しないか、JSON として解釈できません" \
        "現在のチケット: ${TICKET}" \
        "対処: ${WF_CONFIG_REL} を開き、types がオブジェクト（キー = 作業タイプ名）として定義されているか確認・修正してください（このファイルへの Edit はこの状態でも許可されています）。"
fi

# ---------- WF004: 状態不正（フロントマターの type が定義に無い） ----------
if [ "${TYPE_INVALID}" -eq 1 ]; then
    # 復旧経路の保証: フロントマター修正のための wip/10_tickets/ 配下への Edit は許可する
    case "${TOOL}" in
        Edit|Write|NotebookEdit)
            rel=$(wf_to_rel "${FILE_PATH}")
            case "${rel}" in wip/10_tickets/*) allow ;; esac
            ;;
    esac
    block WF004 \
        "[WF004] 状態不正: doing チケットの type「${TICKET_TYPE}」は作業タイプ定義にありません" \
        "対象: ${TICKET}" \
        "対処: ${TICKET} を開き、フロントマターの type を ${WF_TYPES_STR} のいずれかに修正してください（wip/10_tickets/ 配下への Edit はこの状態でも許可されています）。新しい作業タイプが必要な場合は ${WF_CONFIG_REL} への追加をユーザーに提案してください。"
fi

# ---------- パス判定の結果をツール応答に変換 ----------
# deny は exit 2、ask / 未記載は確認、allow は戻る
path_decision() {
    local rel="$1"
    wf_resolve "${rel}"
    case "${WF_DECISION}" in
        allow) return 0 ;;
        deny)
            if [ "${WF_SOURCE}" = "type.deny_paths" ]; then
                block WF002 \
                    "[WF002] パス違反: ${rel} は作業タイプ ${TICKET_TYPE} で禁止されたパス（deny_paths）です" \
                    "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
                    "対処: このパスは現在の作業タイプでは変更できません。変更が必要な場合は勝手に回避せず、適切な作業タイプでのチケット化をユーザーに提案してください。"
            fi
            block WF002 \
                "[WF002] パス違反: ${rel} は保護パス（global.deny_paths）で、作業タイプ ${TICKET_TYPE} では許可されていません" \
                "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
                "対処: 保護パス（.claude/ 配下など）への変更は、${WF_CONFIG_REL} でそのパスを allow_paths に持つ作業タイプのチケットでのみ行えます。必要な場合は勝手に変更せず、該当タイプでのチケット化をユーザーに提案してください（チケットの allowed_paths に追加しても許可されません）。"
            ;;
        ask)
            ask WF010 \
                "[WF010] 要確認パス: ${rel} は毎回確認が必要なパス（${WF_SOURCE}）です。書き込みを許可しますか？" \
                "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）"
            ;;
        unlisted)
            ask WF009 \
                "[WF009] 想定外パスへの書き込み: ${rel} は作業タイプ ${TICKET_TYPE} で本来想定していないパスです。本当に書き込んで良いですか？" \
                "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
                "許可すると、このセッション中は $(wf_memory_unit "${rel}") への書き込みを再確認しません。想定外であれば拒否し、チケットの allowed_paths や作業タイプ定義の見直しを検討してください。"
            ;;
    esac
}

# ---------- Bash: deny-by-default の allowlist 判定 ----------
# 読み取り系（全フェーズ共通）
READONLY_RE='^(ls|cat|head|tail|wc|grep|rg|find|pwd)([[:space:]]|$)|^git[[:space:]]+(status|log|diff|show|branch)([[:space:]]|$)'
# チケット運用（全フェーズ共通）。パス制限は別途検証する
TICKETOP_RE='^git[[:space:]]+(mv|add|commit)([[:space:]]|$)|^mv([[:space:]]|$)'
# ビルド/テスト系（bash_groups に "build" を含む type のみ）。プロジェクトに応じてここを拡張する
BUILD_RE='^(npm|npx|node|python|pytest|go|cargo|make)([[:space:]]|$)'
# フックのテストスクリプト（bash_groups に "test" を含む type のみ）。
# 対象は .claude/hooks/tests/*.sh と .claude/skills/<skill>/scripts/*.sh に限定し、先頭の環境変数指定（VAR=value）は許容する
TEST_RE='^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*bash[[:space:]]+\.claude/(hooks/tests|skills/[^/[:space:]]+/scripts)/[^/[:space:]]+\.sh([[:space:]]|$)'

# mv / git mv: 対象パスがすべて wip/10_tickets/ 配下であること
wf_validate_mv() {
    local tok
    for tok in "$@"; do
        case "${tok}" in
            -*) continue ;;
            QUOTED) return 1 ;;  # クォートされたパスは検証不能のため不可（パスは引用符なしで指定する）
        esac
        case "${tok//\\//}" in
            wip/10_tickets/*) continue ;;
            *) return 1 ;;
        esac
    done
    return 0
}

# git add: 対象パスをパス判定にかける。deny は 1、確認が必要なら ASK_PATHS に積んで 2、全許可なら 0
wf_validate_add() {
    local tok rel rc=0
    for tok in "$@"; do
        case "${tok}" in
            -*|QUOTED) return 1 ;;
        esac
        rel="${tok//\\//}"
        wf_resolve "${rel}"
        case "${WF_DECISION}" in
            allow) ;;
            deny) return 1 ;;
            ask|unlisted) ASK_PATHS+=("${rel}"); rc=2 ;;
        esac
    done
    return "${rc}"
}

check_bash() {
    ASK_PATHS=()
    # クォート内文字列は QUOTED に置換してから判定する（grep "a|b" 等の誤分割・誤検知を防ぐ）
    local sanitized
    sanitized=$(printf '%s' "${COMMAND}" | sed -E "s/'[^']*'/QUOTED/g; s/\"[^\"]*\"/QUOTED/g")

    # リダイレクトによるファイル書き込みは allowlist 該当コマンドでも一律拒否
    if [[ "${sanitized}" == *">"* ]]; then
        block WF003 \
            "[WF003] コマンド違反: リダイレクト（> / >>）によるファイル書き込みは許可されていません" \
            "コマンド: ${COMMAND:0:200}" \
            "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
            "対処: ファイルの作成・編集は Bash ではなく Edit/Write ツールで許可パスに対して行ってください。"
    fi

    # 複合コマンドは連結子（&& || ; |）で分割し、各セグメントを個別に判定する
    local seg
    while IFS= read -r seg; do
        seg=$(printf '%s' "${seg}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
        [ -z "${seg}" ] && continue

        if printf '%s' "${seg}" | grep -Eq "${READONLY_RE}"; then
            continue
        fi

        if printf '%s' "${seg}" | grep -Eq "${TICKETOP_RE}"; then
            # shellcheck disable=SC2206  # sanitized 済みのため単語分割で良い
            local toks=(${seg}) rc=1
            case "${toks[0]}" in
                mv)
                    wf_validate_mv "${toks[@]:1}" && continue ;;
                git)
                    case "${toks[1]}" in
                        mv)     wf_validate_mv "${toks[@]:2}" && continue ;;
                        add)
                            wf_validate_add "${toks[@]:2}"
                            rc=$?
                            [ "${rc}" -ne 1 ] && continue  # 0=許可 / 2=後で確認
                            ;;
                        commit) continue ;;
                    esac
                    ;;
            esac
            block WF003 \
                "[WF003] コマンド違反: チケット運用コマンドの対象パスが許可範囲外です" \
                "コマンド: ${COMMAND:0:200}" \
                "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
                "対処: mv / git mv は wip/10_tickets/ 配下同士の移動のみ、git add は書き込みが許可されたパスのみ使用できます。パスは引用符なし・リポジトリ相対で指定してください。"
        fi

        if [ "${WF_BUILD_ALLOWED}" -eq 1 ] && printf '%s' "${seg}" | grep -Eq "${BUILD_RE}"; then
            continue
        fi

        if [ "${WF_TEST_ALLOWED}" -eq 1 ] && printf '%s' "${seg}" | grep -Eq "${TEST_RE}"; then
            continue
        fi

        block WF003 \
            "[WF003] コマンド違反: このコマンドは現在のフェーズでは許可されていません" \
            "コマンド: ${COMMAND:0:200}" \
            "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
            "対処: ファイルの読み取りは Read/Glob/Grep ツールを使ってください。ファイルの作成・編集は Bash ではなく Edit/Write ツールで許可パスに対して行ってください。チケットの移動・コミットは git mv / git add / git commit のみ許可されています。"
    done <<<"$(printf '%s' "${sanitized}" | sed -E 's/\|\||&&|;|\|/\n/g')"

    if [ ${#ASK_PATHS[@]} -gt 0 ]; then
        local paths
        paths=$(printf '%s, ' "${ASK_PATHS[@]}")
        ask WF009 \
            "[WF009] 想定外パスの git add: ${paths%, } は作業タイプ ${TICKET_TYPE} で本来想定していないパスです。ステージして良いですか？" \
            "コマンド: ${COMMAND:0:200}" \
            "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）"
    fi
    allow
}

# ---------- doing チケット自身への編集: type の書き換え（作業タイプの自己変更）を禁止 ----------
# 編集後の内容をシミュレートし、frontmatter の type が変わるなら WF008 でブロックする。
# 作業ログの追記など type 以外の編集は通常どおり許可される
check_ticket_edit() {
    local rel="$1"
    # チケットは *.md のみ。.gitkeep など非 Markdown は対象外
    case "${rel}" in
        wip/10_tickets/10_doing/*.md) ;;
        *) return 0 ;;
    esac

    if [ "${rel}" != "wip/10_tickets/10_doing/${TICKET}" ]; then
        block WF001 \
            "[WF001] WIPリミット違反: doing に 2 枚目のチケット ${rel##*/} を作成・編集しようとしています（上限 1 枚）" \
            "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
            "対処: 新しいチケットは wip/10_tickets/00_todo/ に作成し、現在のチケットを完了してから着手してください。"
    fi

    # CRLF は判定前に LF へ正規化する（old_string の不一致による判定漏れを防ぐ）
    local current new_content
    current=$(tr -d '\r' <"${WF_TICKET_PATH}")
    case "${TOOL}" in
        Write)
            new_content=$(wf_jq -r '.tool_input.content // ""' <<<"${INPUT}")
            ;;
        Edit)
            local old new all
            old=$(wf_jq -r '.tool_input.old_string // ""' <<<"${INPUT}")
            new=$(wf_jq -r '.tool_input.new_string // ""' <<<"${INPUT}")
            all=$(wf_jq -r '.tool_input.replace_all // false' <<<"${INPUT}")
            [ -z "${old}" ] && return 0
            if [ "${all}" = "true" ]; then
                new_content="${current//"${old}"/"${new}"}"
            else
                new_content="${current/"${old}"/"${new}"}"
            fi
            ;;
        *) return 0 ;;
    esac

    local new_type
    new_type=$(wf_extract_type "${new_content}")
    if [ "${new_type}" != "${TICKET_TYPE}" ]; then
        block WF008 \
            "[WF008] チケット改変: doing チケットの type を書き換えることはできません（${TICKET_TYPE} → ${new_type:-（空）}）" \
            "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
            "対処: 作業タイプの変更が必要な場合は、このチケットを完了または wip/10_tickets/00_todo/ に戻し、適切な type の新しいチケットを作成してユーザーの合意を得てください。作業ログの追記など type 以外の編集は許可されています。"
    fi
    return 0
}

# ---------- ツール別の判定 ----------
case "${TOOL}" in
    Edit|Write|NotebookEdit)
        rel=$(wf_to_rel "${FILE_PATH}")
        check_ticket_edit "${rel}"
        path_decision "${rel}"
        allow
        ;;
    Bash)
        check_bash
        ;;
    EnterPlanMode)
        block WF006 \
            "[WF006] プランモード違反: チケット作業中はプランモードを使用できません" \
            "現在のチケット: ${TICKET}（type: ${TICKET_TYPE}）" \
            "対処: プランモードは新しいワークフローを開始する際の全体計画（wip/00_overall_plan/）の作成・合意にのみ使用します。計画の検討・修正は investigation チケットの成果物として wip/20_plans/ に Edit/Write で行ってください。"
        ;;
    *)
        allow
        ;;
esac
