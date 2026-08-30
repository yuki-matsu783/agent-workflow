# 全体計画: 入口ガードの継続判定に最後のワークのレビュー待ち状態を加える

- 対象 issue: #28 https://github.com/yuki-matsu783/agent-workflow/issues/28
- PR: #32 https://github.com/yuki-matsu783/agent-workflow/pull/32

## Context

`workflow-entry.sh` の「継続中」判定（`wf_tickets_active`）は、`wip/10_tickets/00_todo/` または
`10_doing/` にチケットがある間だけ継続とみなす。しかし最後のワーク（例: retrospective）が
done になると todo / doing は両方空になる一方、`work-boundary.sh request` → 人間レビュー →
`complete` → PR の ready 化という手順がまだ残っている。この「レビュー待ち」区間で次のプロンプトが
来ると、入口ガードは継続中と判定できず WF101 で振り分けスキルの再宣言を要求してしまう
（#12 のワーク6で実際に発生。issue #28 参照）。

`wip/10_tickets/review-state.json` が `requested`（かつその `ticket` が `20_done` の最終チケットと
一致）の間も継続中とみなすよう `wf_tickets_active` 相当の判定を拡張する。判定規則は
`work-boundary.sh` の `wb_compute`（`REVIEW_STATE` を `st_ticket == LAST_DONE` のときだけ有効にする
規則）と揃える。`work-boundary.sh` / `workflow-guard.sh` 自体は変更しない（issue のスコープ外）。

## 実装方針

### 1. `.claude/hooks/workflow-entry.sh`

- 定数 `WF_REVIEW_STATE_REL="wip/10_tickets/review-state.json"` を追加する
- 関数を2つ追加する（`work-boundary.sh` の `wb_ticket_num` / `wb_compute` の LAST_DONE 算出と同じ規則。ロジックを共有ライブラリ化するほどの重複ではないため、このファイル内に短く実装する）:
  - `wf_last_done_ticket()`: `wip/10_tickets/20_done/*.md` のうちファイル名先頭の連番が最大のものを返す（既存の `wf_tickets_active` と同じ「`-e` チェックで無ければ continue」のグロブ書式に合わせる）
  - `wf_review_pending()`: `review-state.json` が存在し、`.state == "requested"` かつ `.ticket` が `wf_last_done_ticket` と一致すれば 0 を返す
- `prompt` モードの分岐に `elif wf_review_pending; then ...` を追加し、レビュー待ちである旨の `additionalContext`（`[WF-ENTRY]` ログに `continue(review)`）を返す。既存の「チケットあり」分岐とは文言を分ける（「レビュー待ち」と明記し、`complete` の実行を促す）
- `guard` モードで `wf_tickets_active` の次に `wf_review_pending` もチェックし、真なら許可（ログは `CONTINUE(review)`）

### 2. `.claude/hooks/tests/test-workflow-entry.sh`

TE014 の直後（`20_done` が空になった状態）に追加する:

- **review-state.json が `requested` かつ `ticket` が最後の done と一致** → guard 許可、prompt の案内に「レビュー待ち」等の文言が出る
- **`state` が `completed`** → 継続しない（WF101）
- **`ticket` が最後の done と不一致（失効した古い状態）** → 継続しない（WF101）

いずれも `${TICKETS}/20_done/` に 1 件チケットを置き、`${TICKETS}/review-state.json` を直接 Write して検証する（`work-boundary.sh` 自体は呼ばない。フックの入力はファイルシステムの状態のみ）。テスト末尾で作成したファイルを削除して次のブロックに影響しないようにする。

### 3. `.claude/docs/10_spec/ワークフロー入口ガード.md`

- 「入力データ」表に `wip/10_tickets/review-state.json` を行追加
- 「継続条件」セクションに、`review-state.json` が `requested` かつ `ticket` が `20_done` の最終チケットと一致する間も継続中とみなす旨を追記し、`work-boundary.sh` の判定規則と揃えている根拠を書く
- 「処理フロー」の ASCII 図に分岐を追加
- 「テストシナリオ」表に追加したケースを追記

## 完了条件（DoD）

- [ ] 全チケット done かつ `review-state.json` が `requested` の状態で、次のプロンプトの Bash / Edit が WF101 でブロックされない
- [ ] `review-state.json` が `completed` または `none`（失効）で todo / doing が空なら、従来どおり宣言が必要
- [ ] `bash .claude/hooks/tests/test-workflow-entry.sh` が新規ケースを含め全件 PASS
- [ ] 仕様書に継続条件が追記されている

## チケット分割

1. `001-ai-asset-implementation-review-pending継続判定.md`（上記1〜2をまとめて実装。フックとテストは `.claude/hooks/**` 配下のため `ai-asset-implementation` タイプ。フックとテストは対で1チケット）
2. `002-ai-asset-design-仕様書追記.md`（`.claude/docs/` のみを変更するため `ai-asset-design` タイプ）
3. `003-retrospective-振り返り.md`

依存関係: 2 は 1 の変更内容を仕様に反映するため 1 に依存。3 は 1・2 に依存。
