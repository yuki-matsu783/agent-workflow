---
type: plan
title: WF012 引用符内状態ファイル名誤反応の修正 全体計画
description: workflow-boundary.sh の WF012 判定が引用符内の review-state.json 文字列に誤反応する不具合の修正計画
tags: [wf012, workflow-boundary, hooks, bugfix]
keywords: [WF012, review-state.json, クォート, QUOTED, workflow-boundary.sh, workflow-guard.sh, test-hooks.sh]
---

# WF012 引用符内状態ファイル名誤反応の修正 全体計画

- 対象 issue: #29 https://github.com/yuki-matsu783/agent-workflow/issues/29
- PR: #34 https://github.com/yuki-matsu783/agent-workflow/pull/34

## 背景・問題

`workflow-boundary.sh` の WF012 判定（レビュー状態ファイル `wip/10_tickets/review-state.json` の直接書き換え防止）は、Bash コマンドの**生の文字列**に対して `case "${seg}" in *review-state.json*)` で判定している。そのため、`gh issue create --title "review-state.json の扱い"` のように引用符内の文字列にファイル名が含まれるだけのコマンドまで誤ってブロックされる。

`workflow-guard.sh` の `check_bash` は、判定前にクォート内文字列を `QUOTED` に置換する前処理（`sed -E "s/'[^']*'/QUOTED/g; s/\"[^\"]*\"/QUOTED/g"`）を行っており、`workflow-boundary.sh` にも同様の前処理が必要。

ただし単純にクォート除去だけを行うと、`rm "wip/10_tickets/review-state.json"` のようにパスそのものをクォートしたケースが `rm QUOTED` に変換され、review-state.json という文字列が消えて WF012 をすり抜けてしまう（バグを直すつもりが別のバグを生む）。これを防ぐため、クォートで囲まれた値が「状態ファイルのパスそのもの」を指す場合は別途検出して引き続きブロックする。

## 修正方針

`.claude/hooks/workflow-boundary.sh` の (a)(b) レビュー状態ファイル保護ブロック（58〜73行目）を以下のロジックに変更する。

1. セグメントごとに、`workflow-guard.sh` と同じ前処理でクォート除去版 `sanitized` を作る
2. `READONLY_RE` / `SCRIPT_RE` の除外判定は `sanitized` に対して行う（元コードは未除去の `seg` に対して行っていたが、判定対象を統一する）
3. `sanitized` に `*review-state.json*` が含まれれば WF012（クォート外にパスがそのまま書かれているケース：`rm wip/10_tickets/review-state.json` 等）
4. 上記でヒットしなければ、元の `seg` からクォートで囲まれた値を `grep -oE "'[^']*'|\"[^\"]*\""` で抽出し、各値をクォート記号を除いて比較する。値が `review-state.json` と完全一致、または `*/review-state.json` に一致すれば WF012（パスそのものをクォートしたケース：`rm "wip/10_tickets/review-state.json"` 等）。値が他の文字列と混在している場合（例: `review-state.json の扱い`）は末尾一致しないため対象外となり、誤検知を防げる

新規ヘルパー関数 `wf_quoted_targets_state()`（`seg` を受け取り、クォート内の値が状態ファイルパスを指せば 0、指さなければ 1 を返す）を `workflow-boundary.sh` 内に追加する。

### 受け入れ条件との対応

| ケース | 期待 | 判定経路 |
|---|---|---|
| `gh issue create --title "...review-state.json..."` | exit 0 | sanitized に review-state.json が残らず、クォート内の値も末尾一致しない → 通過 |
| `rm wip/10_tickets/review-state.json` | WF012 | sanitized のまま `*review-state.json*` にマッチ |
| `rm "wip/10_tickets/review-state.json"` | WF012 | sanitized では消えるが、`wf_quoted_targets_state` が末尾一致で検出 |
| `echo x > wip/10_tickets/review-state.json` | WF012 | sanitized のまま `*review-state.json*` にマッチ（リダイレクト部分はクォートされていない） |

スコープ外: WF011（ワーク境界統制、75行目以降）の判定ロジックは変更しない。

## チケット分割

既存の `wip/10_tickets/20_done/` は issue #12 対応（001〜014）で埋まっているため、番号はその続き（015〜）を使う。

| # | type | 内容 | DoD |
|---|------|------|-----|
| 015 | investigation | 既存実装（workflow-boundary.sh 58-73行目、workflow-guard.sh の sanitized 処理、test-hooks.sh の TC025 系）を確認し、上記修正方針を `wip/20_plans/` に実装計画として記録する | 修正対象箇所・追加するテストケース一覧（TC025 系の追番）を明記した計画書ができている |
| 016 | ai-asset-implementation | `workflow-boundary.sh` に `wf_quoted_targets_state()` を追加し、WF012 判定ロジックを修正方針どおりに書き換える。`test-hooks.sh` に issue #29 のケース（引用符内タイトルは通過／`rm "..."` は引き続き WF012 等）を TC025 系として追加する。`.claude/hooks/**` を触るため type は `ai-asset-implementation` | `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件 PASS する。issue #29 の受け入れ条件3点をすべて満たす |
| 017 | retrospective | 実施内容の振り返りをまとめ、`wip/30_reports/` に結果報告を作成する | うまくいったこと・いかなかったことの整理、改善提案（あれば）の記載 |

依存関係: 016 は 015 に依存、017 は 016 に依存。

## 検証方法

- `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、`結果: PASS=N FAIL=0` になることを確認する
- 手動確認（テストに含めても良い）:
  - `echo '{"tool_name":"Bash","tool_input":{"command":"gh issue create --title \"review-state.json の扱い\" --body x"}}' | CLAUDE_PROJECT_DIR=. bash .claude/hooks/workflow-boundary.sh` → exit 0
  - 同様に `rm wip/10_tickets/review-state.json` / `rm "wip/10_tickets/review-state.json"` / `echo x > wip/10_tickets/review-state.json` を与えて exit 2 (WF012) になることを確認
