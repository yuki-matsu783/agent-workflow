---
name: work-implementation-plan
description: >
  実装・テストフェーズの計画ワーク。設計書（docs/）と調査結果をもとに、変更対象ファイル・allowed_paths 案・
  テスト方針・実装ステップを実装計画書（wip/20_plans/）にまとめ、実装チケット群と次フェーズの計画チケットを起こす。
  チケット type は implementation-plan。workflow-issue-mr-driven のワークループで todo_head_type が implementation-plan のときに呼ばれる。
  Use when the user mentions "実装計画", "実装の計画を立てて", "テスト方針を決めて", "implementation plan".
title: work-implementation-plan — 実装・テスト計画ワーク
type: skill
tags: [work-skill, implementation, plan-phase]
keywords: [実装計画, implementation-plan, allowed_paths, テスト方針, TDD, 実装チケット, 次の計画チケット, テストID, wip/20_plans]
---

# work-implementation-plan — 実装・テスト計画ワーク

設計書をコードに落とすための**変更対象・テスト方針・ステップ**を決め、実装計画書を書き、実装チケット群と次フェーズの計画チケットを起こす。コードは書かない。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-design-exec`（設計を省略した場合は `work-investigation-exec` または `work-overall-plan`） |
| チケット type | `implementation-plan`（`wip/20_plans/**` に書ける） |
| 次のワーク | `work-implementation-exec`（type `implementation`） |
| ワーク境界 | 計画チケットが done になった時点。実装計画（変更対象・テスト方針）が人間レビューを受ける |

## 2. 入力

- 設計書 `docs/**`（仕様書のインターフェース定義・処理フロー・テストシナリオのテスト ID）
- 調査結果・設計計画書（判断点の結論、リスク）
- 全体計画（受け入れ条件との対応）
- リポジトリのビルド / テストの仕組み（`package.json`・`Makefile`・既存テストの配置）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 実装計画書 | `wip/20_plans/実装計画-<slug>.md` | `work-ticket-driven/assets/plan.template.md` をそのまま使う（「変更対象ファイル」「allowed_paths 案」「実装ステップ」「検証方法」が実装計画向けに作られている） |
| 実装チケット群 | `wip/10_tickets/00_todo/0NN-implementation-<slug>.md`（1 枚以上） | `work-ticket-driven/assets/ticket.template.md` |
| 次の計画チケット | `0NN-design-sync-plan-<slug>.md`（フェーズ列の次。設計反映を省略していれば振り返りチケット） | 同上 |

## 4. 手順

### 4-1. 着手する

todo 先頭の `0NN-implementation-plan-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 実装計画書を書く

`plan.template.md` を Read し、`wip/20_plans/実装計画-<slug>.md` に Write する。書くこと:

- **変更対象ファイル**: パスと変更内容（新規 / 変更）。仕様書のインターフェースごとに対応づける
- **allowed_paths 案**: `implementation` type の標準（`src/**`, `tests/**`, `doc/**`）で足りなければ、実装チケットの frontmatter に書く glob（`.claude/**` 等の deny は貫通できない）
- **テスト方針**: 仕様書のテストシナリオ（テスト ID）をどのテスト（単体 / 結合 / E2E）で実装するか、失敗ケース・境界値を含める。TDD を推奨（先にテストを書くステップを入れる）。実行コマンド
- **実装ステップ**: 1 ステップ = 検証可能な単位（テストが通る、ビルドが通る）。実装チケットの一覧を兼ねる
- **検証方法**: 全体としてどう確認するか（テストコマンド、手動確認の観点）
- **リスク・未解決事項**: 実装中に判断が要りそうな点と、設計反映で書き戻しが要りそうな点

### 4-3. チケットを起こす

1. 実装チケット群（`type: implementation`）。1 チケット = 1〜2 ステップ。`allowed_paths` が要るなら frontmatter に書く。DoD の型:
   ```markdown
   - [ ] <対象ファイル> が仕様書 <節> のとおり実装されている
   - [ ] テスト <テスト ID> が追加され、失敗ケースを含めて通る（<コマンド>）
   - [ ] 既存テストが通る
   - [ ] 仕様からの逸脱・判明した差分が作業ログに書かれている（設計反映の入力）
   ```
2. 次の計画チケット 1 枚（通常 `type: design-sync-plan`。設計反映を省略していれば `retrospective`）

### 4-4. 完了する

計画チケットの DoD を確認し、`work-ticket-driven` 手順 5 のとおり done にしてコミットし、`work-boundary.sh status` で `at_boundary: true`・`todo_head_type: implementation` を確認して、手順 6 のとおり完了報告を返す。

計画チケットの DoD の型:

```markdown
- [ ] wip/20_plans/実装計画-<slug>.md に変更対象・allowed_paths 案・テスト方針（テスト ID との対応）・実装ステップ・検証方法が書かれている
- [ ] 実装チケット N 枚が todo に起票され、各 DoD にテスト ID と実行コマンドがある
- [ ] 次の計画チケット（または振り返りチケット）が todo に起票されている
```

## 5. レビュー観点

- 変更対象が仕様書のインターフェースと 1:1 で対応し、漏れ・余計な変更がないか
- テスト方針が仕様書のテストシナリオを網羅し、失敗ケース・境界値を含むか
- ステップの順序（テスト先行、依存の向き）と 1 チケットの大きさ
- `allowed_paths` 案が最小か
- 設計反映で書き戻しが要りそうな点が洗い出されているか

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-implementation-exec`
- 渡すもの: 実装計画書と実装チケット群（テスト ID・コマンド付き）
- 差し戻し時は呼び出し元が `implementation-plan` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `src/**` へ書こうとして WF009 が出た | 計画ワークではコードを書かない。実装チケットで書く |
| ビルド / テストの実行が WF003 で拒否された | 計画 type に `build` は無い。既存テストの状況は設定ファイルとテストコードを Read して把握する |
| 設計書が無い（設計を省略した） | 調査結果と依頼から計画を書き、インターフェースは計画書に明記する。設計反映も不要ならその旨を全体計画で確認する |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
