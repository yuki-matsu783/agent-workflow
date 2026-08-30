#!/usr/bin/env bash
# ============================================================
# test-hooks.sh — workflow-guard / workflow-diff-check のユニットテスト
# ============================================================
# .claude/docs/10_spec/チケット駆動ワークフロー.md のテストシナリオを検証する。
# 一時ディレクトリに Git リポジトリを作って stdin に JSON を与え、
# exit code / stderr / stdout を検証する。
#
# 使い方: bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh
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
        mkdir -p wip/10_tickets/00_todo wip/10_tickets/10_doing wip/10_tickets/20_done wip/20_plans wip/30_reports src lib config \
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
commit_doing() { (cd "${TMP}" && git add -A wip/10_tickets && git commit -qm "chore(ticket): start $1"); }

clear_session() { rm -rf "${TMP}/.claude/hooks/.state"; }

# チケットの論理状態（todo/doing/done）を実ディレクトリ名に対応付ける
ticket_dir() { case "$1" in todo) echo 00_todo ;; doing) echo 10_doing ;; done) echo 20_done ;; esac; }

make_ticket() { # $1=状態(doing/todo/done) $2=filename $3=type $4=extra frontmatter line(optional)
    {
        echo "---"
        echo "type: $3"
        echo "status: doing"
        echo "depends_on: []"
        [ -n "${4:-}" ] && echo "$4"
        echo "---"
        echo "# ticket"
    } >"${TMP}/wip/10_tickets/$(ticket_dir "$1")/$2"
}

clear_doing() { rm -f "${TMP}/wip/10_tickets/10_doing/"*.md; }

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

# TC003: wip/20_plans への Write は許可（type.allow_paths）
run_guard "$(edit_json "${TMPW}/wip/20_plans/調査結果.md")"
check TC003 0 "" "WF"

# TC004: src への Edit は未記載 → 警告付きで確認（WF009）
run_guard "$(edit_json "${TMPW}/src/main.ts")"
check TC004 0 '"permissionDecision": "ask"'
check TC004b 0 "WF009"

# TC005: チケット自身への Edit（作業ログ）は許可（global.allow_paths）
run_guard "$(edit_json "${TMPW}/wip/10_tickets/10_doing/001-investigation-調査.md")"
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
run_guard "$(bash_json "git mv wip/10_tickets/10_doing/001-investigation-調査.md wip/10_tickets/20_done/ && git commit -m \"chore(ticket): done 001\"")"
check TC006b 0 "" "WF"

# TC007b: 調査中の npm 実行は WF003（bash_groups に build が無い）
run_guard "$(bash_json "npm test")"
check TC007b 2 "WF003"

# TC007c: 調査中のテストスクリプト実行は WF003（bash_groups に test が無い）
run_guard "$(bash_json "bash .claude/hooks/tests/test-workflow-entry.sh")"
check TC007c 2 "WF003"

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
run_guard "$(edit_json "${TMPW}/wip/10_tickets/10_doing/001-broken.md")"
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
# TC023: bash_groups "test" を持つ type はフックのテストスクリプトを実行できる（環境変数の前置も可）。対象外のスクリプトは WF003
run_guard "$(bash_json "bash .claude/hooks/tests/test-workflow-entry.sh")"
check TC023 0 "" "WF"
run_guard "$(bash_json "WF_ENTRY_SCRIPT=/tmp/x.sh bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh")"
check TC023b 0 "" "WF"
run_guard "$(bash_json "bash .claude/hooks/workflow-guard.sh")"
check TC023c 2 "WF003"
run_guard "$(bash_json "bash scripts/deploy.sh")"
check TC023d 2 "WF003"
# frontmatter で global.deny 内のパスを足しても許可されない
clear_doing
make_ticket doing 005-ai-asset-implementation-実装.md ai-asset-implementation 'allowed_paths: [".claude/docs/**"]'
run_guard "$(edit_json "${TMPW}/.claude/docs/spec.md")"
check TC017e 2 "WF002"
clear_doing

# ---------- TC018: 作業タイプ定義が読めなければ WF007（設定ファイル自身の Edit は許可） ----------
make_ticket doing 001-investigation-調査.md investigation
mv "${TMP}/.claude/hooks/workflow-types.json" "${TMP}/.claude/hooks/workflow-types.json.bak"
run_guard "$(edit_json "${TMPW}/wip/20_plans/調査結果.md")"
check TC018 2 "WF007"
run_guard "$(edit_json "${TMPW}/.claude/hooks/workflow-types.json")"
check TC018b 0 "" "WF"
mv "${TMP}/.claude/hooks/workflow-types.json.bak" "${TMP}/.claude/hooks/workflow-types.json"
clear_doing

# ---------- TC019: doing チケットの type 書き換えは WF008 ----------
make_ticket doing 001-investigation-調査.md investigation
TICKET_W="${TMPW}/wip/10_tickets/10_doing/001-investigation-調査.md"
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
run_guard "$(write_json "${TMPW}/wip/10_tickets/10_doing/999-investigation-別.md" "---
type: investigation
---")"
check TC019f 2 "WF001"
# doing への .gitkeep（チケットではないファイル）の Write は許可
run_guard "$(write_json "${TMPW}/wip/10_tickets/10_doing/.gitkeep" "")"
check TC019g 0 "" "WF"
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
echo note >"${TMP}/wip/20_plans/調査結果.md"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC011b ""
rm -f "${TMP}/wip/20_plans/調査結果.md"

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
sed -i 's/^type: investigation/type: ai-asset-implementation/' "${TMP}/wip/10_tickets/10_doing/006-investigation-改変.md"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC-post-008 "WF008"
git -C "${TMP}" rm -q --cached "wip/10_tickets/10_doing/006-investigation-改変.md" 2>/dev/null
rm -f "${TMP}/wip/10_tickets/10_doing/006-investigation-改変.md"
git -C "${TMP}" commit -qm "cleanup" --allow-empty

# ---------- TC-dep: depends_on 未完了は WF005 を警告 ----------
clear_doing
make_ticket doing 002-implementation-実装.md implementation
sed -i 's/depends_on: \[\]/depends_on: ["001-investigation-調査.md"]/' "${TMP}/wip/10_tickets/10_doing/002-implementation-実装.md"
run_post '{"tool_name":"Bash","tool_input":{}}'
check_post TC-dep "WF005"

# ============================================================
# ワーク境界（work-boundary.sh / workflow-boundary.sh）
# 仕様: チケット駆動ワークフロー.md「ワーク境界の判定とレビュー状態」TC024〜TC028
# ============================================================
BOUNDARY="${HOOKS_DIR}/workflow-boundary.sh"
WB="${HOOKS_DIR}/work-boundary.sh"
STATE_FILE="${TMP}/wip/10_tickets/review-state.json"
STATE_W="${TMPW}/wip/10_tickets/review-state.json"

# gh のモック（ネットワークに出ない）。リポジトリ外に置く（未コミット扱いにしない）
MOCK_BIN=$(mktemp -d)
BARE=$(mktemp -d)
trap 'rm -rf "${TMP}" "${ERRF}" "${MOCK_BIN}" "${BARE}"' EXIT
cat >"${MOCK_BIN}/gh" <<'EOF'
#!/usr/bin/env bash
[ -n "${GH_MOCK_LOG:-}" ] && printf '%s\n' "$*" >>"${GH_MOCK_LOG}"
[ -n "${GH_MOCK_NO_PR:-}" ] && case "$*" in *"pr view"*) exit 1 ;; esac
case "$*" in
    *"pr view --json number"*) echo "${GH_MOCK_PR:-13}" ;;
    *"pr view"*"--json body"*) printf '%s' "${GH_MOCK_PRBODY:-## 関連 Issue
- Closes #30}" ;;
    *"pr view"*) printf '%s' "${GH_MOCK_PRVIEW:-{\"reviewDecision\":\"\",\"reviews\":[],\"comments\":[]}}" ;;
    *"pr comment"*) echo "https://example.test/pull/13#issuecomment-4242" ;;
    *"pr ready"*) echo "✓ Pull request #13 is marked as ready for review" ;;
    *"issue comment"*) echo "https://example.test/issues/$3#issuecomment-777$3" ;;   # $1=issue $2=comment $3=番号
    *"/replies"*) echo "https://example.test/reply" ;;
    *"/comments"*) printf '%s' "${GH_MOCK_INLINE:-[]}" ;;
    *) echo "mock gh: unsupported: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "${MOCK_BIN}/gh"

run_boundary() { # workflow-boundary.sh を実行（結果は run_guard と同じ変数へ）
    GUARD_OUT=$(CLAUDE_PROJECT_DIR="${TMPW}" WORKFLOW_ENFORCE="${ENFORCE:-1}" bash "${BOUNDARY}" 2>"${ERRF}" <<<"$1")
    GUARD_EXIT=$?
    GUARD_ERR=$(cat "${ERRF}")
}
run_wb() { # work-boundary.sh <subcommand...> を一時リポジトリ内で実行
    GUARD_OUT=$(cd "${TMP}" && CLAUDE_PROJECT_DIR="${TMPW}" PATH="${MOCK_BIN}:${PATH}" bash "${WB}" "$@" 2>"${ERRF}")
    GUARD_EXIT=$?
    GUARD_ERR=$(cat "${ERRF}")
}
clear_tickets() { rm -f "${TMP}"/wip/10_tickets/*/*.md "${STATE_FILE}"; }
commit_all() { (cd "${TMP}" && git add -A && git commit -qm "$1" --allow-empty); }
write_state() { # $1=ticket $2=state $3=local(true/false)
    jq -n --arg t "$1" --arg s "$2" --argjson l "$3" \
        '{version:1, ticket:$t, work_type:"investigation", state:$s, local:$l, pr:(if $l then null else 13 end), head_sha:"x",
          request:{comment_id:(if $l then null else "4242" end), url:null, at:"2020-01-01T00:00:00Z"}, complete:null}' >"${STATE_FILE}"
}

# ---------- TC024: status の境界判定 ----------
clear_tickets; clear_session
make_ticket done 001-investigation-a.md investigation
make_ticket todo 002-investigation-b.md investigation
run_wb status
check TC024 0 '"at_boundary": false'
rm -f "${TMP}/wip/10_tickets/00_todo/002-investigation-b.md"
make_ticket done 002-investigation-b.md investigation
make_ticket todo 003-implementation-c.md implementation
run_wb status
check TC024b 0 '"at_boundary": true'
check TC024b2 0 '"review_state": "none"'
check TC024b3 0 '"last_done": "002-investigation-b.md"'
rm -f "${TMP}/wip/10_tickets/00_todo/003-implementation-c.md"
run_wb status
check TC024c 0 '"at_boundary": true'
clear_tickets
make_ticket todo 001-investigation-a.md investigation
run_wb status
check TC024d 0 '"at_boundary": false'
make_ticket done 001-investigation-a.md investigation
make_ticket doing 002-implementation-b.md implementation
run_wb status
check TC024d2 0 '"at_boundary": false'
# 状態ファイルの ticket が done 末尾と違えば失効（none）
clear_tickets
make_ticket done 002-investigation-b.md investigation
make_ticket todo 003-implementation-c.md implementation
write_state 001-investigation-a.md completed true
run_wb status
check TC024e 0 '"review_state": "none"'
# todo_same_type に同 type の追加チケットが列挙される
make_ticket todo 004-investigation-fix.md investigation
run_wb status
check TC024f 0 '004-investigation-fix.md'
rm -f "${TMP}/wip/10_tickets/00_todo/004-investigation-fix.md"

# ---------- TC025: 状態ファイルの直接書き換えは常に WF012 ----------
run_boundary "$(edit_json "${STATE_W}")"
check TC025 2 "WF012"
run_boundary "$(write_json "${STATE_W}" "{}")"
check TC025-w 2 "WF012"
make_ticket doing 009-investigation-x.md investigation   # doing があっても同じ
run_boundary "$(edit_json "${STATE_W}")"
check TC025-doing 2 "WF012"
clear_doing
for cmd in "rm wip/10_tickets/review-state.json" "sed -i s/requested/completed/ wip/10_tickets/review-state.json" \
    "echo x > wip/10_tickets/review-state.json" "git checkout -- wip/10_tickets/review-state.json" \
    "git rm wip/10_tickets/review-state.json" "mv wip/10_tickets/review-state.json /tmp/x"; do
    run_boundary "$(bash_json "${cmd}")"
    check "TC025b(${cmd%% *})" 2 "WF012"
done
for cmd in "cat wip/10_tickets/review-state.json" "git diff wip/10_tickets/review-state.json" \
    "git log -- wip/10_tickets/review-state.json" "bash .claude/hooks/work-boundary.sh status"; do
    run_boundary "$(bash_json "${cmd}")"
    check "TC025c(${cmd%% *})" 0 "" "WF"
done

# TC025d: 引用符内の文字列に review-state.json が含まれるだけのコマンドは誤検知しない（#29）
for cmd in 'gh issue create --title "review-state.json の扱い" --body x' \
    "gh issue create --title 'review-state.json の扱い' --body x"; do
    run_boundary "$(bash_json "${cmd}")"
    check "TC025d(quoted-title)" 0 "" "WF"
done
# TC025e: パスそのものを引用符で囲んでも WF012 のまま（クォート除去に紛れて素通りしない）
for cmd in 'rm "wip/10_tickets/review-state.json"' "rm 'wip/10_tickets/review-state.json'" \
    'echo x > "wip/10_tickets/review-state.json"'; do
    run_boundary "$(bash_json "${cmd}")"
    check "TC025e(${cmd%% *})" 2 "WF012"
done

# ---------- TC026: 境界でレビュー未完了なら次ワークの着手は WF011 ----------
MV_NEXT="git mv wip/10_tickets/00_todo/003-implementation-c.md wip/10_tickets/10_doing/"
rm -f "${STATE_FILE}"
run_boundary "$(bash_json "${MV_NEXT}")"
check TC026 2 "WF011"
check TC026-remedy 2 "request"
write_state 002-investigation-b.md requested false
run_boundary "$(bash_json "${MV_NEXT}")"
check TC026b 2 "WF011"
check TC026b-remedy 2 "complete"
write_state 002-investigation-b.md completed false
run_boundary "$(bash_json "${MV_NEXT}")"
check TC026c 0 "" "WF"
# 同 type の追加チケットは requested でも着手できる
write_state 002-investigation-b.md requested false
make_ticket todo 004-investigation-fix.md investigation
run_boundary "$(bash_json "git mv wip/10_tickets/00_todo/004-investigation-fix.md wip/10_tickets/10_doing/")"
check TC026d 0 "" "WF"
rm -f "${TMP}/wip/10_tickets/00_todo/004-investigation-fix.md"
# 境界でなければ統制しない
clear_tickets
make_ticket done 001-investigation-a.md investigation
make_ticket todo 002-investigation-b.md investigation
run_boundary "$(bash_json "git mv wip/10_tickets/00_todo/002-investigation-b.md wip/10_tickets/10_doing/")"
check TC026e 0 "" "WF"
# 境界で doing に直接 Write（type が変わる）は WF011、同 type なら許可
clear_tickets
make_ticket done 002-investigation-b.md investigation
make_ticket todo 003-implementation-c.md implementation
run_boundary "$(write_json "${TMPW}/wip/10_tickets/10_doing/003-implementation-c.md" "---
type: implementation
---")"
check TC026f 2 "WF011"
run_boundary "$(write_json "${TMPW}/wip/10_tickets/10_doing/004-investigation-fix.md" "---
type: investigation
---")"
check TC026f2 0 "" "WF"
# 最後のワーク（todo 空）で requested のまま gh pr ready は WF015（issue #30 で WF011 から変更。直接実行は常に拒否）
rm -f "${TMP}/wip/10_tickets/00_todo/003-implementation-c.md"
write_state 002-investigation-b.md requested false
run_boundary "$(bash_json "gh pr ready 13")"
check TC026g 2 "WF015"
ENFORCE=0 run_boundary "$(bash_json "gh pr ready 13")"
check TC026h 0 "" "WF"
unset ENFORCE
# 境界の統制中でも、無関係な操作は素通し
run_boundary "$(bash_json "git push")"
check TC026i 0 "" "WF"
run_boundary "$(edit_json "${TMPW}/wip/10_tickets/00_todo/005-retrospective-r.md")"
check TC026j 0 "" "WF"

# ---------- TC027: request ----------
# フックが書くログとセッション記憶は実リポジトリ同様に Git 管理外（request の「未コミット無し」判定に影響させない）
printf '.claude/hooks/workflow.log\n.claude/hooks/.state/\n' >"${TMP}/.gitignore"
clear_tickets
make_ticket done 001-investigation-a.md investigation
make_ticket todo 002-investigation-b.md investigation
commit_all "tc027 setup"
run_wb request --local            # 境界でない
check TC027 2 "WF013"
check TC027-msg 2 "境界ではありません"
clear_tickets
make_ticket done 002-investigation-b.md investigation
make_ticket todo 003-implementation-c.md implementation
run_wb request --local            # 未コミットの変更あり
check TC027-dirty 2 "未コミット"
[ ! -f "${STATE_FILE}" ] && echo "PASS TC027-nostate" && PASS=$((PASS + 1)) || { echo "FAIL TC027-nostate: 状態ファイルが作られた"; FAIL=$((FAIL + 1)); }
commit_all "tc027 boundary"
run_wb request                    # upstream 無し（push 未済）
check TC027-nopush 2 "push"
# --local の成功: 状態ファイルが requested になりコミットされる
run_wb request --local
check TC027b 0 '"review_state": "requested"'
run_wb status
check TC027b2 0 '"review_state": "requested"'
check TC027b3 0 '"local": true'
git -C "${TMP}" log -1 --pretty=%s | grep -q "chore(review): request 002-investigation-b.md" \
    && { echo "PASS TC027b-commit"; PASS=$((PASS + 1)); } || { echo "FAIL TC027b-commit: $(git -C "${TMP}" log -1 --pretty=%s)"; FAIL=$((FAIL + 1)); }
[ -z "$(git -C "${TMP}" status --porcelain)" ] && { echo "PASS TC027b-clean"; PASS=$((PASS + 1)); } || { echo "FAIL TC027b-clean"; FAIL=$((FAIL + 1)); }
run_wb request --local            # 二重依頼
check TC027c 2 "WF013"
check TC027c-msg 2 "既に requested"

# ---------- TC028: complete ----------
run_wb complete                   # --local 不一致
check TC028-local 2 "WF014"
run_wb complete --local
check TC028b 0 '"review_state": "completed"'
git -C "${TMP}" log -1 --pretty=%s | grep -q "chore(review): complete 002-investigation-b.md" \
    && { echo "PASS TC028b-commit"; PASS=$((PASS + 1)); } || { echo "FAIL TC028b-commit"; FAIL=$((FAIL + 1)); }
run_wb complete --local           # completed からは不可
check TC028-none 2 "WF014"
run_boundary "$(bash_json "${MV_NEXT}")"   # completed なら次ワークに着手できる
check TC028-next 0 "" "WF"

# 非 --local: bare リモートと gh モックで request → complete
git -C "${TMP}" mv wip/10_tickets/00_todo/003-implementation-c.md wip/10_tickets/20_done/ -q 2>/dev/null \
    || mv "${TMP}/wip/10_tickets/00_todo/003-implementation-c.md" "${TMP}/wip/10_tickets/20_done/"
make_ticket todo 004-retrospective-r.md retrospective
commit_all "tc028 impl done"
git -C "${BARE}" init -q --bare
git -C "${TMP}" remote add origin "${BARE}"
git -C "${TMP}" push -qu origin "$(git -C "${TMP}" branch --show-current)" 2>/dev/null
run_wb request
check TC027d 0 '"review_state": "requested"'
check TC027d-url 0 "issuecomment-4242"
run_wb status
check TC027d2 0 '"comment_id": "4242"'
check TC027d3 0 '"local": false'
[ "$(git -C "${TMP}" rev-parse HEAD)" = "$(git -C "${TMP}" rev-parse '@{u}')" ] \
    && { echo "PASS TC027d-pushed"; PASS=$((PASS + 1)); } || { echo "FAIL TC027d-pushed"; FAIL=$((FAIL + 1)); }
export GH_MOCK_PRVIEW='{"reviewDecision":"CHANGES_REQUESTED","reviews":[],"comments":[]}'
run_wb complete
check TC028c-cr 2 "CHANGES_REQUESTED"
export GH_MOCK_PRVIEW='{"reviewDecision":"APPROVED","reviews":[],"comments":[]}'
export GH_MOCK_INLINE='[{"id":1,"path":"a.md","line":3,"body":"fix","in_reply_to_id":null,"user":{"login":"r"},"html_url":"u","created_at":"2099-01-01T00:00:00Z"}]'
run_wb complete
check TC028c-unreplied 2 "返信の無い"
check TC028c-unreplied-id 2 "1 a.md:3"
run_wb status
check TC028c-still 0 '"review_state": "requested"'
export GH_MOCK_INLINE='[{"id":1,"path":"a.md","line":3,"body":"fix","in_reply_to_id":null,"user":{"login":"r"},"html_url":"u","created_at":"2099-01-01T00:00:00Z"},{"id":2,"path":"a.md","line":3,"body":"Claude Code より: done","in_reply_to_id":1,"user":{"login":"me"},"html_url":"u2","created_at":"2099-01-02T00:00:00Z"}]'
export GH_MOCK_PRVIEW='{"reviewDecision":"APPROVED","reviews":[{"author":{"login":"r"},"state":"APPROVED","body":"ok","submittedAt":"2099-01-01T00:00:00Z"}],"comments":[{"id":"c1","author":{"login":"r"},"createdAt":"2099-01-01T00:00:00Z","url":"u","body":"nice"},{"id":"c0","author":{"login":"me"},"createdAt":"2099-01-01T00:00:00Z","url":"u","body":"Claude Code より: 依頼"},{"id":"c9","author":{"login":"r"},"createdAt":"2000-01-01T00:00:00Z","url":"u","body":"old"}]}'
run_wb complete
check TC028c 0 '"review_state": "completed"'
check TC028c-new 0 '"nice"'
check TC028c-own 0 "" "依頼"
check TC028c-old 0 "" '"old"'
check TC028c-review 0 '"APPROVED"'
run_wb status
check TC028c-decision 0 '"review_decision": "APPROVED"'
unset GH_MOCK_PRVIEW GH_MOCK_INLINE
run_wb reply 1 "対応しました"
check TC028-reply 0 "example.test/reply"

# ============================================================
# マージ前作業（merge-prep.sh / workflow-boundary.sh）
# 仕様: チケット駆動ワークフロー.md「マージ前作業の判定と状態」TC029〜TC031
# ============================================================
MP="${HOOKS_DIR}/merge-prep.sh"
MP_STATE_FILE="${TMP}/wip/merge-prep.json"
MP_STATE_W="${TMPW}/wip/merge-prep.json"
MOCK_LOG=$(mktemp)
export GH_MOCK_LOG="${MOCK_LOG}"
trap 'rm -rf "${TMP}" "${ERRF}" "${MOCK_BIN}" "${BARE}" "${MOCK_LOG}" "${TMP2:-}"' EXIT

run_mp() { # merge-prep.sh <subcommand...> を一時リポジトリ内で実行
    GUARD_OUT=$(cd "${TMP}" && CLAUDE_PROJECT_DIR="${TMPW}" PATH="${MOCK_BIN}:${PATH}" bash "${MP}" "$@" 2>"${ERRF}")
    GUARD_EXIT=$?
    GUARD_ERR=$(cat "${ERRF}")
}
pass_if() { # $1=テストID $2=条件（bash -c で評価）
    if bash -c "$2"; then echo "PASS $1"; PASS=$((PASS + 1)); else echo "FAIL $1"; FAIL=$((FAIL + 1)); fi
}

# ---------- TC029: merge-prep.json の保護（WF012）と gh pr ready の常時拒否（WF015） ----------
# 現状: done 002 / 003、todo 004-retrospective、review-state は 003 completed（境界・completed）
run_boundary "$(edit_json "${MP_STATE_W}")"
check TC029 2 "WF012"
run_boundary "$(write_json "${MP_STATE_W}" "{}")"
check TC029-w 2 "WF012"
for cmd in "rm wip/merge-prep.json" "sed -i s/reset/ready/ wip/merge-prep.json" \
    "echo x > wip/merge-prep.json" "git checkout -- wip/merge-prep.json"; do
    run_boundary "$(bash_json "${cmd}")"
    check "TC029b(${cmd%% *})" 2 "WF012"
done
for cmd in "cat wip/merge-prep.json" "git diff wip/merge-prep.json" "bash .claude/hooks/merge-prep.sh status"; do
    run_boundary "$(bash_json "${cmd}")"
    check "TC029c(${cmd%% *})" 0 "" "WF"
done
# gh pr ready は completed でも WF015
run_boundary "$(bash_json "gh pr ready 13")"
check TC029d 2 "WF015"
check TC029d-remedy 2 "merge-prep.sh ready"
run_boundary "$(bash_json "git push && gh pr ready 13")"
check TC029d2 2 "WF015"
make_ticket doing 009-investigation-x.md investigation   # doing があっても同じ
run_boundary "$(bash_json "gh pr ready 13")"
check TC029d3 2 "WF015"
clear_doing
ENFORCE=0 run_boundary "$(bash_json "gh pr ready 13")"
check TC029e 0 "" "WF"
unset ENFORCE
# merge-prep.sh ready 経由は WF015 にならない
run_boundary "$(bash_json "bash .claude/hooks/merge-prep.sh ready")"
check TC029f 0 "" "WF"

# ---------- TC030: reset-wip ----------
touch "${TMP}/wip/10_tickets/20_done/.gitkeep" "${TMP}/wip/20_plans/.gitkeep" "${TMP}/wip/30_reports/.gitkeep"
echo plan >"${TMP}/wip/20_plans/plan.md"
echo report >"${TMP}/wip/30_reports/report.md"
commit_all "tc030 setup"
git -C "${TMP}" push -q 2>/dev/null
run_mp reset-wip                   # todo が残っている
check TC030 2 "WF016"
check TC030-msg 2 "todo にチケットが残っています"
[ ! -f "${MP_STATE_FILE}" ] && { echo "PASS TC030-nostate"; PASS=$((PASS + 1)); } || { echo "FAIL TC030-nostate"; FAIL=$((FAIL + 1)); }
rm -f "${TMP}/wip/10_tickets/00_todo/004-retrospective-r.md"
commit_all "tc030 todo empty"
git -C "${TMP}" push -q 2>/dev/null
echo dirty >"${TMP}/src/dirty.ts"
run_mp reset-wip                   # 未コミットあり
check TC030-dirty 2 "未コミット"
rm -f "${TMP}/src/dirty.ts"
GH_MOCK_NO_PR=1 run_mp reset-wip   # PR なし
check TC030-nopr 2 "open な PR"
write_state 001-investigation-a.md completed false   # 失効 → review_state none
commit_all "tc030 stale review"
run_mp reset-wip
check TC030-review 2 "completed ではありません"
write_state 003-implementation-c.md completed false
commit_all "tc030 review ok"
git -C "${TMP}" push -q 2>/dev/null
run_mp reset-wip --dry-run
check TC030-dry 0 '"dry_run": true'
check TC030-dry2 0 '003-implementation-c.md'
pass_if TC030-dry-keep "[ -f '${TMP}/wip/10_tickets/20_done/003-implementation-c.md' ] && [ -f '${STATE_FILE}' ]"
run_mp reset-wip
check TC030b 0 '"merge_state": "reset"'
check TC030b2 0 'wip/30_reports/report.md'
pass_if TC030b-deleted "[ ! -f '${TMP}/wip/10_tickets/20_done/003-implementation-c.md' ] && [ ! -f '${STATE_FILE}' ] && [ ! -f '${TMP}/wip/20_plans/plan.md' ]"
pass_if TC030b-gitkeep "[ -f '${TMP}/wip/10_tickets/20_done/.gitkeep' ] && [ -f '${TMP}/wip/20_plans/.gitkeep' ]"
pass_if TC030b-state "jq -e '.state == \"reset\" and .pr == 13 and .review.ticket == \"003-implementation-c.md\"' '${MP_STATE_FILE}' >/dev/null"
pass_if TC030b-commit "git -C '${TMP}' log -1 --pretty=%s | grep -q 'chore(merge-prep): reset wip'"
pass_if TC030b-clean "[ -z \"\$(git -C '${TMP}' status --porcelain)\" ]"
pass_if TC030b-pushed "[ \"\$(git -C '${TMP}' rev-parse HEAD)\" = \"\$(git -C '${TMP}' rev-parse '@{u}')\" ]"
run_mp status
check TC030c 0 '"merge_state": "reset"'
check TC030c2 0 '"wip_clean": true'
run_mp reset-wip                   # 再実行は done が無いので拒否
check TC030d 2 "WF016"

# ---------- TC031: check-conflicts / notify-issue / ready ----------
# ベースブランチ base を bare に用意し、両側で src/main.ts を別々に変える
git -C "${TMP}" branch -q base "$(git -C "${TMP}" rev-list --max-parents=0 HEAD | tail -1)"
git -C "${TMP}" push -q origin base 2>/dev/null
echo head-change >"${TMP}/src/main.ts"
commit_all "tc031 head change"
git -C "${TMP}" push -q 2>/dev/null
TMP2=$(mktemp -d)
git clone -q "${BARE}" "${TMP2}" 2>/dev/null
git -C "${TMP2}" config user.email test@example.com
git -C "${TMP2}" config user.name test
git -C "${TMP2}" checkout -q base
echo base-change >"${TMP2}/src/main.ts"
git -C "${TMP2}" commit -qam "tc031 base change"
git -C "${TMP2}" push -q origin base 2>/dev/null
run_mp ready --base base           # notify 前の ready は前提未充足（衝突も列挙される）
check TC031-early 2 "WF016"
check TC031-early2 2 "notified ではありません"
run_mp check-conflicts --base base
check TC031 2 "WF016"
check TC031-file 2 "src/main.ts"
check TC031-remedy 2 "git merge origin/base"
pass_if TC031-recorded "jq -e '.conflicts.has_conflict == true and .state == \"reset\"' '${MP_STATE_FILE}' >/dev/null"
pass_if TC031-tree-clean "[ -z \"\$(git -C '${TMP}' status --porcelain)\" ]"
# 解消: origin/base を merge して衝突を直す
git -C "${TMP}" merge -q origin/base >/dev/null 2>&1
echo merged >"${TMP}/src/main.ts"
git -C "${TMP}" add src/main.ts
git -C "${TMP}" commit -qm "chore: base をマージし src/main.ts の衝突を解消"
git -C "${TMP}" push -q 2>/dev/null
run_mp check-conflicts --base base
check TC031b 0 '"has_conflict": false'
check TC031b2 0 '"merge_state": "checked"'
pass_if TC031b-commit "git -C '${TMP}' log -1 --pretty=%s | grep -q 'chore(merge-prep): check conflicts'"
# notify-issue
run_mp notify-issue                # 本文なし
check TC031c 2 "body-file"
BODY=$(mktemp); echo "完了報告" >"${BODY}"
GH_MOCK_PRBODY="no links" run_mp notify-issue --body-file "${BODY}"   # 通知先なし
check TC031c2 2 "通知先の issue がありません"
run_mp notify-issue --body-file "${BODY}" --issue 7
check TC031d 0 '"merge_state": "notified"'
check TC031d2 0 'issuecomment-77730'
check TC031d3 0 'issuecomment-7777'
pass_if TC031d-log "grep -q '^issue comment 30 ' '${MOCK_LOG}' && grep -q '^issue comment 7 ' '${MOCK_LOG}'"
pass_if TC031d-state "jq -e '.state == \"notified\" and (.notify.issues | map(.number)) == [7,30]' '${MP_STATE_FILE}' >/dev/null"
run_mp notify-issue --body-file "${BODY}"   # 二重投稿は拒否
check TC031e 2 "既に notified"
rm -f "${BODY}"
# ready
: >"${MOCK_LOG}"
run_mp ready --base base
check TC031f 0 '"merge_state": "ready"'
pass_if TC031f-gh "grep -q '^pr ready 13' '${MOCK_LOG}'"
pass_if TC031f-state "jq -e '.state == \"ready\" and .ready.head_sha != null' '${MP_STATE_FILE}' >/dev/null"
pass_if TC031f-commit "git -C '${TMP}' log -1 --pretty=%s | grep -q 'chore(merge-prep): ready'"
run_mp status
check TC031g 0 '"merge_state": "ready"'
run_mp check-conflicts --base base   # ready 後は不可
check TC031h 2 "WF016"
unset GH_MOCK_LOG

echo ""
echo "結果: PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
