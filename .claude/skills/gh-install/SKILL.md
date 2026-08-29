---
name: gh-install
description: >
  Installs the `gh` CLI (GitHub CLI). Use when the user mentions "gh をインストールして", "GitHub CLI 入れて",
  "gh コマンドが使えない", "gh install", or needs to set up GitHub CLI in their environment.
compatibility:
  - bash
  - sudo（Linux の場合、パッケージマネージャによるインストールに必要）
  - Homebrew（macOS の場合）
---

# gh-install — `gh` CLI をインストールする

ユーザーの環境に応じて、決定論的に `gh`（GitHub CLI）をインストールする。

## 手順 1: インストールの確認

まず `gh` が既にインストールされているか確認する。

```bash
gh --version 2>/dev/null || echo "not installed"
```

既にインストールされている場合は、バージョンを表示して終了する。

## 手順 2: インストールスクリプトの実行

インストールが必要な場合は、同梱のシェルスクリプトを実行して決定論的にインストールする。

```bash
bash scripts/install_gh.sh
```

`scripts/install_gh.sh` は以下のロジックでプラットフォームに適した方法を選択する：

| プラットフォーム | パッケージマネージャ | インストール方法 |
|-----------------|---------------------|-----------------|
| macOS | Homebrew | `brew install gh` |
| Debian / Ubuntu | apt | 公式リポジトリから |
| Fedora / RHEL / CentOS | dnf / yum | 公式リポジトリから |
| Arch Linux | pacman | `pacman -Sy gh` |
| Alpine Linux | apk | `apk add gh` |
| その他 | — | 公式リリースアーカイブから |

### スクリプトの動作詳細

1. **事前チェック**: `gh` が既にインストールされていれば即終了
2. **OS 検出**: `uname -s` で macOS / Linux / その他を判定
3. **ディストリビューション検出**: `/etc/debian_version`、`/etc/fedora-release` 等で Linux の種別を判定
4. **インストール実行**: 検出されたプラットフォームに対応するコマンドを実行
5. **検証**: `gh --version` でインストールを確認

## 手順 3: 認証の案内

インストール後、`gh` を使用するには認証が必要です。

```bash
gh auth login
```

ユーザーに `gh auth login` を実行するよう案内する。

## エラーハンドリング

- **権限エラー**: `sudo` が必要な場合はパスワードを要求する旨をユーザーに伝える
- **ネットワークエラー**: インターネット接続を確認する旨を伝える
- **サポート外プラットフォーム**: 公式インストーラ（tarball）でのインストールを試みるが、失敗した場合はエラーメッセージを表示する
