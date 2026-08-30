---
name: work-investigation-exec
description: >
  調査フェーズの実施ワーク。調査計画書に従い調査チケットを 1 枚ずつ実施し、読み取りだけで
  調査結果（wip/20_plans/調査結果-<slug>.md）をまとめる。チケット type は investigation。
  workflow-issue-mr-driven のワークループで work-boundary.sh status の todo_head_type が investigation のときに呼ばれる。
  Use when the user mentions "調査を実施", "調査して結果をまとめて", "調査チケットを進めて", "run investigation".
title: work-investigation-exec — 調査実施ワーク
type: skill
tags: [work-skill, investigation, exec-phase]
keywords: [調査実施, investigation, 調査結果, wip/20_plans, 読み取り専用, 調査観点, 根拠, work-boundary.sh]
---

# work-investigation-exec — 調査実施ワーク

調査計画書の観点に沿って調査チケットを順に実施し、**次の計画ワークが判断できる調査結果**を書く。書き込みは `wip/20_plans/**` のみ。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用（着手・完了・境界判定・フックのブロック時の対処）: `work-ticket-driven` の手順 3・4・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-investigation-plan` |
| チケット type | `investigation`（`wip/20_plans/**` のみ書ける。Bash は読み取り系のみ） |
| 次のワーク | フェーズ列の次の計画ワーク（`work-design-plan` / `work-ai-asset-design-plan` / `work-implementation-plan` など） |
| ワーク境界 | 調査チケットが全部 done になった時点（`work-boundary.sh status` で判定）。調査結果が人間レビューを受ける |

## 2. 入力

- 調査計画書 `wip/20_plans/調査計画-<slug>.md`（観点・対象・方法・成果物の形）
- 調査チケット群（todo）。各チケットの DoD が観点に対応している
- 全体計画（受け入れ条件との対応）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 調査結果 | `wip/20_plans/調査結果-<slug>.md`（ワークで 1 ファイル。チケットごとに節を追記） | `work-ticket-driven/assets/plan.template.md` を Read → Write。「調査サマリ」を観点ごとの小見出しで書き、「変更方針」は候補と比較軸まで（決定は次の計画ワーク）、「リスク・未解決事項」に答えの出なかった観点 |

## 4. 手順

### 4-1. チケットに着手する

todo 先頭の `0NN-investigation-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 調査する

チケットの観点について、Read / Glob / Grep と読み取り系コマンド（`git log` / `git diff` / `ls` / `cat` 等）で調べる。

- 答えには**根拠**（ファイルパス・行・コマンド出力の要約）を必ず添える
- 選択肢が複数ある問いは、比較軸（変更量・リスク・既存パターンとの整合）を並べて候補を残す。決めない
- 想定外の事実（バグ・技術的負債）を見つけたら「リスク・未解決事項」に書く。直さない

### 4-3. 調査結果に書く

最初のチケットで `調査結果-<slug>.md` を Write し、以降は Edit で節を追記する。作業ログもその都度チケットに書く。

### 4-4. チケットを完了し、境界を判定する

DoD を確認し、`work-ticket-driven` 手順 5 のとおり done にしてコミットする。続けて:

```bash
bash .claude/hooks/work-boundary.sh status
```

- `at_boundary: false` → 4-1 に戻り次の調査チケットへ（`git push` はしてよい）
- `at_boundary: true` → 手順 6 のとおりワーク完了報告（完了チケット一覧・調査結果の要約・`todo_head_type`）を返して制御を呼び出し元に戻す

## 5. レビュー観点

- 調査観点のすべてに答え（または「答えが出なかった理由」）があるか
- 根拠が具体的か（パス・行・出力）。推測が事実のように書かれていないか
- 次の計画ワークが判断に使える形か（候補と比較軸が揃っているか）
- 調査の範囲を超えて実装・設計の決定をしていないか

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `todo_head_type` に対応する `work-<next>-plan`
- 渡すもの: `wip/20_plans/調査結果-<slug>.md`
- 差し戻し時は呼び出し元が `investigation` type の追加チケット（例: 追加の観点）を起こす。done 済みチケットは戻さない

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `src/**` 等への Edit が WF009 で確認された | 調査ではコードを触らない。確認を承認せず、修正案は調査結果に書いて後続フェーズに回す |
| ビルド / テストの実行が WF003 で拒否された | `investigation` は `bash_groups` を持たない。既存のテスト結果はログや CI の記録を読む。実行が必要なら実装フェーズで行う |
| 調査中に計画の見直しが必要になった | プランモードは使えない（WF006）。調査結果の「リスク・未解決事項」に書き、レビュー観点で人間に示す |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
