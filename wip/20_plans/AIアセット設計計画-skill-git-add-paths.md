---
type: plan
title: AI アセット設計計画 スキル手順の git add wip/ を許可パスに揃える
description: チケット駆動ワークフロー仕様書に「git add の対象を wip/10_tickets/ と許可パス内のファイルに限定する」規約とテストシナリオを追記する設計計画
tags: [work-ticket-driven, plan, ai-asset-design-plan]
keywords: [git add, wip/, WF009, wf_validate_add, wf_is_ticket_path, チケット運用コマンド, 許可パス, セッション記憶, チケット駆動ワークフロー, テストシナリオ, TC022]
---

# AI アセット設計計画: スキル手順の git add wip/ を許可パスに揃える

- 作成元チケット: 002-ai-asset-design-plan-AIアセット設計計画.md
- 作成日: 2026-08-30
- 全体計画: wip/00_overall_plan/skill-git-add-paths.md（issue #47 / PR #48）

## 調査サマリ

（調査フェーズは省略。発端の軽作業と全体計画の Context で確認済みの事実）

- `workflow-guard.sh` の `wf_validate_add` は `git add` の引数ごとに判定する。`wip/10_tickets/*` は `wf_is_ticket_path` で無条件許可、それ以外は `wf_resolve` で allow / deny / ask / unlisted を判定し、ask・unlisted は WF009 の `permissionDecision: ask` になる
- `wip/` は `wip/10_tickets/*` にも `workflow-types.json` の allow glob（global `wip/10_tickets/**`、type の `wip/20_plans/**` 等）にも一致しないため unlisted → 毎回 WF009
- Bash の承認はセッション記憶されない（`workflow-diff-check.sh` は `FILE_PATH` のある Edit/Write のみ `wf_session_remember` する）
- 仕様書 `.claude/docs/10_spec/チケット駆動ワークフロー.md` は「チケット運用コマンド」で `git add`（`wip/10_tickets/` 配下は無条件、それ以外は許可パス内に限る）と定義しており、フックの挙動は仕様どおり。ただし処理フロー（基本フロー 3・6）は「チケット群を `git add` + `git commit`」とだけ書かれ、**対象パスの書き方（`wip/` 全体を指定しない）が規約として書かれていない**。スキル手順書（`work-ticket-driven` / `work-overall-plan`）の `git add wip/` はこの空白から生じた
- テストシナリオには TC022（`git add src/main.ts` → ask WF009）はあるが、`git add wip/` が ask になること・許可パスを明示した `git add` が exit 0 になることのケースは無い
- 要件定義書 `.claude/docs/00_requirements/チケット駆動ワークフロー.md` は着手・完了時のコミット作成を要求するだけで `git add` の対象には触れていない。用語辞書（`90_glossary/`）、`フェーズ別ワークスキル.md`（要件・仕様）に `git add` の記述は無い

## 変更方針

### 判断点の結論方針

| 判断点 | 結論 | 根拠 |
|--------|------|------|
| フック本体の変更の要否 | **不要**。type 定義の追加も不要 | フックの判定は仕様どおりで妥当。`wip/` を allow にすると global deny の `wip/00_overall_plan/**` まで無条件でステージできてしまう。Bash 承認のセッション記憶は記憶単位が `dirname "wip/"` = `.` になり広すぎる（issue #47 スコープ外として合意済み） |
| 規約を書く節 | 「Bash コマンドの許可（deny-by-default）」の**チケット運用コマンド**の箇条書きに規約を追記し、「処理フロー」基本フロー 3・6 のコマンド表記を規約に合わせる | 許可の定義（allowlist）と手順（処理フロー）の両方に書かないと、手順書だけ読んだ人が再び `git add wip/` を書く |
| 要件定義書の変更 | **不要** | `git add` の対象に関する要件は既存の「基準点からの差分が許可パスの範囲内であることを確認した上でコミット」に含意される。仕様の規約で足りる |
| 用語辞書の変更 | **不要** | 新しい用語・type・スキル名は増えない |
| テストシナリオ | 追加する（TC022b / TC022c）。実装は AI アセット実装フェーズで `.claude/hooks/tests/test-workflow-guard.sh` に追加する | 受け入れ条件④「手順どおりのコミットで WF009 が出ない」を、手動ログ確認だけでなく再現可能なテストにする |

### ヘッドレス実行の扱い

本変更は人間の確認（`ask` / `AskUserQuestion`）を**減らす**方向であり、新しい確認は増えない。ヘッドレス実行では `ask` が自動拒否になるため、従来の `git add wip/` はヘッドレスでチケットの done コミットが**失敗していた**はず（WF009 → 拒否）。規約に合わせた手順ではこの問題も解消される。この点を仕様書の規約に一文添える（`claude-config-headless-awareness.md` の「ask を返す設計はヘッドレスでの帰結を検討する」に沿う）。

## 変更対象ファイル（文書の一覧）

| 文書 | 新規 / 更新 | 骨子 |
|------|------------|------|
| `.claude/docs/10_spec/チケット駆動ワークフロー.md` | 更新（2.2 → 2.3） | (a) 「Bash コマンドの許可」チケット運用コマンドの箇条書きに規約を追記: 「チケット運用のコミットでは `git add` の対象を `wip/10_tickets/` と作業タイプの許可パス内のファイルに限定し、`wip/` のようなディレクトリ全体を指定しない。`wip/` は `wip/10_tickets/*` にも type の allow glob にも一致せず未記載（WF009）の確認になり、Bash の承認はセッション記憶されないため毎回確認になる。ヘッドレス実行では拒否される」 (b) 「処理フロー」基本フロー 3 を「チケット群を `git add wip/10_tickets/` + `git commit`」、6 を「`git add wip/10_tickets/ <許可パス内の変更ファイル>` でコミット」に改める (c) テストシナリオに TC022b（`git add wip/` → ask WF009）、TC022c（`investigation` で `git add wip/10_tickets/ wip/20_plans/x.md` → exit 0）を追加 (d) レビュー記録に 2.3 を追記（issue #47） |
| `.claude/docs/00_requirements/チケット駆動ワークフロー.md` | 変更なし | 上記「判断点の結論方針」のとおり |
| `.claude/docs/90_glossary/*` | 変更なし | 同上 |

**allowed_paths 案**: 設計チケットは type `ai-asset-design` の標準（`.claude/docs/**`、`wip/20_plans/**`）で足りる。追加不要

### 横断文書との整合

- `スキル体系.md`、`issue-PR駆動ワークフロー.md`、`フェーズ別ワークスキル.md`: `git add` の対象パスに言及していないため変更なし
- `work-ticket-driven` / `work-overall-plan` の SKILL.md（手順書本体）は AI アセット実装フェーズで修正する（受け入れ条件①②）。仕様書 (a)(b) がその正になる

### 受け入れ条件との対応

| 受け入れ条件 | 落とし先 |
|-------------|---------|
| ③ 仕様書に「`git add` の対象を `wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` 全体を指定しない」旨が書かれている | 仕様書 (a)(b) |
| ④ 手順どおりのチケット作成・完了コミットで WF009 が出ない | 仕様書 (c) TC022c（実装フェーズでテストスクリプト化） |
| ①② SKILL.md の修正 | AI アセット実装フェーズ（本計画では対象外。仕様書 (a)(b) を正として実装計画が参照する） |

## 実装ステップ（設計チケットの一覧）

1. **003-ai-asset-design-チケット駆動ワークフロー仕様書の更新**: 上記 (a)〜(d) を `task-spec` の更新手順に沿って行う。DoD は文書の骨子と 1 対 1

## 検証方法

- 仕様書の (a)(b) を読んだだけで `git add wip/10_tickets/ <許可パス内のファイル>` の形に到達できること（目視）
- TC022b / TC022c の期待値が現行フックの挙動（`wf_validate_add` の判定）と一致していること（`workflow-guard.sh` の読み合わせ）
- レビュー記録の版が 2.3 になっていること

## リスク・未解決事項

- 仕様書は 1,000 行近い大きな文書のため、Edit の対象箇所を誤ると他節を壊す。(a)〜(d) は節見出しを基準に局所的に Edit する
- TC022c の type は `investigation`（許可パス `wip/20_plans/**`）を例にする。`overall-plan`（`wip/00_overall_plan/**`）の例も併記するかは設計チケットで判断（併記推奨。`work-overall-plan` の手順が該当するため）
