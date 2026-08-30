---
type: ai-asset-implementation
status: todo
depends_on: []
---

# 入口ガードにレビュー待ち継続判定を追加する

## 目的

`.claude/hooks/workflow-entry.sh` の継続判定に、`wip/10_tickets/review-state.json` が
`requested`（かつ `ticket` が `20_done` の最終チケットと一致）の間も継続中とみなす分岐を追加し、
対応するユニットテストを追加する。

## 完了条件（DoD）

- [x] `workflow-entry.sh` に `wf_last_done_ticket` / `wf_review_pending` を追加し、`prompt` / `guard`
      両モードで `wf_tickets_active` に加えて `wf_review_pending` を継続条件として扱う
- [x] `review-state.json` が無い / `state` が `requested` 以外 / `ticket` が最後の done と不一致
      のいずれかなら継続とみなさない
- [x] `.claude/hooks/tests/test-workflow-entry.sh` に以下のケースを追加し、既存分を含め全件 PASS する
  - `requested` かつ `ticket` が一致 → guard 許可、prompt の案内がレビュー待ちである旨を示す
  - `state` が `completed` → WF101
  - `ticket` が最後の done と不一致（失効） → WF101
- [x] `bash .claude/hooks/tests/test-workflow-entry.sh` を実行し、結果を作業ログに記録する

## 作業内容

1. `workflow-entry.sh` に `WF_REVIEW_STATE_REL` 定数と `wf_last_done_ticket` / `wf_review_pending` を追加する
2. `prompt` モードの分岐に `wf_review_pending` のケースを追加し、レビュー待ちの案内文を返す
3. `guard` モードで `wf_tickets_active` の次に `wf_review_pending` を確認し、真なら許可する
4. `test-workflow-entry.sh` の TE014 直後に新規ケース（TE015〜TE017 目安）を追加する
5. テストスクリプトを実行し全件 PASS を確認する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- `work-boundary.sh` の `wb_compute`（`st_ticket == LAST_DONE` のときだけ `review_state` を有効にする規則）をそのまま流用でき、判定ロジックの新規設計は不要だった
- `wf_tickets_active` と同じ「`-e` チェックで無ければ continue」のグロブ書式に揃えたため、コードの読み味が既存部分と一貫している
- `bash .claude/hooks/tests/test-workflow-entry.sh` は PASS=45 FAIL=0（新規 TE015〜TE017 を含め全件 PASS）。既存の `test-workflow-guard.sh` も PASS=4 FAIL=0 で影響なしを確認した

### うまくいかなかったこと

- 特になし
