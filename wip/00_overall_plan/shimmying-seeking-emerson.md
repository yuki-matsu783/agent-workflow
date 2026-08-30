# 全体計画: gh CLI が使えない実行環境でも work-boundary.sh / merge-prep.sh が動作するようにする

- 対象 issue: #41 https://github.com/yuki-matsu783/agent-workflow/issues/41
- PR: #46 https://github.com/yuki-matsu783/agent-workflow/pull/46

## Context

`work-boundary.sh`（ワーク境界のレビュー往復）と `merge-prep.sh`（完了処理のマージ前作業）は、いずれも内部で `gh` CLI（`gh pr view` / `gh pr comment` / `gh api .../comments` / `gh issue comment` / `gh pr ready`）を直接呼び出している。gh CLI が使えない実行環境（本セッションの環境、GitHub 操作が MCP サーバー経由に限定される環境）では、`work-boundary.sh` の非local実行が WF013 で、`merge-prep.sh` は**全サブコマンド**（`mp_compute` が `gh pr view` で PR 番号を取得するため reset-wip・check-conflicts も含む）が WF016 で失敗する。

issue #3 の完了処理で、この問題を `work-boundary.sh --local` + MCP ツールでの手動コメント投稿、`merge-prep.sh` は手作業（`git rm` での reset-wip 相当、`git merge-tree` での衝突確認、MCP での issue コメント、MCP `update_pull_request(draft:false)` での ready 化）で代替した。この場当たり対応を、スクリプト自身が持つ恒久的なフォールバック経路として仕様化・実装する。

設計方針: gh 不在時に「LLM が MCP ツール等で実際に GitHub 操作を行い、その結果（PR 番号・コメント URL・レビュー判定など）をフラグでスクリプトに渡し、スクリプトは前提条件のチェックと状態ファイルへの記録に専念する」。スクリプト自身が GitHub に問い合わせて真偽を確認する現在の強度（LLM の自己申告では状態が進まない）は、gh 不在時には維持できない（issue #41 の論点どおり）。この強度低下を隠さず、仕様書に明記し、`state.via: "gh" | "external"` として記録に残す。

## チケット構成

### 001-ai-asset-design-gh-CLI不在時のフォールバック仕様（type: ai-asset-design, allowed: `.claude/docs/**`）

- `.claude/docs/00_requirements/チケット駆動ワークフロー.md`: 受け入れ基準に、gh 不在時のフォールバック（`--pr`/`--external` 系フラグでの代替）と、証跡強度低下の明記を追加
- `.claude/docs/10_spec/チケット駆動ワークフロー.md`「ワーク境界の判定とレビュー状態」「マージ前作業の判定と状態」に、以下を追記:
  - 両スクリプト共通: `gh` の有無を `command -v gh` で検出するヘルパー、有る場合は現状どおり自動実行
  - `--pr <N>`: `gh pr view` の代わりに PR 番号を明示指定（両スクリプトの全サブコマンドで有効）
  - `work-boundary.sh request/complete`: gh 不在時、`--external` を付けて `--comment-url <url>`（request）/ `--review-decision <value> --comment-ids <json> --inline-ids <json>`（complete）を渡すことで、MCP ツール等で取得済みの実データを記録できるようにする。既存の `CHANGES_REQUESTED` 拒否・未返信スレッド検知のロジックは `--external` でも同様に適用する
  - `merge-prep.sh notify-issue`: gh 不在時、`--pr-body-file <path>`（PR 本文を渡して Closes #N をローカルで抽出）と `--posted "N:url"`（MCP で投稿済みのコメント URL）を受け付ける
  - `merge-prep.sh ready`: gh 不在時、`--external` を付けると `gh pr ready` を呼ばず、他の前提条件（wip_clean・push済み・衝突なし）の検証のみ行って `state: ready` を記録する（実際の draft 解除は呼び出し元が MCP `update_pull_request(draft:false)` で事前に行っている前提）
  - 状態ファイル（`review-state.json`/`merge-prep.json`）に `via: "gh" | "external"` を追加し、証跡の強度差を記録上も区別する
  - 「既存の gh CLI が使える環境での動作に影響しない」ことを明記（デフォルトは現状どおり gh 自動呼び出し。新フラグは gh 不在時のみ必須）

### 002-ai-asset-implementation-gh-CLI不在時のフォールバック実装（type: ai-asset-implementation, allowed: `.claude/skills/**`, `.claude/hooks/**`, depends_on: 001）

- `.claude/hooks/work-boundary.sh`:
  - `wb_gh_available()` を追加。`wb_pr_number()` は gh があれば現状どおり、無ければ空を返す
  - `wb_request`: `--pr <N>` オプションを追加。gh 不在時は `--local` か（`--external --pr <N> --comment-url <url>`）のいずれかを要求。`--external` のときは `gh pr comment` を呼ばず、渡された値を `request.comment_id`/`url` に記録し `local: false, via: "external"` とする
  - `wb_complete`: gh 不在時は `--external --review-decision <value> [--comment-ids <json>] [--inline-ids <json>]` を受け付け、`gh pr view`/`gh api` を呼ばずに渡された値で `CHANGES_REQUESTED` 拒否・未返信スレッド検知（`--inline-ids` の形が返信有無を含む場合のみ）を行う
  - `wb_reply`: gh 不在時はスクリプトでは対応せず、使い方メッセージに「MCP ツール等で直接返信してください（本コマンドは状態を変更しないため必須ではない）」と明記して案内する
- `.claude/hooks/merge-prep.sh`:
  - `mp_gh_available()` を追加。全サブコマンドに `--pr <N>` オプションを追加し、`mp_pr_number()` の代わりに使えるようにする（`reset-wip`/`check-conflicts` はこれだけで gh 不在でも動作する）
  - `mp_notify`: `--pr-body-file <path>`（Closes #N 抽出に使用）と `--posted "N:url"`（複数可）を追加。gh 不在時はこれらを必須にし、`gh pr view`/`gh issue comment` を呼ばない
  - `mp_ready`: `--external` を追加。指定時は `gh pr ready` を呼ばず、他の前提検証後に直接 `state: ready` を記録する
  - 状態ファイルの `state` オブジェクトに `via` フィールドを追加（両スクリプト共通）
- `.claude/skills/work-ticket-driven/SKILL.md`・`.claude/skills/workflow-issue-mr-driven/SKILL.md`: gh 不在時のフラグの使い方（何を MCP で取得し、何をスクリプトに渡すか）をエラーハンドリング表に追記
- `.claude/hooks/tests/` に gh 不在フォールバックの新規テストケースを追加（`ai-asset-implementation` の `bash_groups: ["test"]` で実行可能）

### 003-retrospective-振り返り（type: retrospective, allowed: `wip/30_reports/**`, depends_on: 002）

- 拡張済みの棚卸しフォーマットで本ワークフロー自身の結果報告を作成する

## 検証

- 各サブコマンドを gh モック無し（`PATH` から `gh` を外した状態）で実行し、新フラグを使った代替経路が期待どおり動作すること、フラグ無しでは明確なエラーメッセージ（何を渡す必要があるか）が出ることを確認する
- 既存の gh 前提のテストケース（TC024〜TC031 等）が変更後も同じ結果になること（回帰無し）を確認する
- `.claude/docs/10_spec/チケット駆動ワークフロー.md` のエラーコード表・状態遷移図が新フラグ・`via` フィールドと整合していることを確認する
