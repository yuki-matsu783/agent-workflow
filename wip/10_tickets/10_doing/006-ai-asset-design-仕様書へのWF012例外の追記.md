---
type: ai-asset-design
status: todo
depends_on: ["005-ai-asset-design-plan-設計計画.md"]
---

# 仕様書へのWF012例外の追記

## 目的

`.claude/docs/10_spec/skill-work-ticket-driven.md`「ワーク境界の判定とレビュー状態」に、マージ進行中に限りWF012保護ファイルの直接書き換えを許可する例外の検出条件・許可範囲・内容検証・トレードオフを追記する。

## 完了条件（DoD）

- [x] `.claude/docs/10_spec/skill-work-ticket-driven.md`「ワーク境界の判定とレビュー状態」に検出条件・許可範囲・内容検証・トレードオフが追記されている
- [x] 受け入れ条件4件すべてが仕様書のどこかに対応している
- [x] レビュー記録の版が追記されている

## 作業内容

1. `task-spec`スキルの手順に従い、既存の「ワーク境界の判定とレビュー状態」節を確認する
2. AIアセット設計計画（wip/20_plans/AIアセット設計計画-conflict-wf012-exception.md）の結論方針をもとに、例外条件（MERGE_HEAD存在 かつ 対象ファイルがunmerged）・許可範囲（Edit/Write/Bash）・内容検証（PostToolUse警告）・トレードオフ（doing空でのBash無制限との緊張関係）を追記する
3. 更新履歴（版）を追記する

## 作業ログ

### うまくいったこと

- 「ワーク境界フックのブロック条件」の直後に例外節を追加し、検出条件・内容検証（PostToolUse警告のみ）・見送った選択肢・残るトレードオフをまとめて明記できた。WF012エラーメッセージ仕様と新しいTC032〜034も追加

### うまくいかなかったこと

-
