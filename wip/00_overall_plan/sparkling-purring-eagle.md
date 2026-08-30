---
type: plan
title: 全体計画 フェーズ別ワークスキル（13 件）の新設
description: work 層に全体計画 + 6 フェーズ × 計画 / 実施の 13 スキルと対応する type を追加する全体計画
tags: [work-ticket-driven, overall-plan, skill-taxonomy]
keywords: [work-overall-plan, work-investigation-plan, work-design-plan, design-sync, workflow-types.json, ワーク境界, ai-asset-design, ai-asset-implementation]
---

# 全体計画: フェーズ別ワークスキル（13 件）の新設

- 対象 issue: #39 https://github.com/yuki-matsu783/agent-workflow/issues/39
- PR: #40 https://github.com/yuki-matsu783/agent-workflow/pull/40
- ブランチ: `feature-39-work-phase-skills`

## Context

ワーク層（`work-*`）は現在 `work-ticket-driven` 1 件だけで、全体計画（プランモード）で全チケットを一括作成し、チケット type の切り替わりでワーク境界（人間レビュー）が入る。フェーズごとの「何を入力に、何を成果物として、何をレビューするか」はスキル化されておらず、毎回 LLM が全体計画で組み立てている。

これを、**全体計画 1 件 + 6 フェーズ × 計画 / 実施 = 13 件**の `work-*` スキルとして定義し、「計画 → 人間レビュー → 実施 → 人間レビュー → …」の流れを型にする。チケット運用の仕組み（`wip/` の状態遷移・フック・`work-boundary.sh`）は `work-ticket-driven` に残し、13 スキルは各フェーズの入力・成果物・DoD の型・レビュー観点を定義する薄い層にする（手順の重複を避ける）。

ユーザーとの合意事項（2026-08-30）:

- 計画ワークと実施ワークは別 type にし、計画完了時にもワーク境界（人間レビュー）を挟む
- 設計反映 = 実装・テストで判明した差分・決定事項を設計書に書き戻すこと
- 一般のソフトウェア設計書の置き場は `docs/**`（`.claude/docs/` は AI アセット用）
- 1 issue に 13 スキル + type 定義 + 要件 / 仕様 1 組 + 参照更新を含める。スキルごとの 1:1:1 文書化は #37 に委ねる

## 方針（設計チケットで確定する既定案）

### スキルと type の対応

| フェーズ | 計画スキル | 実施スキル | 計画 type（新規） | 実施 type |
|---|---|---|---|---|
| 全体計画 | `work-overall-plan` | — | `overall-plan` | — |
| 調査 | `work-investigation-plan` | `work-investigation-exec` | `investigation-plan` | `investigation`（既存） |
| 設計 | `work-design-plan` | `work-design-exec` | `design-plan` | `design`（新規、`docs/**`） |
| 実装・テスト | `work-implementation-plan` | `work-implementation-exec` | `implementation-plan` | `implementation`（既存） |
| 設計反映 | `work-design-sync-plan` | `work-design-sync-exec` | `design-sync-plan` | `design-sync`（新規、`docs/**`） |
| AI アセット設計 | `work-ai-asset-design-plan` | `work-ai-asset-design-exec` | `ai-asset-design-plan` | `ai-asset-design`（既存） |
| AI アセット実装 | `work-ai-asset-implementation-plan` | `work-ai-asset-implementation-exec` | `ai-asset-implementation-plan` | `ai-asset-implementation`（既存） |

- 既存 5 type（`retrospective` 含む）は据え置き。追加は `overall-plan` + 計画 6 + `design` / `design-sync` の 9 type
- 計画 type の allow は `wip/20_plans/**`（+ 計画ワークが次のチケットを起こすための `wip/10_tickets/**` は global allow で既に可）。`overall-plan` は `wip/00_overall_plan/**` を type allow で許可する（type の allow は global deny より先に評価されるため既存の判定順で実現できる。`.claude/docs/10_spec/チケット駆動ワークフロー.md`「判定順序」）
- `design` / `design-sync` の allow は `docs/**` と `wip/20_plans/**`。`implementation` の allow に `docs/**` は足さない（実装中に設計書を書き換えるのを防ぎ、設計反映ワークに寄せる）

### ワークの連鎖（チケットを誰が起こすか）

- `work-overall-plan`: 依頼に対して使うフェーズ列を決め（例: ソフトウェア変更 = 調査 → 設計 → 実装・テスト → 設計反映 → 振り返り、AI アセット = 調査 → AI アセット設計 → AI アセット実装 → 振り返り。不要なフェーズは省略可）、全体計画を `wip/00_overall_plan/` に書き、**最初の計画ワークのチケットだけ**を起こす
- 各 `work-<phase>-plan`: そのフェーズの計画書を `wip/20_plans/` に書き、**同フェーズの実施チケット群 + 次フェーズの計画チケット 1 枚**を起こす（連鎖方式。連番は実施順のまま単調増加し、番号の飛びや挿入が要らない）
- 各 `work-<phase>-exec`: 計画に従いチケットを実施する。差し戻しは同 type の追加チケット（既存ルール）
- プランモード（`EnterPlanMode`）は全体計画ワークの導入後は必須ではなくなる。`workflow-issue-mr-driven` 手順 5 の「初回は `work-ticket-driven` 手順 1 から」を「`work-overall-plan` から」に置き換える。単独実行（issue / PR なし）の入口は `work-ticket-driven` 手順 1 に残し、そちらでも `work-overall-plan` を使えるようにする

### 各スキルの SKILL.md の型

frontmatter は `name` / `description`（Claude Code 用）+ `title` / `type: skill` / `tags` / `keywords`（`.claude/rules/markdown-frontmatter.md`）。本文は次の節で統一する:

1. 位置づけ（前後のワーク、対応する type、`work-ticket-driven` への委譲）
2. 入力（前ワークの成果物・issue の受け入れ条件）
3. 成果物とテンプレート（計画: `wip/20_plans/`、実施: フェーズごとの出力先）
4. チケットの起こし方 / DoD の型
5. レビュー観点（ワーク境界で人間に見てもらう点。`work-boundary.sh request --body-file` の本文の元になる）
6. 次のワークへの引き継ぎ
7. エラーハンドリング（フックのブロック時の対処は `work-ticket-driven` を参照）

テンプレートは `work-ticket-driven/assets/plan.template.md` を共通の土台にし、フェーズ固有の節が要る場合だけ各スキルの `assets/` に置く（設計チケットで要否を決める）。

## チケット構成

`ai-asset-design` → `ai-asset-implementation` → `retrospective` の 3 ワーク。各ワーク完了時に PR レビュー（承認④）。

| # | type | チケット | 成果物 / DoD の要点 |
|---|---|---|---|
| 001 | ai-asset-design | 要件定義書の作成 | `.claude/docs/00_requirements/フェーズ別ワークスキル.md`。ユーザーストーリー、受け入れ基準（issue #39 の受け入れ条件を When/Shall に落とす）、前提・制約（既存 type 据え置き、`retrospective` 不変） |
| 002 | ai-asset-design | 仕様書の作成と既存仕様の更新 | `.claude/docs/10_spec/フェーズ別ワークスキル.md`（13 スキル × type 対応表、各 type の allow_paths、ワークの連鎖規則、SKILL.md の型、テンプレート方針、テストシナリオ）。`スキル体系.md`（work 層の一覧・ワーク境界の記述）、`チケット駆動ワークフロー.md`（type 一覧・`overall-plan` の global deny 貫通）、`issue-PR駆動ワークフロー.md`（手順 5 の初回入口）、`90_glossary/スキル名.md` `チケットtype.md` を更新 |
| 003 | ai-asset-implementation | type 定義とフックのテスト | `workflow-types.json` に 9 type 追加。`work-ticket-driven/references/permission-matrix.md`・`assets/ticket.template.md` の type 一覧コメントを更新。`hooks/tests/test-workflow-guard.sh` に `design` の `docs/**` 許可 / `.claude/**` 拒否、`overall-plan` の `wip/00_overall_plan/**` 許可のケースを追加し、既存テストと合わせて通す |
| 004 | ai-asset-implementation | `work-overall-plan` の作成 | SKILL.md + evals。フェーズ列の選び方、全体計画の書式、最初の計画チケットの起こし方 |
| 005 | ai-asset-implementation | 調査・設計の 4 スキル | `work-investigation-plan/exec`、`work-design-plan/exec`。設計の成果物は `docs/**`（`task-requirements` / `task-spec` を成果物作成に使う） |
| 006 | ai-asset-implementation | 実装・テスト・設計反映の 4 スキル | `work-implementation-plan/exec`、`work-design-sync-plan/exec`。設計反映は実装差分と設計書の突き合わせを DoD にする |
| 007 | ai-asset-implementation | AI アセット設計・実装の 4 スキル | `work-ai-asset-design-plan/exec`、`work-ai-asset-implementation-plan/exec`。既存の `ai-asset-design` → `ai-asset-implementation` 運用（`.claude/docs/` → フック・スキル）を型にする。`task-ai-asset-creator` を成果物作成に使う |
| 008 | ai-asset-implementation | 呼び出し元と evals の更新 | `workflow-issue-mr-driven/SKILL.md`（手順 5 初回入口・役割分担表）、`work-ticket-driven/SKILL.md`（手順 1・2 を `work-overall-plan` / 計画ワークとの分担に合わせて改訂、type 一覧）、`workflow-quick-request/SKILL.md`（切り替え時のチケット構成の記述）、各 `evals/evals.json` |
| 009 | retrospective | 振り返り | `wip/30_reports/` に結果報告。AI アセットの棚卸しと改善提案 |

`depends_on` は直前のチケット。005〜007 は互いに独立だが、SKILL.md の型を揃えるため 004 の後に順に実施する。

## 判断が必要になりそうな点（設計チケットで確定し、レビューで確認する）

- 計画 type をフェーズごとに分ける（既定案・13 type）か、共通 `plan` 1 つにまとめるか。境界判定は隣接 type の差で動くため共通 type でも成立するが、レビュー依頼やチケット名からフェーズが読めることを優先して既定案はフェーズ別
- 連鎖方式（計画ワークが次の計画チケットを起こす）か、全体計画で全計画チケットを起こして連番に間隔を空けるか。既定案は連鎖
- `work-overall-plan` 導入後の `EnterPlanMode` の扱い（WF006 の文言、`plansDirectory` の用途）

## 検証

- `bash .claude/hooks/tests/test-workflow-guard.sh` と `bash .claude/hooks/tests/test-workflow-entry.sh` が通る（003 で追加分を含む）
- `bash .claude/hooks/work-boundary.sh status` が、計画 type → 実施 type の切り替わりで `at_boundary: true` を返すことをテストのフィクスチャで確認する
- 13 スキルの `SKILL.md` が同じ節構成で、frontmatter が `markdown-frontmatter.md` の規約を満たす（`grep -L "^type: skill"` で欠落なし）
- `grep -rn "work-ticket-driven 手順 1" .claude/` 等で呼び出し元の記述が新しい入口と矛盾しない
- 各ワーク完了時に PR #40 でレビューを受ける（承認④）
