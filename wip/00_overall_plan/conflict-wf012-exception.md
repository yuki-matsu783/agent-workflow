---
type: plan
title: 全体計画 コンフリクト解消時のWF012例外
description: マージ進行中に限りreview-state.json/merge-prep.jsonの直接編集を許可する
tags: [work-overall-plan, overall-plan]
keywords: [WF012, merge-prep, review-state, workflow-boundary, コンフリクト]
---

# 全体計画: コンフリクト解消時にWF012保護ファイルの編集を許可する

- 対象 issue: #51 https://github.com/yuki-matsu783/agent-workflow/issues/51
- PR: #52 https://github.com/yuki-matsu783/agent-workflow/pull/52
- ブランチ: feature-51-conflict-wf012-exception
- 作成日: 2026-08-30

## Context

- `workflow-boundary.sh` の WF012 は `wip/10_tickets/review-state.json` / `wip/merge-prep.json` の2ファイルを、doing の有無を問わず常時保護する（LLM の自己申告だけでレビュー完了・マージ準備完了の状態を進められないようにする信頼境界。issue #30 由来）
- 実際の `git merge` によるコンフリクト解消であっても、この2ファイルにコンフリクトマーカーが残った場合は WF012 が Edit/Write/Bash からの直接書き換えを一律拒否し、Claude はユーザーに手動解消を委ねるしかない（別セッションでの実例あり）
- ユーザーの要望は「コンフリクト解消だけは全部編集OKにしたい」。ただし WF012 の本来の目的（内容の恣意的な書き換え防止）を弱めすぎない設計が必要（例: `git` が実際にマージ進行中（`MERGE_HEAD` 存在）であることを条件にする、等）
- 対象は `.claude/hooks/workflow-boundary.sh` のロジック変更（AI アセット）

## フェーズ列

| 順 | フェーズ | 計画スキル / 実施スキル | type（計画 / 実施） | 狙い | 省略理由（省略時） |
|----|---------|------------------------|--------------------|------|-------------------|
| 1 | 調査 | work-investigation-plan / work-investigation-exec | investigation-plan / investigation | WF012 の現状実装・検出手段（MERGE_HEAD等）・悪用可能性を調べる | |
| 2 | AI アセット設計 | work-ai-asset-design-plan / work-ai-asset-design-exec | ai-asset-design-plan / ai-asset-design | `.claude/docs/` の要件・仕様に、マージ進行中の例外条件と検証方法・トレードオフを明記する | |
| 3 | AI アセット実装 | work-ai-asset-implementation-plan / work-ai-asset-implementation-exec | ai-asset-implementation-plan / ai-asset-implementation | `workflow-boundary.sh` を変更し、フックのテストで確認する | |
| 末尾 | 振り返り | （work-ticket-driven 手順 4） | retrospective | 結果報告・AI アセットの棚卸し | 省略しない |

設計フェーズ（`docs/`）とその反映は対象外（AI アセットのみの変更のため）。

## 受け入れ条件との対応

| 受け入れ条件 | 満たすフェーズ | 成果物 |
|-------------|--------------|--------|
| MERGE_HEAD 存在時に限り review-state.json / merge-prep.json への直接書き換えを許可し、それ以外は現行どおり常時拒否 | AI アセット実装 | `.claude/hooks/workflow-boundary.sh` |
| コンフリクトマーカー除去以外の内容改変を防ぐ検証方法の設計 | 調査・AI アセット設計 | `.claude/docs/10_spec/skill-work-ticket-driven.md`（例外条件・検証方法） |
| 信頼境界上のトレードオフを仕様書に明記 | AI アセット設計 | 同上 |
| 既存のWF012保護（マージ進行中でない場合）を壊さないことをテストで確認 | AI アセット実装 | `.claude/hooks/tests/`（既存テスト + 追加テスト） |

## 判断が必要になりそうな点

- 「コンフリクトマーカー除去以外の改変を防ぐ」をどこまで機械的に検証するか（例: 許可後に書き込まれた内容がコンフリクトマーカーを含まない有効な JSON であることのみ確認する、等の現実的な落とし所。調査・AI アセット設計フェーズで決める）
- 検出条件を `MERGE_HEAD` のみとするか、`CHERRY_PICK_HEAD` 等の類似操作も含めるか（調査フェーズで洗い出し、AI アセット設計フェーズで決める）

## 最初の計画チケット

- 002-investigation-plan-調査計画.md
