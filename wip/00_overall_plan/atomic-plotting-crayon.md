---
type: plan
title: merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化する
description: gh の GraphQL 自動解決に依存する箇所を gh api（REST + {owner}/{repo}/{branch} プレースホルダ）に置き換える
tags: [workflow-issue-mr-driven, work-ticket-driven, plan]
keywords: [merge-prep, work-boundary, gh api, GraphQL, REST, reviewDecision, agent proxy]
---

- 対象 issue: #44 https://github.com/yuki-matsu783/agent-workflow/issues/44
- PR: #45 https://github.com/yuki-matsu783/agent-workflow/pull/45

## Context

`.claude/hooks/merge-prep.sh` と `.claude/hooks/work-boundary.sh` の GitHub 操作の一部が `gh` の GraphQL API（`gh pr view` / `gh pr comment` / `gh issue comment`）に依存している。プロキシで GraphQL クエリを個別許可制にしている実行環境（agent proxy が「pinned set の PR-review operations のみ許可」を返す環境）では、これらの呼び出しが `HTTP 403` で失敗し、ワーク境界のレビュー依頼・完了判定とマージ前作業が完全に機能停止する（issue #4 対応時に実際に発生し、`--local` での代替運用を余儀なくされた）。

このセッション自身（Claude Code Remote 環境）で検証したところ、`gh pr view` は PR 番号を明示しても `number` 以外のフィールドを含めると GraphQL 経由になり同様に 403 になる一方、`gh api "repos/{owner}/{repo}/..."` 形式の REST 呼び出しは `{owner}`/`{repo}`/`{branch}` プレースホルダをローカルの git 情報から解決してから送信されることを確認した（`gh pr comment` / `gh issue comment` も同じく GraphQL 経由であることを確認済み）。対象4関数・2箇所のコメント投稿をすべて REST 呼び出しに置き換え、GraphQL への依存を無くす。

## 変更方針

設計（`ai-asset-design`）→ 実装（`ai-asset-implementation`）の2ワークで進める。設計ワークで REST 呼び出しの具体的なコマンドと `reviewDecision` 相当の自前計算ロジックを確定し仕様書に反映、実装ワークでフック本体とテストのモックを書き換える。

### 置き換え対象と新しい実装

| 箇所 | 現状（GraphQL） | 変更後（REST） |
|------|-----------------|----------------|
| `mp_pr_number()` / `wb_pr_number()` | `gh pr view --json number -q .number` | `gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open" --jq '.[0].number // empty'` |
| `mp_notify()` の PR 本文取得 | `gh pr view "${PR}" --json body -q .body` | `gh api "repos/{owner}/{repo}/pulls/${PR}" --jq '.body // empty'` |
| `wb_complete()` のレビュー判定・コメント取得 | `gh pr view "${pr}" --json reviewDecision,reviews,comments` | `gh api "repos/{owner}/{repo}/pulls/${pr}/reviews"`（レビュー一覧）+ `gh api "repos/{owner}/{repo}/issues/${pr}/comments"`（会話コメント一覧）。`reviewDecision` は自前で計算（後述） |
| `wb_request()` のレビュー依頼コメント投稿 | `gh pr comment "${pr}" --body-file "${tmp}"` | `gh api "repos/{owner}/{repo}/issues/${pr}/comments" -f body="@${tmp}" --jq '.html_url'` |
| `mp_notify()` の issue コメント投稿 | `gh issue comment "${n}" --body-file "${tmp}"` | `gh api "repos/{owner}/{repo}/issues/${n}/comments" -f body="@${tmp}" --jq '.html_url'` |

`gh api` の `{owner}`/`{repo}`/`{branch}` プレースホルダはローカルの git remote / 現在ブランチから解決され、ネットワークに出ない（このセッションで `GH_DEBUG=api` により実際に解決後の URL を確認済み）。既存の `wb_complete()` のインラインコメント取得（`gh api "repos/{owner}/{repo}/pulls/${pr}/comments"`）と `wb_reply()`（`gh api ".../replies"`）は既に REST のため変更しない。

`-f body="@${tmp}"` は `gh api` の仕様で `@` 始まりの値をファイルから読み込む（既存コードの `--body-file` と等価）。

### `reviewDecision` 相当の自前計算

REST にはブランチ保護込みの `reviewDecision` に相当するフィールドが無いため、`GET .../pulls/{pr}/reviews` の一覧から reviewer ごとの最新レビュー（`COMMENTED` / `PENDING` を除く）を取り、次の順で判定する（GitHub のブランチ保護ルールは考慮しない簡略版であることを仕様書に明記する）:

```
[.[] | select(.state != "COMMENTED" and .state != "PENDING")]
| group_by(.user.login) | map(max_by(.submitted_at))
| if any(.state == "CHANGES_REQUESTED") then "CHANGES_REQUESTED"
  elif any(.state == "APPROVED") then "APPROVED"
  else "" end
```

`wb_complete()` が使うのは `decision == "CHANGES_REQUESTED"` の判定のみなので、この簡略化で既存の合否判定は変わらない。

### フィールド名の対応（REST への移行に伴う変更）

- 会話コメント: `.author.login`→`.user.login`、`.createdAt`→`.created_at`、`.url`→`.html_url`。`comment_ids` は GraphQL の Node ID 文字列から REST の数値 id に変わる（別コメントへの返信 id と同じ体系になり、証跡としての一貫性はむしろ上がる）
- レビュー: `.author.login`→`.user.login`、`.submittedAt`→`.submitted_at`
- 出力 JSON（`new_comments` / `new_reviews` 等）のキー名は現状維持（`author` / `createdAt` / `url` / `submittedAt`）し、値の取得元だけ REST フィールドに変える。呼び出し側（workflow-issue-mr-driven 手順 5-7）が読む JSON の形は変えない

## 変更対象ファイル

| ファイル / パス | 変更内容 |
|----------------|---------|
| `.claude/docs/10_spec/チケット駆動ワークフロー.md` | 「ワーク境界の判定とレビュー状態」「マージ前作業の判定と状態」内の `gh pr view` / `gh pr comment` / `gh issue comment` の記述を上表の REST 呼び出しに更新。`reviewDecision` 自前計算の説明、`comment_ids` の型変更を追記 |
| `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` | 「内部で `gh pr comment` を実行」「内部で `gh pr view` / `gh api`」等の記述を実装に合わせて更新 |
| `.claude/hooks/merge-prep.sh` | `mp_pr_number()`、`mp_notify()` を上表のとおり書き換え |
| `.claude/hooks/work-boundary.sh` | `wb_pr_number()`、`wb_request()`、`wb_complete()` を上表のとおり書き換え |
| `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` | `MOCK_BIN/gh` のパターンマッチを新しい `gh api` 呼び出しに合わせて更新（`pulls?head=` / `pulls/N/reviews` / `issues/N/comments` を区別する）。TC027〜TC028 のフィクスチャ（`GH_MOCK_PRVIEW` 等）を reviews/comments 形式に更新 |

**allowed_paths 案**: 設計チケットは `.claude/hooks/workflow-types.json` の `ai-asset-design`（`.claude/docs/**`）、実装チケットは `ai-asset-implementation`（`.claude/hooks/**` / `.claude/skills/**`）で標準の範囲内に収まる。追加指定は不要。

## 実装ステップ

1. **設計ワーク**（`ai-asset-design`）: 1チケット。上記の対応表・`reviewDecision` 計算式を `wip/20_plans/` に計画書として作成し、`.claude/docs/10_spec/` の2ファイルを更新する
2. **実装ワーク**（`ai-asset-implementation`）: 1チケット。`merge-prep.sh` / `work-boundary.sh` を書き換え、`test-hooks.sh` のモックとフィクスチャを更新し、`bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行して全件 PASS を確認する
3. **振り返りワーク**（`retrospective`）: 1チケット。結果報告を作成し、棚卸し・振り返り・合意を行う

各ワークの完了時にワーク境界チェックポイント（`workflow-issue-mr-driven` 経由のレビュー依頼・完了確認）を経る。

## 検証方法

- `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件 PASS すること（TC024〜TC031 を含む既存スイート）
- 実装後、このセッション内で `gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open"` 等を `GH_DEBUG=api` 付きで実行し、GraphQL エンドポイント（`api.github.com/graphql`）に到達していないこと（REST エンドポイントにのみ到達していること）を目視確認する

## リスク・未解決事項

- `{branch}` プレースホルダは比較的新しい `gh` CLI の機能。最小バージョンを仕様に明記するか、ローカル環境の `gh --version` 依存として許容するかは設計チケットで判断する
- フォーク経由の PR（head が別リポジトリ）は REST の `head=owner:branch` フィルタでは考慮しない。既存の GraphQL 実装もこの点を特別扱いしておらず、扱いは変えない
