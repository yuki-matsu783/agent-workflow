---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-仕様更新.md"]
allowed_paths: ["wip/**"]
---

# フック・設定・テストのパス統一 + .gitkeep

## 目的

チケット駆動フックが参照する `wip/` パスを番号付き命名に統一し、統制を実際に効く状態にする。空ディレクトリを `.gitkeep` で Git に載せる。

## 完了条件（DoD）

- [ ] `.claude/hooks/workflow-types.json` の allow / deny パスと description が新命名になっている
- [ ] `.claude/hooks/workflow-lib.sh` の `WF_DOING_DIR` とフォールバック既定値が新命名になっている
- [ ] `.claude/hooks/workflow-guard.sh`、`.claude/hooks/workflow-diff-check.sh` の `case` パターン・`git show` パス・メッセージ文言が新命名になっている
- [ ] `.claude/skills/ticket-driven-workflow/scripts/test-hooks.sh` の 3 系統（`${TMP}`、`${TMPW}`、Bash コマンド文字列）が新命名になり、全件パスする
- [ ] `wip/10_tickets/{00_todo,10_doing,20_done}/`、`wip/20_plans/`、`wip/30_reports/` に `.gitkeep` がある
- [ ] `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude/hooks` が 0 件
- [ ] このチケット自身の `type` を書き換える Edit が WF008 でブロックされる（統制が生きた証拠）

## 作業内容

1. `workflow-types.json` → `workflow-lib.sh` の順で修正する（統制が生きた瞬間に設定が整合するように）
2. `workflow-guard.sh`、`workflow-diff-check.sh` を修正する
3. `test-hooks.sh` を修正して実行する
4. `.gitkeep` を Write で配置する
5. WF008 の発火を確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
