---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-design-仕様書と既存仕様の更新.md"]
---

# workflow-types.json に新 type を追加し、フックのテストを通す

## 目的

仕様書に従い `workflow-types.json` に 9 type（`overall-plan`、計画 6、`design`、`design-sync`）を追加し、許可範囲をテストで固定する。

## 完了条件（DoD）

- [x] `.claude/hooks/workflow-types.json` に仕様書どおりの 9 type が追加され、既存 5 type は変更されていない（`git diff` が追加行のみ。TC038）
- [x] `.claude/hooks/tests/test-workflow-guard.sh` に次のケースが追加され、通る: `design` で `docs/**` 許可・`.claude/**` 拒否（WF002）/ `overall-plan` で `wip/00_overall_plan/**` 許可 / 計画 type で `src/**` が未記載（WF009 確認）（TC032a〜TC035c、TC039。PASS=14）
- [x] `bash .claude/hooks/tests/test-workflow-guard.sh` と `bash .claude/hooks/tests/test-workflow-entry.sh` の既存ケースがすべて通る（entry PASS=45）
- [x] `work-boundary.sh status` が計画 type → 実施 type の切り替わりで `at_boundary: true` を返すことを確認した（新設 `tests/test-work-boundary.sh`。TC036 / TC036b / TC037 / TC037b、PASS=13）
- [x] `.claude/skills/work-ticket-driven/references/permission-matrix.md` の標準タイプ表と `assets/ticket.template.md` の type 一覧コメントが更新されている

## 作業内容

1. 仕様書「各 type の allow_paths」を `workflow-types.json` に転記する
2. テストケースを追加し、`bash .claude/hooks/tests/test-workflow-guard.sh` で実行する
3. permission-matrix.md と ticket.template.md を更新する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- type 定義の追加だけで `overall-plan` の global deny 貫通と `design` の `docs/**` 許可が成立した（フック本体の変更なし。TC034a / TC032a で確認）
- `test-workflow-guard.sh` に `edit_json` ヘルパーと `use_real_types`（実物の JSON を読ませる）を足したので、今後 type を追加するときも同じ型でテストを書ける
- `work-boundary.sh status` は git / gh を使わないので、`test-work-boundary.sh` は一時ディレクトリにチケットを置くだけで検証できた。ハイフンを含む type（`ai-asset-design-plan`）でも連番の切り出し（`n%%-*`）は先頭の数字だけを見るので問題なし

### うまくいかなかったこと

- `bash tests/x.sh 2>&1 | tail` はリダイレクト禁止（WF003）で弾かれた。テストはそのまま実行して全出力を見る
- 仕様書の TC 番号（TC032〜）と、テストスクリプト内の ID（TC032a/b のように a/b で分割）が完全一致ではない。テストのコメントに仕様書の節を書いて対応付けた
