---
name: work-design-plan
description: >
  設計フェーズの計画ワーク。調査結果をもとに、docs/ に作成・変更する設計書（要件定義書・仕様書）の一覧と
  各設計書の骨子を設計計画書（wip/20_plans/）にまとめ、設計チケット群と次フェーズの計画チケットを起こす。
  チケット type は design-plan。workflow-issue-mr-driven のワークループで todo_head_type が design-plan のときに呼ばれる。
  Use when the user mentions "設計計画", "設計の計画を立てて", "どの設計書を書くか決めて", "design plan".
title: work-design-plan — 設計計画ワーク
type: skill
tags: [work-skill, design, plan-phase]
keywords: [設計計画, design-plan, docs, 要件定義書, 仕様書, 設計チケット, 次の計画チケット, 骨子, 判断点]
---

# work-design-plan — 設計計画ワーク

調査結果を受けて、**どの設計書を・どんな骨子で書くか**を決め、設計計画書を書き、設計チケット群と次フェーズの計画チケットを起こす。設計書そのものは書かない。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-investigation-exec`（調査を省略した場合は `work-overall-plan`） |
| チケット type | `design-plan`（`wip/20_plans/**` に書ける） |
| 次のワーク | `work-design-exec`（type `design`） |
| ワーク境界 | 計画チケットが done になった時点。設計計画（設計書の一覧・骨子・判断の方針）が人間レビューを受ける |

## 2. 入力

- 調査結果 `wip/20_plans/調査結果-<slug>.md`（候補と比較軸・リスク）
- 全体計画（受け入れ条件との対応・判断点）
- 既存の設計書（`docs/` 配下。構成が無ければ `docs/00_requirements/`・`docs/10_spec/` を推奨する。`.claude/docs/` は AI アセット用なので対象外）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 設計計画書 | `wip/20_plans/設計計画-<slug>.md` | `work-ticket-driven/assets/plan.template.md`。「変更対象ファイル」節を**設計書の一覧**（新規 / 更新、パス、骨子）に、「実装ステップ」節を**設計チケットの一覧**に使う |
| 設計チケット群 | `wip/10_tickets/00_todo/0NN-design-<slug>.md`（1 枚以上） | `work-ticket-driven/assets/ticket.template.md` |
| 次の計画チケット | `0NN-implementation-plan-<slug>.md`（フェーズ列の次。最後なら振り返りチケット） | 同上 |

## 4. 手順

### 4-1. 着手する

todo 先頭の `0NN-design-plan-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 設計計画書を書く

`plan.template.md` を Read し、`wip/20_plans/設計計画-<slug>.md` に Write する。書くこと:

- **判断点の結論方針**: 調査結果の候補から、設計で採る案とその根拠（比較軸ごと）。決めきれない点は設計チケットの DoD に「結論を書く」として残す
- **設計書の一覧**: 新規 / 更新の別、パス（`docs/00_requirements/<機能>.md`、`docs/10_spec/<機能>.md` など）、各設計書の骨子（節と要点）。要件定義書は `task-requirements`、仕様書は `task-spec` のテンプレートに従う
- **受け入れ条件との対応**: 受け入れ条件が要件定義書の受け入れ基準と仕様書のテストシナリオのどこに落ちるか
- **設計チケットの一覧**: 1 チケット = 1 設計書（小さければ要件 + 仕様で 1 枚）。各 DoD
- **allowed_paths 案**: 通常は `design` type の `docs/**` で足りる。足りない場合だけ書く

### 4-3. チケットを起こす

1. 設計チケット群（`type: design`）。DoD の型:
   ```markdown
   - [ ] docs/<path> が task-requirements / task-spec のテンプレートに沿って作成（更新）されている
   - [ ] 設計計画書の骨子の各節が埋まっている（プレースホルダ無し）
   - [ ] 受け入れ条件 <X> が受け入れ基準 / テストシナリオに落ちている
   - [ ] レビュー記録に版と変更内容が追記されている（更新時）
   ```
2. 次の計画チケット 1 枚（通常 `type: implementation-plan`。フェーズ列に次が無ければ `retrospective`）。`depends_on` は最後の設計チケット

### 4-4. 完了する

計画チケットの DoD を確認し、`work-ticket-driven` 手順 5 のとおり done にしてコミットし、`work-boundary.sh status` で `at_boundary: true`・`todo_head_type: design` を確認して、手順 6 のとおり完了報告を返す。

計画チケットの DoD の型:

```markdown
- [ ] wip/20_plans/設計計画-<slug>.md に判断点の結論方針・設計書の一覧と骨子・受け入れ条件との対応が書かれている
- [ ] 設計チケット N 枚が todo に起票され、各 DoD が設計書と対応している
- [ ] 次の計画チケット（または振り返りチケット）が todo に起票されている
```

## 5. レビュー観点

- 判断点の結論方針が調査結果の根拠と整合しているか。決めきれない点が明示されているか
- 設計書の一覧が過不足ないか（要件定義書と仕様書の両方が要るか、既存設計書の更新で済むか）
- 骨子が受け入れ条件を漏れなく受け止めているか
- 設計チケットの粒度と次の計画チケットの type

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-design-exec`
- 渡すもの: 設計計画書（結論方針・設計書の一覧と骨子）と設計チケット群
- 差し戻し時は呼び出し元が `design-plan` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `docs/**` へ Write しようとして WF009 が出た | 計画ワークでは設計書を書かない（`design-plan` に `docs/**` は無い）。設計チケットで書く |
| 既存の設計書の置き場が `docs/` 以外にある | 既存の構成に従う。`design` type の allow は `docs/**` なので、別の場所なら設計チケットの `allowed_paths` に書く（deny は貫通できない） |
| 調査結果が無い（調査を省略した） | 全体計画の省略理由を確認し、依頼と受け入れ条件だけで計画を書く。不足があればレビュー観点に書く |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
