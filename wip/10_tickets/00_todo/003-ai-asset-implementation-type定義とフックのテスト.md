---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-design-仕様書と既存仕様の更新.md"]
---

# workflow-types.json に新 type を追加し、フックのテストを通す

## 目的

仕様書に従い `workflow-types.json` に 9 type（`overall-plan`、計画 6、`design`、`design-sync`）を追加し、許可範囲をテストで固定する。

## 完了条件（DoD）

- [ ] `.claude/hooks/workflow-types.json` に仕様書どおりの 9 type が追加され、既存 5 type は変更されていない
- [ ] `.claude/hooks/tests/test-workflow-guard.sh` に次のケースが追加され、通る: `design` で `docs/**` 許可・`.claude/**` 拒否（WF002）/ `overall-plan` で `wip/00_overall_plan/**` 許可 / 計画 type で `src/**` が未記載（WF009 確認）
- [ ] `bash .claude/hooks/tests/test-workflow-guard.sh` と `bash .claude/hooks/tests/test-workflow-entry.sh` の既存ケースがすべて通る
- [ ] `work-boundary.sh status` が計画 type → 実施 type の切り替わりで `at_boundary: true` を返すことを確認した（フィクスチャまたは既存テストの流用）
- [ ] `.claude/skills/work-ticket-driven/references/permission-matrix.md` の標準タイプ表と `assets/ticket.template.md` の type 一覧コメントが更新されている

## 作業内容

1. 仕様書「各 type の allow_paths」を `workflow-types.json` に転記する
2. テストケースを追加し、`bash .claude/hooks/tests/test-workflow-guard.sh` で実行する
3. permission-matrix.md と ticket.template.md を更新する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
