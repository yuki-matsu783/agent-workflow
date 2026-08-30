- 対象 issue: #30 https://github.com/yuki-matsu783/agent-workflow/issues/30
- PR: #31 https://github.com/yuki-matsu783/agent-workflow/pull/31

# 全体計画: 完了処理にマージ前作業を追加し、実施済みを機械的に判定してから draft を解除する

## Context

`workflow-issue-mr-driven` の完了処理（手順 6）は「PR 本文の最終整形 → 承認③ → `gh pr ready`」だけで、次の 3 点が抜けている。

1. **wip のリセット**: `wip/` 配下の成果物（チケット・全体計画・計画書・結果報告・`review-state.json`）がそのまま main にマージされ蓄積している（`origin/main` に 59 ファイル）
2. **コンフリクト確認**: default ブランチとの衝突を確認せず ready にしている
3. **関連 issue へのコメント**: マージされる旨・成果の要約が issue 側に残らない

参考リポジトリ `c:\Users\taniyama\Desktop\git\MR-driven-workflow` のフェーズ 5（5-1 コンフリクト検知・解消 `check-base-conflicts.sh` / 5-2 関連 issue 通知（投稿前に人間承認）/ 5-5 片付け `cleanup-task.sh` / 5-6 Draft 解除、DDR i0028-01・i0046-01・i0086-01・i0112-01）に倣い、本リポジトリの `work-boundary.sh` / `workflow-boundary.sh`（issue #12）と同じ「**スクリプトだけが状態を書き、実操作を自ら行って証跡を残す。フックは迂回を exit 2 で拒否する**」方式で取り込む。ユーザーの要求は「マージ前作業をしてから draft 解除してマージ依頼する」「やったかどうかを機械的に判断できること」の 2 点。

## 決定済みの設計方針

1. **新規 CLI `.claude/hooks/merge-prep.sh`**（`work-boundary.sh` と同じ流儀: `set -uo pipefail`、`workflow-lib.sh` を source、前提未充足は exit 2 + `[WFxxx]`、結果は JSON を stdout）。サブコマンド:

   | サブコマンド | 前提（満たさなければ exit 2 + WF016） | 動作 |
   |---|---|---|
   | `status` | — | `wip/merge-prep.json` と現状（wip の成果物の有無・PR 番号）から状態 JSON を返す（exit 0） |
   | `reset-wip [--dry-run]` | todo / doing が空・done あり・`work-boundary.sh status` の `review_state == completed`・未コミット無し・現在ブランチに open な PR がある | `wip/00_overall_plan/*.md`、`wip/10_tickets/{00_todo,10_doing,20_done}/*.md`、`wip/20_plans/*.md`、`wip/30_reports/*.md`、`wip/10_tickets/review-state.json` を削除（`.gitkeep` は残す）。最後のワークのレビュー完了の証跡（ticket / work_type / review_decision / complete.at）を状態ファイルへ写してから `chore(merge-prep): reset wip` でコミット・push。`--dry-run` は削除予定一覧だけを JSON で返し何も変えない |
   | `check-conflicts` | 状態ファイルが現在の PR のもの（`reset` 済み）・未コミット無し | `git fetch origin <default>` → `git merge-tree --write-tree --name-only --no-messages HEAD origin/<default>`（作業ツリー不変）。結果（base / base_sha / head_sha / files / has_conflict / at）を記録してコミット。衝突ありは記録したうえで exit 2（WF016）で対象ファイルと解消手順（`git merge origin/<default>` → 解消 → コミット → push → 再実行。**rebase 禁止**）を返す |
   | `notify-issue --body-file <path> [--issue N ...]` | `conflicts.has_conflict == false` が記録済み | 通知先は PR 本文の `Closes #N`（複数可）＋ `--issue` の指定。本文の先頭に `Claude Code より:` と目印 `<!-- merge-prep: notify pr=<M> -->` を付けて `gh issue comment N --body-file`。issue 番号・コメント URL・時刻を記録してコミット |
   | `ready` | `reset` / `conflicts`（衝突なし）/ `notify` がすべて記録済み・**再検証**（wip に成果物が無い・`merge-tree` で衝突なし（fetch あり）・未コミット無し・HEAD が push 済み）を通る | `gh pr ready <M>` を実行し `ready.at` を記録・コミット・push。以後 AI は止まる（マージは人間） |

   状態ファイル `wip/merge-prep.json`（Git 管理、直近 1 PR 分のみ）: `{version, pr, branch, state: reset|checked|notified|ready, review: {...}, reset: {at, commit, deleted: [...]}, conflicts: {...} | null, notify: {...} | null, ready: {at} | null}`。`pr` が現在ブランチの PR 番号と一致しなければ失効（`status` が `none`）。ヘッドレス実行を考慮し `permissionDecision: ask` は使わず exit 2 のみ。

2. **フック `workflow-boundary.sh` の拡張**（新規フックは作らず、既存の `Edit|Write|NotebookEdit|Bash` matcher のまま）:
   - **WF015（新設）**: Bash のセグメントに `gh pr ready` があれば、doing の有無・境界の有無を問わず**常に**拒否（対処: `bash .claude/hooks/merge-prep.sh ready`）。現行の (d)（WF011 の `gh pr ready`）はこれに置き換える（TC026g の期待値を WF015 に変更）
   - **WF012 の対象拡張**: `wip/merge-prep.json` も `review-state.json` と同じく直接書き換え（Edit / Write / NotebookEdit / Bash の rm・sed -i・リダイレクト・git checkout -- 等）を拒否。`SCRIPT_RE` に `merge-prep.sh` を追加
   - `settings.json` は変更不要（matcher 同一）

3. **`workflow-issue-mr-driven` 手順 6 の改訂**（マージ前作業の順序は参考 DDR i0112-01 に合わせ「コンフリクト → 通知 → 片付け」を基本にしつつ、本リポジトリは片付け（reset-wip）が即コミットするため作業ツリーは汚れない。よって **reset-wip → check-conflicts → notify-issue → ready** の順にし、reset 後の HEAD に対して衝突を確認する）:
   1. PR 本文の最終整形（`wip/30_reports/` の要約。**reset 前に行う**。報告は削除されるため）
   2. 承認③: 「マージ前作業（wip リセット → コンフリクト確認 → issue コメント → ready）に進むか / draft のまま / 追加作業」
   3. `reset-wip`（`--dry-run` で削除対象を提示してから本実行）
   4. `check-conflicts`。衝突ありなら内容を提示して**承認⑤**（解消してよいか）を取り、`git merge origin/<default>`（rebase 禁止）→ 解消 → コミット → push → 再実行。解消方針が一意でない衝突は `AskUserQuestion` で人間に判断を仰ぐ
   5. issue コメント本文案を作り**承認⑥**（本文そのものを見せる。外部への副作用のため。参考 DDR i0086-01）→ `notify-issue --body-file`
   6. `ready` → 報告して停止（マージは人間。`gh pr merge` は実行しない）
   - 承認④は既存のまま。承認ポイント表に⑤⑥を追加し、ヘッドレス実行では⑤⑥が取れず止まる旨を明記（`.claude/rules/claude-config-headless-awareness.md`）

4. **スコープ外**（issue #30 に明記済み）: マージ操作そのもの、DDR 重複検知・追従監視、`Closes #N` 以外の関連 issue の自動特定、#28（入口ガードの継続判定。完了処理の途中でプロンプトが分かれた場合は振り分けの再宣言が必要。本計画では変更しない）・#29

## 変更対象ファイル

| ファイル | 変更内容 | チケット |
|---|---|---|
| `.claude/docs/10_spec/チケット駆動ワークフロー.md` | 新節「マージ前作業の判定と状態（`merge-prep.sh` / `wip/merge-prep.json`）」、フック条件 (e)(f)、エラーコード WF015 / WF016 とメッセージテンプレート、TC029〜TC031、ディレクトリ構成図に `merge-prep.json`、レビュー記録 v2.0 | 015 |
| `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` | 承認ポイント⑤⑥、基本フロー 8（完了処理）の改訂、状態遷移図、使用コマンド、エラーケース、IP015〜IP018、レビュー記録 v1.5 | 015 |
| `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` | 受け入れ基準に「マージ前作業の実施と機械判定」「issue 通知前の承認」「AI はマージしない」を追加、v1.3 | 015 |
| `.claude/docs/10_spec/スキル体系.md` | ワークフロー層の「ワーク間の人間承認」に加え完了処理のゲート（WF015 / WF016）への言及を 1 段落追加、v1.4 | 015 |
| `.claude/docs/90_glossary/ワークフロー用語.md` | 「承認①②③」→「承認①〜⑥」、「マージ前作業」「merge-prep.json」の項を追加。WF コード欄に WF015 / WF016 | 015 |
| `.claude/hooks/merge-prep.sh` | 新規（上記サブコマンド） | 016 |
| `.claude/hooks/workflow-boundary.sh` | WF015 追加、WF012 の対象に `wip/merge-prep.json`、`SCRIPT_RE` 拡張、(d) を WF015 に統合 | 016 |
| `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` | TC029（merge-prep.json 保護 / `gh pr ready` 常時拒否）、TC030（reset-wip の前提・削除結果・dry-run・冪等）、TC031（check-conflicts の衝突あり／なし、notify-issue、ready の前提未充足と成功。`gh` モックに `issue comment` / `pr ready` / `pr view --json body` を追加、bare リモートで `origin/main` を用意） | 016 |
| `.claude/skills/work-ticket-driven/SKILL.md` | 手順 6 末尾「完了報告」に「`workflow-issue-mr-driven` 経由なら同スキル手順 6（マージ前作業）へ」を追記。エラーハンドリングに WF015 / WF016 | 016 |
| `.claude/skills/workflow-issue-mr-driven/SKILL.md` | 役割分担表に `merge-prep.sh`、承認ポイント⑤⑥、手順 6 の全面改稿、フロー図、エラーハンドリング（WF015 / WF016 / 衝突あり）、ベストプラクティス | 017 |
| `.claude/skills/workflow-issue-mr-driven/assets/issue-notify.template.md` | 新規。issue コメント本文のテンプレート（対象 PR・変更の要約・受け入れ条件との対応・成果物） | 017 |
| `.claude/skills/workflow-issue-mr-driven/evals/evals.json` | id 3 の期待値を新手順に更新、id 7（reset-wip 前提未充足）、id 8（衝突あり）、id 9（直接 `gh pr ready` が WF015）を追加 | 017 |
| `.claude/skills/task-gh-feature/SKILL.md` | issue 連携モード末尾の `gh pr ready N` の記述を「`workflow-issue-mr-driven` では `merge-prep.sh ready` 経由」に注記 | 017 |
| `wip/30_reports/018-結果報告-マージ前作業の機械化.md` | 結果報告 | 018 |

`workflow-guard.sh` / `workflow-lib.sh` / `workflow-entry.sh` / `work-boundary.sh` / `settings.json` / `workflow-types.json` は変更しない（`merge-prep.sh` の実行は doing が空のときに限られ、`workflow-guard.sh` は不活性。`work-boundary.sh status` は `reset-wip` の前提判定にそのまま使う）。

## チケット分割（015〜018、依存関係: 015→016→017→018）

連番は `wip/10_tickets/20_done/` の既存最大（014）の続きから振る（`work-boundary.sh status` は done の連番最大を境界の基準にするため、既存より小さい番号を使うと判定が狂う）。

| # | type | 目的 | DoD 概要 |
|---|---|---|---|
| 015 | `ai-asset-design` | 仕様・要件・用語辞書の改訂（`merge-prep.sh` の I/F、状態ファイルのスキーマ、フック条件、WF015 / WF016、承認⑤⑥、テストシナリオ） | `.claude/docs/**` 5 ファイルが更新され、レビュー記録に追記済み |
| 016 | `ai-asset-implementation` | `merge-prep.sh` 新規、`workflow-boundary.sh` 拡張、`test-hooks.sh` に TC029〜031、`work-ticket-driven/SKILL.md` の追記 | `test-hooks.sh` 新旧全件パス、`test-workflow-entry.sh` / `test-workflow-guard.sh` 回帰なし、`bash -n` 通過 |
| 017 | `ai-asset-implementation` | `workflow-issue-mr-driven/SKILL.md` 手順 6 の改稿、通知テンプレート新設、evals 更新、`task-gh-feature` の注記 | SKILL.md の手順が 015 の仕様と一致、evals.json が JSON として妥当、`grep` で旧記述（直接の `gh pr ready`）の残存なし |
| 018 | `retrospective` | 振り返り・結果報告。**この PR 自身の完了処理で reset-wip → check-conflicts → notify-issue → ready を実地で通す**（結果報告作成後、`workflow-issue-mr-driven` 手順 6 として実施） | `wip/30_reports/` に結果報告。各ワークのレビュー結果を記載 |

ワークの区切りは 015 / 016+017（同 type で 1 ワーク）/ 018 の 3 つ（レビュー往復 3 回）。

## 受け入れ条件との対応

| issue #30 の受け入れ条件 | チケット |
|---|---|
| `reset-wip` が成果物を削除しコミット・push、前提未充足は exit 2 で不変 | 016（TC030） |
| `check-conflicts` が作業ツリー不変で JSON を返し記録、衝突ありは exit 2 | 016（TC031） |
| `notify-issue` が `Closes #N` の issue にコメントし URL を記録 | 016（TC031、`gh` モック） |
| `ready` は全記録＋再検証が通ったときだけ `gh pr ready`、欠けると exit 2 | 016（TC031） |
| 直接の `gh pr ready` と `wip/merge-prep.json` の直接書き換えをフックが拒否 | 016（TC029） |
| テスト全件パス | 016 |
| 仕様書・SKILL.md・用語辞書の更新 | 015 / 016 / 017 |
| この PR 自身で新手順を通す | 018 完了後の完了処理 |

## 検証方法

- `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh`（新旧全件 PASS。`gh` はモック、`git merge-tree` は bare リモートに `main` を push して実物で検証）
- `bash .claude/hooks/tests/test-workflow-entry.sh`、`bash .claude/hooks/tests/test-workflow-guard.sh`（回帰なし）
- `bash -n .claude/hooks/merge-prep.sh .claude/hooks/workflow-boundary.sh`
- 実地: 018 完了・レビュー完了後に、このブランチで `merge-prep.sh reset-wip --dry-run` → `reset-wip` → `check-conflicts` → `notify-issue`（承認⑥）→ `ready` を通し、PR #31 が draft 解除され issue #30 にコメントが付くこと。直接 `gh pr ready 31` を Bash から試みて WF015 で止まることも確認する

## リスク・判断が必要な点

- `reset-wip` 後は `wip/10_tickets/` が空になるため、`workflow-entry.sh` の継続判定が効かず、完了処理の途中でプロンプトが分かれると振り分けの再宣言（WF101）が必要になる。#28 と同種の課題として残課題に記載し、本計画では対応しない
- 既存 main 上の古い wip 成果物は、この PR の `reset-wip` で初めて全削除される（以降のブランチは空の状態から始まる）
- `git merge-tree --write-tree` は git 2.38 以降が必要（実機は 2.43 以降の想定。`check-conflicts` 内で `git version` を確認し、古ければ exit 2 で理由を返す）
