---
type: ai-asset-implementation
status: todo
depends_on: ["004-ai-asset-implementation-plan-AIアセット実装計画.md"]
---

# test-workflow-guard.sh に TC022b / TC022c（+ TC022d 案）を追加する

## 目的

実装計画（wip/20_plans/AIアセット実装計画-skill-git-add-paths.md）ステップ 1。仕様書 2.3 の TC022b（`git add wip/` → ask WF009）・TC022c（規約どおりの `git add` → 確認なし）を `.claude/hooks/tests/test-workflow-guard.sh` に追加し、現行フックで通ることを確認する（フック変更不要の裏付け。受け入れ条件④）。

## 完了条件（DoD）

- [ ] .claude/hooks/tests/test-workflow-guard.sh に、仕様書「テストケース一覧」の TC022b（`investigation` / `overall-plan` で `git add wip/` → exit 0 + `WF009`）と TC022c（`investigation` で `git mv … && git add wip/10_tickets/ wip/20_plans/調査結果.md && git commit -m x`、`overall-plan` で `git add wip/10_tickets/ wip/00_overall_plan/` → exit 0 かつ出力に `WF009` を含まない）が追加され、既存ケース（TG001〜TC039）とあわせて `bash .claude/hooks/tests/test-workflow-guard.sh` が FAIL=0 で通る
- [ ] TC022d 案（`investigation` で `git add wip/10_tickets`（末尾スラッシュ無し）→ exit 0 + `WF009`）が「仕様書未記載・現行挙動の固定」とコメントを添えて追加されている
- [ ] 「`WF009` を含まない」を検証する手段（`check` の拡張または補助関数）を決めて作業ログに書いてある
- [ ] スクリプト冒頭のコメントに、検証対象として仕様書 2.3 の `git add` の対象パスの規約が追記されている
- [ ] 参照更新: なし（テストのみ）。フック本体・`workflow-types.json` は変更していない

## 作業内容

1. `test-workflow-guard.sh` の `use_real_types` 以降（TC039 の後）に TC022b / TC022c / TC022d を追加する
2. `bash .claude/hooks/tests/test-workflow-guard.sh` を実行して PASS を確認する
3. 他のテスト（`test-workflow-entry.sh` / `test-work-boundary.sh` / `test-json-syntax.sh`）も回して回帰が無いことを確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
