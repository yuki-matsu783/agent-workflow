#!/bin/bash
# PreToolUse hook: blocks commands matching forbidden patterns.
# Add new entries to BLOCKED_PATTERNS to extend.

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# 禁止パターン（grep -E）。^ で始まるものも ;/|/& の後も許可。
# 追加する場合はこの配列に "(^|[|;&\n])[[:space:]]*コマンド名[[:space:]]" を追加する
BLOCKED_PATTERNS=(
  "(^|[|;&\n])[[:space:]]*chmod[[:space:]]"
  "(^|[|;&\n])[[:space:]]*/(bin|usr/bin)/chmod[[:space:]]"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$command" | grep -Eq "$pattern"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"},"systemMessage":"🚫 禁止されたコマンドが検出されました。"}'
    exit 2
  fi
done

exit 0
