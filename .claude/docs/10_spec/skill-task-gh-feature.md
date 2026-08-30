---
type: spec
title: featureブランチとPR/MR作成 仕様
description: gh/glab CLIによるfeatureブランチ・PR/MR作成の入出力・処理フロー
tags: [task-gh-feature, github, gitlab, branch, pull-request]
keywords: [feature branch, PR, MR, gh, glab, issue連携モード, draft, 空コミット]
---

# featureブランチとPR/MR作成 仕様書

## 概要

- **背景・目的**: `.claude/docs/00_requirements/skill-task-gh-feature.md` を参照。
- **スコープ**: `task-gh-feature` スキルの通常モード・issue連携モードの入出力と処理フローを定義する。

---

## 入力（Input）定義

### 入力元

- **入力元**: ユーザーの依頼（通常モード）、または `workflow-issue-mr-driven` からの承認済みパラメータ（issue連携モード）

### 入力データ

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| プラットフォーム | string | Y（自動判定） | `git remote get-url origin` のホスト名から GitHub/GitLab を判定 | - |
| ベースブランチ | string | N | 未指定時はデフォルトブランチ | デフォルトブランチ |
| ブランチ名 | string | Y | 通常モードはユーザー指定、issue連携モードは `<prefix>-<N>-<slug>` | - |
| issue番号 | int | issue連携モードのみ必須 | `Closes #N` に使う | - |
| PR/MRタイトル・本文 | string | Y | 通常モードはユーザー指定、issue連携モードは呼び出し元が承認済みの値 | - |
| draftフラグ | bool | N | issue連携モードは常に true | false |

### 入力フォーマット

CLIコマンドの引数として渡される。JSON等の構造化フォーマットは使わない。

---

## 出力（Output）定義

### 出力先

- **出力先**: リモートリポジトリ（GitHub/GitLab）とユーザーへの報告

### 出力データ

| 項目名 | 型 | 説明 | デフォルト値 |
|--------|----|------|-------------|
| feature ブランチ名 | string | 作成・push したブランチ | - |
| ベースブランチ | string | 最新化して使用したブランチ | - |
| PR/MR URL | string | `gh pr create`/`glab mr create` の出力から取得 | - |
| PR/MR 番号 | int | あれば | - |

### ステータス（スキルの終了状態）

| 状態 | 意味 |
|------|------|
| 成功 | ブランチ・PR/MRが作成され、URLと番号を報告 |
| 中断（未コミット変更） | ユーザー確認待ちで停止 |
| 中断（CLI未導入・未認証） | `task-gh-install` 等を案内して停止 |
| 対象外 | origin が GitHub/GitLab でない |

---

## 処理フロー

### 承認ポイント

| # | タイミング | 確認内容（通常モードのみ。issue連携モードは呼び出し元で承認済みのため省略） |
|---|-----------|---------------------------------------------------------|
| ① | 手順2 | ベースブランチの確認 |
| ② | 手順3 | feature ブランチ名の確認・衝突時の代替名 |
| ③ | 手順6 | PR/MR タイトル・本文の確認 |
| ④ | 未コミット変更検知時 | コミット/stash/破棄/中断の選択 |

### 基本フロー（通常モード）

1. 前準備チェック（git リポジトリ確認、プラットフォーム判定、CLI導入・認証確認、未コミット変更確認）
2. デフォルトブランチを取得し、ユーザーに確認の上ベースブランチを決定・最新化する
3. feature ブランチ名をユーザーに確認し、リモートとの衝突をチェックする
4. `git checkout -b <branch> <base>` でブランチを作成する
5. `git push -u origin <branch>` でリモートへ push する
6. PR/MR のタイトル・本文を収集し、`gh pr create` / `glab mr create` で作成する（テンプレート `assets/pr.template.md` を利用可）
7. ブランチ名・ベース・PR/MR の URL と番号を報告する

### 代替フロー（issue連携モード）

1. 前準備チェック（未コミット変更があれば呼び出し元に戻す）
2. ベースブランチを最新化する（対話確認なし）
3. ブランチ名の衝突チェック（衝突時は末尾に `-2` 等を付けて呼び出し元に戻す）
4. `git checkout -b <branch> <base>` の後、**空コミット**（`chore: start #N <slug>`）を作成して push する
5. `assets/pr.template.md` を土台に「関連 Issue」へ `Closes #N` を書いた本文で **draft** PR/MR を作成する
6. URL・番号を呼び出し元へ返す

### 例外フロー

1. 未コミットの変更を検知 → `AskUserQuestion` でコミット/stash/破棄/中断を確認（自動判断しない）
2. `gh`/`glab` 未導入・未認証 → `task-gh-install` または認証コマンドを案内して停止
3. PR/MR 作成が差分なしで失敗 → 空コミットを作成して再試行
4. ブランチ名衝突 → 別名を提案
5. `origin` が GitHub/GitLab 以外 → 対象外として報告

---

## データ設計

### 命名規約

| 対象 | 通常モード | issue連携モード |
|------|-----------|-----------------|
| ブランチ | ユーザー指定（例: `feature/ログイン画面実装`） | `<prefix>-<N>-<slug>`（ハイフン区切りのみ。`prefix`はバグなら`fix`、それ以外は`feature`） |
| PR/MRタイトル | ユーザー指定 | `<prefix>: <issueタイトル> (#<N>)` |

### 責務の分担

| 呼び出し元 | 承認 | 実行 |
|-----------|------|------|
| ユーザー直接依頼（通常モード） | 各手順内で対話確認 | `task-gh-feature` が全手順を実行 |
| `workflow-issue-mr-driven`（issue連携モード） | 呼び出し元の承認②で確定済み | `task-gh-feature` は機械的に実行するのみ |

---

## インターフェース定義

### 使用するghコマンド

| 用途 | GitHub | GitLab |
|------|--------|--------|
| プラットフォーム判定 | `git remote get-url origin` | 同左 |
| デフォルトブランチ取得 | `gh repo view --json defaultBranchRef` | `glab api "projects/GROUP%2FPROJECT" --jq '.default_branch'` |
| ブランチpush | `git push -u origin <branch>` | 同左 |
| PR/MR作成 | `gh pr create --base <base> --head <branch> --title ... --body-file ... [--draft]` | `glab mr create --source-branch <branch> --target-branch <base> --title ... --description-file ... [--draft] --yes` |
| PR/MR本文更新・ready化 | `gh pr edit N --body-file <path>` / `gh pr ready N` | `glab mr update N --description-file <path>` / `glab mr update N --ready` |

---

## エラーハンドリング

### エラーケース一覧

| エラー | 対処 |
|--------|------|
| プラットフォーム判定不能 | `AskUserQuestion` で確認（推測しない） |
| CLI未導入・未認証 | `task-gh-install` または認証コマンドを案内 |
| 未コミットの変更 | `AskUserQuestion` で扱いを確認 |
| 差分なしでPR/MR作成失敗 | 空コミットを作成して再試行 |
| ブランチ名衝突 | 別名を提案 |
| `gh pr create`/`glab mr create` の差分ゼロ以外の失敗 | コマンドと出力をそのまま報告して停止（別コマンドで代替しない） |

---

## 前提条件

`.claude/docs/00_requirements/skill-task-gh-feature.md` の前提条件を参照。

## 制約条件

`.claude/docs/00_requirements/skill-task-gh-feature.md` の制約条件を参照。

## 非機能要件

`.claude/docs/00_requirements/skill-task-gh-feature.md` の非機能要件を参照。

---

## テストシナリオ

### テストケース一覧

| テストID | シナリオ | 入力 | 期待出力 | 結果 |
|---------|---------|------|---------|------|
| TC001 | 通常モードでのブランチ・PR作成 | GitHubリポジトリ、feature名指定 | ブランチとPRが作成されURLが返る | |
| TC002 | issue連携モードでの機械的実行 | issue番号・ブランチ名・PRタイトル承認済み | 空コミット+draft PRが作成される | |
| TC003 | 未コミット変更がある場合 | 未コミットファイルあり | `AskUserQuestion` で確認され、承認まで進まない | |
| TC004 | 差分ゼロでのPR作成失敗 | 空コミットなしでPR作成試行 | 空コミット作成後に再試行し成功する | |

---

## 関連するドキュメント

- `.claude/skills/task-gh-feature/SKILL.md`
- `.claude/docs/00_requirements/skill-task-gh-feature.md`
- `.claude/docs/10_spec/skill-workflow-issue-mr-driven.md`（issue連携モードの呼び出し元仕様）

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
