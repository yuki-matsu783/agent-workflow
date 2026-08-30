---
name: work-ai-asset-design-plan
description: >
  AI アセット設計フェーズの計画ワーク。調査結果をもとに、.claude/docs/ に作成・変更する要件定義書・仕様書・用語辞書の
  一覧と骨子を設計計画書（wip/20_plans/）にまとめ、AI アセット設計チケット群と次フェーズの計画チケットを起こす。
  チケット type は ai-asset-design-plan。todo_head_type が ai-asset-design-plan のときに呼ばれる。
  Use when the user mentions "AI アセット設計の計画", "フック/スキルの要件と仕様を決める計画", "ai asset design plan".
title: work-ai-asset-design-plan — AI アセット設計計画ワーク
type: skill
tags: [work-skill, ai-asset-design, plan-phase]
keywords: [AIアセット設計計画, ai-asset-design-plan, .claude/docs, 要件定義書, 仕様書, 用語辞書, 設計チケット, 次の計画チケット, ヘッドレス]
---

# work-ai-asset-design-plan — AI アセット設計計画ワーク

AI アセット（フック・スキル・ルール・エージェント・`settings.json`）の変更に先立ち、**どの要件定義書・仕様書・用語辞書を、どんな骨子で書くか**を決め、設計計画書を書き、AI アセット設計チケット群と次フェーズの計画チケットを起こす。`.claude/docs/` は書かない。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-investigation-exec`（調査を省略した場合は `work-overall-plan`） |
| チケット type | `ai-asset-design-plan`（`wip/20_plans/**` に書ける） |
| 次のワーク | `work-ai-asset-design-exec`（type `ai-asset-design`） |
| ワーク境界 | 計画チケットが done になった時点。設計計画（文書の一覧・骨子・判断の方針）が人間レビューを受ける |

## 2. 入力

- 調査結果 `wip/20_plans/調査結果-<slug>.md`（既存アセットの構造・フックの判定順・影響範囲・候補と比較軸）
- 全体計画（受け入れ条件との対応・判断点）
- 既存の `.claude/docs/`（`00_requirements/`・`10_spec/`・`90_glossary/`）と、対象アセットに対応する既存文書の有無（issue #37 の 1:1:1 原則。無ければ新規、あれば更新）
- `.claude/rules/`（`markdown-frontmatter.md`、`claude-config-headless-awareness.md`）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 設計計画書 | `wip/20_plans/AIアセット設計計画-<slug>.md` | `work-ticket-driven/assets/plan.template.md`。「変更対象ファイル」を**文書の一覧**（新規 / 更新、パス、骨子）に、「実装ステップ」を設計チケットの一覧に使う |
| AI アセット設計チケット群 | `wip/10_tickets/00_todo/0NN-ai-asset-design-<slug>.md`（1 枚以上） | `work-ticket-driven/assets/ticket.template.md` |
| 次の計画チケット | `0NN-ai-asset-implementation-plan-<slug>.md`（フェーズ列の次。最後なら振り返りチケット） | 同上 |

## 4. 手順

### 4-1. 着手する

todo 先頭の `0NN-ai-asset-design-plan-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 設計計画書を書く

`plan.template.md` を Read し、`wip/20_plans/AIアセット設計計画-<slug>.md` に Write する。書くこと:

- **判断点の結論方針**: 調査結果の候補から採る案と根拠。フック変更を伴うなら「type 定義の追加で済むか、フック本体の変更が要るか」を明示する
- **文書の一覧**: 要件定義書（`.claude/docs/00_requirements/<名前>.md`）・仕様書（`.claude/docs/10_spec/<名前>.md`）・用語辞書（`90_glossary/`）の新規 / 更新と骨子。既存文書の更新はレビュー記録の版を上げる
- **横断文書との整合**: `スキル体系.md`・`チケット駆動ワークフロー.md`・`issue-PR駆動ワークフロー.md` 等に追記が要るか
- **ヘッドレス実行の扱い**: 人間の確認（`ask`・`AskUserQuestion`）を増やす設計なら、ヘッドレスでの帰結と代替経路を仕様書に書く（`claude-config-headless-awareness.md`）
- **受け入れ条件との対応**: 受け入れ条件が要件定義書の受け入れ基準・仕様書のテストシナリオ（テスト ID）のどこに落ちるか
- **設計チケットの一覧**: 1 チケット = 要件定義書 / 仕様書（+ 横断文書の更新）。各 DoD

### 4-3. チケットを起こす

1. AI アセット設計チケット群（`type: ai-asset-design`）。DoD の型:
   ```markdown
   - [ ] .claude/docs/<path> が task-requirements / task-spec のテンプレートに沿って作成（更新）されている
   - [ ] 受け入れ条件 <X> が受け入れ基準 / テストシナリオ（テスト ID）に落ちている
   - [ ] 横断文書（<スキル体系.md 等>）と用語辞書の該当箇所が更新され、レビュー記録に版が追記されている
   - [ ] ヘッドレス実行時の挙動が仕様書に書かれている（確認を伴う設計の場合）
   ```
2. 次の計画チケット 1 枚（通常 `type: ai-asset-implementation-plan`。フェーズ列に次が無ければ `retrospective`）

### 4-4. 完了する

計画チケットの DoD を確認し、`work-ticket-driven` 手順 5 のとおり done にしてコミットし、`work-boundary.sh status` で `at_boundary: true`・`todo_head_type: ai-asset-design` を確認して完了報告を返す。

計画チケットの DoD の型:

```markdown
- [ ] wip/20_plans/AIアセット設計計画-<slug>.md に結論方針・文書の一覧と骨子・横断文書との整合・受け入れ条件との対応が書かれている
- [ ] AI アセット設計チケット N 枚が todo に起票され、各 DoD が文書と対応している
- [ ] 次の計画チケット（または振り返りチケット）が todo に起票されている
```

## 5. レビュー観点

- 文書の一覧が 1:1:1 原則（アセットごとに要件・仕様）と横断文書の扱いに沿っているか（#37 との整合）
- 結論方針が調査結果の根拠と整合し、フック本体の変更の要否が明示されているか
- ヘッドレス実行の帰結が検討されているか
- 設計チケットの粒度と次の計画チケットの type

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-ai-asset-design-exec`
- 渡すもの: 設計計画書（結論方針・文書の一覧と骨子）と設計チケット群
- 差し戻し時は呼び出し元が `ai-asset-design-plan` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `.claude/docs/**` へ書こうとして WF002 で拒否された | 計画 type は `.claude/**` に書けない。設計チケット（`ai-asset-design`）で書く |
| フック・スキル本体を先に直したくなった | 設計 → 実装の順を崩さない。実装フェーズ（`ai-asset-implementation`）に回す |
| 対象アセットに既存の要件・仕様が無い | 新規作成として一覧に載せる。横断文書に既に書かれている場合は、その節を正として参照する方針を計画書に書く |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
