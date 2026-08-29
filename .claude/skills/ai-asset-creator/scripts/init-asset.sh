#!/usr/bin/env bash
# init-asset.sh — アセットタイプに応じてテンプレートをコピーして新規アセットを初期化する
#
# 使い方:
#   init-asset.sh <rule|hook|agent> <アセット名> [--user]
#   --user は agent のみ有効。~/.claude/agents/ に作成する（既定はプロジェクトの .claude/agents/）

set -euo pipefail

ASSET_TYPE="${1:?アセットの種類を指定してください (rule/hook/agent)}"
ASSET_NAME="${2:?アセット名を指定してください}"
SCOPE="${3:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TEMPLATE_DIR="${PROJECT_DIR}/.claude/skills/ai-asset-creator/assets"

# agent の name は小文字とハイフンのみ（Claude Code の制約）
validate_agent_name() {
    if ! [[ "${ASSET_NAME}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        echo "Error: agent 名は小文字英数字とハイフンのみ使用できます: '${ASSET_NAME}'" >&2
        exit 1
    fi
}

NEEDS_EXEC=false

case "${ASSET_TYPE}" in
    rule)
        TARGET_DIR="${PROJECT_DIR}/.claude/rules"
        TEMPLATE="${TEMPLATE_DIR}/rule-template.md"
        EXT="md"
        ;;
    hook)
        TARGET_DIR="${PROJECT_DIR}/.claude/hooks"
        TEMPLATE="${TEMPLATE_DIR}/hook-template.sh"
        EXT="sh"
        NEEDS_EXEC=true
        ;;
    agent)
        validate_agent_name
        if [ "${SCOPE}" = "--user" ]; then
            TARGET_DIR="${HOME}/.claude/agents"
        else
            TARGET_DIR="${PROJECT_DIR}/.claude/agents"
        fi
        TEMPLATE="${TEMPLATE_DIR}/agent-template.md"
        EXT="md"
        ;;
    skill)
        echo "Error: skill の作成は skill-creator を活用してください。" >&2
        echo "  $ ai-asset-creator で '○○というスキルを作って' と聞いてください。" >&2
        exit 1
        ;;
    *)
        echo "Error: 不正なアセット種類 '${ASSET_TYPE}'。" >&2
        echo "  指定可能な種類: rule, hook, agent" >&2
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

# 実行権限が必要なのはシェルスクリプト（hook）のみ
if [ "${NEEDS_EXEC}" = true ]; then
    chmod +x "${OUTPUT_FILE}"
fi

# agent はファイル名と frontmatter の name を一致させる必要があるので先に埋める
if [ "${ASSET_TYPE}" = "agent" ]; then
    sed -i "s/^name: <エージェント名（小文字とハイフンのみ）>$/name: ${ASSET_NAME}/" "${OUTPUT_FILE}"
fi

echo "Created: ${OUTPUT_FILE}"
echo ""
echo "次の手順:"
echo "  1. ${OUTPUT_FILE} を開いて内容を編集する"
case "${ASSET_TYPE}" in
    hook)  echo "  2. .claude/settings.json にフック設定を追加する" ;;
    rule)  echo "  2. 必要に応じて .claude/rules/ 内の他ルールと整合を取る" ;;
    agent)
        echo "  2. description に「何をするか」と「いつ委任するか」を書き、tools を必要最小限に絞る"
        echo "  3. 使わないオプションのコメント行を削除し、<...> が残っていないか確認する"
        echo "  4. /agents で認識されているか確認する（同一セッション内なら再起動が必要な場合がある）"
        ;;
esac
