---
type: guide
title: 用語辞書 - チケットtype
tags: [glossary, ticket-type]
keywords: [チケットtype, investigation, implementation, retrospective, ai-asset-design, ai-asset-implementation, workflow-types.json]
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

## 補足

チケット type は `.claude/docs/10_spec/スキル体系.md` が定義する3層構造（`workflow-*`/`work-*`/`task-*`）とは別の識別子体系。混同しないこと。

- 定義元: `../10_spec/スキル体系.md`
