---
type: ai-asset-design
status: todo
depends_on: ["008-investigation-レビュー往復ロジック確認.md"]
---

# 3層仕様書・関連仕様書の改訂（work完了チェックポイントの人間レビュー化）

## 目的

3層仕様（`.claude/docs/10_spec/スキル体系.md`）の「ワーク完了チェックポイント」節と、関連する要件定義書・issue-PR駆動ワークフロー仕様・チケット駆動ワークフロー仕様を、決定済みの設計方針（work完了ごとの人間レビュー、ブランチ命名規約変更）に沿って改訂する。

## 完了条件（DoD）

- [ ] `.claude/docs/10_spec/スキル体系.md`の「ワーク完了チェックポイント」節に、work-ticket-driven固有の運用（workflow-*経由時はワークフロー層と同一発火点、単独時はAskUserQuestion）を追記している。3層定義表の汎用文言（work層＝敵対的レビューエージェント、対象外）は変更していない
- [ ] `.claude/docs/00_requirements/スキル体系.md`のAcceptance Criteriaに、承認者置き換えの要件を追記している
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`の命名規約表・具体例（59, 109, 139, 251行目付近）をハイフン区切り（`<prefix>-<N>-<slug>`）に更新し、承認ポイントに「work単位のレビュー依頼」を追加し、コメント取得コマンド例を追記している
- [ ] `.claude/docs/10_spec/チケット駆動ワークフロー.md`の基本フロー節に、work境界（type完了→呼び出し元へ制御を返す）の説明を追記している
- [ ] 各仕様書の「レビュー記録」表に変更履歴を追記している

## 作業内容

1. `wip/20_plans/008-work完了レビュー往復-実装方針.md`（008の成果物）を読む
2. `.claude/docs/10_spec/スキル体系.md`を改訂する
3. `.claude/docs/00_requirements/スキル体系.md`を改訂する
4. `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`を改訂する（命名規約・承認ポイント・コメント取得コマンド）
5. `.claude/docs/10_spec/チケット駆動ワークフロー.md`を改訂する（work境界の説明）
6. 各ファイルのレビュー記録表に追記する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
