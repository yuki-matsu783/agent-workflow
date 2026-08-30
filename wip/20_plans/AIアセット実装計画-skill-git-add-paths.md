---
type: plan
title: AI アセット実装計画 スキル手順の git add wip/ を許可パスに揃える
description: work-ticket-driven / work-overall-plan の SKILL.md 4 か所を仕様書 2.3 の規約に揃え、TC022b / TC022c を test-workflow-guard.sh に追加する実装計画
tags: [work-ticket-driven, plan, ai-asset-implementation-plan]
keywords: [git add, wip/10_tickets/, WF009, work-ticket-driven, work-overall-plan, SKILL.md, test-workflow-guard.sh, TC022b, TC022c, TG004, 許可パス, 末尾スラッシュ]
---

# AI アセット実装計画: スキル手順の git add wip/ を許可パスに揃える

- 作成元チケット: 004-ai-asset-implementation-plan-AIアセット実装計画.md
- 作成日: 2026-08-30
- 入力: 仕様書 `.claude/docs/10_spec/チケット駆動ワークフロー.md` 2.3（「Bash コマンドの許可」の `git add` の対象パスの規約、基本フロー 3・6、TC022b / TC022c）、設計計画 `wip/20_plans/AIアセット設計計画-skill-git-add-paths.md`、全体計画 `wip/00_overall_plan/skill-git-add-paths.md`（issue #47 / PR #48）

## 調査サマリ

- 仕様書 2.3 の規約: チケット運用のコミットでは `git add` の対象を `wip/10_tickets/` と作業タイプの許可パス内のファイルに限定し、`wip/` のような親ディレクトリ全体を指定しない。基本フロー 3 = `git add wip/10_tickets/`、6 = `git add wip/10_tickets/ <許可パス内の変更ファイル>`
- `git add wip/` を指示している箇所（`grep -rn 'git add wip' .claude/skills`）は 4 か所のみ:
  - `.claude/skills/work-ticket-driven/SKILL.md:88`（手順 2 チケット作成後のコミット）、`:160`（手順 5 done のコミット `git add wip/ <allowed_paths内の変更ファイル>`）
  - `.claude/skills/work-overall-plan/SKILL.md:75`（4-1 チケット作成後のコミット）、`:122`（4-5 done のコミット）
  - 他の `work-*-plan` / `work-*-exec` は `work-ticket-driven` の手順番号を参照するだけで、コマンド例を持たない。`evals.json`・`references/permission-matrix.md` にも `git add wip/` は無い
- 既存テスト `.claude/hooks/tests/test-workflow-guard.sh` は、一時ディレクトリに doing チケットと `workflow-types.json` を置き、`cmd_json` / `edit_json` で PreToolUse JSON を作って `run` → `check <ID> <exit> <含まれる文字列>` で検証する形。TG001〜TG004（`git add` / `git mv` の `wip/10_tickets/` 無条件許可）と TC032〜TC039（実物 type 定義）がある。**仕様書の TC022（`git add src/main.ts` → WF009）は TG004 として実装済み**（設計チケットの積み残しは解消）
- `wf_is_ticket_path` は `wip/10_tickets/*` の case パターンで判定するため、**末尾スラッシュ無しの `wip/10_tickets` は一致しない**（`workflow.log` 736 行目: `git add wip/10_tickets wip/3…` が ASK）。`wf_match` の `wip/10_tickets/**` → `wip/10_tickets/*` も同じ。SKILL.md のコマンド例は必ず `wip/10_tickets/`（末尾スラッシュあり）で書く

## 変更方針

- フック本体（`workflow-guard.sh` / `workflow-lib.sh`）・`workflow-types.json`・`settings.json` は変更しない（要件の制約。issue #47 スコープ外）。変更するのは SKILL.md 2 本とテストスクリプト 1 本
- テストを先に追加して現行フックの挙動を固定し（TC022b が ask、TC022c が exit 0 になることを確認）、その後 SKILL.md を修正する
- 末尾スラッシュ無しのケースは仕様書に TC が無い。フックの挙動としては「`wip/10_tickets` は未記載 → ask」で一貫しており、規約どおり末尾スラッシュ付きで書けば問題にならないため、**フックは変えず、TC022b の派生として `git add wip/10_tickets`（スラッシュ無し）→ ask を TC022d 案としてテストに含める**。仕様書への TC022d の追記は振り返りで「設計反映が必要な差分」として扱う（レビュー観点で人間に示す）

## 変更対象ファイル

| ファイル / パス | 種類 | 変更内容 |
|----------------|------|---------|
| `.claude/hooks/tests/test-workflow-guard.sh` | hook のテスト | `use_real_types` 以降に TC022b / TC022c（+ TC022d 案）を追加。`write_ticket investigation` で `git add wip/` → exit 0 + `WF009`、`git mv …10_doing/001-… …20_done/ && git add wip/10_tickets/ wip/20_plans/調査結果.md && git commit -m x` → exit 0 かつ出力に `WF009` を含まない。`write_ticket overall-plan` で `git add wip/` → `WF009`、`git add wip/10_tickets/ wip/00_overall_plan/` → exit 0 かつ `WF009` なし。`git add wip/10_tickets`（スラッシュ無し）→ `WF009`。冒頭コメントの検証対象に 2.3 の規約を追記 |
| `.claude/skills/work-ticket-driven/SKILL.md` | skill | 手順 2（:88）`git add wip/` → `git add wip/10_tickets/`。手順 5（:160）`git add wip/ <allowed_paths内の変更ファイル>` → `git add wip/10_tickets/ <許可パス内の変更ファイル>`。手順 5 のコマンド例の直後に 1 行、規約（`wip/` のような親ディレクトリ全体を指定しない。未記載 → WF009 の確認になる。仕様書「Bash コマンドの許可」参照）を添える。frontmatter は変更しない |
| `.claude/skills/work-overall-plan/SKILL.md` | skill | 4-1（:75）`git add wip/` → `git add wip/10_tickets/`。4-5（:122）`git add wip/` → `git add wip/10_tickets/ wip/00_overall_plan/`（`overall-plan` type の許可パス）。frontmatter は変更しない |

**allowed_paths 案**: `ai-asset-implementation` type の標準（`.claude/hooks/**`、`.claude/skills/**`）で足りる。追加不要

## テスト方針

| TC | 置き場所 | 内容 | 期待 |
|----|---------|------|------|
| TC022b | `test-workflow-guard.sh` | `investigation` / `overall-plan` で `git add wip/` | exit 0 + 出力に `WF009` |
| TC022c | 同上 | `investigation` で `git mv … && git add wip/10_tickets/ wip/20_plans/調査結果.md && git commit -m x`、`overall-plan` で `git add wip/10_tickets/ wip/00_overall_plan/` | exit 0 かつ出力に `WF009` を含まない（`check` は「含む」しか検証しないため、`grep -q WF009` の否定を別途書くか、`check` に否定用の引数を足す） |
| TC022d（案） | 同上 | `investigation` で `git add wip/10_tickets`（末尾スラッシュ無し） | exit 0 + `WF009`（現行挙動の固定。仕様書に未記載） |
| 回帰 | `bash .claude/hooks/tests/test-workflow-guard.sh`、`bash .claude/hooks/tests/test-workflow-entry.sh`、`bash .claude/hooks/tests/test-work-boundary.sh`、`bash .claude/hooks/tests/test-json-syntax.sh`、`bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` | 全部回して PASS のみ | |

注意: TC022c の `git mv` は一時ディレクトリの実ファイルを動かさない（フックは JSON のコマンド文字列だけを判定する）ので、ファイルの実在は不要。`git commit -m x` は `cmd_json` の引数内でクォートされるため `sanitized` で `QUOTED` になり、`commit` セグメントは無条件許可

## 実装ステップ

1. **テスト追加（005）**: `test-workflow-guard.sh` に TC022b / TC022c / TC022d を追加し、`bash .claude/hooks/tests/test-workflow-guard.sh` で PASS を確認する（現行フックで通ること = フック変更不要の裏付け）
2. **スキル修正（006）**: `work-ticket-driven/SKILL.md` 2 か所と `work-overall-plan/SKILL.md` 2 か所を仕様書 2.3 のとおり修正し、`grep -rn 'git add wip/' .claude/skills` が 0 件になることを確認する。全テストを回して回帰確認
3. **振り返り（007）**: 結果報告。受け入れ条件④の根拠として本 PR の `workflow.log`（001〜006 の done コミットが ALLOW）を引用する。TC022d の仕様書追記を「設計反映が必要な差分」として棚卸しする

## 参照更新の一覧

- `.claude/skills/work-*/SKILL.md`（`work-ticket-driven` / `work-overall-plan` 以外）: コマンド例を持たず手順番号参照のみ → 更新なし（`grep -rn 'git add' .claude/skills` で確認し、実装チケットの作業ログに結果を添える）
- `.claude/skills/*/evals/evals.json`: `git add wip/` の記述なし → 更新なし
- `.claude/skills/work-ticket-driven/references/permission-matrix.md`: `:91`「チケット運用」行に `git add` の判定規則がある（`wip/10_tickets/` 配下は無条件、それ以外は判定表）。仕様書 2.3 の規約（親ディレクトリ全体を指定しない）を 1 文追記する → **006 で更新**
- `.claude/skills/work-ticket-driven/scripts/test-hooks.sh`: TC022（`:209` `git add src/main.ts` → WF009）を含む結合テスト。TC022b / TC022c の置き場所は仕様書どおり `.claude/hooks/tests/test-workflow-guard.sh` とし、こちらは変更せず回帰確認（`bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh`）に含める
- `.claude/docs/10_spec/チケット駆動ワークフロー.md`: 2.3 で更新済み。TC022d は未記載（振り返りで棚卸し）

## 検証方法

- `bash .claude/hooks/tests/test-workflow-guard.sh` → TC022b / TC022c / TC022d を含め FAIL=0
- `grep -rn 'git add wip/' .claude/skills` → 0 件。`grep -rn 'git add wip/10_tickets/' .claude/skills` → 4 件
- 本 PR の後続チケット（005〜007）の done コミットが `workflow.log` で ALLOW（受け入れ条件④）

## リスク・未解決事項

- フック本体は触らないためロックアウトの懸念は無い。テストスクリプトの追加のみ（`ai-asset-implementation` は `test` グループで `bash .claude/hooks/tests/*.sh` を実行できる）
- `check` 関数は「文字列を含む」しか検証しない。TC022c の「`WF009` を含まない」は `check` を拡張するか、`case "${R_OUT}${R_ERR}" in *WF009*)` で FAIL にする補助関数を追加する（005 で判断し作業ログに書く）
- TC022d（末尾スラッシュ無し）の仕様書追記は本 PR のスコープ外。振り返りで棚卸しし、必要なら別 issue または設計反映として提案する
