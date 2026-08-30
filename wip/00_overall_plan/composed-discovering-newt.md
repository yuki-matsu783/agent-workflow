---
type: plan
title: task-gh-feature を GitHub/GitLab 両対応にする 全体計画
description: task-gh-feature スキルの gh 専用コマンドを GitHub/GitLab 両対応に書き換える計画
tags: [task-gh-feature, gitlab, glab, スキル改修]
keywords: [task-gh-feature, glab, mr create, GitHub, GitLab, 両対応]
---

# task-gh-feature を GitHub/GitLab 両対応にする 全体計画

- 対象 issue: #23 https://github.com/yuki-matsu783/agent-workflow/issues/23
- PR: #24 https://github.com/yuki-matsu783/agent-workflow/pull/24

## Context

`task-gh-feature` は feature ブランチと PR を作る中核スキルだが、`gh`（GitHub CLI）専用のため
GitLab プロジェクトでは使えない。同種の対応は `task-repo-merge-settings`・`task-gh-install`（#18,
完了）・`task-gh-issue`（#20, 対応中 PR #21）で先行しており、いずれも「`git remote get-url origin`
のホスト名で GitHub/GitLab を判定し、対応する CLI（`gh`/`glab`）のコマンドに切り替える」という
共通パターンを採っている。`task-gh-feature` だけがこのパターンから外れており、GitHub/GitLab 両対応を
謳う `task-gh-install`・`task-repo-merge-settings` の効果を打ち消している状態にある。本ワークは
`task-gh-feature` を同じパターンに揃え、workflow-issue-mr-driven からの呼び出し経路も含めて
GitHub/GitLab 双方で使えるようにする。

## 対応方針（コマンド対応表）

`task-repo-merge-settings/SKILL.md` の判定方式・`task-gh-install`/`task-gh-issue` のコマンド
併記スタイルをそのまま踏襲する。GitLab 側は GitLab CLI 公式ドキュメント
（`gitlab-org/cli` の `docs/source/mr/create.md` 等）で確認済みの以下オプションを使う。

| 用途 | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|
| CLI 導入確認 | `gh --version` | `glab --version` |
| CLI 認証確認 | `gh auth status` | `glab auth status` |
| デフォルトブランチ取得 | `gh api repos/ORG/REPO --jq '.default_branch'` | `glab api projects/GROUP%2FPROJECT --jq '.default_branch'`（`/` は `%2F` エンコード。`gitlab-merge-settings.sh` と同じ方式） |
| PR/MR 作成（本文直接） | `gh pr create --repo ORG/REPO --base BASE --head BRANCH --title T --body B [--draft]` | `glab mr create --source-branch BRANCH --target-branch BASE --title T --description B [--draft] --yes` |
| PR/MR 作成（本文ファイル） | `gh pr create --body-file PATH` | `glab mr create --description-file PATH` |
| PR/MR 作成（ブラウザ） | `gh pr create --web` | `glab mr create --web` |
| PR/MR 本文更新 | `gh pr edit N --body-file PATH` | `glab mr update N --description-file PATH` |
| draft 解除 | `gh pr ready N` | `glab mr update N --ready` |
| CI 確認 | `gh pr checks N` | `glab ci status --branch=BRANCH` |
| ブランチ名衝突チェック | `git ls-remote --heads origin BRANCH_NAME`（共通・変更なし） | 同左 |

`--yes` は `glab mr create` が非対話実行だと確認プロンプトで止まるための対応
（`.claude/rules/claude-config-headless-awareness.md` 準拠。`gh pr create` は非対話でも
既定で確認を挟まないため不要）。

## チケット分割

1. **001-ai-asset-implementation-gitlab対応.md**（`ai-asset-implementation`）
   - `task-gh-feature/SKILL.md`: frontmatter description に GitLab/glab のトリガー語を追加。
     手順0（前準備チェック）にプラットフォーム判定（`task-repo-merge-settings` と同方式、
     判定不能なら `AskUserQuestion`）を追加。手順1・6・issue連携モードのコマンドを上表に沿って
     GitHub/GitLab 併記に書き換える。手順7・「考慮すべき状況」・エラーハンドリング表も
     GitLab 観点（未導入/未認証/判定不能）を追記
   - `task-gh-feature/assets/pr.template.md`: PR/MR 双方で使える内容のため変更不要（据え置き）
   - `task-gh-feature/evals/evals.json`: 既存 3 件（GitHub）はそのまま残し、GitLab（`glab mr
     create` 系コマンドを期待する）シナリオを 1 件追加
   - `workflow-issue-mr-driven/SKILL.md` のエラーハンドリング表「origin が GitHub でない →
     対象外として報告する（GitLab の MR は未対応）」を「GitLab でも task-gh-feature が対応する」旨に更新
   - DoD は issue #23 の受け入れ条件をそのまま使う
2. **002-retrospective-振り返り.md**（`retrospective`）
   - 作業ログを読み、`wip/30_reports/` に結果報告を作成
   - ワーク完了チェックポイントは「レビュー結果: 未実施（今後の自動化対象）」と明記（`work-ticket-driven`
     手順6の現状運用どおり）

investigation チケットは起こさない。GitLab 側のコマンド仕様は本計画作成時に GitLab CLI 公式ドキュメントで
確認済みで、判定パターンも既存3スキルから流用するだけのため、追加調査コストに見合わない
（`task-gh-install` の #18 実装時も investigation なしで直接 `ai-asset-implementation` から着手した前例に倣う）。

## 検証方法

- この実行環境には `gh`/`glab` いずれも未導入（`gh: command not found` 済み確認）のため、コマンドの
  実行結果そのものを確認することはできない。GitHub 側は元の記述を変更しない範囲に留め、GitLab 側は
  公式ドキュメントで確認したオプションのみを使うことで正確性を担保する
- `evals/evals.json` に追加する GitLab シナリオで、期待するコマンド列（`glab repo view`/`glab api`
  でのデフォルトブランチ取得、`glab mr create --draft --yes` 等）を明文化し、将来のスキル実行時の
  期待値として機能させる
- SKILL.md 全体を読み直し、GitHub 専用の記述（`gh` 決め打ちの文言、「GitHub のリポジトリ設定」等の
  表現）が残っていないか確認する
