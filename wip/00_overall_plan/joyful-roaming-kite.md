# 全体計画: 入口ガードの状態ベース継続と wip ディレクトリ構成の統一

- 対象 issue: #1 https://github.com/yuki-matsu783/agent-workflow/issues/1
- PR: #2 https://github.com/yuki-matsu783/agent-workflow/pull/2
- ブランチ: `feature/1-entry-guard-continuation`

## Context

- 入口ガード `workflow-entry.sh` はプロンプトごとに入口スキルの再宣言を求める。進行中の issue-pr 作業ではフォローアップ（「はい」「続けて」）のたびに WF101 になり過剰。**チケットの有無で継続を機械的に判定する**（案 C）ことで合意済み
- 調査で判明した付随問題: `wip/` の実ディレクトリ（`10_tickets/{00_todo,10_doing,20_done}`, `20_plans`, `30_reports`）はローカルにだけ存在する空ディレクトリで、フック・仕様・スキルはすべて旧命名（`ticket/{todo,doing,done}`, `plan`, `retrospective`）を参照している。`wip/ticket/doing` が無いため**チケット駆動フックは現在すべて素通し**になっている
- ユーザー決定: **番号付き命名に統一**し、空ディレクトリは **`.gitkeep` で Git に載せる**

### パス対応表（この計画の正）

| 旧（参照側） | 新（統一後） |
|---|---|
| `wip/ticket/todo` | `wip/10_tickets/00_todo` |
| `wip/ticket/doing` | `wip/10_tickets/10_doing` |
| `wip/ticket/done` | `wip/10_tickets/20_done` |
| `wip/ticket/**` | `wip/10_tickets/**` |
| `wip/plan` | `wip/20_plans` |
| `wip/retrospective` | `wip/30_reports` |
| `wip/00_overall_plan` | 変更なし |

## 進め方（チケット分割）

チケットは最初から新命名 `wip/10_tickets/00_todo/` に作る。**001〜002 の間はフックが素通し**（旧命名の doing を見ているため。現状と同じ）で、002 で `workflow-lib.sh` を直した時点から新命名で統制が効き始める。002 の中では `workflow-types.json` → `workflow-lib.sh` の順で直す（統制が生きた瞬間に設定が整合しているように）。

| # | type | 成果物 | depends_on |
|---|------|--------|-----------|
| 001 | `ai-asset-design` | 仕様書の更新（構成統一 + 継続ルール） | — |
| 002 | `ai-asset-implementation` | フック・設定・テストのパス統一 + `.gitkeep` | 001 |
| 003 | `ai-asset-implementation` | 入口ガードの継続ロジック + テスト + CLAUDE.md | 002 |
| 004 | `ai-asset-implementation` | スキル・テンプレート・evals・ルールの文言統一 | 002 |
| 005 | `retrospective` | 結果報告 | 003, 004 |

### 001 ai-asset-design: 仕様書の更新

- `.claude/docs/10_spec/チケット駆動ワークフロー.md`: ディレクトリ構成ツリー（280 行付近）、テンプレート作成先の表、`global.allow_paths` 等のデフォルト値、エラーメッセージ例、テストシナリオ、前提（`.gitkeep` で空ディレクトリを保持）を新命名に。改訂履歴に追記
- `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`、`.claude/docs/00_requirements/チケット駆動ワークフロー.md`、`.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`: パス表記を新命名に
- `.claude/docs/10_spec/ワークフロー入口ガード.md`: 「状態ファイル」の宣言済み定義に**継続条件**を追加（`wip/10_tickets/00_todo/` または `10_doing/` に `*.md` がある → `issue-pr-driven-workflow` 継続中とみなし宣言不要）。処理フロー図・制約（113 行目「フォローアップでも宣言が必要」を書き換え）・テストシナリオ表に TE012/TE013 を追加
- DoD: 上記 5 ファイルに旧命名が残っていない（`grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude/docs` が 0 件）。継続条件が仕様として明記されている

### 002 ai-asset-implementation: フック・設定・テストのパス統一 + .gitkeep

frontmatter: `allowed_paths: ["wip/**"]`（`.gitkeep` 配置用。`wip/00_overall_plan` は global deny のままで、この計画ファイルがあるので不要）

- `.claude/hooks/workflow-types.json`: `global.allow_paths` → `wip/10_tickets/**`、`deny_paths` の `wip/00_overall_plan/**` はそのまま、各 type の `wip/plan/**` → `wip/20_plans/**`、`wip/retrospective/**` → `wip/30_reports/**`、description の文言
- `.claude/hooks/workflow-lib.sh`: `:168` `WF_DOING_DIR` → `wip/10_tickets/10_doing`、`:150` フォールバック → `wip/10_tickets/**`
- `.claude/hooks/workflow-guard.sh`（16 箇所）: `case` パターン（`:75`, `:90`, `:149`, `:252`, `:256`）とメッセージ文言
- `.claude/hooks/workflow-diff-check.sh`: `:72`（そのまま）, `:91` `git show HEAD:wip/10_tickets/10_doing/…`, `:108` done の参照, `:96`/`:113` 文言
- `.claude/skills/ticket-driven-workflow/scripts/test-hooks.sh`: 3 系統すべて（`${TMP}/wip/…`、`${TMPW}/wip/…`、Bash コマンド文字列内の相対パス）。`setup_repo` の `mkdir -p` も新命名に
- `.gitkeep`: `wip/10_tickets/{00_todo,10_doing,20_done}/`, `wip/20_plans/`, `wip/30_reports/`。旧命名ディレクトリは作らない
- DoD: `bash .claude/skills/ticket-driven-workflow/scripts/test-hooks.sh` が全件パス。`grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude/hooks` が 0 件。002 の doing チケット自身に対して WF008（type 書き換え禁止）が実際に発火することを Edit で確認（= 統制が生きた証拠）

### 003 ai-asset-implementation: 入口ガードの継続ロジック + テスト + CLAUDE.md

frontmatter: `allowed_paths: ["CLAUDE.md"]`

- `.claude/hooks/workflow-entry.sh`:
  - 定数 `WF_TICKET_ACTIVE_DIRS=("wip/10_tickets/00_todo" "wip/10_tickets/10_doing")` を追加
  - `wf_tickets_active()`: いずれかのディレクトリに `*.md` があれば 0（`nullglob` の扱いは `workflow-lib.sh` の `wf_init` と同じ手法）
  - `guard`: `wf_declared || wf_tickets_active` で許可。継続で通した場合はログに `CONTINUE(ticket)` を残す
  - `prompt`: `wf_tickets_active` なら additionalContext を「未完了チケットがあるため `issue-pr-driven-workflow` の継続中とみなす。宣言不要。別の依頼を始めるならチケットを完了または todo に戻してから」に切り替える（`prompt_seq` の加算は従来どおり）
  - `record` は変更なし
  - **安全な編集手順**: このフックは編集した瞬間から本セッションに効く。scratchpad に新版を Write し、テストスクリプトの `ENTRY` を環境変数 `WF_ENTRY_SCRIPT` で差し替えられるようにして先にテストを通し、その後 Write で本体に反映する
- `.claude/hooks/tests/test-workflow-entry.sh`: `ENTRY="${WF_ENTRY_SCRIPT:-…}"` の差し替え対応。TE012（`10_doing` にチケットあり → record 無しでも guard 許可、prompt が「継続中」）、TE013（`00_todo` のみでも継続）、TE014（`20_done` のみは継続しない → WF101）を追加。`setup` で `${TMP}/wip/10_tickets/{00_todo,10_doing,20_done}` を作る
- `CLAUDE.md`「作業の入口」: 「宣言はプロンプトごとに必要」の箇条書きに「ただし `wip/10_tickets/` に未完了チケットがある間（issue-pr 作業中）は継続とみなし再宣言不要」を追記
- DoD: `bash .claude/hooks/tests/test-workflow-entry.sh` が全件（既存 33 + 新規）パス。本セッションで次のプロンプトが `[WF-ENTRY] … 継続中` になり、Skill 未呼び出しで Edit が通る

### 004 ai-asset-implementation: スキル・テンプレート・evals・ルールの文言統一

- `.claude/skills/ticket-driven-workflow/`: `SKILL.md`（特に `:56` の `mkdir -p` と `git mv` の例）、`references/permission-matrix.md`、`assets/{ticket,plan,report}.template.md`、`evals/evals.json`
- `.claude/skills/issue-pr-driven-workflow/SKILL.md`、`evals/evals.json`
- `.claude/skills/light-task-workflow/SKILL.md`（`wip/ticket/doing/` 2 箇所）
- `.claude/rules/markdown-frontmatter.md`（`:46`, `:47`, `:60`）
- DoD: `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude CLAUDE.md` が 0 件（`workflow.log` と `.state` を除く）

### 005 retrospective: 結果報告

- `wip/30_reports/` に `report.template.md` から作成。対象 issue #1 / PR #2 を記入。issue の受け入れ条件 5 項目を確認項目にする
- 使った AI アセットの棚卸し（`light-task-workflow` 手順 5 と同じ観点）を含める

## 検証

1. `bash .claude/skills/ticket-driven-workflow/scripts/test-hooks.sh` → 全件 PASS（002 以降）
2. `bash .claude/hooks/tests/test-workflow-entry.sh` → 全件 PASS（003 以降）
3. `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude CLAUDE.md --exclude=workflow.log --exclude-dir=.state` → 0 件（004 以降）
4. 実セッション: 003 完了後の次のプロンプトで、Skill 未呼び出しのまま Edit/Bash が通り、UserPromptSubmit が「継続中」を返す
5. `git ls-files wip` に `.gitkeep` 5 件と本計画ファイルが載っている

## 完了後（issue-pr-driven-workflow 手順 6）

`git push` → PR #2 本文を成果で更新 → 承認③（ready for review）
