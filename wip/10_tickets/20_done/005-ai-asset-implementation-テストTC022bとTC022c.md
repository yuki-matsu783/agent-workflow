---
type: ai-asset-implementation
status: todo
depends_on: ["004-ai-asset-implementation-plan-AIアセット実装計画.md"]
---

# test-workflow-guard.sh に TC022b / TC022c（+ TC022d 案）を追加する

## 目的

実装計画（wip/20_plans/AIアセット実装計画-skill-git-add-paths.md）ステップ 1。仕様書 2.3 の TC022b（`git add wip/` → ask WF009）・TC022c（規約どおりの `git add` → 確認なし）を `.claude/hooks/tests/test-workflow-guard.sh` に追加し、現行フックで通ることを確認する（フック変更不要の裏付け。受け入れ条件④）。

## 完了条件（DoD）

- [x] .claude/hooks/tests/test-workflow-guard.sh に、仕様書「テストケース一覧」の TC022b（`investigation` / `overall-plan` で `git add wip/` → exit 0 + `WF009`）と TC022c（`investigation` で `git mv … && git add wip/10_tickets/ wip/20_plans/調査結果.md && git commit -m x`、`overall-plan` で `git add wip/10_tickets/ wip/00_overall_plan/` → exit 0 かつ出力に `WF009` を含まない）が追加され、既存ケース（TG001〜TC039）とあわせて `bash .claude/hooks/tests/test-workflow-guard.sh` が FAIL=0 で通る（PASS=19 FAIL=0）
- [x] TC022d 案（`investigation` で `git add wip/10_tickets`（末尾スラッシュ無し）→ exit 0 + `WF009`）が「仕様書未記載・現行挙動の固定」とコメントを添えて追加されている
- [x] 「`WF009` を含まない」を検証する手段（`check` の拡張または補助関数）を決めて作業ログに書いてある
- [x] スクリプト冒頭のコメントに、検証対象として仕様書 2.3 の `git add` の対象パスの規約が追記されている
- [x] 参照更新: なし（テストのみ）。フック本体・`workflow-types.json` は変更していない

## 作業内容

1. `test-workflow-guard.sh` の `use_real_types` 以降（TC039 の後）に TC022b / TC022c / TC022d を追加する
2. `bash .claude/hooks/tests/test-workflow-guard.sh` を実行して PASS を確認する
3. 他のテスト（`test-workflow-entry.sh` / `test-work-boundary.sh` / `test-json-syntax.sh`）も回して回帰が無いことを確認する

## 作業ログ

### うまくいったこと

- TC022b-1/2、TC022c-1/2、TC022d を `use_real_types` 以降（TC039 の後）に追加。現行フックのまま全件 PASS（`test-workflow-guard.sh`: PASS=19 FAIL=0）→ フック変更不要の裏付け
- 「`WF009` を含まない」の検証は、既存 `check` を変えずに `check_absent`（exit code 一致 + 文字列不在で PASS）を追加した。既存ケースの挙動に影響しない
- 回帰: `test-workflow-entry.sh` PASS=45、`test-work-boundary.sh` PASS=13、`test-json-syntax.sh` PASS=24、いずれも FAIL=0
- TC022c-1 は done コミットの複合コマンド（`git mv … && git add … && git commit -m x`）をそのまま与え、`commit` セグメントが `QUOTED` 化されて無条件許可になることも同時に確認できた

### うまくいかなかったこと

- TC022d は仕様書未記載のため、振り返りで「設計反映が必要な差分」として棚卸しする
- `scripts/test-hooks.sh`（結合テスト）内に既に `TC022b` という ID（`git add .claude/settings.json` → WF003 の deny ケース、仕様書には無い採番）があり、仕様書 2.3 の TC022b（`git add wip/` → ask）と ID が衝突している。今回は仕様書の採番を正とし `test-workflow-guard.sh` 側を仕様どおりにした。`test-hooks.sh` 側の ID 付け替え（または仕様書への deny ケースの追記）は振り返りの改善提案に残す
