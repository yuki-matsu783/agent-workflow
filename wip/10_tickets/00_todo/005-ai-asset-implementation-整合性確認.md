---
type: ai-asset-implementation
status: todo
depends_on: ["004-ai-asset-implementation-チケット駆動分解.md"]
---

# 旧名称の残存確認とテスト全件パスの確認

## 目的

リネーム作業全体を横断的に検査し、旧スキル名の残存・リンク切れが無いこと、既存テストが全件パスすることを確認する。

## 完了条件（DoD）

- [ ] `grep -rn "issue-pr-driven-workflow\|light-task-workflow\|ticket-driven-workflow\|gh-issue\|gh-feature\|gh-install\|ai-asset-creator\|investigating-technologies" .claude CLAUDE.md` の結果、`wip/` 配下の完了済みチケット・ログ以外に旧名称が残っていない
- [ ] `bash .claude/hooks/tests/test-workflow-entry.sh` が全件パスする
- [ ] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件パスする
- [ ] 仕様書間の相互参照リンクが切れていない（ファイルパスの存在確認）

## 作業内容

1. grep で旧名称の残存を確認し、見つかった箇所を修正する
2. 両テストスクリプトを実行する
3. 仕様書内のリンク（`.claude/docs/`、`.claude/skills/` へのパス表記）が実在するか確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
