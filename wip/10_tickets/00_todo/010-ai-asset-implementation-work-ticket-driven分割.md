---
type: ai-asset-implementation
status: todo
depends_on: ["009-ai-asset-design-スキル体系仕様改訂.md"]
---

# work-ticket-driven のワーク境界分割実装

## 目的

`work-ticket-driven` を、チケットtype単位の「ワーク境界」で呼び出し元に制御を返す構造に改修する。手順5と手順6の間に境界判定を新設し、手順6を「呼び出し元がある場合は報告して制御を返す／単独時はAskUserQuestionで完結」に改稿する。

## 完了条件（DoD）

- [ ] `work-ticket-driven/SKILL.md`に手順5.5「ワーク境界の判定」が新設され、done直後のtypeとtodo先頭のtypeを比較するロジックが手順として明記されている
- [ ] 手順6が改稿され、workflow-issue-mr-driven等の呼び出し元がある場合は完了報告のみ行い制御を返す、単独時はAskUserQuestionでチェックポイントを完結させる、の分岐が明記されている
- [ ] 手順0（状態確認）に、type境界での再開（doingが空でtodoに次typeが残っている状態からの再開）が追記されている
- [ ] レビュー指摘対応時は「同typeの新規チケットをtodoに追加する」方針が明記されている
- [ ] `work-ticket-driven/assets/report.template.md`の「レビュー結果」欄の説明が、type単位の人間レビュー結果一覧を書く形に更新されている
- [ ] `work-ticket-driven/evals/evals.json`に、type完了時に制御を返して停止する新規ケースが追加されている
- [ ] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が無改修のまま全件パスする

## 作業内容

1. `wip/20_plans/008-work完了レビュー往復-実装方針.md`と009の改訂済み仕様書を読む
2. `work-ticket-driven/SKILL.md`を改訂する（手順0・手順5.5新設・手順6改稿）
3. `work-ticket-driven/assets/report.template.md`を更新する
4. `work-ticket-driven/evals/evals.json`に新規ケースを追加する
5. `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh`を実行し、既存フックが無改修で通ることを確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
