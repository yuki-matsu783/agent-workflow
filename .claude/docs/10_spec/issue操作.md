---
type: spec
title: issue操作（検索・作成・編集） 仕様
description: gh/glab CLIによるissue検索・作成・編集の入出力・処理フロー
tags: [task-gh-issue, github, gitlab, issue]
keywords: [issue, 検索, 作成, 編集, gh, glab, テンプレート, 本文保全]
---

# issue操作（検索・作成・編集） 仕様書

## 概要

- **背景・目的**: `.claude/docs/00_requirements/issue操作.md` を参照。
- **スコープ**: `task-gh-issue` スキルの検索・作成・編集の3モードの入出力と処理フローを定義する。

---

## 入力（Input）定義

### 入力元

- **入力元**: ユーザーの依頼、または `workflow-issue-mr-driven`/`workflow-quick-request` からのモード指定

### 入力データ

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| モード | enum(検索/作成/編集) | Y | 呼び出し元指定 or 依頼文言から判断 | - |
| ホスト | string | Y（自動判定） | `origin` のホスト名から GitHub/GitLab を判定 | - |
| キーワード | string[] | 検索モードのみ必須 | 日本語・英語の両方を試す | - |
| タイトル・本文 | string | 作成モードのみ必須 | 本文はテンプレート優先 | `assets/issue.template.md` |
| issue番号 | int | 編集モードのみ必須 | 対象issue | - |

### 入力フォーマット

CLI引数のみ。構造化データは扱わない。

---

## 出力（Output）定義

### 出力先

- **出力先**: GitHub/GitLabリポジトリとユーザーへの報告

### 出力データ

| 項目名 | 型 | 説明 | デフォルト値 |
|--------|----|------|-------------|
| 検索結果 | table | 番号・タイトル・状態・URL | - |
| issue URL・番号 | string/int | 作成・編集後のissue | - |

### ステータス（スキルの終了状態）

| 状態 | 意味 |
|------|------|
| 成功 | issueのURL・番号を報告 |
| 検索0件 | closed含めた再検索を提案、それでも0件なら作成モードへ |
| 中断（CLI未導入・未認証） | 案内して停止 |
| 中断（ホスト判定不能） | `AskUserQuestion` で確認 |

---

## 処理フロー

### 基本フロー（モード判定）

1. `git remote get-url origin` でホストを判定する
2. 呼び出し元からモード指定があればそれに従い、単独実行なら依頼文言から判断する（「作って」→作成、「探して/ある？」→検索、「直して/追記して」→編集）
3. モードごとの処理へ分岐する

### 検索モードのフロー

1. キーワード（日本語・英語）でopen issueを検索する
2. 0件ならclosedも含めて再検索する
3. 結果を番号・タイトル・状態・URLの表で提示する（類似判定基準は呼び出し元 `references/issue-triage.md` に従う）

### 作成モードのフロー

1. タイトルをユーザーから取得する
2. 本文をテンプレート優先で収集する（`assets/issue.template.md` / カスタムテンプレートファイル / インラインコンテンツ）
3. `gh issue create`/`glab issue create` で作成する（長文は一時ファイル経由の `--body-file`/`--description-file`）
4. 作成結果のURL・番号を報告する

### 編集モードのフロー

1. **本文追記**: 現在の本文を取得 → 末尾に追記セクションを付けた全文を一時ファイルに書く → `gh issue edit`/`glab issue update` で反映 → 既存部分が変わっていないことを確認
2. **タイトル・ラベル・状態変更**: `gh issue edit`/`glab issue update`（タイトル・ラベル）、`gh issue reopen`/`close`（状態）
3. **コメント**: `gh issue comment`/`glab issue note` で進捗・残課題を追加（本文は変更しない）

### 例外フロー

1. `gh`/`glab` 未導入・未認証 → `task-gh-install` または認証コマンドを案内
2. ホスト判定不能（自社ホスト等） → `AskUserQuestion` でGitHub/GitLabの別と `org/repo` を確認
3. 検索0件 → キーワード変更または `--state all`/`--all` で再検索
4. `gh issue edit`/`glab issue update` の失敗（権限・番号違い） → コマンドと出力をそのまま報告

---

## データ設計

### 命名規約（org/repoスラグ変換）

| プラットフォーム | SSH形式 | HTTPS形式 |
|-----------------|---------|-----------|
| GitHub | `git@github.com:org/repo.git` → `org/repo` | `https://github.com/org/repo.git` → `org/repo` |
| GitLab | `git@gitlab.com:group/project.git` → `group/project` | `https://gitlab.com/group/project.git` → `group/project` |

---

## インターフェース定義

### 既存スキルへの委譲内容

| 呼び出し元 | 用途 |
|-----------|------|
| `workflow-issue-mr-driven` | 検索・作成・編集モードの指定、類似判定基準（`references/issue-triage.md`） |
| `workflow-quick-request` | 振り返りからのissue化（作成モード） |
| `task-gh-install` | CLI未導入時の案内先 |

### 使用するghコマンド

| モード | GitHub | GitLab |
|--------|--------|--------|
| 検索 | `gh issue list --search "..." --json ...` | `glab issue list --search "..." --output json` |
| 作成 | `gh issue create --title ... --body-file ...` | `glab issue create --title ... --description-file ...` |
| 編集（本文） | `gh issue edit N --body-file ...` | `glab issue update N --description-file ...` |
| 編集（状態） | `gh issue reopen N` / `gh issue close N` | `glab issue reopen N` / `glab issue close N` |
| コメント | `gh issue comment N --body-file ...` | `glab issue note N < ...` |

---

## エラーハンドリング

### エラーコード一覧

| 状況 | 対処 |
|------|------|
| `gh`/`glab` 未導入・未認証 | `task-gh-install` または認証コマンドを案内 |
| ホスト判定不能 | `AskUserQuestion` で確認（推測しない） |
| 検索0件 | キーワード変更 or closed含めて再検索 |
| 編集失敗（権限・番号違い） | コマンドと出力をそのまま報告、代替しない |

---

## 前提条件

`.claude/docs/00_requirements/issue操作.md` の前提条件を参照。

## 制約条件

`.claude/docs/00_requirements/issue操作.md` の制約条件を参照。

## 非機能要件

`.claude/docs/00_requirements/issue操作.md` の非機能要件を参照。

---

## テストシナリオ

### テストケース一覧

| テストID | シナリオ | 入力 | 期待出力 | 結果 |
|---------|---------|------|---------|------|
| TC001 | 検索モードでキーワードヒット | 既存issueに一致するキーワード | 該当issueの表が返る | |
| TC002 | 作成モードでテンプレート利用 | タイトルのみ指定 | テンプレートを土台にissue作成 | |
| TC003 | 編集モードで本文追記 | 既存issueへの追記依頼 | 既存本文が保持されたまま追記される | |
| TC004 | 検索0件からのclosed再検索 | 存在しないキーワード | closed含め再検索し0件を報告 | |

---

## 関連するドキュメント

- `.claude/skills/task-gh-issue/SKILL.md`
- `.claude/docs/00_requirements/issue操作.md`
- `.claude/skills/workflow-issue-mr-driven/references/issue-triage.md`

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
