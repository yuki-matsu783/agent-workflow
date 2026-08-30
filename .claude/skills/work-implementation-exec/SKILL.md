---
name: work-implementation-exec
description: >
  実装・テストフェーズの実施ワーク。実装計画書に従い実装チケットを 1 枚ずつ実施し、テスト（失敗ケース含む）を
  書いてコードを変更し、ビルド / テストで確認する。チケット type は implementation。
  workflow-issue-mr-driven のワークループで todo_head_type が implementation のときに呼ばれる。
  Use when the user mentions "実装を進めて", "実装チケットをやって", "テストを書いて実装して", "implement".
title: work-implementation-exec — 実装・テスト実施ワーク
type: skill
tags: [work-skill, implementation, exec-phase]
keywords: [実装実施, implementation, テスト, TDD, ビルド, bash_groups build, allowed_paths, 仕様からの逸脱, 設計反映の入力]
---

# work-implementation-exec — 実装・テスト実施ワーク

実装計画書のステップに従って実装チケットを順に実施する。テストを先に書き、コードを変え、ビルド / テストで確かめる。仕様からの逸脱は必ず作業ログに残す（設計反映フェーズの入力になる）。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・4・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-implementation-plan` |
| チケット type | `implementation`（`src/**`, `tests/**`, `doc/**`, `wip/20_plans/**` + チケットの `allowed_paths`。`bash_groups: build` でビルド / テスト系コマンドが使える。`docs/**` は書けない） |
| 次のワーク | `work-design-sync-plan`（設計反映を省略していれば振り返り） |
| ワーク境界 | 実装チケットが全部 done になった時点。コードとテストが人間レビューを受ける |

## 2. 入力

- 実装計画書 `wip/20_plans/実装計画-<slug>.md`（変更対象・テスト方針・ステップ・検証方法）
- 実装チケット群（DoD にテスト ID とコマンド）
- 設計書 `docs/**`（インターフェース・処理フロー・テストシナリオ）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | 備考 |
|--------|--------|------|
| コード | `src/**` 等（計画書の変更対象） | テンプレートなし。既存のコード規約に従う |
| テスト | `tests/**` 等 | テスト ID を名前やコメントに残す（仕様書との対応） |
| 逸脱の記録 | 各チケットの作業ログ「うまくいかなかったこと」 | 仕様と違う実装にした点・仕様の誤り・追加で決めた点。設計反映の入力 |

## 4. 手順

### 4-1. チケットに着手する

todo 先頭の `0NN-implementation-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。`allowed_paths` が frontmatter にあるか確認する。

### 4-2. テストを書き、実装する

1. DoD のテスト ID に対応するテストを先に書く（失敗ケース・境界値を含める）。実行して失敗することを確認する
2. 計画書のステップどおりにコードを変更する。仕様書のインターフェースを守る
3. テストを実行して通す。既存テストも通す（`bash_groups: build` の範囲: `npm` / `npx` / `node` / `python` / `pytest` / `go` / `cargo` / `make` 等）
4. 仕様どおりに実装できない・仕様が誤っている・仕様に無い判断をした、のいずれかがあれば**その場で作業ログに書く**。設計書は直さない（`docs/**` には書けない。設計反映フェーズで書き戻す）

### 4-3. チケットを完了し、境界を判定する

DoD を確認し、`git status` で差分が `allowed_paths` 内に収まっていることを見て、`work-ticket-driven` 手順 5 のとおり done にしてコミットする。`work-boundary.sh status` が `at_boundary: false` なら次の実装チケットへ（`git push` してよい）、`true` なら完了報告（完了チケット・テスト結果・逸脱の一覧・`todo_head_type`）を返して制御を戻す。

## 5. レビュー観点

- DoD のテスト ID がすべてテストとして存在し、失敗ケースを含めて通っているか（テスト結果の出力）
- 差分が計画書の変更対象に収まっているか。計画外の変更があれば理由が作業ログにあるか
- 仕様からの逸脱の一覧が揃っているか（設計反映でこれを書き戻す）
- コード品質（可読性・単一責任・マジックナンバー・エラーハンドリング。`CLAUDE.md`「システム開発における基本原則」）

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-design-sync-plan`（`todo_head_type: design-sync-plan`）。省略時は `work-ticket-driven` の retrospective
- 渡すもの: コード差分（ワーク開始コミット〜HEAD）、テスト結果、作業ログの逸脱一覧
- 差し戻し時は呼び出し元が `implementation` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `docs/**` への Edit が WF009 で確認された | 実装では設計書を直さない。逸脱として作業ログに書き、設計反映フェーズで書き戻す。確認は承認しない |
| 計画に無いファイルを触る必要が出た（WF009） | 理由が明確なら承認してよい（セッション記憶に入る）。作業ログに理由を書き、レビュー観点で示す。範囲が大きく変わるなら呼び出し元に `implementation-plan` の追加チケットを提案する |
| テストが通らないまま DoD を満たせない | done にしない。原因と試したことを作業ログに書き、判断が要るなら呼び出し元に報告する（同 type の追加チケットで続ける） |
| `[WF-DIFF]` で許可パス外の差分を指摘された | 指示に従い基準コミットの状態に戻す |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
