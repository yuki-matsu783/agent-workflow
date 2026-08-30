---
type: requirements
title: issue操作（検索・作成・編集） 要件定義
description: gh/glab CLIでGitHub/GitLab issueを検索・作成・編集する要件
tags: [task-gh-issue, github, gitlab, issue]
keywords: [issue, 検索, 作成, 編集, gh, glab, テンプレート]
---

# issue操作（検索・作成・編集） 要件定義

## 概要

- **背景**: issue駆動で開発を進める（`workflow-issue-mr-driven`）際、既存issueとの重複確認、issueの新規作成、既存issueへの追記といった操作を都度手動で行うと、既存本文の消失やテンプレート未使用による情報不足が起きやすい。
- **目的**: `git remote get-url origin` からホスト（GitHub/GitLab）を判定し、対応するCLI（`gh`/`glab`）でissueの検索・作成・編集を一貫した手順で行えるようにする。既存issueへの追記では本文を保全する。
- **スコープ**:
  - 含む: ホスト判定、検索モード、作成モード、編集モード（本文追記・タイトル/ラベル/状態変更・コメント）
  - 含まない: feature ブランチ・PR/MRの作成（`task-gh-feature` が担当）、issueに紐づくチケット駆動ワークフローの実施（`work-ticket-driven` が担当）

---

## ユーザーストーリー

**[As a]** GitHub/GitLab issueを扱う開発者として、

**[I want]** 検索・作成・編集の3モードを一貫した手順で扱いたい、

**[So that]** 重複issueの作成や既存issue本文の消失を避け、テンプレートに沿った情報の揃ったissueを維持できるため。

### ユーザーストーリーの別パターン

| パターン | フォーマット | 例 |
|---------|------------|-----|
| 条件付き | Unless | Unless 既存issueへの追記の場合、既存本文を消してはならない |

---

## 受け入れ基準（Acceptance Criteria）

### メインフロー

- When issueの検索・作成・編集のいずれかが依頼されたとき、Shall `git remote get-url origin` でホストを判定し、対応するCLIを選択しなければならない
- When `workflow-issue-mr-driven` から呼ばれたとき、Shall 指定されたモード（検索/作成/編集）に従わなければならない
- When 単独で呼ばれたとき、Shall 依頼文言（「作って」「探して」「直して」等）からモードを判断しなければならない

### 検索モードのフロー

- When issueを検索するとき、Shall キーワード（日本語・英語の両方）でopen issueを検索し、0件ならclosedも含めて再検索しなければならない

### 作成モードのフロー

- When issueを作成するとき、Shall タイトルを必ずユーザーから取得しなければならない
- When 本文が指定されていないとき、Shall `assets/issue.template.md` を読み込み、テンプレートとして使用しなければならない

### 編集モード（追記）のフロー

- When 既存issueに追記するとき、Shall 現在の本文を取得し、末尾に追記セクションを付けた全文で更新しなければならない（既存の記述を消してはならない）
- When 追記が完了したとき、Shall 既存部分が変わっていないことを確認しなければならない

### アルタナティブフロー（代替経路）

- When 自社ホスト（GitHub Enterprise / self-managed GitLab）等でホストが判定できないとき、Shall ユーザーにGitHub/GitLabの別と `org/repo`（`group/project`）を確認しなければならない
- When 検索結果が0件のとき、Shall キーワードを変えるか `--state all`/`--all` でclosedを含めて再検索しなければならない

### 例外フロー（エラーケース）

- When `gh`/`glab` が未導入・未認証であるとき、Shall `task-gh-install` または認証コマンドを案内しなければならない
- When `gh issue edit`/`glab issue update` が権限や番号違いで失敗したとき、Shall コマンドと出力をそのまま報告し、別の方法で代替してはならない

---

## 前提条件

- 対象が git リポジトリであり、`origin` からホストを判定できること（判定不能時はユーザーに確認）
- `gh`（GitHub）または `glab`（GitLab）が導入・認証済みであること

---

## 制約条件

- **技術的制約**: ホスト判定は `task-repo-merge-settings` と同じ方式に統一する
- **ビジネス的制約**: 特になし
- **外部的制約**: issueのクローズはPR/MRの `Closes #N` によるマージ時の自動クローズに委ね、通常は手動でクローズしない

---

## 依存関係

- `task-gh-install`: CLI未導入時の案内先
- `workflow-issue-mr-driven`: 検索/作成/編集モードの呼び出し元（`references/issue-triage.md` の類似判定基準を使用）
- `workflow-quick-request`: 振り返りからのissue化で作成モードを使用

---

## 非機能要件

| 項目 | 説明 |
|------|------|
| 一貫性 | GitHub/GitLabのどちらでも同じ3モード構成で操作できること |
| データ保全性 | 追記時に既存本文を破壊しないこと |

---

## 関連するドキュメント

- `.claude/skills/task-gh-issue/SKILL.md`
- `.claude/docs/10_spec/skill-task-gh-issue.md`

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
