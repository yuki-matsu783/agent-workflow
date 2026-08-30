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

- [x] `wip/20_plans/` に実装計画書が作成され、対象4関数・2箇所のコメント投稿それぞれについて
      置き換え後の具体的な `gh api` コマンド（エンドポイント・`--jq`・`-f` の指定）が明記されている
- [x] `reviewDecision` 相当を `pulls/{pr}/reviews` から自前で計算する jq ロジックが確定し、計画書に記載されている
- [x] GraphQL フィールド名（`.author.login` 等）と REST フィールド名（`.user.login` 等）の対応表が計画書に記載されている
- [x] `.claude/docs/10_spec/チケット駆動ワークフロー.md` の「ワーク境界の判定とレビュー状態」「マージ前作業の判定と状態」が、上記の REST 呼び出しに書き換わっている
- [x] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` 内の `gh pr comment` / `gh pr view` / `gh api` に関する記述が、実装後の内部実装（すべて REST）と矛盾しない内容に更新されている
- [x] `{branch}` プレースホルダの `gh` 最小バージョンについて、仕様に明記するか許容事項として扱うかの結論が計画書に記載されている

## 作業内容

1. `wip/00_overall_plan/atomic-plotting-crayon.md` の対応表を土台に、`wip/20_plans/` へ実装計画書（`assets/plan.template.md` を Read→Write でコピー）を作成する
2. `reviewDecision` 自前計算の jq ロジックを確定し、`gh` の実コマンドで動作確認する（`echo '<reviews配列>' | jq '...'` 等、ネットワーク不要な範囲で）
3. `.claude/docs/10_spec/チケット駆動ワークフロー.md` の該当箇所を更新する
4. `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` の該当箇所を更新する

## 作業ログ

### うまくいったこと

- `GH_DEBUG=api` を付けてこのセッション自身で `gh pr view` / `gh pr comment` / `gh issue comment` / `gh api "repos/{owner}/{repo}/..."` を実測し、前者3つが GraphQL、後者が REST であること、`{owner}`/`{repo}`/`{branch}` プレースホルダがローカルで解決されることを設計の根拠にできた
- `reviewDecision` 相当の jq ロジックは標準の `group_by` / `max_by` / `any(condition)` の組み合わせで表現でき、`wb_complete()` が実際に使う判定（`CHANGES_REQUESTED` の検知のみ）に対して十分であることを確認した

### うまくいかなかったこと

- `ai-asset-design` の作業タイプは bash_groups が空のため、jq ロジックをこのチケット内で実際に `jq` コマンドへ流して動作確認することができなかった（WF003 でブロックされる）。ロジックの妥当性は手作業でのトレースに留め、実行確認は次の実装チケット（`ai-asset-implementation`。bash_groups に `test` を含む）に委ねた
