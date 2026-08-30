---
type: spec
title: gh/glab CLIインストール 仕様
description: プラットフォーム判定〜決定論的インストールの入出力・処理フロー
tags: [task-gh-install, github, gitlab, cli]
keywords: [gh, glab, install, OS検出, ディストリビューション検出, ヘッドレス]
---

# gh/glab CLIインストール 仕様書

## 概要

- **背景・目的**: `.claude/docs/00_requirements/CLIインストール.md` を参照。
- **スコープ**: `task-gh-install` スキルの判定・確認・インストール・認証案内の入出力と処理フローを定義する。

---

## 入力（Input）定義

### 入力元

- **入力元**: ユーザーの依頼、および `git remote get-url origin` から取得するリポジトリ情報

### 入力データ

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| プラットフォーム | string | Y（自動判定） | `origin` のホスト名から GitHub/GitLab を判定。判定不能なら `AskUserQuestion` | - |
| インストール承認 | bool | Y | `AskUserQuestion` の回答 | - |

### 入力フォーマット

CLI引数・対話確認のみ。構造化データは扱わない。

---

## 出力（Output）定義

### 出力先

- **出力先**: ローカル環境（`${HOME}/.local/bin` にCLIバイナリを配置、または各パッケージマネージャ経由）とユーザーへの報告

### 出力データ

| 項目名 | 型 | 説明 | デフォルト値 |
|--------|----|------|-------------|
| インストール結果 | string | `<CLI> --version` の出力 | - |
| 認証案内 | string | `gh auth login`/`glab auth login` の案内文 | - |

### ステータス（スキルの終了状態）

| 状態 | 意味 |
|------|------|
| 既導入 | バージョン表示のみで終了 |
| インストール成功 | バージョン表示 + 認証案内 |
| 承認拒否 | 手動インストール手順を案内して終了 |
| ヘッドレス自動拒否 | インストールを行わず停止（スクリプト直接呼び出しを案内） |
| 失敗 | エラーメッセージを表示 |

---

## 処理フロー

### 基本フロー

1. `git remote get-url origin` でプラットフォームを判定する
2. `gh --version`/`glab --version` で導入確認する。既導入ならバージョン表示のみで終了
3. 未導入の場合、`AskUserQuestion` でインストール可否を確認する
4. 承認された場合のみ `scripts/install_gh.sh`/`scripts/install_glab.sh` を実行する
5. 認証コマンド（`gh auth login`/`glab auth login`）を案内する

### 代替フロー（インストールスクリプトの内部動作）

1. 事前チェック: 対象CLIが既にインストールされていれば即終了
2. OS検出: `uname -s` で macOS / Linux / その他を判定
3. ディストリビューション検出: `/etc/debian_version`・`/etc/fedora-release` 等でLinuxの種別を判定
4. インストール実行: 検出されたプラットフォームに対応するコマンド（下記インターフェース定義参照）を実行
5. 検証: `<CLI> --version` でインストールを確認

### 例外フロー

1. ヘッドレス実行で `AskUserQuestion` に応答できない → 自動的に拒否として扱われ停止する。ヘッドレスで確実にインストールしたい場合はスキルを介さず `bash scripts/install_gh.sh` を直接呼び出す
2. ユーザーがインストールを拒否 → 公式サイト（GitHub: https://cli.github.com/ 、GitLab: https://gitlab.com/gitlab-org/cli#installation ）の手動手順を案内
3. 権限エラー（sudo要求） → その旨を伝える
4. ネットワークエラー → インターネット接続の確認を促す
5. サポート外プラットフォーム → 公式リリースアーカイブでのインストールを試行し、失敗時はエラーメッセージを表示

---

## データ設計

### プラットフォーム別インストール方法

| プラットフォーム | パッケージマネージャ | gh | glab |
|-----------------|---------------------|----|------|
| macOS | Homebrew | `brew install gh` | `brew install glab`（公式サポート） |
| Debian / Ubuntu | apt | 公式リポジトリ登録 → `apt install gh` | WakeMeOpsリポジトリ登録 → `apt install glab` |
| Fedora / RHEL / CentOS | dnf / yum | 公式リポジトリから | 公式リポジトリの`glab`パッケージから |
| Arch Linux | pacman | `pacman -Sy gh` | `pacman -S glab`（extra） |
| Alpine Linux | apk | `apk add gh` | `apk add glab`（community） |
| その他 | — | 公式リリースアーカイブから | GitLabリリースtarballから |

---

## インターフェース定義

### 既存スキルへの委譲内容

| 呼び出し元 | 用途 |
|-----------|------|
| `task-gh-feature` | CLI未導入・未認証時の案内先 |
| `task-gh-issue` | 同上 |
| `task-repo-merge-settings` | 同上 |

### 使用するコマンド

| 用途 | コマンド |
|------|---------|
| 判定 | `git remote get-url origin` |
| 導入確認 | `gh --version` / `glab --version` |
| インストール | `bash scripts/install_gh.sh` / `bash scripts/install_glab.sh` |
| 認証 | `gh auth login` / `glab auth login` |

---

## エラーハンドリング

### エラーコード一覧

| 状況 | 対処 |
|------|------|
| プラットフォーム判定不能 | `AskUserQuestion` で確認（推測しない） |
| インストール拒否 | 手動インストール手順を案内して終了 |
| 権限エラー | sudoパスワード要求の旨を伝える |
| ネットワークエラー | インターネット接続の確認を促す |
| サポート外プラットフォーム | 公式インストーラ（tarball）を試行、失敗時はエラー表示 |

---

## 前提条件

`.claude/docs/00_requirements/CLIインストール.md` の前提条件を参照。

## 制約条件

`.claude/docs/00_requirements/CLIインストール.md` の制約条件を参照。

## 非機能要件

`.claude/docs/00_requirements/CLIインストール.md` の非機能要件を参照。

---

## テストシナリオ

### テストケース一覧

| テストID | シナリオ | 入力 | 期待出力 | 結果 |
|---------|---------|------|---------|------|
| TC001 | 既導入時の確認のみ | ghインストール済み環境 | バージョン表示のみで終了 | |
| TC002 | 未導入・承認ありのインストール | GitHubリポジトリ、Debian環境 | ghがaptでインストールされる | |
| TC003 | 未導入・承認なし | インストール確認で拒否 | 手動インストール手順を案内して終了 | |
| TC004 | ヘッドレス実行での自動拒否 | `claude -p`、未導入 | 確認できず自動拒否、停止 | |

---

## 関連するドキュメント

- `.claude/skills/task-gh-install/SKILL.md`
- `.claude/docs/00_requirements/CLIインストール.md`
- `.claude/rules/claude-config-headless-awareness.md`

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
