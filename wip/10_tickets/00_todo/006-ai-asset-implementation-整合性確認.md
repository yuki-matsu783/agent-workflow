---
type: ai-asset-implementation
status: todo
depends_on: ["005-ai-asset-design-doc用語更新.md"]
---

# 旧名称の残存確認とテスト全件パスの確認

## 目的

リネーム作業全体を横断的に検査し、旧スキル名の残存・リンク切れが無いこと、既存テストが全件パスすることを確認する（005 で `.claude/docs/**` 内の残存は解消済みの想定。本チケットは `.claude/hooks/**`・`.claude/rules/**`・`.claude/skills/**` の範囲を担当）。

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
