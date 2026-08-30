---
name: work-design-exec
description: >
  設計フェーズの実施ワーク。設計計画書に従い、task-requirements / task-spec を使って docs/ に要件定義書・仕様書を
  作成・更新する。チケット type は design。workflow-issue-mr-driven のワークループで todo_head_type が design のときに呼ばれる。
  Use when the user mentions "設計を実施", "設計書を書いて", "要件定義書と仕様書を作って", "design docs".
title: work-design-exec — 設計実施ワーク
type: skill
tags: [work-skill, design, exec-phase]
keywords: [設計実施, design, docs, 要件定義書, 仕様書, task-requirements, task-spec, 受け入れ基準, テストシナリオ, レビュー記録]
---

# work-design-exec — 設計実施ワーク

設計計画書の骨子に従って設計チケットを順に実施し、`docs/` に要件定義書・仕様書を作る。作成には `task-requirements` / `task-spec` のテンプレートと手順を使う。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・4・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-design-plan` |
| チケット type | `design`（`docs/**` と `wip/20_plans/**` に書ける。`.claude/**` は書けない） |
| 次のワーク | `work-implementation-plan`（フェーズ列の次） |
| ワーク境界 | 設計チケットが全部 done になった時点。設計書が人間レビューを受ける |

## 2. 入力

- 設計計画書 `wip/20_plans/設計計画-<slug>.md`（結論方針・設計書の一覧と骨子・受け入れ条件との対応）
- 調査結果（根拠の参照元）
- 既存の設計書（更新の場合）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート / 手順 |
|--------|--------|-------------------|
| 要件定義書 | `docs/00_requirements/<機能>.md`（既存の構成があればそれに従う） | `task-requirements`（`assets/requirements.template.md`。ユーザーストーリー・EARS 形式の受け入れ基準） |
| 仕様書 | `docs/10_spec/<機能>.md` | `task-spec`（`assets/spec.template.md`。入出力・処理フロー・IF・エラー・テストシナリオ） |

frontmatter は `type: requirements` / `type: spec`（`.claude/rules/markdown-frontmatter.md`）。

## 4. 手順

### 4-1. チケットに着手する

todo 先頭の `0NN-design-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 設計書を書く

- 設計計画書の骨子を節に展開する。`task-requirements` / `task-spec` の手順に従うが、ヒアリングは行わず、調査結果・設計計画書・issue の受け入れ条件を回答として使う
- 要件定義書: 受け入れ条件を When / Shall（If / Then、Shall not）に落とす。前提・制約・依存関係を書く
- 仕様書: 入出力・処理フロー・インターフェース・エラーハンドリング・テストシナリオ（テスト ID を振る。実装フェーズの DoD とテストの対応に使う）
- 設計計画書で「結論を書く」とした判断点は、根拠つきで結論を書く
- 既存設計書の更新は既存の記述を消さず、レビュー記録に版と変更内容を追記する

### 4-3. チケットを完了し、境界を判定する

DoD（設計計画書の DoD の型）を確認し、テンプレートのプレースホルダ（`<!-- … -->` や `<…>`）が残っていないことを Grep で確かめて、`work-ticket-driven` 手順 5 のとおり done にしてコミットする。`work-boundary.sh status` が `at_boundary: false` なら次の設計チケットへ、`true` なら完了報告を返して制御を戻す。

## 5. レビュー観点

- 受け入れ条件が要件定義書の受け入れ基準と仕様書のテストシナリオに漏れなく落ちているか
- 判断点の結論が根拠つきで書かれ、調査結果と矛盾しないか
- 仕様が実装可能なレベル（入出力・エラー・IF）まで具体化されているか。逆に実装の詳細（コード）に踏み込みすぎていないか
- 既存設計書との整合（用語・IF・レビュー記録）

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-implementation-plan`（`todo_head_type: implementation-plan`）
- 渡すもの: `docs/` の要件定義書・仕様書（特にテストシナリオのテスト ID）
- 差し戻し時は呼び出し元が `design` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `.claude/docs/**` へ書こうとして WF002 で拒否された | AI アセットの設計は `ai-asset-design` フェーズで扱う。`design` では `docs/**` のみ |
| `src/**` に書きたくなった（例: 型定義の雛形） | 設計ではコードを書かない。仕様書のインターフェース定義に書き、実装フェーズに回す |
| 設計計画書の骨子どおりに書けない（前提が崩れた） | 設計書に「未解決事項」として残し、レビュー観点に書く。必要なら呼び出し元に `design-plan` の追加チケットを提案する |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
