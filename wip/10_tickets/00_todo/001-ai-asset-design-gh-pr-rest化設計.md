---
type: ai-asset-design
status: todo
depends_on: []
---

# merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化する設計

## 目的

`gh pr view`（GraphQL 自動解決）/ `gh pr comment` / `gh issue comment` に依存している箇所を
`gh api`（REST + `{owner}`/`{repo}`/`{branch}` プレースホルダ）に置き換える具体的な仕様を確定し、
`.claude/docs/10_spec/` に反映する。実装（次チケット）はこの設計をそのまま実装する。

## 完了条件（DoD）

- [ ] `wip/20_plans/` に実装計画書が作成され、対象4関数・2箇所のコメント投稿それぞれについて
      置き換え後の具体的な `gh api` コマンド（エンドポイント・`--jq`・`-f` の指定）が明記されている
- [ ] `reviewDecision` 相当を `pulls/{pr}/reviews` から自前で計算する jq ロジックが確定し、計画書に記載されている
- [ ] GraphQL フィールド名（`.author.login` 等）と REST フィールド名（`.user.login` 等）の対応表が計画書に記載されている
- [ ] `.claude/docs/10_spec/チケット駆動ワークフロー.md` の「ワーク境界の判定とレビュー状態」「マージ前作業の判定と状態」が、上記の REST 呼び出しに書き換わっている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` 内の `gh pr comment` / `gh pr view` / `gh api` に関する記述が、実装後の内部実装（すべて REST）と矛盾しない内容に更新されている
- [ ] `{branch}` プレースホルダの `gh` 最小バージョンについて、仕様に明記するか許容事項として扱うかの結論が計画書に記載されている

## 作業内容

1. `wip/00_overall_plan/atomic-plotting-crayon.md` の対応表を土台に、`wip/20_plans/` へ実装計画書（`assets/plan.template.md` を Read→Write でコピー）を作成する
2. `reviewDecision` 自前計算の jq ロジックを確定し、`gh` の実コマンドで動作確認する（`echo '<reviews配列>' | jq '...'` 等、ネットワーク不要な範囲で）
3. `.claude/docs/10_spec/チケット駆動ワークフロー.md` の該当箇所を更新する
4. `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` の該当箇所を更新する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
