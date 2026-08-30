---
name: work-ai-asset-design-exec
description: >
  AI アセット設計フェーズの実施ワーク。設計計画書に従い、task-requirements / task-spec を使って .claude/docs/ に
  要件定義書・仕様書を作成・更新し、用語辞書と横断文書を整合させる。チケット type は ai-asset-design。
  workflow-issue-mr-driven のワークループで todo_head_type が ai-asset-design のときに呼ばれる。
  Use when the user mentions "AI アセットの設計を実施", "フック/スキルの要件定義書と仕様書を書いて", ".claude/docs を更新して".
title: work-ai-asset-design-exec — AI アセット設計実施ワーク
type: skill
tags: [work-skill, ai-asset-design, exec-phase]
keywords: [AIアセット設計実施, ai-asset-design, .claude/docs, 要件定義書, 仕様書, 用語辞書, task-requirements, task-spec, レビュー記録, テストID]
---

# work-ai-asset-design-exec — AI アセット設計実施ワーク

設計計画書の骨子に従って設計チケットを順に実施し、`.claude/docs/` に要件定義書・仕様書を作り、用語辞書・横断文書を整合させる。フック・スキル本体は触らない。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・4・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-ai-asset-design-plan` |
| チケット type | `ai-asset-design`（`.claude/docs/**` と `wip/20_plans/**` に書ける。`.claude/hooks|skills|rules/**`・`settings.json` は書けない） |
| 次のワーク | `work-ai-asset-implementation-plan` |
| ワーク境界 | 設計チケットが全部 done になった時点。要件・仕様が人間レビューを受ける |

## 2. 入力

- 設計計画書 `wip/20_plans/AIアセット設計計画-<slug>.md`（結論方針・文書の一覧と骨子・横断文書との整合）
- 調査結果（根拠の参照元）
- 既存の `.claude/docs/`（更新対象）と `.claude/rules/markdown-frontmatter.md`

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート / 手順 |
|--------|--------|-------------------|
| 要件定義書 | `.claude/docs/00_requirements/<名前>.md` | `task-requirements`（`assets/requirements.template.md`。`type: requirements`） |
| 仕様書 | `.claude/docs/10_spec/<名前>.md` | `task-spec`（`assets/spec.template.md`。`type: spec`。テストシナリオに TC 番号） |
| 用語辞書 | `.claude/docs/90_glossary/*.md` | 既存の書式（一言説明 + 定義元）に追記 |
| 横断文書の更新 | `.claude/docs/10_spec/スキル体系.md` 等 | 既存ファイルを Edit。レビュー記録に版を追記 |

## 4. 手順

### 4-1. チケットに着手する

todo 先頭の `0NN-ai-asset-design-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 文書を書く

- `task-requirements` / `task-spec` の手順に従うが、ヒアリングは行わず、調査結果・設計計画書・issue の受け入れ条件を回答として使う
- 要件定義書: 受け入れ条件を When / Shall に落とす。制約条件に「フック本体を変えない」等の割り切りを明記する
- 仕様書: 入力（フックが受け取る JSON・状態ファイル）、出力（exit code・stderr・additionalContext）、処理フロー、エラーコード、テストシナリオ（既存の TC 番号の続きを採番し、どのテストスクリプトに置くかを書く）。人間の確認を伴う設計はヘッドレス実行時の挙動を書く
- 用語辞書: 新しいスキル名・type・用語を追加する
- 横断文書: 該当節を Edit し、レビュー記録に版と変更内容（issue #N）を追記する。既存の記述は消さない
- 設計計画書で「結論を書く」とした判断点は根拠つきで結論を書く

### 4-3. チケットを完了し、境界を判定する

DoD を確認し、テンプレートのプレースホルダが残っていないことを Grep で確かめ、`work-ticket-driven` 手順 5 のとおり done にしてコミットする。`work-boundary.sh status` が `at_boundary: false` なら次の設計チケットへ、`true` なら完了報告（作成・更新した文書と版、テスト ID の一覧）を返して制御を戻す。

## 5. レビュー観点

- 受け入れ条件が受け入れ基準とテストシナリオに漏れなく落ちているか
- 仕様がフック・スキルの実装に落とせるレベルか（入出力・判定順・エラーコード・テストの置き場所）
- 横断文書・用語辞書との整合（用語のぶれ、レビュー記録）
- ヘッドレス実行時の挙動が書かれているか（確認を伴う設計の場合）
- 既存文書の記述を消していないか

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-ai-asset-implementation-plan`（`todo_head_type: ai-asset-implementation-plan`）
- 渡すもの: `.claude/docs/` の要件定義書・仕様書（テストシナリオの TC 番号と置き場所）
- 差し戻し時は呼び出し元が `ai-asset-design` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `.claude/hooks/**`・`.claude/skills/**` に書こうとして WF002 で拒否された | 設計ではアセット本体を触らない。仕様書に書き、実装フェーズに回す |
| `docs/**`（一般の設計書）を直したくなった | それは `design` フェーズの対象。AI アセットに関係する記述だけなら仕様書側に書き、`docs/` の更新は別 issue にする |
| 仕様を書く途中でフック本体の変更が避けられないと分かった | 仕様書に「フック本体の変更」として明記し、要件定義書の制約条件を更新する。レビュー観点で人間に示す |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
