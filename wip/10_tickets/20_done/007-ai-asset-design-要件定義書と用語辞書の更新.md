---
type: ai-asset-design
status: todo
depends_on: ["006-ai-asset-design-仕様書へのWF012例外の追記.md"]
---

# 要件定義書と用語辞書の更新

## 目的

`.claude/docs/00_requirements/skill-work-ticket-driven.md`の受け入れ基準にWF012例外を追加し、`.claude/docs/90_glossary/ワークフロー用語.md`の該当節を更新する。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/skill-work-ticket-driven.md`の受け入れ基準に例外条件が追加されている
- [x] `.claude/docs/90_glossary/ワークフロー用語.md`の該当節が更新され、keywordsに`MERGE_HEAD`が追加されている
- [x] レビュー記録の版が追記されている

## 作業内容

1. `task-requirements`スキルの手順に従い、既存の要件定義書の受け入れ基準に「マージ進行中に限りWF012保護ファイルを編集できる」「マージ進行中でない場合は現行どおり常時拒否」を追加する
2. `.claude/docs/90_glossary/ワークフロー用語.md`の「merge-prep.json」節（review-state.jsonを含む記述）にWF012例外の存在を追記し、keywordsに`MERGE_HEAD`を追加する
3. 更新履歴（版）を追記する

## 作業ログ

### うまくいったこと

- 006で仕様書に追記した節見出し（「(a)(b)(f) の例外: マージコンフリクト解消中の直接編集（issue #51）」）をそのまま要件定義書・用語辞書からの参照先として使えたため、文書間の整合が取りやすかった

### うまくいかなかったこと

- 用語辞書には仕様書のようなレビュー記録（版）の節が無く、DoDの「レビュー記録の版が追記されている」は要件定義書側のみで満たす形になった（用語辞書の更新履歴管理は本チケットのスコープ外）
