---
type: ai-asset-implementation
status: todo
depends_on: ["003-ai-asset-implementation-フラットスキルリネーム.md"]
---

# ticket-driven-workflow を work-ticket-driven へ改名し、用語対応とワーク完了チェックポイントを追加

## 目的

`ticket-driven-workflow` を `work-ticket-driven` に `git mv` でリネームし、「チケット＝タスク」の用語対応の明記、ワーク完了チェックポイント節の新設、003 でリネーム済みのスキルへの相互参照更新を行う。

## 完了条件（DoD）

- [x] `ticket-driven-workflow` が `work-ticket-driven` に `git mv` でリネームされ、`SKILL.md` の `name:` が更新されている
- [x] SKILL.md 冒頭に「チケットは3層構造のタスクに相当する」旨の一文が追記されている
- [x] 手順6に「ワーク完了チェックポイント」節が新設され、敵対的レビューエージェントの承認が入る位置・入出力（実装対象外の明記込み）が書かれている
- [x] `references/permission-matrix.md`（変更不要と確認）、`assets/*.template.md`（report テンプレートへのレビュー結果欄追加）が更新されている
- [x] 本文中の `issue-pr-driven-workflow` への言及が `workflow-issue-mr-driven` に、`ai-asset-creator` への言及が `task-ai-asset-creator` に更新されている
- [x] `scripts/test-hooks.sh` が全件パスする（PASS=62 FAIL=0）
- [x] `.claude/hooks/**`・`.claude/rules/**`・`.claude/skills/**` 内に残っていた `ticket-driven-workflow` 言及（003で保留していた分）も更新した

## 作業内容

1. `git mv .claude/skills/ticket-driven-workflow .claude/skills/work-ticket-driven`
2. `SKILL.md` の `name:`・冒頭説明・相互参照を Edit で更新する
3. 手順6にワーク完了チェックポイント節を追加する
4. `references/permission-matrix.md`、`assets/report.template.md` を更新する
5. `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行して確認する

## 作業ログ

### うまくいったこと

- 003で保留していた `ticket-driven-workflow` 言及（workflow-entry.sh、test-workflow-entry.sh、markdown-frontmatter.md、workflow-issue-mr-driven/workflow-light-taskのSKILL.mdとevals.json）を、`.claude/hooks/**`・`.claude/rules/**`・`.claude/skills/**` の範囲内で一括して拾えた
- `references/permission-matrix.md` はそもそもスキル名への言及が無く、変更不要と確認できた

### うまくいかなかったこと

- `.claude/docs/**`（`ワークフロー入口ガード.md`、`issue-PR駆動ワークフロー.md`、`スキル体系.md` など）に残っている `ticket-driven-workflow` 言及は、`ai-asset-implementation` type の `allow_paths` に `.claude/docs/**` が含まれておらず（`ai-asset-design` type専用）、このチケットでは更新できないことが判明した。005（同じく ai-asset-implementation）でも同様に更新できないため、005の前に `ai-asset-design` type の追加チケットを挟む計画変更が必要
