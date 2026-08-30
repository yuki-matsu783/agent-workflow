#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install_glab.sh — GitLab CLI (glab) をプラットフォームに応じて
# 決定論的にインストールするシェルスクリプト
# ============================================================

# 既定のインストール先（後続のコマンドで glab を見つけられるように PATH を通す）
GLAB_BIN_DIR="${HOME}/.local/bin"
mkdir -p "${GLAB_BIN_DIR}"

# ---------- 事前チェック ----------

if command -v glab &>/dev/null; then
    echo "glab は既にインストールされています: $(glab --version 2>&1 | head -1)"
    exit 0
fi

echo "glab のインストールを開始します..."

# ---------- OS 検出 ----------

OS="$(uname -s)"

install_linux_deb() {
    # Debian / Ubuntu 用 — WakeMeOps リポジトリ経由（glab のコミュニティメンテナンス手段のひとつ）
    curl -sSL "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | sudo bash
    sudo apt-get install -y -qq glab
}

install_linux_rpm() {
    # Fedora / RHEL / CentOS 用 — 公式リポジトリの glab パッケージから
    if command -v dnf &>/dev/null; then
        sudo dnf install -y glab
    elif command -v yum &>/dev/null; then
        sudo yum install -y glab
    else
        echo "Error: dnf も yum も見つかりません。" >&2
        exit 1
    fi
}

install_linux_arch() {
    # Arch Linux 用 — 公式 extra リポジトリの glab パッケージ
    sudo pacman -Sy --noconfirm glab
}

install_linux_apk() {
    # Alpine Linux 用 — community リポジトリの glab パッケージ
    sudo apk add --no-cache glab
}

install_macos() {
    # macOS 用 — Homebrew が glab の公式サポートするインストール方法
    if command -v brew &>/dev/null; then
        brew install glab
    else
        echo "Homebrew が見つかりません。リリース tarball を使用します。"
        install_from_release_tarball "darwin"
    fi
}

# GitLab のリリースページから最新タグを取得し、tarball をダウンロードして展開する。
# 展開後の内部構造がバージョンによって変わっても壊れないよう、tar 内から glab バイナリを find で探す。
install_from_release_tarball() {
    local os_name="$1"
    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo "Error: サポート外の CPU アーキテクチャです（$(uname -m)）。" >&2
            exit 1
            ;;
    esac

    echo "GitLab のリリースページから最新バージョンを取得しています..."
    local latest_url
    latest_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' -L \
        "https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest")"
    local tag="${latest_url##*/}"
    local version="${tag#v}"

    if [ -z "${tag}" ]; then
        echo "Error: 最新バージョンの取得に失敗しました。" >&2
        exit 1
    fi

    local asset="glab_${version}_${os_name}_${arch}.tar.gz"
    local download_url="https://gitlab.com/gitlab-org/cli/-/releases/${tag}/downloads/${asset}"
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    echo "ダウンロード中: ${download_url}"
    curl -fsSL "${download_url}" -o "${tmp_dir}/glab.tar.gz"
    tar -xzf "${tmp_dir}/glab.tar.gz" -C "${tmp_dir}"

    local glab_binary
    glab_binary="$(find "${tmp_dir}" -type f -name glab | head -1)"
    if [ -z "${glab_binary}" ]; then
        echo "Error: 展開したアーカイブ内に glab バイナリが見つかりませんでした。" >&2
        rm -rf "${tmp_dir}"
        exit 1
    fi

    install -m 0755 "${glab_binary}" "${GLAB_BIN_DIR}/glab"
    rm -rf "${tmp_dir}"
}

install_other() {
    # その他の UNIX — リリース tarball からインストール
    echo "検出できないプラットフォームです。リリース tarball を使用します。"
    local os_name
    os_name="$(uname -s | tr '[:upper:]' '[:lower:]')"
    install_from_release_tarball "${os_name}"
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
            install_from_release_tarball "linux"
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

export PATH="${GLAB_BIN_DIR}:${PATH}"

if command -v glab &>/dev/null; then
    echo "glab のインストールが完了しました: $(glab --version 2>&1 | head -1)"
else
    echo "Error: glab のインストールに失敗しました。" >&2
    echo "PATH に '${GLAB_BIN_DIR}' が追加されたターミナルで再度ログインするか、手動でインストールしてください。" >&2
    exit 1
fi
