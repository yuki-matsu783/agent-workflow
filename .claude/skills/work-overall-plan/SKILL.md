---
name: work-overall-plan
description: >
  フェーズ別ワークスキルの先頭ワーク。依頼と issue の受け入れ条件から使うフェーズ列
  （調査 / 設計 / 実装・テスト / 設計反映 / AI アセット設計 / AI アセット実装）を決め、
  全体計画を wip/00_overall_plan/ に書き、最初の計画チケットを起こす。チケット type は overall-plan。
  workflow-issue-mr-driven のワークループの初回、または work-ticket-driven の単独実行の入口として呼ばれる。
  Use when the user mentions "全体計画", "フェーズ列を決めて", "全体計画ワーク", "overall plan",
  or when workflow-issue-mr-driven starts its work loop for a new issue.
title: work-overall-plan — 全体計画ワーク
type: skill
tags: [work-skill, overall-plan, phase-workflow]
keywords: [全体計画, フェーズ列, overall-plan, wip/00_overall_plan, 計画チケット, work-boundary.sh, todo_head_type, 省略, 受け入れ条件]
---

# work-overall-plan — 全体計画ワーク

依頼に対して**どのフェーズを使うか**を決め、全体計画を書き、最初の計画チケットを 1 枚だけ起こす。ここで起こした計画チケットを次のワーク（`work-<phase>-plan`）が実施し、以降は各計画ワークが連鎖的に次のチケットを起こす。

- 要件: `.claude/docs/00_requirements/フェーズ別ワークスキル.md`
- 仕様（スキル × type 対応表・連鎖規則・レビュー観点の正）: `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用（着手・完了・境界判定・フックのブロック時の対処）: `work-ticket-driven` の手順 3・5・5.5・6 とエラーハンドリング。本スキルはそれらを再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | なし（先頭。`workflow-issue-mr-driven` 手順 5 の初回、または単独実行の `work-ticket-driven` 手順 1 から呼ばれる） |
| チケット type | `overall-plan`（`wip/00_overall_plan/**` に書ける。global deny を type の allow で貫通する） |
| 次のワーク | フェーズ列の最初の計画ワーク `work-<phase>-plan`（通常は `work-investigation-plan`） |
| ワーク境界 | 本ワークの完了（`001-overall-plan-…` が done）で境界に達し、全体計画が人間レビューを受ける |

## 2. 入力

- 依頼の要約と、`workflow-issue-mr-driven` 経由なら対象 issue（`#N <url>`）・PR（`#M <url>`）・受け入れ条件（acceptance）
- 既存の全体計画（`wip/00_overall_plan/*.md`）があればそれ（プランモードで作成済み、または再開時。下記「既存の全体計画があるとき」）
- リポジトリの現状（設計書の有無: `docs/`、`.claude/docs/`。省略判断の材料）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 全体計画 | `wip/00_overall_plan/<slug>.md` | `assets/overall-plan.template.md` を Read → Write（`type: plan`） |
| 自分のチケット | `wip/10_tickets/00_todo/001-overall-plan-全体計画.md` | `work-ticket-driven/assets/ticket.template.md` を Read → Write |
| 最初の計画チケット | `wip/10_tickets/00_todo/002-<phase>-plan-<slug>.md` | 同上 |

## 4. 手順

### 4-0. 状態確認

```bash
ls wip/00_overall_plan/ wip/10_tickets/00_todo/ wip/10_tickets/10_doing/ wip/10_tickets/20_done/ 2>/dev/null
git branch --show-current
```

- `wip/10_tickets/` が空で全体計画も無い → 4-1 から
- 全体計画が既にある（プランモードの成果物など） → 「既存の全体計画があるとき」に従う
- `001-overall-plan-…` が doing にある → 作業ログを読んで 4-2 以降の途中から再開する
- main 上なら作業しない（`workflow-issue-mr-driven` 経由なら feature ブランチにいるはず）

`wip/` の各ディレクトリが無ければ `work-ticket-driven` 手順 1 のとおり `mkdir -p` で作る。

### 4-1. 自分のチケットを起こして着手する

`work-ticket-driven/assets/ticket.template.md` を Read し、`type: overall-plan` で `wip/10_tickets/00_todo/001-overall-plan-全体計画.md` を Write する。DoD は次を定型とする:

```markdown
- [ ] 全体計画 wip/00_overall_plan/<slug>.md にフェーズ列・省略理由・受け入れ条件との対応が書かれている
- [ ] 最初の計画チケット 002-<phase>-plan-<slug>.md が todo に起票されている
```

コミットして着手する（`work-ticket-driven` 手順 2・3）:

```bash
git add wip/10_tickets/
git commit -m "chore(ticket): create tickets for <作業名>"
git mv wip/10_tickets/00_todo/001-overall-plan-全体計画.md wip/10_tickets/10_doing/
git commit -m "chore(ticket): start 001-全体計画"
```

着手後は `EnterPlanMode` を使わない（WF006 でブロックされる。全体計画は Write で書く）。

### 4-2. フェーズ列を決める

依頼の種類から標準のフェーズ列を選び、省略するフェーズがあれば理由を決める。

| 依頼の種類 | 標準のフェーズ列 |
|-----------|----------------|
| ソフトウェアの変更（機能追加・バグ修正・リファクタリング） | 調査 → 設計 → 実装・テスト → 設計反映 → 振り返り |
| AI アセット（フック・スキル・ルール・エージェント・設定）の作成・変更 | 調査 → AI アセット設計 → AI アセット実装 → 振り返り |

省略の目安（いずれも全体計画に理由を書く）:

| 省略するフェーズ | 目安 |
|-----------------|------|
| 調査 | 対象が 1〜2 ファイルに閉じ、現状が依頼文だけで把握できる |
| 設計 / 設計反映 | `docs/` に設計書が無く、今回も作らない小さな修正。設計反映は「設計で作った・触った設計書が無い」なら不要 |
| AI アセット設計 | `.claude/docs/` の要件・仕様に変更が要らない（文言修正など） |

振り返り（`retrospective`）は省略しない。フェーズ列の最後の計画ワークが振り返りチケットを起こす。

### 4-3. 全体計画を書く

`assets/overall-plan.template.md` を Read し、`wip/00_overall_plan/<slug>.md` に Write する。必須項目:

- 冒頭: `- 対象 issue: #N <url>` / `- PR: #M <url>` / `- ブランチ: <branch>`（無ければ「なし」）
- Context: 背景・目的・ユーザーとの合意事項
- フェーズ列の表（順 / フェーズ / 計画スキル・実施スキル / 狙い / 省略理由）
- 受け入れ条件との対応（issue の受け入れ条件 → どのフェーズの成果物で満たすか）
- 判断が必要になりそうな点（後続の計画ワークで結論を出す項目）

### 4-4. 最初の計画チケットを起こす

フェーズ列の最初のフェーズの計画チケットを 1 枚だけ Write する（例: `wip/10_tickets/00_todo/002-investigation-plan-調査計画.md`、`type: investigation-plan`、`depends_on: ["001-overall-plan-全体計画.md"]`）。DoD は対応する `work-<phase>-plan` スキルの「DoD の型」に従う。**他のフェーズのチケットは起こさない**（各計画ワークが連鎖的に起こす）。

### 4-5. 完了する

DoD を確認して作業ログを書き、`work-ticket-driven` 手順 5 のとおり done にしてコミットする:

```bash
git mv wip/10_tickets/10_doing/001-overall-plan-全体計画.md wip/10_tickets/20_done/
git add wip/10_tickets/ wip/00_overall_plan/
git commit -m "chore(ticket): done 001-全体計画"
bash .claude/hooks/work-boundary.sh status
```

`at_boundary: true`・`todo_head_type: <phase>-plan` になる。`work-ticket-driven` 手順 6 のとおり**ワーク完了報告を返して制御を呼び出し元に戻す**（push・レビュー依頼は `workflow-issue-mr-driven` が行う。単独実行なら `AskUserQuestion` で承認を取る）。

## 5. レビュー観点

ワーク境界で人間に見てもらう点。`workflow-issue-mr-driven` が `work-boundary.sh request --body-file` に書く本文の元にする。

- フェーズ列が依頼と受け入れ条件に対して過不足ないか（足りないフェーズ、余計なフェーズ）
- 省略理由が妥当か
- 受け入れ条件がどのフェーズの成果物で満たされるか、対応が一意か
- 判断が必要になりそうな点が洗い出され、どの計画ワークで結論を出すか決まっているか
- 最初の計画チケットの type がフェーズ列の先頭と一致しているか

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `todo_head_type` が `<phase>-plan` → `work-<phase>-plan`
- 渡すもの: 全体計画（フェーズ列・受け入れ条件との対応・判断点）。計画ワークはこれを入力に、そのフェーズの計画書と実施チケット群、次の計画チケットを起こす
- レビューで差し戻された場合、呼び出し元が `overall-plan` type の追加チケット（例: `003-overall-plan-フェーズ列の見直し.md`）を起こし、全体計画を Edit で直す。done 済みの `001` は戻さない

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| 既存の全体計画があるとき（プランモードで作成済み・再開） | 新しい全体計画を作らない。既存のものを読み、フェーズ列の表と受け入れ条件との対応が無ければ Edit で追記する。最初の計画チケットが未起票なら 4-1 → 4-4 を行い、起票済みなら本ワークは完了扱いとして 4-5 へ |
| `wip/00_overall_plan/` への Write が WF002 で拒否された | doing チケットの type が `overall-plan` でない。`001-overall-plan-…` を着手しているか確認する |
| `EnterPlanMode` が WF006 で拒否された | 着手後はプランモードを使わない。全体計画は Write で書く |
| フェーズ列に無い type が必要になった | 全体計画に理由を書いた上で追加する。type 定義（`workflow-types.json`）に無い type は使わず、追加をユーザーに提案する |
| ヘッドレス実行 | 本ワークの完了後、`workflow-issue-mr-driven` が `request` を出して応答を終える。単独実行の `AskUserQuestion` は応答が得られず拒否扱いになるため、非対話環境での単独実行は想定しない |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
