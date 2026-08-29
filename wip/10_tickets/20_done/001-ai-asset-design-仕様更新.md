---
type: ai-asset-design
status: todo
depends_on: []
---

# 仕様書の更新（wip 構成の統一 + 入口ガードの継続ルール）

## 目的

全体計画のパス対応表に従い、仕様書・要件定義書の `wip/` 表記を番号付き命名に統一する。あわせて入口ガードの仕様に「未完了チケットがある間は issue-pr-driven-workflow の継続とみなす」ルールを追加する。

## 完了条件（DoD）

- [x] `.claude/docs/10_spec/チケット駆動ワークフロー.md` のディレクトリ構成ツリー・テンプレート作成先・デフォルト値・エラーメッセージ例・テストシナリオ・前提（`.gitkeep`）が新命名になり、改訂履歴に追記されている
- [x] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`、`.claude/docs/00_requirements/チケット駆動ワークフロー.md`、`.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` のパス表記が新命名になっている
- [x] `.claude/docs/10_spec/ワークフロー入口ガード.md` に継続条件（`wip/10_tickets/00_todo/` または `10_doing/` に `*.md` がある → 宣言不要）、処理フロー図の更新、制約の書き換え、TE012〜TE014 のテストシナリオが追加されている
- [x] `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude/docs` が 0 件

## 作業内容

1. 5 ファイルの `wip/` 参照を対応表で置き換える（Edit）
2. 入口ガード仕様に継続条件・フロー・制約・テストシナリオを追記する
3. grep で残存を確認する

## 作業ログ

### うまくいったこと

- 4 ファイルの `wip/` 参照は sed の置換順（todo/doing/done → ticket/ → plan/ → retrospective/）で一括変換でき、手作業は ASCII ツリー・前提条件・改訂履歴の 3 箇所だけで済んだ
- 入口ガード仕様には「継続条件」を独立した節にし、入力データ表・処理フロー図・制約・テストシナリオ（TE012〜014）を同時に更新した

### うまくいかなかったこと

- `wip/plan へ Write` のように末尾スラッシュが無い表記（TC003 の説明文）は sed のパターンから漏れ、grep で拾って追加修正した。置換パターンは `wip/plan/` だけでなく `wip/plan` 単体も考慮すべきだった
- このチケットの間、フックは旧命名の doing を見ているため素通し。統制が効いていない状態で `.claude/docs/` を編集している（計画どおりだが、002 までは自制頼み）
