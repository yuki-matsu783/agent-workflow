---
type: report
title: 結果報告 入口ガードの状態ベース継続と wip 構成統一
description: issue #1 / PR #2 の結果報告。入口ガードのチケット有無による自動継続、wip ディレクトリの番号付き命名への統一、test グループの追加
tags: [ticket-driven-workflow, report]
keywords: [入口ガード, workflow-entry, 継続, wip, 10_tickets, .gitkeep, bash_groups, test, WF101, WF001, WF003]
---

# 結果報告: 入口ガードの状態ベース継続と wip 構成統一

- 対象ブランチ: `feature/1-entry-guard-continuation`
- 対象 issue: #1 https://github.com/yuki-matsu783/agent-workflow/issues/1
- PR: #2 https://github.com/yuki-matsu783/agent-workflow/pull/2
- 期間: 2026-08-30（1 セッション）

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 001-ai-asset-design-仕様更新 | 完了 | 仕様書 5 本の `wip/` 表記を統一。入口ガード仕様に継続条件・TE012〜014 を追加 |
| 002-ai-asset-implementation-フック統一 | 完了 | フック 4 本・types.json・test-hooks.sh を統一し `.gitkeep` 配置。追加で `bash_groups: ["test"]` と WF001 の `*.md` 限定を実装（ユーザー承認あり）。62 件パス |
| 003-ai-asset-implementation-入口継続 | 完了（1 項目は次プロンプトで確認） | `workflow-entry.sh` に `wf_tickets_active` を追加。40 件パス。CLAUDE.md 追記 |
| 004-ai-asset-implementation-スキル統一 | 完了 | スキル 3 本・テンプレート 3 本・evals 2 本・ルール 1 本を Edit 31 回で統一 |
| 006-ai-asset-design-仕様追記 | 完了 | 002/003 で増えた挙動を仕様書 1.6 として反映。permission-matrix.md との不整合を検出 → 007 |
| 007-ai-asset-implementation-マトリクス同期 | 完了 | permission-matrix.md を仕様 1.6 に同期 |
| 005-retrospective-振り返り | 完了 | 本報告 |

計画時は 5 枚、実施中に 2 枚（006・007）を追加した。

## issue #1 の受け入れ条件

| # | 条件 | 状況 |
|---|------|------|
| 1 | チケットが todo / doing にあるプロンプトでは Skill 未呼び出しでも guard が通る | ユニットテスト TE012b/c・TE013 で確認。実セッションでの確認は次のユーザープロンプトで行う（このセッションはプロンプト #4 で宣言済みのため `wf_declared` が先に真になり、継続経路を通っていない） |
| 2 | その状態の UserPromptSubmit は「継続中」の案内を返す | TE012 で確認。実セッションは同上 |
| 3 | チケットが無ければ現状どおり宣言が必要（TE001〜TE011 パス） | 40 件パス（TE014: done のみ / .gitkeep のみでは継続しない） |
| 4 | `wip/` の実ディレクトリと参照パスが一致し、両テストがパス | `grep` 0 件（`.claude`・CLAUDE.md）。test-hooks 62 件・test-workflow-entry 40 件パス。`.gitkeep` 5 件を Git に載せた |
| 5 | 入口ガード仕様書と CLAUDE.md を更新 | 完了。加えてチケット駆動仕様 1.5/1.6、要件書 2 本、permission-matrix.md |

## 成果物一覧

- 計画書: `wip/00_overall_plan/joyful-roaming-kite.md`（プランモードで合意）
- コード変更: 36 ファイル、+638 / −163
  - フック: `workflow-entry.sh`（継続ロジック）、`workflow-lib.sh`・`workflow-guard.sh`・`workflow-diff-check.sh`・`workflow-types.json`（パス統一、`test` グループ、WF001 の `*.md` 限定）
  - テスト: `test-workflow-entry.sh`（+7 件、`WF_ENTRY_SCRIPT` 差し替え）、`test-hooks.sh`（+6 件、`ticket_dir()`）
  - 仕様・要件: `.claude/docs/` 5 本
  - スキル・テンプレート・evals・ルール: 10 ファイル
  - `CLAUDE.md`「作業の入口」に継続ルール 1 行
  - `wip/10_tickets/{00_todo,10_doing,20_done}`、`wip/20_plans`、`wip/30_reports` の `.gitkeep`

## うまくいったこと

- 計画で決めた順序（types.json → lib）により、統制が生きた瞬間に設定が整合していた。002 の途中で `.gitkeep` の Write が WF001 になったのは「統制が効き始めた」証拠として機能した
- 002 で追加した `test` グループのおかげで、003 以降は統制下のままテストを反復できた。ユーザー確認 → 実装 → 仕様反映（006）→ 要約同期（007）と、増えた仕様を同じワークフロー内で閉じられた
- 本体直接編集（ユーザー判断）に切り替えた際、6 つの小さな Edit に分割して途中状態でも安全側（未定義関数は偽）に倒れるようにした
- 統制下で `sed -i` が使えない場面で、迂回（チケット開始コミットと同じ Bash に sed を混ぜる）をせず Edit で完遂した
- 並行セッションによる作業ツリーの変化（コミット済み・新規未コミット・リネーム中）を都度検知し、勝手に stash / コミットせず 3 回ユーザーに確認した

## うまくいかなかったこと

- **計画の見落とし**: ai-asset-implementation でテストスクリプトが実行できない（WF003）ことに、統制が生きてから気付いた。計画段階で「各チケットで必要な Bash コマンドが allowlist にあるか」を確認していなかった
- **scratchpad での検証案**: 理由を計画に書いていたが、Write の直前に説明しなかったためユーザーに「なぜそのパスか」と問われ、却下された。リポジトリ外へのファイル作成は事前に一言添えるべきだった
- **統制下の Bash の癖**: `cd "…" &&` の前置、`2>&1`、`echo`、`jq` がそれぞれ WF003 になり、3 回やり直した。スキルの手順 4 に注意書きはあるが、統制が効いていない間の習慣が残っていた
- **仕様と要約の二重管理**: 仕様書（docs）と permission-matrix.md（skills）で管轄タイプが違うため、小さな仕様差分に 006・007 の 2 チケットが必要だった
- **改訂履歴の採番衝突**: 並行セッションが 1.5 を使っており、仕様書に 1.5 が 2 行ある
- **DoD の設計**: 003 の「次のプロンプトで継続が効く」は、チケット内で検証できない条件だった

## 改善提案

### AI アセットの棚卸しと振り返り（light-task-workflow 手順 5 と同じ観点）

| アセット | 判定 | 気付き |
|---|---|---|
| `issue-pr-driven-workflow` | 問題なし | 手順 0 の「未コミットの変更があるとき」が並行セッション対応で 3 回機能した |
| `ticket-driven-workflow` | 足りなかった | 手順 2（チケット作成）に「各チケットで必要な Bash コマンドが type の allowlist に含まれるか確認する」が無い。手順 4 の Bash 注意（`cd` 前置・`2>&1`・`echo`・`jq` 不可）は具体例を列挙した方がよい |
| `workflow-guard.sh` | 邪魔だった → 修正済み | `test` グループが無かった（追加済み）。`.gitkeep` が WF001 になった（修正済み）。残: `echo`・`jq`・`bash -n <file>` は読み取り系として許可してよい候補 |
| `workflow-entry.sh` | 邪魔だった → 修正済み | プロンプトごとの再宣言（本 issue の主題。継続ロジックで解消） |
| `workflow-types.json` | 問題なし | `test` グループを設定で付け外しできる構造が活きた |
| `permission-matrix.md`（要約） | 邪魔だった | 仕様書との二重管理。仕様書の該当節への参照に置き換えるか、生成物にする |
| `.claude/rules/claude-config-headless-awareness.md` | 問題なし | 入口ガードを ask ではなく exit 2 で設計する根拠になった |
| `light-task-workflow` | 問題なし | 手順 5-3 の合意 → issue-pr への切り替えが今回の起点として機能した |
| CLAUDE.md「作業の入口」 | 問題なし | 継続ルールを 1 行足すだけで済んだ |
| Explore サブエージェント | 問題なし | `wip/` 参照 170 行の全件洗い出しが正確で、計画の精度を上げた |

### 恒久的な改善候補（ユーザー判断待ち）

1. `ticket-driven-workflow` 手順 2 に「必要な Bash コマンドと type の allowlist の突き合わせ」を追加（文言修正 = 軽微）
2. `READONLY_RE` に `echo`・`jq`・`bash -n` を追加（フックのロジック変更 = issue 化）
3. `permission-matrix.md` を仕様書参照に置き換える（スキル手順変更 = issue 化）
4. 許可パス内に限って `sed -i` を許す Bash グループ（フックのロジック変更 = issue 化。Edit 31 回のコスト対策）
5. 仕様書の改訂履歴に並行編集時の採番ルール（日付＋連番など）を決める（文言修正 = 軽微）
6. 以前から見送り中の 3 件（ticket-driven の振り返り形式を light と揃える / CLAUDE.md に `.claude/` 配下の作業は issue-pr 経由と明記 / issue-pr に軽作業からの切り替え受け口）は引き続き保留

## 残課題・フォローアップ

- 受け入れ条件 1・2 の実セッション確認（次のユーザープロンプトで `[WF-ENTRY] … 継続中` と `CONTINUE(ticket)` ログを確認する。ただし本チケットを done にすると todo/doing が空になり継続条件を満たさなくなるため、確認は PR の完了処理前、または次のワークフローで行う）
- PR #2 の本文更新と ready for review の判断（承認③）
- 改善候補 1〜5 の採否
