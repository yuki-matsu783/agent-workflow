---
type: ai-asset-design
status: todo
depends_on: []
---

# issue-PR駆動ワークフローの要件定義書・仕様書に振り返りからの切り替え受け口を追加する

## 目的

`workflow-quick-request` 手順 5-3 から切り替えて来たときの引き継ぎ（summary / acceptance / kind / チケット構成）を、`workflow-issue-mr-driven` 側の入力・代替フローとして要件定義書・仕様書に明記する。

## 完了条件（DoD）

- [ ] `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` の「アルタナティブフロー（代替経路）」に、quick-request 手順 5-3 からの切り替え時は summary / acceptance / kind / チケット構成をそのまま用い、依頼の要約に関する曖昧点の質問を省略してよい（未コミットの変更確認は省略しない）旨が追加されている
- [ ] `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` のレビュー記録に版が追加されている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` の「入力（Input）定義」の入力データ表に「振り返りからの引き継ぎ情報」（任意項目）が追加されている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` の「代替フロー」に、振り返りからの切り替え時の扱いが追加されている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` の「テストシナリオ」に切り替えケース（IP015）が追加されている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` のレビュー記録に版が追加されている
- [ ] 引き継ぐ項目名が `.claude/skills/workflow-quick-request/SKILL.md` 手順 5-3 の記述（summary / acceptance / kind / チケット構成）と一致している

## 作業内容

1. `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` を編集する
2. `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` を編集する
3. 両ファイルのレビュー記録に版を追加する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
