---
type: guide
title: 用語辞書 - チケットtype
tags: [glossary, ticket-type]
keywords: [チケットtype, investigation, implementation, retrospective, ai-asset-design, ai-asset-implementation, overall-plan, investigation-plan, design, design-sync, workflow-types.json]
---

# チケット type

`work-ticket-driven` におけるチケットの作業タイプ（frontmatterの `type`）の一覧。許可されるパス・bashコマンドの正は `.claude/hooks/workflow-types.json` を参照。

### investigation

調査。読み取り中心で、計画書を `wip/20_plans/` に作成する。

- 定義元: `.claude/hooks/workflow-types.json`（`types.investigation`）

### implementation

実装。`wip/20_plans/` の計画に従い `src/**` 等のソースコードを変更する。

- 定義元: `.claude/hooks/workflow-types.json`（`types.implementation`）

### retrospective

振り返り。結果報告を `wip/30_reports/` に作成する。

- 定義元: `.claude/hooks/workflow-types.json`（`types.retrospective`）

### ai-asset-design

AIアセットの設計。要件定義書・仕様書（`.claude/docs/**`）のみ変更できる。

- 定義元: `.claude/hooks/workflow-types.json`（`types.ai-asset-design`）

### ai-asset-implementation

AIアセットの実装。フック・ルール・スキル・`settings.json`（`.claude/hooks/**` / `.claude/rules/**` / `.claude/skills/**` / `.claude/settings.json`）を変更できる。

- 定義元: `.claude/hooks/workflow-types.json`（`types.ai-asset-implementation`）

### overall-plan

全体計画。フェーズ列を決めて `wip/00_overall_plan/**` に全体計画を書き、最初の計画チケットを起こす（`work-overall-plan`）。global deny の `wip/00_overall_plan/**` を type の allow で貫通する唯一の type。

- 定義元: `.claude/hooks/workflow-types.json`（`types.overall-plan`）、`../10_spec/フェーズ別ワークスキル.md`

### investigation-plan / design-plan / implementation-plan / design-sync-plan / ai-asset-design-plan / ai-asset-implementation-plan

各フェーズの計画。計画書を `wip/20_plans/**` に書き、同フェーズの実施チケット群と次フェーズの計画チケット（最後のフェーズなら振り返りチケット）を起こす（`work-<phase>-plan`）。許可範囲はすべて `wip/20_plans/**`。フェーズごとに type を分けるのは、`work-boundary.sh status` の `todo_head_type` からスキルを一意に選ぶため。

- 定義元: `.claude/hooks/workflow-types.json`（`types.<phase>-plan`）、`../10_spec/フェーズ別ワークスキル.md`

### design

設計。`docs/**` に要件定義書・仕様書を作成・更新する（`work-design-exec`）。`.claude/**` には書けない。

- 定義元: `.claude/hooks/workflow-types.json`（`types.design`）

### design-sync

設計反映。実装・テストで判明した差分・決定事項を `docs/**` の設計書に書き戻す（`work-design-sync-exec`）。

- 定義元: `.claude/hooks/workflow-types.json`（`types.design-sync`）

## 補足

チケット type は `.claude/docs/10_spec/スキル体系.md` が定義する3層構造（`workflow-*`/`work-*`/`task-*`）とは別の識別子体系。混同しないこと。

- 定義元: `../10_spec/スキル体系.md`
