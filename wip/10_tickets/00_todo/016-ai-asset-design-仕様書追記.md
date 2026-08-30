---
type: ai-asset-design
status: todo
depends_on: ["015-ai-asset-implementation-review-pending継続判定.md"]
---

# 仕様書にレビュー待ち継続条件を追記する

## 目的

`.claude/docs/10_spec/ワークフロー入口ガード.md` に、015 で実装したレビュー待ち継続判定を反映する。

## 完了条件（DoD）

- [ ] 「入力データ」表に `wip/10_tickets/review-state.json` の行が追加されている
- [ ] 「継続条件」セクションに、`review-state.json` が `requested` かつ `ticket` が `20_done` の
      最終チケットと一致する間も継続中とみなす旨と、`work-boundary.sh` の判定規則と揃えている根拠が
      追記されている
- [ ] 「処理フロー」の ASCII 図にレビュー待ちの分岐が反映されている
- [ ] 「テストシナリオ」表に 015 で追加したテストケースが追記されている

## 作業内容

1. 015 の実装差分（`workflow-entry.sh` / `test-workflow-entry.sh`）を確認する
2. 仕様書の該当セクションを更新する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
