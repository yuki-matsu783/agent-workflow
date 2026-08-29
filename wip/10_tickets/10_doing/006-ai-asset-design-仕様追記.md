---
type: ai-asset-design
status: todo
depends_on: ["002-ai-asset-implementation-フック統一.md", "003-ai-asset-implementation-入口継続.md"]
---

# 仕様書への追記（test グループ・doing 配下の非 Markdown・継続ロジックの実装差分）

## 目的

002 / 003 の実装中に追加した挙動を仕様書に反映し、実装と仕様の乖離を無くす。

## 完了条件（DoD）

- [ ] `.claude/docs/10_spec/チケット駆動ワークフロー.md` に `bash_groups: "test"`（`TEST_RE`: `.claude/hooks/tests/*.sh` と `.claude/skills/*/scripts/*.sh`、環境変数の前置可）と、ai-asset-implementation への付与が記載されている
- [ ] 同仕様書に「doing 配下のチケット判定は `*.md` のみ（`.gitkeep` 等は WF001 の対象外）」が記載されている
- [ ] 同仕様書のテストシナリオ表に TC007c / TC019g / TC023〜TC023d が追加され、改訂履歴に 1.6 が追記されている
- [ ] `.claude/skills/ticket-driven-workflow/references/permission-matrix.md` との整合が取れている（参照のみ。修正が必要なら振り返りで報告）

## 作業内容

1. 仕様書の作業タイプ定義表・Bash allowlist・WF001 の記述・テストシナリオ・改訂履歴を Edit する
2. permission-matrix.md を読み、差異があれば振り返りに記録する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
