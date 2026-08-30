---
type: report
title: 結果報告 git add の wip/10_tickets/ 配下判定をハードコード許可にする
description: git add の wip/10_tickets/ 配下パス判定を git mv と同様に workflow-types.json を経由しないハードコード許可に揃えた
tags: [work-ticket-driven, report]
keywords: [git add, git mv, allow_paths, workflow-guard, workflow-types.json, wip/10_tickets]
---

# 結果報告: git add の wip/10_tickets/ 配下判定をハードコード許可にする

- 対象ブランチ: claude/wip-ticket-allow-list-check-txoxc0
- 対象 issue: #26 <https://github.com/yuki-matsu783/agent-workflow/issues/26>
- PR: #27 <https://github.com/yuki-matsu783/agent-workflow/pull/27>
- 期間: 2026-08-30（1日）
- レビュー結果: 未実施（今後の自動化対象。ワーク完了チェックポイントの自動起動は未整備）

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 001-ai-asset-design-git-add-allow-list-仕様更新 | 完了 | `.claude/skills/**` は `ai-asset-design` の allow_paths 外だったため、`permission-matrix.md` の修正は 002 に移した |
| 002-ai-asset-implementation-git-add-ハードコード実装 | 完了 | `wf_validate_mv`/`wf_validate_add` 共通のヘルパー `wf_is_ticket_path` を追加し、新規テスト4件を作成 |
| 003-retrospective-振り返り | 完了（本報告） | |

## 成果物一覧

- 計画書: `wip/00_overall_plan/steady-whistling-seahorse.md`（プランモードの全体計画）
- コード変更:
  - `.claude/hooks/workflow-guard.sh`: `wf_is_ticket_path` ヘルパーを追加し、`wf_validate_mv` / `wf_validate_add` の両方から `wip/10_tickets/*` の無条件許可判定に使うよう統一
  - `.claude/hooks/tests/test-workflow-guard.sh`（新規）: `git add`/`git mv` のハードコード許可を検証するテスト4件（TG001〜TG004）
  - `.claude/docs/10_spec/チケット駆動ワークフロー.md`: パス判定順序表・セッション記憶・保護パス・Bash allowlist の記述を実装に整合させる4箇所を更新
  - `.claude/skills/work-ticket-driven/references/permission-matrix.md`: 上記仕様書と同様の記述を2箇所更新

## うまくいったこと

- 質問の調査（`git add`/`git mv` の判定経路の非対称性）から issue 化・仕様修正・実装・テストまで一連の流れを、workflow-quick-request → workflow-issue-mr-driven → work-ticket-driven の入口設計どおりに移行できた
- `wf_validate_mv` と `wf_validate_add` の共通条件を `wf_is_ticket_path` ヘルパーに切り出せたことで、DRY 原則に沿い、今後どちらかだけ直して非対称に戻る事故を防ぎやすい実装にできた
- 新規テスト（TG003）で、旧実装なら `types.<type>.deny_paths` に `wip/10_tickets/**` を指定すると `git add` が deny になっていたはずのシナリオを再現し、新実装がそれを解消したことを直接示せた
- 既存テスト（`test-workflow-entry.sh` 40件）が最後まで全て PASS のままだった

## うまくいかなかったこと

- 旧実装との直接比較（`git stash`や一時的なファイル差し替えでの A/B 実行）は、チケット作業中の Bash allowlist（`mv`/`git add`/`git commit`/読み取り系/フックのテストスクリプトのみ）に阻まれ実施できなかった。`.claude/hooks/tests/` 配下のテストスクリプト経由でしか Bash 実行ができない設計は、通常の実装作業では安全策として機能する一方、フック自身の新旧比較検証のような自己言及的な検証には制約になった
- 001 の計画段階で、`.claude/skills/**` が `ai-asset-design` の allow_paths 外であることに気づけず、`permission-matrix.md` の修正を 001 に割り当ててしまい、着手後に WF002 で拒否されて 002 に振り直す手戻りが発生した

## 改善提案

- `.claude/hooks/workflow-types.json` の `ai-asset-design`/`ai-asset-implementation` の allow_paths（`.claude/docs/**` のみ／`.claude/skills/**` 含む）は、チケット分割の計画段階で見落としやすい。`work-ticket-driven` スキルの手順2（チケット作成）に「対象パスが `.claude/skills/**` を含む場合は `ai-asset-design` ではなく `ai-asset-implementation` に倒す」といった簡潔な注意書きを追記すると、同種の手戻りを防げる可能性がある（恒久化するかはユーザー判断）
- フック自身（`workflow-guard.sh`/`workflow-lib.sh`）の新旧比較のような自己言及的な検証を安全に行う経路（例: `ai-asset-implementation` の `bash_groups` に限定的な `diff`/一時ファイル比較コマンドを追加する等）が無いことに気づいた。現状は許容範囲だが、フック自体の改修が今後も発生するなら検討の余地がある

## 残課題・フォローアップ

- ワーク完了チェックポイント（敵対的レビューエージェントによる承認）は自動化未整備のため未実施。`workflow-issue-mr-driven` の手順6（完了処理）で PR を ready for review にする際、人間のレビューで代替する
- スクラッチパッドに作成した一時ファイル（issue 本文の下書き、旧 `workflow-guard.sh` の一時コピー）は、チケット作業中の Bash 制約により削除できていない。全チケット完了後（doing が空の状態）に削除する
