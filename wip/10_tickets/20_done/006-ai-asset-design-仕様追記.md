---
type: ai-asset-design
status: todo
depends_on: ["002-ai-asset-implementation-フック統一.md", "003-ai-asset-implementation-入口継続.md"]
---

# 仕様書への追記（test グループ・doing 配下の非 Markdown・継続ロジックの実装差分）

## 目的

002 / 003 の実装中に追加した挙動を仕様書に反映し、実装と仕様の乖離を無くす。

## 完了条件（DoD）

- [x] `.claude/docs/10_spec/チケット駆動ワークフロー.md` に `bash_groups: "test"`（`TEST_RE`: `.claude/hooks/tests/*.sh` と `.claude/skills/*/scripts/*.sh`、環境変数の前置可）と、ai-asset-implementation への付与が記載されている
- [x] 同仕様書に「doing 配下のチケット判定は `*.md` のみ（`.gitkeep` 等は WF001 の対象外）」が記載されている
- [x] 同仕様書のテストシナリオ表に TC007c / TC019g / TC023〜TC023d が追加され、改訂履歴に 1.6 が追記されている
- [x] `.claude/skills/ticket-driven-workflow/references/permission-matrix.md` との整合を確認した → **不整合あり**（`test` グループ・WF001 の `*.md` 限定が未反映）。`.claude/skills/**` はこのタイプでは触れないため 007（ai-asset-implementation）を追加して対応する

## 作業内容

1. 仕様書の作業タイプ定義表・Bash allowlist・WF001 の記述・テストシナリオ・改訂履歴を Edit する
2. permission-matrix.md を読み、差異があれば振り返りに記録する

## 作業ログ

### うまくいったこと

- 実装（002/003）で増えた挙動を、仕様書の 5 箇所（入力定義の表・標準タイプ表・WF001 の判定・Bash allowlist 表・テストシナリオ）と改訂履歴に一度で反映できた

### うまくいかなかったこと

- 仕様書の改訂履歴に「1.5」が 2 行あった（並行セッションの編集と番号が衝突）。今回は 1.6 として追記したが、並行編集時のバージョン採番ルールが無い
- `permission-matrix.md`（スキル側の要約）は ai-asset-design では触れないため、仕様と要約の同期に別チケットが要る。「設計 → 実装」の順で切ると、実装中に増えた仕様は「設計（仕様書）→ 実装（要約）」をもう 1 周することになり、小さな差分でも 2 チケット必要になる
