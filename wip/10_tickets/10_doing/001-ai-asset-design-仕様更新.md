---
type: ai-asset-design
status: todo
depends_on: []
---

# 仕様書の更新（wip 構成の統一 + 入口ガードの継続ルール）

## 目的

全体計画のパス対応表に従い、仕様書・要件定義書の `wip/` 表記を番号付き命名に統一する。あわせて入口ガードの仕様に「未完了チケットがある間は issue-pr-driven-workflow の継続とみなす」ルールを追加する。

## 完了条件（DoD）

- [ ] `.claude/docs/10_spec/チケット駆動ワークフロー.md` のディレクトリ構成ツリー・テンプレート作成先・デフォルト値・エラーメッセージ例・テストシナリオ・前提（`.gitkeep`）が新命名になり、改訂履歴に追記されている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`、`.claude/docs/00_requirements/チケット駆動ワークフロー.md`、`.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` のパス表記が新命名になっている
- [ ] `.claude/docs/10_spec/ワークフロー入口ガード.md` に継続条件（`wip/10_tickets/00_todo/` または `10_doing/` に `*.md` がある → 宣言不要）、処理フロー図の更新、制約の書き換え、TE012〜TE014 のテストシナリオが追加されている
- [ ] `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude/docs` が 0 件

## 作業内容

1. 5 ファイルの `wip/` 参照を対応表で置き換える（Edit）
2. 入口ガード仕様に継続条件・フロー・制約・テストシナリオを追記する
3. grep で残存を確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
