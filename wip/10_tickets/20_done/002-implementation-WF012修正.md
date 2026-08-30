---
type: ai-asset-implementation
status: todo
depends_on: ["001-investigation-WF012原因調査.md"]
---

# WF012 判定の修正とテストケース追加

## 目的

`wip/20_plans/WF012修正計画.md` に基づき、`workflow-boundary.sh` の WF012 判定を修正し、`test-hooks.sh` にテストケースを追加する。

## 完了条件（DoD）

- [x] `.claude/hooks/workflow-boundary.sh` の WF012 判定が、クォート内文字列を除去した上で判定し、かつクォートで囲まれたパスが実際に `review-state.json` を指す場合は引き続き検出するようになっている
- [x] `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` に issue #29 のケース（引用符内タイトルのみは通過／`rm "wip/10_tickets/review-state.json"` のようにパスをクォートしたケースは引き続き WF012）が TC025 系として追加されている
- [x] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、全件 PASS する
- [x] issue #29 の受け入れ条件3点をすべて満たす

## 作業内容

1. `.claude/hooks/workflow-boundary.sh` に `wf_quoted_targets_state()` を追加し、WF012 判定ロジックを計画どおりに書き換える
2. `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` の TC025b/TC025c 付近に新規ケースを追加する
3. `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、全件 PASS することを確認する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- 計画書どおりの二段判定（sanitized での判定 + wf_quoted_targets_state によるクォート内パス検出）で実装でき、設計と実装のブレがなかった
- 既存の TC025b/TC025c のテストヘルパー（run_boundary / bash_json / check）をそのまま流用でき、TC025d/TC025e の追加が数行で済んだ
- テストスイート全135件が一度で PASS した

### うまくいかなかったこと

- チケットの type を最初 `implementation` にしてしまい、`.claude/hooks/**` への Edit が WF002（保護パス）でブロックされた。doing チケットの type は書き換え不可（WF008）のため、一度 todo に戻して type を `ai-asset-implementation` に修正してから再着手する手戻りが発生した
