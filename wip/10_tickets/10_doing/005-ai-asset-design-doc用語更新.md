---
type: ai-asset-design
status: todo
depends_on: ["004-ai-asset-implementation-チケット駆動分解.md"]
---

# `.claude/docs/**` に残る旧スキル名（ticket-driven-workflow 等）の更新

## 目的

003・004 は `ai-asset-implementation` type（`.claude/hooks/**`・`.claude/rules/**`・`.claude/skills/**` のみ許可）で実施したため、`.claude/docs/**`（`ai-asset-design` type専用）に残る旧スキル名の言及を更新できなかった。本チケットでその残りを解消する。

## 完了条件（DoD）

- [ ] `.claude/docs/10_spec/ワークフロー入口ガード.md`、`.claude/docs/10_spec/issue-PR駆動ワークフロー.md`、`.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`、`.claude/docs/10_spec/スキル体系.md`、`.claude/docs/00_requirements/スキル体系.md` 内の `ticket-driven-workflow` 言及が `work-ticket-driven` に更新されている
- [ ] 同様に `issue-pr-driven-workflow` / `light-task-workflow` / `gh-issue` / `gh-feature` / `gh-install` / `ai-asset-creator` / `investigating-technologies` / `requirements` / `spec` の残存があれば新名称に更新されている
- [ ] `grep -rln "ticket-driven-workflow\|issue-pr-driven-workflow\|light-task-workflow\|gh-issue\|gh-feature\|gh-install\|ai-asset-creator\|investigating-technologies" .claude/docs` の結果が空になる

## 作業内容

1. `.claude/docs/**` 配下を Grep で旧名称の残存を洗い出す
2. 見つかった箇所を Edit で新名称に更新する
3. 更新後に再度 Grep して残存が無いことを確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
