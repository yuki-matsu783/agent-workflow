---
type: requirements
title: featureブランチとPR/MR作成 要件定義
description: gh/glab CLIでfeatureブランチとPR/MRを一貫した手順で作成する要件
tags: [task-gh-feature, github, gitlab, branch, pull-request]
keywords: [feature branch, PR, MR, gh, glab, issue連携モード, draft]
---

# featureブランチとPR/MR作成 要件定義

## 概要

- **背景**: 開発作業を始める際、デフォルトブランチの確認・最新化、feature ブランチの作成、PR/MR の作成という一連の手順は GitHub と GitLab で使うコマンドが異なり、都度判断すると手順の抜け漏れ（未コミット変更の見落とし、ベースブランチの古さ、ブランチ名衝突）が起きやすい。
- **目的**: `git remote get-url origin` からプラットフォーム（GitHub/GitLab）を自動判定し、対応する CLI（`gh`/`glab`）で feature ブランチと PR/MR を一貫した手順で作成できるようにする。`workflow-issue-mr-driven` から呼ばれる場合は、承認済みの情報を機械的に反映する専用モード（issue 連携モード）を提供する。
- **スコープ**:
  - 含む: プラットフォーム判定、前準備チェック、ベースブランチの最新化、feature ブランチの作成・push、PR/MR の作成、issue 連携モード
  - 含まない: issue の検索・作成・編集（`task-gh-issue` が担当）、マージ関連設定の変更（`task-repo-merge-settings` が担当）、CLI 自体のインストール（`task-gh-install` が担当）

---

## ユーザーストーリー

**[As a]** GitHub/GitLab リポジトリで開発作業を行う開発者として、

**[I want]** デフォルトブランチを自動判定してfeatureブランチを切り、PR/MRを一貫した手順で作成したい、

**[So that]** プラットフォームごとのコマンドの違いや手順の抜け漏れを気にせず、安全に作業を開始できるため。

### ユーザーストーリーの別パターン

| パターン | フォーマット | 例 |
|---------|------------|-----|
| 標準 | As a / I want / So that | As a 開発者として、I want feature ブランチと draft PR を一度に作りたい、So that issue に紐づいた作業をすぐ開始できるため |
| 条件付き | Unless | Unless 未コミットの変更がある場合、ブランチ作成を進めない |

---

## 受け入れ基準（Acceptance Criteria）

### メインフロー

- When ユーザーが feature ブランチと PR/MR の作成を依頼したとき、Shall `git remote get-url origin` からプラットフォームを判定し、対応する CLI（`gh`/`glab`）を選択しなければならない
- When プラットフォーム判定が完了したとき、Shall デフォルトブランチを取得し、最新化してからブランチを作成しなければならない
- When ブランチが作成されたとき、Shall リモートに push し、PR/MR を作成しなければならない

### issue 連携モード（`workflow-issue-mr-driven` から呼ばれる場合）

- When issue 番号・ブランチ名・PR/MR タイトル・ベースブランチが呼び出し元から承認済みとして渡されたとき、Shall 対話的な確認（手順2・3・6）を省略し、機械的に実行しなければならない
- When issue 連携モードでブランチを作成したとき、Shall 差分ゼロによる PR/MR 作成失敗を避けるため、空コミットを作成してから push しなければならない
- When issue 連携モードで PR/MR を作成するとき、Shall 本文の「関連 Issue」に `Closes #N` を含め、draft として作成しなければならない

### アルタナティブフロー（代替経路）

- When デフォルトブランチが `main` 以外（`master`/`develop`/`trunk` 等）であるとき、Shall それをベースとして使用しなければならない
- When `git pull --ff-only` が失敗したとき、Shall ユーザーに通常マージまたはリベースを確認しなければならない
- When feature ブランチ名がリモートに既に存在するとき、Shall 別名を提案するかユーザーに確認しなければならない

### 例外フロー（エラーケース）

- When 未コミットの変更があるとき、Shall 自分で判断して stash・コミット・破棄をせず、`AskUserQuestion` でユーザーに扱いを確認しなければならない
- When `gh`/`glab` が未導入・未認証であるとき、Shall `task-gh-install` スキルまたは認証コマンドを案内して停止しなければならない
- When PR/MR 作成が差分なしで失敗したとき、Shall 空コミットを作成して再試行しなければならない
- When `origin` が GitHub でも GitLab でもないとき、Shall 対象外として報告しなければならない

---

## 前提条件

- 作業対象が git リポジトリであり、`origin` リモートが設定されていること
- `gh`（GitHub）または `glab`（GitLab）が導入・認証済みであること（未導入時は `task-gh-install` を案内）

---

## 制約条件

- **技術的制約**: プラットフォーム判定は `task-repo-merge-settings`・`task-gh-issue` と同じ方式（`git remote get-url origin` のホスト名判定）に統一する
- **ビジネス的制約**: 特になし
- **外部的制約**: GitHub/GitLab 以外のホスティングサービスは対象外

---

## 依存関係

- `task-repo-merge-settings`: プラットフォーム判定方式を共有
- `task-gh-install`: CLI 未導入時の案内先
- `workflow-issue-mr-driven`: issue 連携モードの呼び出し元

---

## 非機能要件

| 項目 | 説明 |
|------|------|
| 一貫性 | GitHub/GitLab のどちらでも同じ手順の流れ（判定→前準備→ベース最新化→ブランチ作成→push→PR/MR作成）を辿ること |
| 安全性 | 未コミットの変更・ブランチ名衝突・差分ゼロなど、失敗しうる状態を事前に検知しユーザーに確認すること |

---

## 関連するドキュメント

- `.claude/skills/task-gh-feature/SKILL.md`
- `.claude/docs/10_spec/featureブランチとPR作成.md`

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
