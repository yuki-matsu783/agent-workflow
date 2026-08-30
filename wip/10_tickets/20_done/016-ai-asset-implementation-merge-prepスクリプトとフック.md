---
type: ai-asset-implementation
status: todo
depends_on: ["015-ai-asset-design-マージ前作業の仕様.md"]
---

# merge-prep.sh の実装とワーク境界フックの拡張

## 目的

015 で確定した仕様に従い、`.claude/hooks/merge-prep.sh`（`status` / `reset-wip` / `check-conflicts` / `notify-issue` / `ready`）を新規実装し、`workflow-boundary.sh` に WF015（直接の `gh pr ready` の拒否）と `wip/merge-prep.json` の保護（WF012）を追加する。`test-hooks.sh` に TC029〜TC031 を追加して全件パスさせる。

## 完了条件（DoD）

- [x] `.claude/hooks/merge-prep.sh` が新規作成され、5 サブコマンドが仕様どおりに動く（前提未充足は exit 2 + `[WF016]`、状態ファイルは変更しない。結果は JSON を stdout）
- [x] `reset-wip` が `wip/00_overall_plan/*.md`、`wip/10_tickets/{00_todo,10_doing,20_done}/*.md`、`wip/20_plans/*.md`、`wip/30_reports/*.md`、`wip/10_tickets/review-state.json` を削除（`.gitkeep` は残す）し `chore(merge-prep): reset wip` でコミット・push する。`--dry-run` は何も変えない
- [x] `check-conflicts` が `git merge-tree --write-tree` で作業ツリーを変えずに判定し、衝突ありは記録のうえ exit 2 で対象ファイルと解消手順を返す
- [x] `notify-issue` が `Closes #N` の issue（＋`--issue`）へ `gh issue comment` し URL を記録する
- [x] `ready` が全記録＋再検証を通ったときだけ `gh pr ready` を実行し、欠けると exit 2 で未充足を列挙する
- [x] `workflow-boundary.sh` が直接の `gh pr ready` を常に WF015 で拒否し、`wip/merge-prep.json` の直接書き換えを WF012 で拒否する。`merge-prep.sh` 経由は許可
- [x] `test-hooks.sh` に TC029〜TC031 が追加され（`gh` はモック、`origin/main` は bare リモート）、既存分を含め全件 PASS（PASS=189 FAIL=0。既存 130 + 新規 59）。TC026g の期待値は WF015 に更新
- [x] `bash .claude/hooks/tests/test-workflow-entry.sh`（40/40）/ `test-workflow-guard.sh`（4/4）が全件 PASS（回帰なし）
- [x] `.claude/skills/work-ticket-driven/SKILL.md` の完了報告に「`workflow-issue-mr-driven` 経由なら同スキル手順 6（マージ前作業）へ」が追記され、エラーハンドリングに WF015 / WF016 が加わっている

## 作業内容

1. `merge-prep.sh` を `work-boundary.sh` と同じ構造（`workflow-lib.sh` を source、`wb_die` 相当、`wf_jq`）で実装する
2. `workflow-boundary.sh` の (a)(b) に `merge-prep.json` を加え、`gh pr ready` を WF015 として常時判定に移す。(d) を削除
3. `test-hooks.sh` の `gh` モックを拡張し、TC029〜TC031 を追加する
4. `work-ticket-driven/SKILL.md` を追記する
5. テスト 3 本と `bash -n` を実行する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- `work-boundary.sh` の骨格（`wf_jq`・`wb_die` 相当・状態ファイルのコミット・push）をそのまま流用でき、`merge-prep.sh` は 1 回の実装でテスト初回 187/189 PASS。失敗 2 件はテスト側の gh モックの引数位置ミス（`$2` → `$3`）だった
- 衝突判定は `gh` をモックせず、bare リモートに `base` ブランチを置いて実物の `git merge-tree --write-tree` で検証できた（衝突あり → `git merge` で解消 → 衝突なし、の往復まで）
- `gh pr ready` の直接実行を WF011 の境界条件から切り離して常時拒否（WF015）にしたことで、フック側の (c) が `mv` だけになり単純化した

### うまくいかなかったこと

- テスト実行コマンドに `2>&1` を付けて WF003（リダイレクト判定）で止まった。#13 の残課題「Bash ツールで `2>&1` を付けない」が未反映のまま。CLAUDE.md か `work-ticket-driven` への追記候補
- `bash -n` による構文チェックは `TEST_RE` 外で WF003 になるため実行できず、テストの実行で代替した（`ai-asset-implementation` の bash group に `bash -n .claude/hooks/*.sh` を加える案は別途）
- `ready` の再検証で衝突を見つけた場合に `conflicts` を記録してコミットするため、`ready` が失敗しても HEAD が 1 つ進む（`mp_pushed` は先に評価しているので判定には影響しない）。仕様どおりだが、失敗時にコミットが増える点は結果報告で触れる
