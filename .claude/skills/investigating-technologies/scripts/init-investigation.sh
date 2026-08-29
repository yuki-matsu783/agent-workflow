#!/bin/bash
# 技術調査レポート初期化スクリプト
# 指定したディレクトリにテンプレートをコピーして新しい技術調査レポートを初期化する

set -euo pipefail

INV_DIR="${1:-investigation}"
DATE="${2:-$(date +%Y-%m-%d)}"
TITLE="${3:-未定義}"

mkdir -p "$INV_DIR"
OUTPUT_FILE="${INV_DIR}/${DATE}-${TITLE}.md"

if [ -f "$OUTPUT_FILE" ]; then
  echo "Error: $OUTPUT_FILE already exists" >&2
  exit 1
fi

# テンプレートをコピー
TEMPLATE_PATH="$(dirname "$0")/../assets/tech-investigation.template.md"
cp "$TEMPLATE_PATH" "$OUTPUT_FILE"

echo "Created: $OUTPUT_FILE"
