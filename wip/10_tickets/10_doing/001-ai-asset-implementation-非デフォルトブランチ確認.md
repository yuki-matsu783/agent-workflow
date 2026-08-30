---
type: ai-asset-implementation
status: todo
depends_on: []
---

# light-task-workflow に非デフォルトブランチ確認を追加

## 目的

`light-task-workflow` の手順1（状態確認）に、現在ブランチがデフォルトブランチと異なる場合の
確認フローを追加する（issue #9）。

## 完了条件（DoD）

- [ ] `light-task-workflow/SKILL.md` 手順1に、現在ブランチとデフォルトブランチを取得する手順が明記されている
- [ ] 両者が異なる場合に `AskUserQuestion` で「このまま現在のブランチで実施する / デフォルトブランチに切り替えて実施する / 中断する」を確認するフローが明記されている
- [ ] デフォルトブランチへの切り替えが選ばれた場合、`git checkout` → `git pull` で最新化してから軽作業を継続する手順になっている
- [ ] ヘッドレス実行（`claude -p`、CI）時は確認せず現在のブランチのまま進める旨が明記されている（`.claude/rules/claude-config-headless-awareness.md` 準拠）
- [ ] 既存の手順1の前提（ファイル変更を伴う場合のみ実施）と矛盾しない

## 作業内容

1. `light-task-workflow/SKILL.md` 手順1のコマンド例に `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` を追加する
2. 分岐箇条書きに、現在ブランチ ≠ デフォルトブランチのときの `AskUserQuestion` フローを追加する
3. ヘッドレス実行時の挙動（確認せず現在のブランチのまま進める）を明記する
4. 差分を見直し、他の手順（手順2以降）との整合を確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
