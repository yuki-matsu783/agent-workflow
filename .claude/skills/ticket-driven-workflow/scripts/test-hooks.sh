#!/usr/bin/env bash
# ============================================================
# test-hooks.sh — workflow-guard / workflow-diff-check のユニットテスト
# ============================================================
# .claude/docs/10_spec/チケット駆動ワークフロー.md のテストシナリオを検証する。
# 一時ディレクトリに Git リポジトリを作って stdin に JSON を与え、
# exit code / stderr / stdout を検証する。
#
# 使い方: bash .claude/skills/ticket-driven-workflow/scripts/test-hooks.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "${SCRIPT_DIR}/../../../hooks" && pwd)"
GUARD="${HOOKS_DIR}/workflow-guard.sh"
DIFF_CHECK="${HOOKS_DIR}/workflow-diff-check.sh"
SESSION="testsession"

TMP=$(mktemp -d)
ERRF=$(mktemp)  # stderr の受け皿はリポジトリ外に置く（差分検出の対象にしない）
trap 'rm -rf "${TMP}" "${ERRF}"' EXIT

# 実環境では CLAUDE_PROJECT_DIR も file_path も Windows 形式で渡ってくる。
# MSYS はネイティブ exe（jq）への引数のみパス変換するため、テストでは cygpath で表記を統一する
if command -v cygpath >/dev/null 2>&1; then
    TMPW=$(cygpath -m "${TMP}")
else
    TMPW="${TMP}"
fi

PASS=0
FAIL=0

# ---------- テスト環境の構築 ----------
setup_repo() {
    (
        cd "${TMP}"
        git init -q
        git config user.email test@example.com
        git config user.name test
        mkdir -p wip/ticket/todo wip/ticket/doing wip/ticket/done wip/plan wip/retrospective src lib config \
            .claude/hooks .claude/docs .claude/skills/foo
        echo base >src/main.ts
        echo base >lib/util.ts
        echo '{}' >package.json
        echo base >README.md
        # フックは WF_ROOT 配下の作業タイプ定義を読むため、実物を複製する
        cp "${HOOKS_DIR}/workflow-types.json" .claude/hooks/
        git add -A
        git commit -qm "initial"
    )
}

# チケットを doing に置き、基準点コミットを作る（WF008 の二次チェック用）
commit_doing() { (cd "${TMP}" && git add -A wip/ticket && git commit -qm "chore(ticket): start $1"); }

clear_session() { rm -rf "${TMP}/.claude/hooks/.state"; }

make_ticket() { # $1=dir(doing/todo/done) $2=filename $3=type $4=extra frontmatter line(optional)
    {
        echo "---"
        echo "type: $3"
        echo "status: doing"
        echo "depends_on: []"
        [ -n "${4:-}" ] && echo "$4"
        echo "---"
        echo "# ticket"
    } >"${TMP}/wip/ticket/$1/$2"
}

clear_doing() { rm -f "${TMP}/wip/ticket/doing/"*.md; }

edit_json() { jq -n --arg fp "$1" --arg s "${SESSION}" '{tool_name: "Edit", session_id: $s, tool_input: {file_path: $fp}}'; }
bash_json() { jq -n --arg c "$1" --arg s "${SESSION}" '{tool_name: "Bash", session_id: $s, tool_input: {command: $c}}'; }
plan_json() { jq -n --arg s "${SESSION}" '{tool_name: "EnterPlanMode", session_id: $s, tool_input: {}}'; }
edit_ticket_json() { # $1=ticket path $2=old_string $3=new_string
    jq -n --arg fp "$1" --arg o "$2" --arg n "$3" --arg s "${SESSION}" \
        '{tool_name: "Edit", session_id: $s, tool_input: {file_path: $fp, old_string: $o, new_string: $n}}'
}
write_json() { jq -n --arg fp "$1" --arg c "$2" --arg s "${SESSION}" '{tool_name: "Write", session_id: $s, tool_input: {file_path: $fp, content: $c}}'; }

run_guard() { # stdin JSON を与えて guard を実行。GUARD_EXIT / GUARD_ERR / GUARD_OUT に結果を格納
    GUARD_OUT=$(CLAUDE_PROJECT_DIR="${TMPW}" WORKFLOW_ENFORCE="${ENFORCE:-1}" bash "${GUARD}" 2>"${ERRF}" <<<"$1")
    GUARD_EXIT=$?
    GUARD_ERR=$(cat "${ERRF}")
}

run_post() { # PostToolUse を実行し POST_OUT に stdout を格納
    POST_OUT=$(CLAUDE_PROJECT_DIR="${TMPW}" bash "${DIFF_CHECK}" <<<"$1")
    POST_EXIT=$?
}

check() { # $1=テストID $2=期待exit $3=stderr/stdoutに含まれるべき文字列(空可) $4=含まれてはいけない文字列(空可)
    local id="$1" want_exit="$2" want="${3:-}" unwant="${4:-}"
    local combined="${GUARD_ERR}${GUARD_OUT}"
    if [ "${GUARD_EXIT}" -ne "${want_exit}" ]; then
        echo "FAIL ${id}: exit ${GUARD_EXIT} (expected ${want_exit}) : ${combined}"
        FAIL=$((FAIL + 1))
        return
    fi
    if [ -n "${want}" ] && ! grep -q "${want}" <<<"${combined}"; then
        echo "FAIL ${id}: 出力に '${want}' が無い : ${combined}"
        FAIL=$((FAIL + 1))
        return
    fi
    if [ -n "${unwant}" ] && grep -q "${unwant}" <<<"${combined}"; then
        echo "FAIL ${id}: 出力に '${unwant}' が含まれる : ${combined}"
        FAIL=$((FAIL + 1))
        return
    fi
    echo "PASS ${id}"
    PASS=$((PASS + 1))
}

check_post() { # $1=テストID $2=含まれるべき文字列(空=出力なしを期待) $3=含まれてはいけない文字列(空可)
    local id="$1" want="${2:-}" unwant="${3:-}"
    if [ "${POST_EXIT}" -ne 0 ]; then
        echo "FAIL ${id}: exit ${POST_EXIT} : ${POST_OUT}"
        FAIL=$((FAIL + 1)); return
    fi
    if [ -z "${want}" ] && [ -n "${POST_OUT}" ]; then
        echo "FAIL ${id}: 出力なしを期待したが出力あり : ${POST_OUT}"
        FAIL=$((FAIL + 1)); return
    fi
    if [ -n "${want}" ] && ! grep -q "${want}" <<<"${POST_OUT}"; then
        echo "FAIL ${id}: 出力に '${want}' が無い : ${POST_OUT}"
        FAIL=$((FAIL + 1)); return
    fi
    if [ -n "${unwant}" ] && grep -q "${unwant}" <<<"${POST_OUT}"; then
        echo "FAIL ${id}: 出力に '${unwant}' が含まれる : ${POST_OUT}"
        FAIL=$((FAIL + 1)); return
    fi
    echo "PASS ${id}"
    PASS=$((PASS + 1))
}

setup_repo

# ---------- TC001: doing 0 枚（通常セッション）は素通し ----------
run_guard "$(edit_json "${TMPW}/src/main.ts")"
check TC001 0 "" "WF"

# TC013b: doing 0 枚ならプランモード（全体計画の作成）は許可
run_guard "$(plan_json)"
check TC013b 0 "" "WF"

# ---------- TC002: doing 2 枚は WF001 ----------
make_ticket doing 001-investigation-a.md investigation
make_ticket doing 002-investigation-b.md investigation
run_guard "$(edit_json "${TMPW}/src/main.ts")"
check TC002 2 "WF001"
clear_doing

# ---------- 調査チケット 1 枚を doing に置く ----------
make_ticket doing 001-investigation-調査.md investigation

# TC003: wip/plan への Write は許可（type.allow_paths）
run_guard "$(edit_json "${TMPW}/wip/plan/調査結果.md")"
check TC003 0 "" "WF"

# TC004: src への Edit は未記載 → 警告付きで確認（WF009）
run_guard "$(edit_json "${TMPW}/src/main.ts")"
check TC004 0 '"permissionDecision": "ask"'
check TC004b 0 "WF009"

# TC005: チケット自身への Edit（作業ログ）は許可（global.allow_paths）
run_guard "$(edit_json "${TMPW}/wip/ticket/doing/001-investigation-調査.md")"
check TC005 0 "" "WF"

# TC006: 読み取り Bash は許可（パイプ複合も含む）
run_guard "$(bash_json "git log --oneline | head -5")"
check TC006 0 "" "WF"

# TC007: リダイレクトによる書き込みは WF003
run_guard "$(bash_json "echo x > src/a.ts")"
check TC007 2 "WF003"

# TC008: sed -i は WF003
run_guard "$(bash_json "sed -i s/a/b/ src/a.ts")"
check TC008 2 "WF003"

# TC006b: チケット運用コマンド（doing→done の移動とコミット）は許可
run_guard "$(bash_json "git mv wip/ticket/doing/001-investigation-調査.md wip/ticket/done/ && git commit -m \"chore(ticket): done 001\"")"
check TC006b 0 "" "WF"

# TC007b: 調査中の npm 実行は WF003（bash_groups に build が無い）
run_guard "$(bash_json "npm test")"
check TC007b 2 "WF003"

# TC013: チケット作業中のプランモードは WF006
run_guard "$(plan_json)"
check TC013 2 "WF006"

# TC014: チケット作業中の全体計画（plansDirectory）への Edit は WF002（global.deny）
run_guard "$(edit_json "${TMPW}/wip/00_overall_plan/plan.md")"
check TC014 2 "WF002"

# TC015b: 保護パス（フック自体）への Edit は WF002
run_guard "$(edit_json "${TMPW}/.claude/hooks/workflow-guard.sh")"
check TC015b 2 "WF002"

# TC022: 未記載パスの git add は確認（WF009）。deny パスの git add は WF003
run_guard "$(bash_json "git add src/main.ts")"
check TC022 0 "WF009"
run_guard "$(bash_json "git add .claude/settings.json")"
check TC022b 2 "WF003"

# ---------- TC020: セッション記憶（承認 → 同ディレクトリは再確認しない） ----------
clear_session
run_post "$(edit_json "${TMPW}/src/main.ts")"      # PostToolUse = ユーザーが承認して実行された
run_guard "$(edit_json "${TMPW}/src/other.ts")"    # 同じディレクトリ → allow
check TC020 0 "" "WF"
run_guard "$(edit_json "${TMPW}/src/sub/deep.ts")" # サブディレクトリには波及しない → ask
check TC020b 0 "WF009"
run_guard "$(edit_json "${TMPW}/lib/util.ts")"     # 別ディレクトリ → ask
check TC020c 0 "WF009"
run_guard "$(bash_json "git add src/main.ts")"     # 記憶済みなら git add も許可
check TC020d 0 "" "WF"
# 記憶はセッション単位: 別セッション ID では再確認
SESSION=othersession
run_guard "$(edit_json "${TMPW}/src/other.ts")"
check TC020e 0 "WF009"
SESSION=testsession
clear_session

# ---------- TC021: ask_paths は毎回確認、file_level は ファイル単位で記憶 ----------
# 一時リポジトリの設定だけを書き換える（global.ask_paths に config/** を追加）
jq '.global.ask_paths = ["config/**"]' "${TMP}/.claude/hooks/workflow-types.json" >"${TMP}/.claude/hooks/tmp.json" \
    && mv "${TMP}/.claude/hooks/tmp.json" "${TMP}/.claude/hooks/workflow-types.json"
run_guard "$(edit_json "${TMPW}/config/app.yaml")"
check TC021 0 "WF010"
run_post "$(edit_json "${TMPW}/config/app.yaml")"  # 承認・実行されても記憶しない
run_guard "$(edit_json "${TMPW}/config/app.yaml")"
check TC021b 0 "WF010"
# file_level（package.json）はファイル単位で記憶: 承認後も同ディレクトリの README.md は再確認
run_post "$(edit_json "${TMPW}/package.json")"
run_guard "$(edit_json "${TMPW}/package.json")"
check TC021c 0 "" "WF"
run_guard "$(edit_json "${TMPW}/README.md")"
check TC021d 0 "WF009"
cp "${HOOKS_DIR}/workflow-types.json" "${TMP}/.claude/hooks/workflow-types.json"
clear_session

# ---------- TC009: フロントマター不正は WF004（チケット修正の Edit は許可） ----------
clear_doing
make_ticket doing 001-broken.md "unknown-type"
run_guard "$(edit_json "${TMPW}/src/main.ts")"
check TC009 2 "WF004"
run_guard "$(edit_json "${TMPW}/wip/ticket/doing/001-broken.md")"
check TC009b 0 "" "WF"
clear_doing

# ---------- TC010: WORKFLOW_ENFORCE=0 で全チェック無効 ----------
make_ticket doing 001-investigation-調査.md investigation
ENFORCE=0 run_guard "$(edit_json "${TMPW}/.claude/hooks/workflow-guard.sh")"
check TC010 0 "" "WF"
unset ENFORCE

# ---------- TC012: チケットの allowed_paths は追加の allow ----------
clear_doing
make_ticket doing 002-implementation-実装.md implementation 'allowed_paths: ["lib/**"]'
run_guard "$(edit_json "${TMPW}/lib/util.ts")"
check TC012 0 "" "WF"
run_guard "$(edit_json "${TMPW}/src/main.ts")"  # type の allow はそのまま有効
check TC012b 0 "" "WF"

# TC-impl: implementation ではビルド/テスト系を許可
run_guard "$(bash_json "npm test")"
check TC-impl 0 "" "WF"
clear_doing

# ---------- TC015: チケットの allowed_paths は global.deny に勝てない ----------
make_ticket doing 003-implementation-設定変更.md implementation 'allowed_paths: [".claude/**"]'
run_guard "$(edit_json "${TMPW}/.claude/settings.json")"
check TC015 2 "WF002"
run_guard "$(bash_json "git add .claude/settings.json")"
check TC015c 2 "WF003"
clear_doing

# ---------- TC016: ai-asset-design は .claude/docs のみ ----------
make_ticket doing 004-ai-asset-design-設計.md ai-asset-design
run_guard "$(edit_json "${TMPW}/.claude/docs/spec.md")"
check TC016 0 "" "WF"
run_guard "$(edit_json "${TMPW}/.claude/hooks/workflow-guard.sh")"
check TC016b 2 "WF002"
run_guard "$(edit_json "${TMPW}/.claude/settings.json")"
check TC016c 2 "WF002"
clear_doing

# ---------- TC017: ai-asset-implementation はフック/スキル/settings.json を修正できる ----------
make_ticket doing 005-ai-asset-implementation-実装.md ai-asset-implementation
run_guard "$(edit_json "${TMPW}/.claude/hooks/workflow-guard.sh")"
check TC017 0 "" "WF"
run_guard "$(edit_json "${TMPW}/.claude/settings.json")"
check TC017b 0 "" "WF"
run_guard "$(edit_json "${TMPW}/.claude/docs/spec.md")"  # docs は design 側の担当 → global.deny
check TC017c 2 "WF002"
run_guard "$(bash_json "git add .claude/settings.json .claude/skills/foo/SKILL.md")"
check TC017d 0 "" "WF"
# frontmatter で global.deny 内のパスを足しても許可されない
clear_doing
make_ticket doing 005-ai-asset-implementation-実装.md ai-asset-implementation 'allowed_paths: [".claude/docs/**"]'
run_guard "$(edit_json "${TMPW}/.claude/docs/spec.md")"
check TC017e 2 "WF002"
clear_doing

# ---------- TC018: 作業タイプ定義が読めなければ WF007（設定ファイル自身の Edit は許可） ----------
make_ticket doing 001-investigation-調査.md investigation
mv "${TMP}/.claude/hooks/workflow-types.json" "${TMP}/.claude/hooks/workflow-types.json.bak"
run_guard "$(edit_json "${TMPW}/wip/plan/調査結果.md")"
check TC018 2 "WF007"
run_guard "$(edit_json "${TMPW}/.claude/hooks/workflow-types.json")"
check TC018b 0 "" "WF"
mv "${TMP}/.claude/hooks/workflow-types.json.bak" "${TMP}/.claude/hooks/workflow-types.json"
clear_doing

# ---------- TC019: doing チケットの type 書き換えは WF008 ----------
make_ticket doing 001-investigation-調査.md investigation
TICKET_W="${TMPW}/wip/ticket/doing/001-investigation-調査.md"
run_guard "$(edit_ticket_json "${TICKET_W}" "type: investigation" "type: ai-asset-implementation")"
check TC019 2 "WF008"
# type を含まない置換（作業ログ追記）は許可
run_guard "$(edit_ticket_json "${TICKET_W}" "# ticket" "# ticket
- うまくいったこと: x")"
check TC019b 0 "" "WF"
# status 行の書き換えは type に影響しないので許可
run_guard "$(edit_ticket_json "${TICKET_W}" "status: doing" "status: done")"
check TC019c 0 "" "WF"
# Write で type を変えた全文を書き込むのも WF008
run_guard "$(write_json "${TICKET_W}" "---
type: implementation
status: doing
depends_on: []
---
# ticket")"
check TC019d 2 "WF008"
# type 行の削除も WF008
run_guard "$(edit_ticket_json "${TICKET_W}" "type: investigation
" "")"
check TC019e 2 "WF008"
# doing に 2 枚目を Write するのは WF001
run_guard "$(write_json "${TMPW}/wip/ticket/doing/999-investigation-別.md" "---
type: investigation
---")"
check TC019f 2 "WF001"
clear_doing

# ---------- TC011: 許可されていないパスの差分は additionalContext（WF-DIFF） ----------
clear_session
make_ticket doing 001-investigation-調査.md investigation
echo modified >>"${TMP}/src/main.ts"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC011 "WF-DIFF"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC011c "src/main.ts"
git -C "${TMP}" checkout -q -- src/main.ts

# TC011b: 許可パス内のみの差分なら additionalContext なし
echo note >"${TMP}/wip/plan/調査結果.md"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC011b ""
rm -f "${TMP}/wip/plan/調査結果.md"

# TC011d: 承認済み（セッション記憶あり）の未記載パスの差分は違反にしない
echo modified >>"${TMP}/src/main.ts"
run_post "$(edit_json "${TMPW}/src/main.ts")"   # この Edit の実行 = 承認
check_post TC011d "" "WF-DIFF"
git -C "${TMP}" checkout -q -- src/main.ts
clear_session

# ---------- TC-post-008: コミット済み type と異なれば PostToolUse が WF008 を警告 ----------
clear_doing
make_ticket doing 006-investigation-改変.md investigation
commit_doing 006-改変
sed -i 's/^type: investigation/type: ai-asset-implementation/' "${TMP}/wip/ticket/doing/006-investigation-改変.md"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC-post-008 "WF008"
git -C "${TMP}" rm -q --cached "wip/ticket/doing/006-investigation-改変.md" 2>/dev/null
rm -f "${TMP}/wip/ticket/doing/006-investigation-改変.md"
git -C "${TMP}" commit -qm "cleanup" --allow-empty

# ---------- TC-dep: depends_on 未完了は WF005 を警告 ----------
clear_doing
make_ticket doing 002-implementation-実装.md implementation
sed -i 's/depends_on: \[\]/depends_on: ["001-investigation-調査.md"]/' "${TMP}/wip/ticket/doing/002-implementation-実装.md"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC-dep "WF005"

echo ""
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
