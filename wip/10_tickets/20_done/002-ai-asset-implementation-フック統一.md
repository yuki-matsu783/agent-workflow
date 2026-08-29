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

- [x] `.claude/hooks/workflow-types.json` の allow / deny パスと description が新命名になっている
- [x] `.claude/hooks/workflow-lib.sh` の `WF_DOING_DIR` とフォールバック既定値が新命名になっている
- [x] `.claude/hooks/workflow-guard.sh`、`.claude/hooks/workflow-diff-check.sh` の `case` パターン・`git show` パス・メッセージ文言が新命名になっている
- [x] `.claude/skills/ticket-driven-workflow/scripts/test-hooks.sh` の 3 系統（`${TMP}`、`${TMPW}`、Bash コマンド文字列）が新命名になり、全件パスする（62 件）
- [x] `wip/10_tickets/{00_todo,10_doing,20_done}/`、`wip/20_plans/`、`wip/30_reports/` に `.gitkeep` がある
- [x] `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude/hooks` が 0 件
- [x] このチケット自身の `type` を書き換える Edit が WF008 でブロックされる（統制が生きた証拠）
- [x] （追加）`bash_groups: ["test"]` により ai-asset-implementation 中にテストスクリプトを実行できる（実地確認済み）
- [x] （追加）doing 配下の非 `.md`（`.gitkeep`）は WF001 の対象外

## 作業内容

1. `workflow-types.json` → `workflow-lib.sh` の順で修正する（統制が生きた瞬間に設定が整合するように）
2. `workflow-guard.sh`、`workflow-diff-check.sh` を修正する
3. `test-hooks.sh` を修正して実行する
4. `.gitkeep` を Write で配置する
5. WF008 の発火を確認する

## 作業ログ

### うまくいったこと

- sed の一括置換（types.json → guard → diff-check → test-hooks → lib の順）と `test-hooks.sh` の実行を 1 つの Bash コマンドにまとめたことで、統制が生きる前に検証まで完了できた（56 件パス）
- `make_ticket` の `$1`（todo/doing/done の論理名）は `ticket_dir()` で実ディレクトリ名に対応付けた
- `.gitkeep` の Write が WF001 でブロックされ、統制が効き始めたことを実地で確認できた

### うまくいかなかったこと

- `check_ticket_edit` が doing 配下の全ファイルをチケット扱いするため `.gitkeep` が WF001 になった → `*.md` のみを対象に修正（TC019g を追加）
- **ai-asset-implementation の `bash_groups` が空のため、統制が生きた後はテストスクリプト（`bash …/test-hooks.sh`）を実行できない（WF003）**。002 は運良く同一コマンド内で済んだが、003 の反復には致命的 → ユーザー承認のうえ `bash_groups: ["test"]` を追加（`TEST_RE`: `.claude/hooks/tests/*.sh` と `.claude/skills/*/scripts/*.sh` のみ、環境変数の前置可）。TC007c / TC023〜d を追加し 62 件パス。仕様書への反映は 003 完了後に行う
- 統制下では `cd "…" &&` の前置と `2>&1` が WF003 になる。Bash はリポジトリ相対・リダイレクト無しで書く必要がある（スキルの手順 4 に書いてあるが、統制が生きていない間の癖が残っていた）
- `join("")` のように制御文字を含む行は Edit の old_string に載せられない。隣接する行だけを対象にして回避した
