---
type: ai-asset-implementation
status: todo
depends_on: ["005-ai-asset-implementation-テストTC022bとTC022c.md"]
---

# work-ticket-driven / work-overall-plan の git add wip/ を許可パスに揃える

## 目的

実装計画（wip/20_plans/AIアセット実装計画-skill-git-add-paths.md）ステップ 2。仕様書 2.3 の規約と基本フロー 3・6 のとおり、SKILL.md 4 か所の `git add wip/` を `git add wip/10_tickets/ …` に修正し、`permission-matrix.md` に規約を 1 文添える（受け入れ条件①②）。

## 完了条件（DoD）

- [x] .claude/skills/work-ticket-driven/SKILL.md 手順 2 のコミット例が `git add wip/10_tickets/`、手順 5 のコミット例が `git add wip/10_tickets/ <許可パス内の変更ファイル>` になり、手順 5 の直後に規約 1 行（`wip/` のような親ディレクトリ全体を指定しない。未記載 → WF009 の確認になる。仕様書「Bash コマンドの許可」参照）が添えられている
- [x] .claude/skills/work-overall-plan/SKILL.md 4-1 のコミット例が `git add wip/10_tickets/`、4-5 が `git add wip/10_tickets/ wip/00_overall_plan/` になっている
- [x] .claude/skills/work-ticket-driven/references/permission-matrix.md の「チケット運用」行に、仕様書 2.3 の規約（対象は `wip/10_tickets/` と許可パス内のファイル。親ディレクトリ全体を指定しない）が 1 文追記されている
- [x] `grep -rn 'git add wip/' .claude/skills` が 0 件、`grep -rn 'git add wip/10_tickets/' .claude/skills` が 4 件（SKILL.md 2 本）であることを作業ログに記録している。他の `work-*` スキルに `git add wip/` 相当が無いことの確認（受け入れ条件②）
- [x] SKILL.md の frontmatter（name / description / title / type / tags / keywords）は変更していない。テンプレートのプレースホルダの混入なし（`git diff` でコマンド例と規約 1 段落のみの変更を確認）
- [x] 参照更新: `evals.json` は `git add wip/` の記述なしのため更新なし。全テスト（`bash .claude/hooks/tests/*.sh` 4 本 + `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh`）が通る

## 作業内容

1. SKILL.md 2 本の 4 か所を Edit する（末尾スラッシュ付きの `wip/10_tickets/` で書く）
2. `permission-matrix.md:91` に規約を追記する
3. grep で残存確認、全テストを回す

## 作業ログ

### うまくいったこと

- SKILL.md 2 本 4 か所を仕様書 2.3 のとおり修正（`work-ticket-driven` 手順 2・5、`work-overall-plan` 4-1・4-5）。手順 5 の直後に規約の段落を 1 つ追加。`permission-matrix.md` の「チケット運用」行に規約を 1 文追記。差分は 3 ファイル、7 行追加・5 行削除で、frontmatter・他の節は不変
- 残存確認: `grep -rn 'git add wip/' .claude/skills` → 0 件（`wip/10_tickets/` を含む行のみ）。`grep -rn 'git add wip/10_tickets/' .claude/skills` → 4 件（`work-overall-plan/SKILL.md:75,122`、`work-ticket-driven/SKILL.md:88,160`）。他の `work-*` スキルはコマンド例を持たず手順番号参照のみ（受け入れ条件②）
- 回帰: `test-workflow-guard.sh` PASS=19、`test-workflow-entry.sh` PASS=45、`test-work-boundary.sh` PASS=13、`test-json-syntax.sh` PASS=24、`scripts/test-hooks.sh` PASS=194、すべて FAIL=0
- 本チケットの着手・完了コミットも規約どおり（`git add wip/10_tickets/ <許可パス内のファイル>`）で WF009 なし

### うまくいかなかったこと

- 特になし。`scripts/test-hooks.sh` は 120 秒を超えるためバックグラウンド実行で完了を待った（結果は正常）
