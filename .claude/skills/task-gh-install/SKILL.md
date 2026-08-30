---
name: task-gh-install
description: >
  Installs the CLI that matches the current project's platform — `gh` (GitHub CLI) for GitHub, `glab`
  (GitLab CLI) for GitLab. Use when the user mentions "gh をインストールして", "GitHub CLI 入れて",
  "gh コマンドが使えない", "gh install", "glab をインストールして", "GitLab CLI 入れて",
  "glab コマンドが使えない", "glab install", or needs to set up gh/glab in their environment.
compatibility:
  - bash
  - sudo（Linux の場合、パッケージマネージャによるインストールに必要）
  - Homebrew（macOS の場合。glab は Homebrew が公式サポートするインストール方法）
  - glab の非 Homebrew インストールは Debian/Ubuntu は WakeMeOps リポジトリ、Fedora/RHEL/CentOS は
    dnf/yum、Arch は pacman（extra/glab）、Alpine は apk と、ディストリビューションごとに経路が異なる
---

# task-gh-install — プロジェクトに応じて `gh`/`glab` CLI をインストールする

現在のプロジェクトが GitHub / GitLab のどちらかを自動判定し、対応する CLI
（GitHub なら `gh`、GitLab なら `glab`）を決定論的にインストールする。

> **ヘッドレス実行での注意**（`.claude/rules/claude-config-headless-awareness.md` 準拠）:
> 手順3の確認は `AskUserQuestion` で行うため、ユーザーに確認できないヘッドレス実行（`claude -p`、CI 等）
> では自動的に「拒否」として扱われ、インストールは行われずに停止する。ヘッドレスでも決定論的に
> インストールしたい場合は、このスキルを使わず `bash scripts/install_gh.sh` /
> `bash scripts/install_glab.sh` を直接呼び出す（確認ステップを経ない）。

## 手順 1: プロジェクトのプラットフォーム判定

`task-repo-merge-settings` と同じ方式で判定する。

```bash
git remote get-url origin
```

- ホスト名に `github.com` を含む、または GitHub Enterprise 等で GitHub と明言されている → GitHub
- ホスト名に `gitlab.com` を含む、または GitLab Self-Managed 等で GitLab と明言されている → GitLab
- git リポジトリでない、`origin` が無い、ホスト名からどちらか判定できない場合は、`AskUserQuestion` で
  「GitHub / GitLab のどちらの CLI をインストールするか」をユーザーに確認する。推測で決め打ちしない

## 手順 2: 対応する CLI の導入確認

判定結果に応じて確認する。

```bash
# GitHub の場合
gh --version 2>/dev/null || echo "not installed"

# GitLab の場合
glab --version 2>/dev/null || echo "not installed"
```

既にインストールされている場合は、バージョンを表示して終了する。

## 手順 3: 未導入時のインストール確認

未導入の場合、**インストールしてよいか `AskUserQuestion` でユーザーに確認する**。
承認が得られるまでインストールスクリプトを実行しない。

- 確認内容の例:「`gh`（GitHub CLI）がインストールされていません。インストールしてよいですか？」
- ユーザーが拒否した場合は、インストールを行わずに手動インストール手順（GitHub:
  <https://cli.github.com/>、GitLab: <https://gitlab.com/gitlab-org/cli#installation>）を案内して終了する

## 手順 4: インストールスクリプトの実行

承認された場合のみ、同梱のシェルスクリプトを実行して決定論的にインストールする。

```bash
# GitHub の場合
bash scripts/install_gh.sh

# GitLab の場合
bash scripts/install_glab.sh
```

### `scripts/install_gh.sh` の動作

| プラットフォーム | パッケージマネージャ | インストール方法 |
|-----------------|---------------------|-----------------|
| macOS | Homebrew | `brew install gh` |
| Debian / Ubuntu | apt | 公式リポジトリから |
| Fedora / RHEL / CentOS | dnf / yum | 公式リポジトリから |
| Arch Linux | pacman | `pacman -Sy gh` |
| Alpine Linux | apk | `apk add gh` |
| その他 | — | 公式リリースアーカイブから |

### `scripts/install_glab.sh` の動作

| プラットフォーム | パッケージマネージャ | インストール方法 |
|-----------------|---------------------|-----------------|
| macOS | Homebrew（公式サポート） | `brew install glab` |
| Debian / Ubuntu | apt（WakeMeOps リポジトリ経由） | WakeMeOps のリポジトリ登録スクリプト → `apt install glab` |
| Fedora / RHEL / CentOS | dnf / yum | 公式リポジトリの `glab` パッケージから |
| Arch Linux | pacman | `pacman -S glab`（公式 extra リポジトリ） |
| Alpine Linux | apk | `apk add glab`（community リポジトリ） |
| その他 | — | GitLab のリリース tarball（`glab_<version>_<os>_<arch>.tar.gz`）から |

両スクリプトとも以下の流れで動作する:

1. **事前チェック**: 対象 CLI が既にインストールされていれば即終了
2. **OS 検出**: `uname -s` で macOS / Linux / その他を判定
3. **ディストリビューション検出**: `/etc/debian_version`、`/etc/fedora-release` 等で Linux の種別を判定
4. **インストール実行**: 検出されたプラットフォームに対応するコマンドを実行
5. **検証**: `<CLI> --version` でインストールを確認

## 手順 5: 認証の案内

インストール後、CLI を使用するには認証が必要です。

```bash
# GitHub の場合
gh auth login

# GitLab の場合
glab auth login
```

ユーザーに該当するコマンドを実行するよう案内する。

## エラーハンドリング

| 状況 | 対処 |
|------|------|
| プラットフォーム判定不能（origin なし、ホスト名から判定できない等） | 推測で決め打ちせず、`AskUserQuestion` で GitHub/GitLab のどちらか確認する |
| インストールが拒否された（手順3で承認されなかった） | インストールを行わず、公式サイトの手動インストール手順を案内して終了する |
| 権限エラー | `sudo` が必要な場合はパスワードを要求する旨をユーザーに伝える |
| ネットワークエラー | インターネット接続を確認する旨を伝える |
| サポート外プラットフォーム | 公式インストーラ（tarball）でのインストールを試みるが、失敗した場合はエラーメッセージを表示する |
