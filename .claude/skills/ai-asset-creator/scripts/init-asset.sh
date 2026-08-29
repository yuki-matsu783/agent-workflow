#!/usr/bin/env bash
# init-asset.sh — アセットタイプに応じてテンプレートをコピーして新規アセットを初期化する

set -euo pipefail

ASSET_TYPE="${1:?アセットの種類を指定してください (skill/rule/hook):}"
ASSET_NAME="${2:?アセット名を指定してください}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

case "${ASSET_TYPE}" in
    rule)
        TARGET_DIR="${PROJECT_DIR}/.claude/rules"
        TEMPLATE="${PROJECT_DIR}/.claude/skills/ai-asset-creator/assets/rule-template.md"
        EXT="md"
        ;;
    hook)
        TARGET_DIR="${PROJECT_DIR}/.claude/hooks"
        TEMPLATE="${PROJECT_DIR}/.claude/skills/ai-asset-creator/assets/hook-template.sh"
        EXT="sh"
        ;;
    skill)
        echo "Error: skill の作成は skill-creator を活用してください。" >&2
        echo "  $ ai-asset-creator で '○○というスキルを作って' と聞いてください。" >&2
        exit 1
        ;;
    *)
        echo "Error: 不正なアセット種類 '${ASSET_TYPE}'。" >&2
        echo "  指定可能な種類: rule, hook" >&2
        exit 1
        ;;
esac

mkdir -p "${TARGET_DIR}"

OUTPUT_FILE="${TARGET_DIR}/${ASSET_NAME}.${EXT}"

if [ -f "${OUTPUT_FILE}" ]; then
    echo "Error: ${OUTPUT_FILE} already exists" >&2
    exit 1
fi

if [ ! -f "${TEMPLATE}" ]; then
    echo "Error: Template not found: ${TEMPLATE}" >&2
    exit 1
fi

cp "${TEMPLATE}" "${OUTPUT_FILE}"
chmod +x "${OUTPUT_FILE}"

echo "Created: ${OUTPUT_FILE}"
echo ""
echo "次の手順:"
echo "  1. ${OUTPUT_FILE} を開いて内容を編集する"
echo "  2. $(if [ "${ASSET_TYPE}" = "hook" ]; then echo '.claude/settings.json にフック設定を追加する'; else echo '必要に応じて .claude/rules/ に追加する'; fi)"
