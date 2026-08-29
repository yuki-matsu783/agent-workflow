#!/bin/bash
# タスクログ初期化スクリプト
# 指定したディレクトリにテンプレートをコピーして新しいタスクログを初期化する

set -euo pipefail

LOG_DIR="${1:-task-log}"
DATE="${2:-$(date +%Y-%m-%d)}"
TITLE="${3:-未定義}"

mkdir -p "$LOG_DIR"
OUTPUT_FILE="${LOG_DIR}/${DATE}-${TITLE}.md"

if [ -f "$OUTPUT_FILE" ]; then
  echo "Error: $OUTPUT_FILE already exists" >&2
  exit 1
fi

# テンプレートをコピー
TEMPLATE_PATH="$(dirname "$0")/../assets/task-log-template.md"
cp "$TEMPLATE_PATH" "$OUTPUT_FILE"

echo "Created: $OUTPUT_FILE"
