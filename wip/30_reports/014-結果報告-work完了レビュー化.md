---
type: report
title: 結果報告 work完了ごとに人間レビューを挟むフローへ改訂
description: チケット type 単位のワーク境界で push・レビュー依頼・コメント確認を行うフローへの改訂と、その判定・状態遷移をスクリプトとフックで機械化した作業の振り返り
tags: [work-ticket-driven, report, review-loop]
keywords: [ワーク境界, work-boundary.sh, workflow-boundary.sh, review-state.json, WF011, WF012, WF013, WF014, 承認④, ハイフン区切り, ドッグフーディング, 敵対的レビュー, 人間レビュー]
---

# 結果報告: work完了ごとに人間レビューを挟むフローへ改訂

- 対象ブランチ: `feature-12-work-review-loop`
- 対象 issue: #12 https://github.com/yuki-matsu783/agent-workflow/issues/12
- PR: #13 https://github.com/yuki-matsu783/agent-workflow/pull/13
- 期間: 2026-08-30 〜 2026-08-30
- レビュー結果: investigation(008)=承認 / ai-asset-design(009)=承認 / ai-asset-implementation(010)=承認 / ai-asset-design(011)=承認 / ai-asset-implementation(012+013)=承認（`work-boundary.sh request` → `complete` 経由、指摘 0 件） / retrospective(014)=本報告の push 後にレビュー依頼

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 008-investigation-レビュー往復ロジック確認 | 完了 | 責務分担（レビュー往復＝workflow 層、境界で制御を返す＝work 層）と手順文言の草案を確定。調査チケット中は `gh` が WF003 で使えないことを実地で確認 |
| 009-ai-asset-design-スキル体系仕様改訂 | 完了 | 承認④・ワーク境界・ハイフン区切り命名・IP011〜014 を 5 仕様書に反映。汎用定義（敵対的レビューエージェント）は残し `work-ticket-driven` に個別上書き |
| 010-ai-asset-implementation-work-ticket-driven分割 | 完了 | 手順 5.5（境界判定）新設、手順 6 改稿、report.template・evals 更新。フック無改修で 62 件パス |
| 011-ai-asset-design-ワーク境界スクリプトとフック仕様 | 完了 | ユーザー指示（機械化・状態ファイルの保護）を受けて追加。`work-boundary.sh` / `review-state.json` / `workflow-boundary.sh`、WF011〜WF014、TC024〜028 を仕様化 |
| 012-ai-asset-implementation-ワーク境界スクリプトとフック | 完了 | 実装。`test-hooks.sh` PASS=130 FAIL=0（新規 68 件）、`test-workflow-entry.sh` PASS=40 |
| 013-ai-asset-implementation-workflow-issue-mr-drivenワークループ化 | 完了 | 手順 5 をワークループ（5-1〜5-8）に改稿、承認④、命名規約変更、evals id 4〜6 追加 |
| 014-retrospective-振り返り | 完了 | 本報告 |

当初は 012 が retrospective だったが、010 完了時点のユーザー指示（「境界判定はスクリプトで決定論的に。フックで exit 2」「レビュー状態を生成 AI が書き換えられないように」）を受けて 011/012 を挿入し、旧 011→013、旧 012→014 に改番した。

## 成果物一覧

- 計画書: `wip/00_overall_plan/gleaming-hopping-moth.md`（全体計画・設計変更の経緯）、`wip/20_plans/008-work完了レビュー往復-実装方針.md`
- 仕様・要件: `.claude/docs/10_spec/スキル体系.md`（v1.2）、`.claude/docs/00_requirements/スキル体系.md`（v1.2）、`.claude/docs/10_spec/issue-PR駆動ワークフロー.md`（v1.4）、`.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`（v1.2）、`.claude/docs/10_spec/チケット駆動ワークフロー.md`（v1.9。新節「ワーク境界の判定とレビュー状態」）
- AI アセット（新規）: `.claude/hooks/work-boundary.sh`（CLI: `status` / `request` / `complete` / `reply`）、`.claude/hooks/workflow-boundary.sh`（PreToolUse フック: WF011 / WF012）
- AI アセット（改訂）: `.claude/settings.json`（フック登録）、`work-ticket-driven/SKILL.md`・`assets/report.template.md`・`evals/evals.json`・`scripts/test-hooks.sh`、`workflow-issue-mr-driven/SKILL.md`・`assets/issue-addendum.template.md`・`evals/evals.json`、`task-gh-feature/SKILL.md`（issue 連携モードの表）
- 状態: `wip/10_tickets/review-state.json`（Git 管理。直近のワーク境界のレビュー状態）
- 規模: 26 ファイル、+1652 / -76、20 コミット（main 比、本報告前）

## うまくいったこと

- **仕様→スキル→実装の順で進めたことで手戻りがなかった**。009 / 011 でレビューを通した文言をそのまま SKILL.md（010 / 013）と実装（012）に落とせ、実装段階で新たに設計判断する場面がほぼ無かった
- **このワークフロー自身でドッグフーディングできた**。ワーク1〜4 は手動の `gh pr comment` / `gh pr view` で、ワーク5 からは `work-boundary.sh request` / `complete` で、計 6 回のレビュー往復を実際に回した。`status` は「012 done → 013 は同 type → 境界でない」「013 done → 014 は別 type → 境界」を正しく判定した
- **フック（`workflow-guard.sh`）を無改修で済ませた**。doing が空なら不活性化する既存設計を利用し、境界統制は別フック `workflow-boundary.sh` として追加したため、既存 62 件のテストに影響しなかった
- **`gh` をモックにしたテスト**で、`request`（push・コメント投稿・証跡記録）と `complete`（CHANGES_REQUESTED 拒否・未返信スレッド拒否・自分の投稿と request 以前のコメントの除外）をネットワーク無しで検証できた
- **状態ファイルの識別子を「done 末尾のチケット名」にした**ことで、差し戻し対応の追加チケットが done になると状態が自動で失効し、再 `request` が必要になる。差し戻し→対応→再レビューの経路が状態機械として閉じた
- 「request 以降の新規コメントあり」を `complete` の拒否条件に**入れなかった**判断（approve 目的のコメントでも通らなくなる）は 011 のレビューで承認された

## うまくいかなかったこと

- **調査チケットの DoD に `gh` の実行を含めてしまった**（008）。チケット作業中は WF003 で `gh` が使えないため、done 直後に確認して計画書に追記する形で回避した。ベストプラクティスに「調査チケットの DoD に `gh` を含めない」を追記済み
- **jq の `join` の区切り文字が生の 0x1E 文字として `workflow-boundary.sh` に入った**（012）。`workflow-guard.sh` は `""` のエスケープ表記。jq の文字列リテラルとしては有効でテストも通るが、目に見えない文字が残っている。Edit ツールで当該文字を指定できず、そのままになっている
- **`test-hooks.sh` の実行時間が 120 秒を超えた**（012）。境界フックが `work-boundary.sh status` を子プロセスで呼び、その中で jq を複数回起動するため。Bash ツールの既定タイムアウトに収まらず、`timeout` を延ばしてバックグラウンド実行する必要があった
- **Bash ツールの `2>&1` がリダイレクト判定で WF003 になる**（010）。テスト出力は元々 stdout に出るので付けなければよいが、癖で付けると止まる
- **ワーク5 のレビューで指摘 0 件だったため、WF014（CHANGES_REQUESTED / 未返信スレッド）や差し戻し→追加チケットの経路は実地で通していない**。テスト（TC026d / TC028c 系）でのみ検証済み
- 途中の設計変更（011/012 の挿入）で当初計画の「フックは変更しない」を撤回した。全体計画の「設計変更」節と各仕様書のレビュー記録に経緯を残したが、009 の時点で「フックはワーク境界を検知しない」と書いた文言を 011 で書き直す二度手間が生じた

## 改善提案

- **`workflow-boundary.sh` の `join("<0x1E>")` を `--arg rs "${WF_RS}"` + `join($rs)` に書き換える**（可読性。`workflow-guard.sh` も同様に統一してよい）
- **`work-boundary.sh status` の jq 呼び出しを 1 回にまとめる**（`test-hooks.sh` の実行時間短縮。フック 1 回あたりの体感遅延も減る）
- **CLAUDE.md / `work-ticket-driven` のベストプラクティスに「Bash ツールで `2>&1` を付けない」を追記**する（本 issue で 2 回踏んだ）
- **差し戻し経路の実地検証**: 次の issue でレビュアーが意図的に `CHANGES_REQUESTED` かインラインコメントを付け、WF014 → 追加チケット → 再 `request` → `complete` の流れを一度通す
- スキル体系.md の汎用定義に残した「敵対的レビューエージェント」は、`work-boundary.sh` の `complete` の前段に自動レビューを挟む形で実装できる構造になった（`request` と `complete` の間に別プロセスがコメントを投稿すればよい）。将来の課題として issue 化を検討する

## 残課題・フォローアップ

- `workflow-boundary.sh` の区切り文字（上記）— 軽微な保守として次回の `ai-asset-implementation` で対応
- `test-hooks.sh` の実行時間 — 同上
- `work-ticket-driven` を単独（PR なし）で使う `request --local` / `complete --local` の経路は、テスト（TC027b / TC028b）でのみ検証。実運用は未経験
- issue #12 の受け入れ条件は全て満たした（work-ticket-driven の type 単位分割、workflow-issue-mr-driven のワークループ、スキル体系.md の承認者更新、命名規約のハイフン化、既存フック・テストとの整合、関連仕様書の追従）。加えてユーザー指示によるスクリプト・フックの機械化を実装した
