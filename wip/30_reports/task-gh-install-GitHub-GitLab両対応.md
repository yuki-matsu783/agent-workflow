---
type: report
title: 結果報告 task-gh-install の GitHub/GitLab 両対応
description: task-gh-install スキルに glab インストール対応を追加し、GitHub/GitLab を自動判定して確認つきでインストールするようにした結果報告
tags: [work-ticket-driven, report, task-gh-install]
keywords: [task-gh-install, glab, gh, GitHub, GitLab, AskUserQuestion, インストール]
---

# 結果報告: task-gh-install の GitHub/GitLab 両対応

- 対象ブランチ: `claude/task-gh-install-dual-support-7n291j`
- 対象 issue: [#18](https://github.com/yuki-matsu783/agent-workflow/issues/18)
- PR: [#19](https://github.com/yuki-matsu783/agent-workflow/pull/19)
- 期間: 2026-08-30（単日）
- レビュー結果: 未実施（今後の自動化対象）

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 001-ai-asset-implementation-gh-glab両対応 | 完了 | SKILL.md 書き換え・install_glab.sh 新規作成・task-repo-merge-settings 更新 |
| 002-ai-asset-design-用語集更新 | 完了 | 用語集の task-gh-install 説明を dual 対応に更新 |
| 003-retrospective-振り返り | 完了 | 本報告書の作成 |

## 成果物一覧

- 計画書: `wip/00_overall_plan/synchronous-mixing-pearl.md`
- コード変更:
  - `.claude/skills/task-gh-install/SKILL.md`: プラットフォーム判定（手順1）→ CLI導入確認（手順2）→
    未導入なら `AskUserQuestion` で確認（手順3・新規）→ 承認時のみインストールスクリプト実行（手順4）→
    認証案内（手順5）の流れに再構成。ヘッドレス実行時の注意書きを追加
  - `.claude/skills/task-gh-install/scripts/install_glab.sh`: 新規作成。`install_gh.sh` と同じ構成で
    macOS(Homebrew)/Debian・Ubuntu(WakeMeOps)/Fedora・RHEL・CentOS(dnf/yum)/Arch(pacman)/Alpine(apk)/
    その他(リリースtarball)に対応
  - `.claude/skills/task-repo-merge-settings/SKILL.md`: GitLab 未導入時の案内文を
    「task-gh-install（GitHub/GitLab 両対応）を案内」に更新（GitHub 側と表現を統一）
  - `.claude/docs/90_glossary/スキル名.md`: `task-gh-install` の説明を dual 対応に更新

## うまくいったこと

- 既存の `task-repo-merge-settings` が採用していた `git remote get-url origin` のホスト名判定パターンを
  そのまま踏襲でき、新しい判定ロジックを一から設計する必要がなかった
- glab の公式インストール方法を WebFetch で `gitlab-org/cli` の README・`docs/installation_options.md`
  から直接確認し、Homebrew が公式サポート、他は WakeMeOps/dnf/pacman/apk がコミュニティメンテナンスの
  手段であることを正確に把握できた。リリース tarball のURLパターン
  （`https://gitlab.com/<ns>/<proj>/-/releases/<tag>/downloads/<asset>`）も実際にダウンロードして
  存在を検証済み（`glab_1.115.0_linux_amd64.tar.gz` の取得成功で確認）
- `install_glab.sh` をこの実行環境（Debian系、gh/glab 未導入）で実行し、Debian分岐 → WakeMeOps
  リポジトリ登録スクリプト → `apt-get install glab` の流れまでクラッシュせず到達することを確認できた
- 「未導入時はユーザーに確認してから（承認時のみ）インストールする」という、依頼の核心部分を
  `AskUserQuestion` ベースの手順3として明確に追加できた。ヘッドレス実行での自動拒否の可能性も
  `.claude/rules/claude-config-headless-awareness.md` に従って明記した

## うまくいかなかったこと

- `bash -n` によるシンタックスチェックは `ai-asset-implementation` タイプの bash allowlist
  （`bash .claude/skills/<skill>/scripts/<name>.sh` の単発呼び出しのみ許可）に一致せず WF003 で
  ブロックされた。フラグ付き呼び出しは許可対象外のため、スクリプトを直接実行することで構文検証を
  代替した（構文エラーがあれば実行が即座に失敗するため代替として機能する）
- `git mv` の対象パスをダブルクォートで囲んで実行すると WF003 で拒否された（フックがクォート付き
  パスを検証できないため）。引用符なし・リポジトリ相対パスで再実行することで解決した
- この実行環境はネットワークがプロキシ制限されており、WakeMeOps リポジトリ（`deb.wakemeops.com`）への
  接続が 403 Forbidden で失敗した。スクリプト自体の不具合ではなく実行環境のネットワーク制限によるもので、
  「未導入からインストールを試みる分岐に入ること」という DoD は満たしている

## 改善提案

- `.claude/hooks/workflow-types.json` の `bash_groups: ["test"]` の allowlist は
  `bash <script>` の単発呼び出しのみを想定しており、`bash -n <script>`（構文チェック）や
  `sh -c` 経由の呼び出しは通らない。スクリプトの構文チェックを AI 自身が安全に行えるようにするには、
  allowlist に `bash -n .claude/skills/*/scripts/*.sh` のようなパターンを追加することを検討したい
  （恒久的な教訓としてフックの改善候補に挙げる）
- `git mv` / `git add` のパス引数がクォートされていると WF003 で拒否される挙動は
  `permission-matrix.md` に明記されているとおり仕様だが、日本語ファイル名を含むリポジトリでは
  クォートしたくなる場面が多いため、今後 AI アセット作成時のガイド（`task-ai-asset-creator` 等）に
  「Bash でのパス指定は引用符なしで」という注意を目立たせてもよいかもしれない

## 残課題・フォローアップ

- `install_glab.sh` の各パッケージマネージャ経路（brew/dnf/pacman/apk）は、この実行環境に該当パッケージ
  マネージャが無いため実機確認できていない。将来 macOS/Fedora/Arch/Alpine 環境でユーザーが実際に
  インストールを試みた際に、経路ごとの動作を確認できると望ましい
- glab の認証フロー自体（`glab auth login` の詳細な案内内容など）は今回のスコープ外としたまま
