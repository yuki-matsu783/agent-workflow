# 全体計画: git add の wip/10_tickets/ 配下判定を git mv と同様にハードコード許可にする

- 対象 issue: #26 <https://github.com/yuki-matsu783/agent-workflow/issues/26>
- PR: #27 <https://github.com/yuki-matsu783/agent-workflow/pull/27>

## Context

ユーザーからの質問「wip/ticket ディレクトリの git add, mv あたりは多くのタスクで実施するが、allow_list にない場合があるか？」を調査した結果、`.claude/hooks/workflow-guard.sh` の判定経路に構造的な非対称性が見つかった。

- `git mv`（`wf_validate_mv`）: `wip/10_tickets/*` を `case` 文でハードコードして常に許可。`workflow-types.json` を一切参照しない
- `git add`（`wf_validate_add` → `wf_resolve`）: `workflow-types.json` の `global.allow_paths` の**デフォルト値** `["wip/10_tickets/**"]`（`workflow-lib.sh` の `wf_load_config`、`.global.allow_paths // [...]`）経由で許可されている

現状の5作業タイプはいずれも `deny_paths`/`ask_paths` が空のため実害は無いが、`global.allow_paths` の明示的な上書きや、将来追加する作業タイプでの `deny_paths`/`ask_paths` 指定によって `git add wip/10_tickets/...` が許可されなくなり得る。チケット駆動ワークフローの状態管理そのものである `wip/10_tickets/` に対して、セットで使う `git mv` と `git add` の頑健性が異なるのは意図しない不整合であり、ユーザーの意向で `git add` も `git mv` と同じくハードコード判定に揃える。

仕様書 `.claude/docs/10_spec/チケット駆動ワークフロー.md` は現在この非対称性をそのまま仕様として記述している（182・191・219行目: 「`git add` の対象パス判定にも使う」「許可パス内に限る」）ため、実装だけでなく仕様書の修正も必要（`ai-asset-design` → `ai-asset-implementation` の順）。

## チケット分割

| # | type | 内容 |
|---|------|------|
| 001 | ai-asset-design | 仕様書 `.claude/docs/10_spec/チケット駆動ワークフロー.md` を更新し、「`wip/10_tickets/` 配下の `git add` は `git mv` と同様に設定に依存せず常に許可する」設計を明記する |
| 002 | ai-asset-implementation | `wf_validate_add` を `wf_validate_mv` と同じパターンに揃えて実装し、動作確認する |
| 003 | retrospective | 振り返りと結果報告の作成 |

### 001 ai-asset-design（依存: なし）

- 対象箇所:
  - 182行目「`git add` の対象パス判定にも使う」→ セッション記憶は「未記載パス」の場合のみ関係する旨に修正（`wip/10_tickets/**` はハードコード許可のため、この判定に到達しなくなる）
  - 191行目「`git add` の対象パスも同じ判定を適用する」→ `wip/10_tickets/**` を除外する旨を追記
  - 219行目「`git add`（許可パス内に限る）」→ 「`git add`（`wip/10_tickets/` 配下同士は無条件、それ以外は許可パス内に限る）」のように `git mv` と対になる記述に修正
  - パス判定順序表（160-172行目付近）の直後に、「`wip/10_tickets/**` への `git mv`/`git add` はこの判定表を経由せず常に許可される」旨の注記を追加
  - `references/permission-matrix.md`（work-ticket-driven スキル）や TC022 付近のテストケース記述に影響があれば合わせて確認・修正
- DoD: 上記の記述が実装後の挙動と一致する内容になっている。既存の記述（用語・章立て）を壊さない

### 002 ai-asset-implementation（依存: 001）

- 対象ファイル: `.claude/hooks/workflow-guard.sh`
- 実装方針: `wf_validate_add`（166-181行目）の各トークン判定で、`wf_validate_mv`（146-163行目）と同様に `wip/10_tickets/*` に一致するパスは `wf_resolve` を呼ばず即座に allow 扱いにする。共通化できる場合は両関数から使う小さなヘルパー（例: パスが `wip/10_tickets/*` に一致するかを返す関数）を切り出す。`wip/10_tickets/` 以外のパスは既存どおり `wf_resolve` の判定にかける
- 動作確認:
  - 既存 `bash .claude/hooks/tests/test-workflow-entry.sh` が通ること
  - 新規に確認用のケースを用意し、`workflow-types.json` の `global.allow_paths` を空にした状態を模擬しても `git add wip/10_tickets/10_doing/x.md` が allow になることを確認する（既存テストの形式に合わせて `.claude/hooks/tests/` にスクリプトを追加するか、手動確認の手順をチケットの作業ログに残す）
- DoD: `git add wip/10_tickets/**` が設定内容に関わらず常に allow。`wip/10_tickets/` 以外を含む `git add` の挙動は変わらない。既存テストが通る

### 003 retrospective（依存: 002）

- `wip/30_reports/` に結果報告を作成
- 各チケットの作業ログを要約し、うまくいった点・いかなかった点をまとめる
- ワーク完了チェックポイントは自動化未整備のため「レビュー結果: 未実施（今後の自動化対象）」と明記

## 検証方法

- `bash .claude/hooks/tests/test-workflow-entry.sh` が成功する
- 追加したテスト（あれば）が成功する
- 手動確認: doing チケットがある状態で `git add wip/10_tickets/10_doing/<ticket>.md` 相当のコマンドが、`workflow-types.json` の `global.allow_paths` を変更しても常に許可されることを確認する
