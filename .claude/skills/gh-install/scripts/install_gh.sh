#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install_gh.sh — GitHub CLI (gh) をプラットフォームに応じて
# 決定論的にインストールするシェルスクリプト
# ============================================================

# 既定のインストール先（後続のコマンドで gh を見つけられるように PATH を通す）
GH_BIN_DIR="${HOME}/.local/bin"
mkdir -p "${GH_BIN_DIR}"

# ---------- 事前チェック ----------

if command -v gh &>/dev/null; then
    echo "gh は既にインストールされています: $(gh --version 2>&1 | head -1)"
    exit 0
fi

echo "gh のインストールを開始します..."

# ---------- OS 検出 ----------

OS="$(uname -s)"

install_linux_deb() {
    # Debian / Ubuntu 用 — 公式リポジトリからインストール
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://download.github.com/gh-keyring.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/gh-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gh-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh
}

install_linux_rpm() {
    # Fedora / RHEL / CentOS 用 — 公式リポジトリからインストール
    if command -v dnf &>/dev/null; then
        sudo dnf install -y gh
    elif command -v yum &>/dev/null; then
        sudo yum install -y gh
    else
        echo "Error: dnf も yum も見つかりません。" >&2
        exit 1
    fi
}

install_linux_arch() {
    # Arch Linux 用
    sudo pacman -Sy --noconfirm gh
}

install_linux_apk() {
    # Alpine Linux 用
    sudo apk add gh
}

install_macos() {
    # macOS 用 — Homebrew が利用可能ならそこから、なければ公式インストーラ
    if command -v brew &>/dev/null; then
        brew install gh
    else
        echo "Homebrew が見つかりません。公式インストーラを使用します。"
        curl -fsSL https://github.com/cli/cli/releases/latest/download/gh_linux_amd64.tar.gz -o /tmp/gh.tar.gz
        tar -xzf /tmp/gh.tar.gz -C "${GH_BIN_DIR}" --strip-components=2 gh_*/bin/gh
        rm -f /tmp/gh.tar.gz
    fi
}

install_other() {
    # その他の UNIX — 公式のリリースアーカイブからインストール
    echo "検出できないプラットフォームです。公式インストーラを使用します。"
    local platform
    platform="$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m)"
    curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_${platform}.tar.gz" -o /tmp/gh.tar.gz
    tar -xzf /tmp/gh.tar.gz -C "${GH_BIN_DIR}" --strip-components=2 gh_*/bin/gh
    rm -f /tmp/gh.tar.gz
}

# ---------- インストール実行 ----------

case "${OS}" in
    Linux)
        if [ -f /etc/debian_version ]; then
            install_linux_deb
        elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
            install_linux_rpm
        elif command -v pacman &>/dev/null; then
            install_linux_arch
        elif command -v apk &>/dev/null; then
            install_linux_apk
        else
            install_linux_rpm
        fi
        ;;
    Darwin)
        install_macos
        ;;
    *)
        install_other
        ;;
esac

# ---------- 検証 ----------

export PATH="${GH_BIN_DIR}:${PATH}"

if command -v gh &>/dev/null; then
    echo "gh のインストールが完了しました: $(gh --version 2>&1 | head -1)"
else
    echo "Error: gh のインストールに失敗しました。" >&2
    echo "PATH に '${GH_BIN_DIR}' が追加されたターミナルで再度ログインするか、手動でインストールしてください。" >&2
    exit 1
fi
