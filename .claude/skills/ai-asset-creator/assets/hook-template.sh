#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# <フック名> — <フックの概要をここに記載>
# ============================================================
# 発火タイミング: <PreToolUse | PostToolUse | Stop | SubagentStop | etc.>
# Matcher: <matcher パターン>
# ============================================================

# ---------- 設定 ----------

# ログ出力先（必要に応じて）
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/<フック名>.log"

# ---------- 前提チェック ----------

# 必要なツールや環境変数の確認
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    echo "Error: CLAUDE_PROJECT_DIR is not set" >&2
    exit 1
fi

# ---------- メイン処理 ----------

main() {
    # ここにフックの処理を記述する
    echo "Running <フック名>..."

    # 例: チェックや処理をここに書く
    # local result
    # result=$(何かのチェック)
    # if [ "$result" = "fail" ]; then
    #     echo "Blocked: reason" >&2
    #     exit 1
    # fi
}

main "$@"
