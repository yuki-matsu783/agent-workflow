---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-gh-pr-rest化設計.md"]
---

# merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化する実装

## 目的

前チケットの設計どおりに `.claude/hooks/merge-prep.sh` / `.claude/hooks/work-boundary.sh` を書き換え、
`.claude/skills/work-ticket-driven/scripts/test-hooks.sh` のモックとフィクスチャを追従させ、
既存テストが通ることを確認する。

## 完了条件（DoD）

- [ ] `merge-prep.sh` の `mp_pr_number()` / `mp_notify()` が設計どおり `gh api` に置き換わっている
- [ ] `work-boundary.sh` の `wb_pr_number()` / `wb_request()` / `wb_complete()` が設計どおり `gh api` に置き換わっている
- [ ] `wb_complete()` の `reviewDecision` 相当が `pulls/{pr}/reviews` から自前計算され、`CHANGES_REQUESTED` 判定と未返信インラインスレッド判定が既存と同じ挙動をする
- [ ] `test-hooks.sh` の `MOCK_BIN/gh` が新しい `gh api` 呼び出しパターン（`pulls?head=` / `pulls/N/reviews` / `issues/N/comments`）を区別してモックしている
- [ ] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、全件 PASS する（FAIL 0 件）
- [ ] `grep -n "gh pr view\|gh pr comment\|gh issue comment" .claude/hooks/merge-prep.sh .claude/hooks/work-boundary.sh` がヒットしない（GraphQL 経由の呼び出しが残っていない）

## 作業内容

1. `wip/20_plans/` の実装計画に従い `merge-prep.sh` を書き換える
2. `work-boundary.sh` を書き換える
3. `test-hooks.sh` の `MOCK_BIN/gh` パターンとフィクスチャ（`GH_MOCK_PRVIEW` 等）を新しい呼び出しに合わせて更新する
4. `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、FAIL が無いことを確認する（あれば修正して再実行）

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
