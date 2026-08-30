---
type: report
title: 結果報告 task-gh-issue の GitHub/GitLab 両対応化
description: task-gh-issue スキルを gh/glab 両対応にした作業の結果報告
tags: [work-ticket-driven, report]
keywords: [task-gh-issue, GitHub, GitLab, gh, glab, issue, 両対応]
---

# 結果報告: task-gh-issue の GitHub/GitLab 両対応化

- 対象ブランチ: claude/github-gitlab-skill-1rke2f
- 対象 issue: #20 https://github.com/yuki-matsu783/agent-workflow/issues/20
- PR: #21 https://github.com/yuki-matsu783/agent-workflow/pull/21
- 期間: 2026-08-30（1セッション内で完結）
- レビュー結果: 未実施（今後の自動化対象）

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 001-ai-asset-implementation-gh-issue-dual-support | 完了 | SKILL.md と evals.json を更新 |

## 成果物一覧

- 計画書: `wip/00_overall_plan/steady-scribbling-salamander.md`
- コード変更:
  - `.claude/skills/task-gh-issue/SKILL.md`: 手順1にホスト判定（GitHub/GitLab）を追加し、検索・作成・編集の3モードすべてに `glab issue` 相当のコマンドを併記。エラーハンドリング表を表形式に改め、glab未導入・未認証・ホスト判定不能のケースを追加
  - `.claude/skills/task-gh-issue/evals/evals.json`: 既存3件の期待値を GitHub/GitLab 非依存の書き方に更新し、GitLab を明示するケースを1件追加（計4件）

## うまくいったこと

- 本リポジトリに既存の `task-repo-merge-settings` が gh/glab 両対応のリファレンス実装として存在しており、ホスト判定方式（`git remote get-url origin` のホスト名判定）をそのまま踏襲できた
- `glab issue` の実コマンド体系（`--output json`、`--description-file`、`--label`/`--unlabel`、`note` コマンド名など）を WebSearch で GitLab CLI 公式ドキュメント・man ページ由来の情報から事前に確認してから記載したため、推測でコマンドを書かずに済んだ
- 元の SKILL.md がモード（検索/作成/編集）ごとにセクション分けされていたため、各セクション内に **GitHub:** / **GitLab:** を並記する形で機械的に拡張でき、全体構成を変えずに済んだ
- チケットは `task-repo-merge-settings` 導入時（issue #15）の前例（実装チケット1枚＋振り返り1枚、設計/調査チケットは無し）を踏襲し、過剰な分割をせずに済んだ

## うまくいかなかったこと

- WebFetch で docs.gitlab.com・man.archlinux.org・mankier.com など複数のドキュメントドメインへの直接アクセスが、このセッションのネットワークプロキシに軒並みブロックされた。WebSearch のスニペット経由で間接的にフラグを確認する形になり、公式ページの完全な一次情報を直接読めたわけではない点は留意が必要
- `evals/evals.json` の JSON 妥当性確認について、`ai-asset-implementation` タイプの `bash_groups`（`test`）には `python3` 等の汎用コマンドの実行が含まれておらず、`python3 -m json.tool` を実行できなかった。Read ツールでの目視確認に留めた（実害は無かったが、機械的な検証ができない点は今後の課題）

## 改善提案

- `ai-asset-implementation` タイプの `bash_groups` に、`evals/*.json` のような成果物の妥当性を機械的に確認できる軽量コマンド（例: `python3 -m json.tool` や `jq .` の evals.json 限定実行）を許可する拡張を検討してもよい。ただし汎用的に `python3`/`jq` を解禁すると許可範囲が広がりすぎるため、範囲を絞った専用チェックスクリプト（`scripts/validate-evals.sh` のようなもの）を用意し、それだけを allowlist する方式が安全
- 今回 `glab` の実コマンド調査に WebSearch のスニペットしか使えなかった。今後 `task-gh-install`（#18）が完了し `glab` が実際に導入された環境が手に入れば、SKILL.md の記載内容を実機で動作確認するチケットを追加で立てるのが望ましい
- `task-gh-feature` / `workflow-issue-mr-driven` は現状 GitHub 専用（PR の `Closes #N`、GitHub 前提のエラーハンドリング）のまま残っている。GitLab の MR に対応させる場合は、今回と同様に別 issue として切り出すのが妥当（スコープ外として明記済み）

## 残課題・フォローアップ

- `task-gh-feature` / `workflow-issue-mr-driven` の GitLab（MR）対応は本ワークのスコープ外。必要になれば別 issue で対応する
- `glab` の実機での動作確認（コマンドの実行結果検証）は未実施。`glab` 環境が用意でき次第、確認チケットを立てることを推奨する
