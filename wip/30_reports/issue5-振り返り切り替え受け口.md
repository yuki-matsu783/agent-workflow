---
type: report
title: 結果報告 issue-pr-driven-workflow への振り返り切り替え受け口追加
description: workflow-quick-request 手順 5-3 からの切り替えを受ける口を workflow-issue-mr-driven に追加した
tags: [work-ticket-driven, report]
keywords: [issue-pr駆動ワークフロー, 振り返り, workflow-quick-request, workflow-issue-mr-driven, 受け口, チケット構成]
---

# 結果報告: issue-pr-driven-workflow に quick-request-workflow の振り返りからの受け口を追加する

- 対象ブランチ: claude/issue-pr-workflow-switchover-v5ymht
- 対象 issue: #5 https://github.com/yuki-matsu783/agent-workflow/issues/5
- PR: #33 https://github.com/yuki-matsu783/agent-workflow/pull/33
- 期間: 2026-08-30（1日）
- レビュー結果: ai-asset-design=承認（指摘0件） / ai-asset-implementation=承認（指摘0件） / retrospective=このチケットで実施中

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 015-ai-asset-design-振り返り切り替え受け口仕様追加 | 完了 | 要件定義書・仕様書に代替経路とテストケース（IP015）を追加 |
| 016-ai-asset-implementation-振り返り切り替え受け口実装 | 完了 | SKILL.md 手順1・手順5の追記、evals.json への切り替えケース（id:7）追加 |
| 017-retrospective-振り返り | 実施中（本レポート） | |

## 成果物一覧

- 計画書: wip/00_overall_plan/fluffy-roaming-hummingbird.md
- コード変更:
  - `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`（+6行）
  - `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`（+8行程度、入力データ・代替フロー・テストケース・レビュー記録）
  - `.claude/skills/workflow-issue-mr-driven/SKILL.md`（+10行、手順1「振り返りからの切り替え」小節・手順5のAIアセット標準チケット構成）
  - `.claude/skills/workflow-issue-mr-driven/evals/evals.json`（+12行、切り替えケース id:7）

## issue #5 受け入れ条件の確認

- [x] `issue-pr-driven-workflow/SKILL.md` に振り返りからの切り替え時の受け口（引き継ぐ項目・省略できる手順・省略できない手順）が書かれている
  → `workflow-issue-mr-driven/SKILL.md` 手順1「振り返りからの切り替え」に記載
- [x] `light-task-workflow` 5-3 の記述と往復で整合している（引き継ぐ項目名が一致）
  → `workflow-quick-request/SKILL.md` 手順5-3（summary / acceptance / kind / チケット構成）と `workflow-issue-mr-driven/SKILL.md` 手順1の項目名を一致させた
- [x] 仕様書・要件定義書に入力・代替フローとして記載されている
  → 要件定義書のアルタナティブフロー、仕様書の入力データ表・代替フロー・テストシナリオ（IP015）に記載
- [x] `evals/evals.json` に切り替えケースがある
  → `workflow-issue-mr-driven/evals/evals.json` の id:7 として追加

## うまくいったこと

- `workflow-quick-request` 手順5-3に引き継ぎ項目（summary/acceptance/kind/チケット構成）が既に明記されていたため、受け口側は項目名をそのまま踏襲するだけで往復の整合が取れた
- issue #5 自体が指定していた `ai-asset-design → ai-asset-implementation` のチケット構成に従うことで、ドキュメント変更とスキル実装を分離してレビューできた

## うまくいかなかったこと

- チケット番号を `001` から採番してしまい、`work-boundary.sh` のワーク境界判定（`wip/10_tickets/20_done/` 全体でのファイル名連番の最大値/最小値比較）と衝突した。既存の done チケットは過去の全PRを通じてリポジトリに蓄積され続けており、番号は各PR/ブランチでリセットされず**リポジトリ全体で継続する**必要があると分かった。着手直後（doing が空の段階）で気付き、`015〜017` に振り直して事なきを得た
- この環境（Claude Code on the web のリモートセッション）には `gh` CLI が無く、`GitHub MCP ツールのみ使用`という制約があるため、`work-boundary.sh request`/`complete` の非ローカルモード（内部で `gh pr comment` / `gh pr view` / `gh api` を実行する）がそのままでは使えなかった。実際の PR コメント投稿は `mcp__github__add_issue_comment` で代替し、レビュー内容の取得は `mcp__github__pull_request_read`（get_reviews / get_comments / get_review_comments）で代替した上で、状態記録のみ `work-boundary.sh request --local` / `complete --local` を使う運用にした
- `ai-asset-implementation` の bash_groups（`test`）には `python3 -m json.tool` のような汎用コマンドの実行が含まれておらず、JSON の妥当性確認はチケットの DoD にコマンド実行を書いていたが、実際には Read ツールでの目視確認に切り替えた

## 改善提案

- **`work-boundary.sh` の `gh` CLI 依存**: この種のリモート実行環境（`gh` 不可・GitHub MCP のみ）では非ローカルモードが機能しない。`work-boundary.sh` に「`gh` の代わりに渡された値を使う」モード（例: 呼び出し側が MCP で取得した `reviewDecision` や inline コメント一覧を引数/ファイルで渡す）を追加するか、`.claude/docs/10_spec/issue-PR駆動ワークフロー.md`・`work-ticket-driven` の仕様に「`gh` 不可の環境では MCP ツールで代替し、状態記録は `--local` を使う」という代替経路を明記することを提案する（現状は今回のセッションでその場判断をしたのみで、仕様には残っていない）
- **チケット番号の採番規則**: `work-ticket-driven/SKILL.md` 手順2に「チケット番号はブランチ内で001から振り直すのではなく、`wip/10_tickets/20_done/` に既存する最大の連番の続きから振る」旨を明記した方がよい。境界判定ロジック（`work-boundary.sh`）が全体最大値/最小値に依存しているため、番号の衝突は静かに誤動作（不整合はしないが、意図しないチケットが last_done として扱われる）を招く

## 残課題・フォローアップ

- 上記2つの改善提案（`gh` 不可環境への対応、チケット番号採番規則の明記）は本 issue のスコープ外のため、別 issue 化をユーザーに確認する
