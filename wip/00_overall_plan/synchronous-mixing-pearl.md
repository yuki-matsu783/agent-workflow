---
type: plan
title: task-gh-install の GitHub/GitLab 両対応
description: task-gh-install スキルに GitLab CLI（glab）対応を追加し、実行時にプロジェクトのプラットフォームを自動判定してCLIの導入確認・確認付きインストールを行うようにする全体計画
tags: [task-gh-install, glab, gh, dual-support]
keywords: [task-gh-install, glab, gh, GitHub, GitLab, CLI, インストール, AskUserQuestion]
---

# task-gh-install の GitHub/GitLab 両対応

- 対象 issue: [#18](https://github.com/yuki-matsu783/agent-workflow/issues/18)
- PR: [#19](https://github.com/yuki-matsu783/agent-workflow/pull/19)

## Context

`task-gh-install` は現状 `gh`（GitHub CLI）専用で、GitLab プロジェクトでは使えない。
`task-repo-merge-settings` のように gh/glab 両対応が既に必要とされる場面がある一方、
`glab` 専用のインストールスキルは存在しない（`task-repo-merge-settings/SKILL.md` に
「本リポジトリに glab 専用のインストールスキルは無い」と明記されている）。

今回、ユーザーから「`task-gh-install` を GitHub/GitLab 両対応にしたい。スキルの最初で現在プロジェクトが
どちらかを確認し、そのCLIが入っているか確認し、なければユーザに確認してOKならインストールする」という
依頼があった。既存の `task-repo-merge-settings` が採用しているプラットフォーム判定方式
（`git remote get-url origin` のホスト名判定）を踏襲しつつ、`task-gh-install` に
「未導入時は確認してからインストールする」という新しいフロー（現状は確認なしで即インストール）を追加する。

## 現状把握（調査結果）

- `.claude/skills/task-gh-install/SKILL.md`: `gh --version` で確認 → 未導入なら確認なしで
  `scripts/install_gh.sh` を実行 → `gh auth login` を案内、の3手順のみ
- `.claude/skills/task-gh-install/scripts/install_gh.sh`: OS/ディストリビューション判定 →
  各パッケージマネージャで `gh` をインストール → 検証、という決定論的スクリプト
- `.claude/skills/task-repo-merge-settings/SKILL.md` 手順1・2: `git remote get-url origin` の
  ホスト名で GitHub/GitLab を判定し、対応する CLI の導入・認証を確認するパターンが既にある
  （ただし glab 未導入時は公式手順を「案内するだけ」で、この skill 自体はインストールしない）
- `glab`（GitLab CLI）の公式インストール方法（WebFetch で `gitlab-org/cli` の README・
  `docs/installation_options.md` を確認済み）:
  - **公式サポート**: Homebrew（macOS/Linux/Windows共通） `brew install glab`
  - コミュニティメンテナンスのオプション（`docs/installation_options.md` に記載）:
    - Debian/Ubuntu: WakeMeOps リポジトリ経由
      `curl -sSL "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | sudo bash` → `sudo apt install glab`
    - Fedora/RHEL/CentOS: 公式リポジトリ内に `glab` パッケージがあり `dnf install glab`（RHEL/CentOS は `yum`）
    - Arch Linux: `extra/glab`（公式 extra リポジトリ）を `pacman -S glab`
    - Alpine Linux: `apk add --no-cache glab`（community リポジトリ）
    - その他: リリース tarball（`https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest` から
      最新タグを取得し、`https://gitlab.com/gitlab-org/cli/-/releases/<tag>/downloads/glab_<version>_<os>_<arch>.tar.gz`
      をダウンロード。実際に `glab_1.115.0_linux_amd64.tar.gz` のダウンロードが成功することを確認済み）
- `.claude/docs/90_glossary/スキル名.md` の `task-gh-install` の説明が「`gh` CLI（GitHub CLI）を
  インストールするタスクスキル」のままで、両対応後は不正確になる
- `.claude/rules/claude-config-headless-awareness.md`: 「ユーザーに確認する」手順を追加する場合、
  ヘッドレス実行では `ask` が自動拒否される旨を SKILL.md に明記する必要がある

## 実施方針

### 1. `task-gh-install/SKILL.md` の書き換え

- frontmatter の `description` を「GitHub CLI (gh) と GitLab CLI (glab) を、現在のプロジェクトに
  応じてインストールする」旨に更新（トリガー語に "glab", "GitLab CLI", "gitlab" 系も追加）
- 本文を以下の手順に再構成する:
  1. **手順1: プロジェクトのプラットフォーム判定** — `git remote get-url origin` のホスト名で
     GitHub/GitLab を判定する（`task-repo-merge-settings` 手順1と同じロジックを踏襲。
     `github.com`/`gitlab.com` を含むかで判定し、self-hosted 等で判定できない場合や git リポジトリで
     ない場合は `AskUserQuestion` でユーザーに確認する）
  2. **手順2: 対応するCLIの導入確認** — 判定結果に応じ `gh --version` または `glab --version` を実行
  3. **手順3: 未導入時の確認** — 導入済みならバージョンを表示して終了。未導入の場合は
     `AskUserQuestion` で「インストールしてよいか」を確認する（**ここが今回の主要な変更点**。
     現状は確認なしで即インストールしている）。ヘッドレス実行では `ask` 相当が自動拒否されうる旨を
     注記する（`.claude/rules/claude-config-headless-awareness.md` 準拠）
  4. **手順4: インストールスクリプトの実行** — 承認された場合のみ `scripts/install_gh.sh` または
     `scripts/install_glab.sh` を実行する。拒否された場合はインストールを行わず終了する
  5. **手順5: 認証の案内** — `gh auth login` または `glab auth login` を案内する
- エラーハンドリング表に「プラットフォーム判定不能」「インストールが拒否された」を追加し、
  GitLab 版の権限・ネットワークエラーの扱いも記載する
- compatibility フィールドに glab 関連（WakeMeOps/dnf/pacman/apk 等）を追記する

### 2. `task-gh-install/scripts/install_glab.sh` の新規作成

`install_gh.sh` と同じ構成（事前チェック→OS検出→ディストリビューション検出→インストール実行→検証）で
以下のロジックを実装する:

- 事前チェック: `command -v glab` があれば即終了
- macOS: `brew install glab`（brew が無い場合は tarball フォールバック）
- Debian/Ubuntu (`/etc/debian_version`): WakeMeOps リポジトリスクリプト → `apt-get install -y glab`
- Fedora/RHEL/CentOS (`/etc/fedora-release` or `/etc/redhat-release`): `dnf install -y glab`
  （無ければ `yum install -y glab`）
- Arch (`pacman` コマンド存在): `pacman -S --noconfirm glab`
- Alpine (`apk` コマンド存在): `apk add --no-cache glab`
- その他/フォールバック: `https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest` にリダイレクト
  追跡でアクセスして最新タグ（例: `v1.115.0`）を取得し、`glab_<version>_<os>_<arch>.tar.gz` を
  `https://gitlab.com/gitlab-org/cli/-/releases/<tag>/downloads/` からダウンロードして展開、
  tar 内から `glab` バイナリを探して `${HOME}/.local/bin/glab` に配置する
  （tar 内部構造の変化に強くするため `find` でバイナリを探す実装にする。`install_gh.sh` の
  `--strip-components` 決め打ちより頑健にする）
- 検証: `command -v glab` で確認し、成功/失敗メッセージを出す

### 3. `task-repo-merge-settings/SKILL.md` の記述更新

手順2の GitLab 行「本リポジトリに `glab` 専用のインストールスキルは無い」を、
「未導入なら `task-gh-install` スキル（GitHub/GitLab 両対応）を案内」に更新する
（GitHub 行と表現を揃える）。エラーハンドリング表の該当行も同様に更新する。

### 4. `.claude/docs/90_glossary/スキル名.md` の更新

`task-gh-install` の説明文を「`gh`（GitHub CLI）と `glab`（GitLab CLI）を、プロジェクトに応じて
インストールするタスクスキル」に更新する。

## チケット分割

`.claude/hooks/workflow-types.json` の制約上、`.claude/skills/**` の変更（`ai-asset-implementation`）と
`.claude/docs/**` の変更（`ai-asset-design`）は別チケットに分ける必要がある。

| # | type | 内容 | depends_on |
|---|------|------|-----------|
| 001 | ai-asset-implementation | `task-gh-install/SKILL.md` 書き換え、`scripts/install_glab.sh` 新規作成、`task-repo-merge-settings/SKILL.md` の該当記述更新 | なし |
| 002 | ai-asset-design | `.claude/docs/90_glossary/スキル名.md` の `task-gh-install` 説明更新 | 001 |
| 003 | retrospective | 結果報告の作成（`wip/30_reports/`） | 002 |

001 の DoD には、この実行環境（`gh`/`glab` ともに未導入）で `install_glab.sh` を実行し、
クラッシュせず「未導入からインストールを試みる」動作になること（ネットワーク/権限都合で実際の
インストールが失敗しても、スクリプトの分岐・エラーメッセージが妥当であることの確認）を含める。
また `bash -n` によるシンタックスチェックも行う。

## 検証方法

- `bash -n .claude/skills/task-gh-install/scripts/install_glab.sh` で構文チェック
- この環境（Debian系コンテナ、sudo 権限は不明、`gh`/`glab` 未導入）で
  `bash .claude/skills/task-gh-install/scripts/install_glab.sh` を実行し、Debian分岐に入って
  WakeMeOps スクリプトの取得を試みる（ネットワーク/sudo 権限次第で失敗はしうるが、クラッシュや
  想定外の分岐に入らないことを確認する）
- 同様に `bash .claude/skills/task-gh-install/scripts/install_gh.sh` は既存のまま変更しないため、
  回帰確認は不要（触らない）
- SKILL.md の手順が `task-repo-merge-settings` のプラットフォーム判定ロジックと整合していることを
  読み合わせで確認する
