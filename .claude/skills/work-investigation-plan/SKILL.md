---
name: work-investigation-plan
description: >
  調査フェーズの計画ワーク。全体計画のフェーズ列に従い、何を・どこを・どう調べるかを調査計画書
  （wip/20_plans/）にまとめ、調査チケット群と次フェーズの計画チケットを起こす。チケット type は investigation-plan。
  workflow-issue-mr-driven のワークループで work-boundary.sh status の todo_head_type が investigation-plan のときに呼ばれる。
  Use when the user mentions "調査計画", "調査の計画を立てて", "何を調べるか決めて", "investigation plan".
title: work-investigation-plan — 調査計画ワーク
type: skill
tags: [work-skill, investigation, plan-phase]
keywords: [調査計画, investigation-plan, wip/20_plans, 調査チケット, 次の計画チケット, 調査観点, 連鎖, work-boundary.sh]
---

# work-investigation-plan — 調査計画ワーク

調査フェーズで**何を明らかにするか**を決め、調査計画書を書き、調査チケット群と次フェーズの計画チケットを起こす。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用（着手・完了・境界判定・フックのブロック時の対処）: `work-ticket-driven` の手順 3・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-overall-plan`（通常、調査はフェーズ列の先頭） |
| チケット type | `investigation-plan`（`wip/20_plans/**` に書ける。チケットの起票は global allow） |
| 次のワーク | `work-investigation-exec`（type `investigation`） |
| ワーク境界 | 本ワークの計画チケットが done になった時点。調査計画が人間レビューを受ける |

## 2. 入力

- 全体計画 `wip/00_overall_plan/*.md`（フェーズ列・受け入れ条件との対応・判断が必要になりそうな点）
- 依頼と issue の受け入れ条件
- リポジトリの現状（Read / Glob / Grep で概観する。深掘りは調査チケットで行う）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 調査計画書 | `wip/20_plans/調査計画-<slug>.md` | `work-ticket-driven/assets/plan.template.md` を Read → Write。「調査サマリ」は空でよく、「実装ステップ」節を**調査チケットの一覧**として使う |
| 調査チケット群 | `wip/10_tickets/00_todo/0NN-investigation-<slug>.md`（1 枚以上） | `work-ticket-driven/assets/ticket.template.md` |
| 次の計画チケット | `wip/10_tickets/00_todo/0NN-<next>-plan-<slug>.md`（フェーズ列の次。最後なら `0NN-retrospective-振り返り.md`） | 同上 |

## 4. 手順

### 4-1. 着手する

todo 先頭の `0NN-investigation-plan-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。doing にある状態から再開したときは作業ログを読んで途中から続ける。

### 4-2. 調査計画書を書く

`plan.template.md` を Read し、`wip/20_plans/調査計画-<slug>.md` に Write する。書くこと:

- **調査観点**: 全体計画の「判断が必要になりそうな点」と受け入れ条件から、調査で答えを出す問いを列挙する（例: 現状の構造、影響範囲、制約、既存テストの有無、選択肢と比較軸）
- **対象と方法**: 問いごとに、読む場所（パス・シンボル）と方法（Grep / Read / 既存テストの実行結果の読み取り）。書き込みは行わない
- **調査チケットの一覧**（「実装ステップ」節）: 1 チケット = 1 つの問いのまとまり。多くても 3〜4 枚。各チケットの DoD を書く
- **成果物の形**: 調査結果 `wip/20_plans/調査結果-<slug>.md` に何を書けば次の計画ワークが判断できるか

### 4-3. チケットを起こす

`ticket.template.md` を Read し、次を Write する。連番は todo / done の最大値の次から実施順に振る。

1. 調査チケット群（`type: investigation`）。`depends_on` は直前のチケット。DoD の型:
   ```markdown
   - [ ] 調査観点「<問い>」に対する答えが wip/20_plans/調査結果-<slug>.md の「調査サマリ」に書かれている
   - [ ] 根拠（ファイル・行・コマンド出力）が添えられている
   - [ ] 答えが出なかった問いは「リスク・未解決事項」に理由つきで残っている
   ```
2. 次の計画チケット 1 枚（全体計画のフェーズ列の次。例: `type: design-plan` / `ai-asset-design-plan` / `implementation-plan`）。`depends_on` は最後の調査チケット。フェーズ列に次が無ければ振り返りチケット（`type: retrospective`）を起こす。DoD は対応する `work-<next>-plan` スキルの「DoD の型」に従う

### 4-4. 完了する

計画チケットの DoD（下記の型）を確認して作業ログを書き、`work-ticket-driven` 手順 5 のとおり done にしてコミットし、`bash .claude/hooks/work-boundary.sh status` で `at_boundary: true`・`todo_head_type: investigation` を確認する。手順 6 のとおりワーク完了報告を返して制御を呼び出し元に戻す。

計画チケットの DoD の型:

```markdown
- [ ] wip/20_plans/調査計画-<slug>.md に調査観点・対象と方法・成果物の形が書かれている
- [ ] 調査チケット N 枚が todo に起票され、各 DoD が観点に対応している
- [ ] 次の計画チケット（または振り返りチケット）0NN-…が todo に起票されている
```

## 5. レビュー観点

- 調査観点が全体計画の判断点と受け入れ条件を網羅しているか。答えが出ても次の計画に効かない観点が混じっていないか
- 調査チケットの粒度（1 チケット = 1 まとまり）と枚数が妥当か
- 調査の範囲が広すぎないか（実装まで踏み込んでいないか）
- 次の計画チケットの type がフェーズ列と一致しているか

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-investigation-exec`
- 渡すもの: 調査計画書（観点・対象・方法・成果物の形）と調査チケット群
- 差し戻し時は呼び出し元が `investigation-plan` type の追加チケットを起こし、計画書と調査チケットを見直す（起票済みの調査チケットは Edit で直す。done 済みチケットは戻さない）

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| 調査中に触りたくなるパス（`src/**` 等）へ Write しようとして WF009 が出た | 計画ワークではコードを触らない。確認を承認せず、実施チケットまたは後続フェーズに回す |
| 全体計画のフェーズ列に「次」が書かれていない | 全体計画を Read して確認する。無ければ振り返りチケットを起こし、レビュー観点にその旨を書く |
| 次の計画チケットを起こし忘れて done にした | 呼び出し元が todo に直接起こす（起票は global allow）。本スキルの DoD で防ぐのが原則 |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
