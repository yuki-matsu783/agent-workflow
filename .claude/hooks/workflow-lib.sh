#!/usr/bin/env bash
# ============================================================
# workflow-lib — チケット駆動ワークフロー用フックの共通ライブラリ
# ============================================================
# workflow-guard.sh / workflow-diff-check.sh から source される。
# 仕様: .claude/docs/10_spec/skill-work-ticket-driven.md
#
# 作業タイプ（type）とパスの allow / deny / ask は外部設定
# .claude/hooks/workflow-types.json で定義し、ここで動的に読み込む。
#
# パス判定の優先順位（wf_resolve）:
#   1. types.<type>.deny_paths   → deny
#   2. types.<type>.ask_paths    → ask（毎回確認）
#   3. types.<type>.allow_paths  → allow
#   4. global.deny_paths         → deny
#   5. global.ask_paths          → ask（毎回確認）
#   6. チケット frontmatter の allowed_paths → allow（deny / ask には勝てない）
#   7. global.allow_paths        → allow
#   8. セッション記憶（承認済み）  → allow
#   9. 未記載                    → unlisted（警告付きで確認。承認後はセッション内で記憶）
#
# 提供する関数・変数:
#   wf_init            : ガード条件を評価し、対象外なら exit 0 で抜ける
#   wf_resolve <rel>   : 判定結果を WF_DECISION（allow|deny|ask|unlisted）と WF_SOURCE に設定
#   wf_session_remember <rel> : 承認済みとしてセッション記憶に記録する
#   wf_log <msg>       : 判定ログを .claude/hooks/workflow.log に追記する
#   wf_to_rel <path>   : 絶対パスをリポジトリ相対（/ 区切り）に変換する
#   wf_extract_type <content> : frontmatter から type の値を取り出す
# ============================================================

WF_CONFIG_REL=".claude/hooks/workflow-types.json"
WF_STATE_DIR_REL=".claude/hooks/.state"

# jq の値取得ラッパー。Windows ビルドの jq は CRLF を出力するため \r を除去する
# （pipefail 前提で jq の終了コードは保たれる）
wf_jq() {
    jq "$@" | tr -d '\r'
}

wf_log() {
    # ログ出力の失敗（ディレクトリ不在など）でフック本体を止めない・汚さない
    echo "$(date '+%Y-%m-%dT%H:%M:%S') $*" 2>/dev/null >>"${WF_LOG_FILE}" || true
}

# 文字列（チケット本文）のフロントマターから type の値を取り出す
wf_extract_type() {
    printf '%s\n' "$1" | tr -d '\r' | sed -n '2,/^---/{s/^type:[[:space:]]*//p}' | head -1
}

# フロントマター（1つ目の --- から 2つ目の --- まで）からキーの値を取得する
wf_fm_get() {
    sed -n '2,/^---/{s/^'"$1"':[[:space:]]*//p}' "${WF_TICKET_PATH}" | head -1 | tr -d '\r'
}

# 絶対パス → リポジトリ相対パス（\ を / に正規化、ドライブレターは大文字小文字無視）
wf_to_rel() {
    local p="${1//\\//}" r="${WF_ROOT}"
    local lp lr
    lp=$(printf '%s' "${p}" | tr '[:upper:]' '[:lower:]')
    lr=$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')
    if [ -n "${r}" ] && [ "${lp#"${lr}"/}" != "${lp}" ]; then
        printf '%s' "${p:$((${#r} + 1))}"
    else
        printf '%s' "${p}"
    fi
}

# $1 がパターン群（glob。** は * に読み替え）のいずれかに一致すれば 0 を返す
wf_match() {
    local rel="$1" pat
    shift
    for pat in "$@"; do
        pat="${pat//\*\*/*}"
        # shellcheck disable=SC2254  # 変数をパターンとして展開させる
        case "${rel}" in
            ${pat}) return 0 ;;
        esac
    done
    return 1
}

# ---------- セッション記憶 ----------
# 記憶の単位: session_memory.file_level に一致するパスはファイル単位、それ以外は親ディレクトリ単位
# （直下のみ。サブディレクトリには波及しない）
wf_memory_unit() {
    local rel="$1"
    if wf_match "${rel}" ${WF_FILE_LEVEL[@]+"${WF_FILE_LEVEL[@]}"}; then
        printf 'file:%s' "${rel}"
    else
        printf 'dir:%s' "$(dirname "${rel}")"
    fi
}

wf_session_file() {
    [ -n "${WF_SESSION_ID:-}" ] || return 1
    printf '%s/%s/%s.approved' "${WF_ROOT}" "${WF_STATE_DIR_REL}" "${WF_SESSION_ID}"
}

wf_session_remembered() {
    local f
    f=$(wf_session_file) || return 1
    [ -f "${f}" ] || return 1
    grep -Fxq -- "$(wf_memory_unit "$1")" "${f}"
}

wf_session_remember() {
    local f unit
    f=$(wf_session_file) || return 0
    unit=$(wf_memory_unit "$1")
    mkdir -p "$(dirname "${f}")" 2>/dev/null || return 0
    grep -Fxq -- "${unit}" "${f}" 2>/dev/null || echo "${unit}" >>"${f}"
    wf_log "[memory] remember ${unit} session=${WF_SESSION_ID}"
}

# ---------- パス判定 ----------
# 結果: WF_DECISION = allow | deny | ask | unlisted、WF_SOURCE = 根拠
wf_resolve() {
    local rel="$1"
    WF_DECISION="unlisted"
    WF_SOURCE="none"
    if wf_match "${rel}" ${WF_T_DENY[@]+"${WF_T_DENY[@]}"};   then WF_DECISION=deny;  WF_SOURCE="type.deny_paths";  return 0; fi
    if wf_match "${rel}" ${WF_T_ASK[@]+"${WF_T_ASK[@]}"};     then WF_DECISION=ask;   WF_SOURCE="type.ask_paths";   return 0; fi
    if wf_match "${rel}" ${WF_T_ALLOW[@]+"${WF_T_ALLOW[@]}"}; then WF_DECISION=allow; WF_SOURCE="type.allow_paths"; return 0; fi
    if wf_match "${rel}" ${WF_G_DENY[@]+"${WF_G_DENY[@]}"};   then WF_DECISION=deny;  WF_SOURCE="global.deny_paths";  return 0; fi
    if wf_match "${rel}" ${WF_G_ASK[@]+"${WF_G_ASK[@]}"};     then WF_DECISION=ask;   WF_SOURCE="global.ask_paths";   return 0; fi
    if wf_match "${rel}" ${WF_TICKET_ALLOW[@]+"${WF_TICKET_ALLOW[@]}"}; then WF_DECISION=allow; WF_SOURCE="ticket.allowed_paths"; return 0; fi
    if wf_match "${rel}" ${WF_G_ALLOW[@]+"${WF_G_ALLOW[@]}"}; then WF_DECISION=allow; WF_SOURCE="global.allow_paths"; return 0; fi
    if wf_session_remembered "${rel}";                        then WF_DECISION=allow; WF_SOURCE="session";            return 0; fi
    return 0
}

# 区切り文字（レコード = RS、リスト要素 = US）で連結された文字列を配列に分解する
WF_RS=$'\x1e'
WF_US=$'\x1f'
wf_split_list() { # $1=変数名 $2=US 区切り文字列
    local -n _dst="$1"
    _dst=()
    [ -n "$2" ] || return 0
    IFS="${WF_US}" read -r -a _dst <<<"$2"
}

# 作業タイプ定義を jq 1 回で読み込む（プロセス起動コストを抑えるため個別クエリにしない）
# 出力: 設定不正なら空。正常なら RS 区切りで
#   types一覧 / g.allow / g.deny / g.ask / file_level / type存在(1|0) / t.allow / t.deny / t.ask / build(1|0) / test(1|0)
wf_load_config() {
    wf_jq -r --arg t "${TICKET_TYPE}" '
        def L(a): (a // []) | map(tostring) | join("\u001f");
        if (.types | type) != "object" then empty else
        [ (.types | keys | join(" / ")),
          L(.global.allow_paths // ["wip/10_tickets/**"]),
          L(.global.deny_paths),
          L(.global.ask_paths),
          L(.session_memory.file_level),
          (if .types[$t] then "1" else "0" end),
          L(.types[$t].allow_paths),
          L(.types[$t].deny_paths),
          L(.types[$t].ask_paths),
          (if ((.types[$t].bash_groups // []) | index("build")) != null then "1" else "0" end),
          (if ((.types[$t].bash_groups // []) | index("test")) != null then "1" else "0" end)
        ] | join("\u001e") end' "${WF_CONFIG_FILE}" 2>/dev/null
}

# ガード条件の評価と状態ソース（設定ファイル + doing チケット）の読み込み
# 戻り: 対象外なら exit 0。異常はフラグを立てて戻る（ブロックするかは呼び出し側の責務）
wf_init() {
    WF_ROOT="${CLAUDE_PROJECT_DIR:-.}"
    WF_ROOT="${WF_ROOT//\\//}"
    WF_LOG_FILE="${WF_ROOT}/.claude/hooks/workflow.log"
    WF_DOING_DIR="${WF_ROOT}/wip/10_tickets/10_doing"
    WF_CONFIG_FILE="${WF_ROOT}/${WF_CONFIG_REL}"
    WF_WIP_VIOLATION=0
    WF_CONFIG_INVALID=0
    TYPE_INVALID=0
    WF_BUILD_ALLOWED=0
    WF_TEST_ALLOWED=0
    WF_TYPES_STR=""
    WF_G_ALLOW=(); WF_G_DENY=(); WF_G_ASK=(); WF_FILE_LEVEL=()
    WF_T_ALLOW=(); WF_T_DENY=(); WF_T_ASK=(); WF_TICKET_ALLOW=()

    # ガード1: 緊急脱出（WORKFLOW_ENFORCE=0 で全チェック無効）
    [ "${WORKFLOW_ENFORCE:-1}" = "0" ] && exit 0

    # ガード2: doing チケットが無ければ通常セッション。何もしない
    [ -d "${WF_DOING_DIR}" ] || exit 0
    local nullglob_was_set=0
    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob
    WF_TICKETS=("${WF_DOING_DIR}"/*.md)
    [ "${nullglob_was_set}" -eq 0 ] && shopt -u nullglob
    WF_COUNT=${#WF_TICKETS[@]}
    [ "${WF_COUNT}" -eq 0 ] && exit 0

    # ガード3: WIP リミット（doing は最大1枚）
    if [ "${WF_COUNT}" -ge 2 ]; then
        WF_WIP_VIOLATION=1
        return 0
    fi
    WF_TICKET_PATH="${WF_TICKETS[0]}"
    TICKET="${WF_TICKET_PATH##*/}"

    # ガード4: 作業タイプ定義（外部設定）の読み込み。読めなければフェイルセーフ
    TICKET_TYPE=$(wf_fm_get type)
    local raw
    raw=$(wf_load_config)
    if [ -z "${raw}" ]; then
        WF_CONFIG_INVALID=1
        return 0
    fi
    local fields
    IFS="${WF_RS}" read -r -a fields <<<"${raw}"
    WF_TYPES_STR="${fields[0]}"
    wf_split_list WF_G_ALLOW    "${fields[1]}"
    wf_split_list WF_G_DENY     "${fields[2]}"
    wf_split_list WF_G_ASK      "${fields[3]}"
    wf_split_list WF_FILE_LEVEL "${fields[4]}"

    # ガード5: 状態ソース（doing チケットの frontmatter）の検証
    if [ "${fields[5]}" != "1" ]; then
        TYPE_INVALID=1
        return 0
    fi
    wf_split_list WF_T_ALLOW "${fields[6]}"
    wf_split_list WF_T_DENY  "${fields[7]}"
    wf_split_list WF_T_ASK   "${fields[8]}"
    [ "${fields[9]}" = "1" ] && WF_BUILD_ALLOWED=1
    [ "${fields[10]:-0}" = "1" ] && WF_TEST_ALLOWED=1

    # チケット frontmatter の allowed_paths（追加の allow。deny / ask には勝てない）
    local custom_raw
    custom_raw=$(wf_fm_get allowed_paths)
    if [ -n "${custom_raw}" ] && [ "${custom_raw}" != "[]" ]; then
        local parts p
        IFS=',' read -ra parts <<<"$(printf '%s' "${custom_raw}" | sed -E 's/^\[//; s/\]$//')"
        for p in "${parts[@]}"; do
            p=$(printf '%s' "${p}" | sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//')
            [ -n "${p}" ] && WF_TICKET_ALLOW+=("${p}")
        done
    fi
    return 0
}
