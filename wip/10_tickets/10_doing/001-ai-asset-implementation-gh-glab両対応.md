---
type: ai-asset-implementation
status: todo
depends_on: []
---

# task-gh-install を GitHub/GitLab 両対応にする（スキル・スクリプト実装）

## 目的

`.claude/skills/task-gh-install/` に GitLab CLI（`glab`）のインストール対応を追加し、実行時に
`git remote get-url origin` のホスト名でプロジェクトの GitHub/GitLab を自動判定、対応する CLI の
導入有無を確認し、未導入なら `AskUserQuestion` でユーザーに確認してから（承認時のみ）インストール
するフローに書き換える（全体計画 `wip/00_overall_plan/synchronous-mixing-pearl.md` 実施方針 1〜3）。

## 完了条件（DoD）

- [ ] `task-gh-install/SKILL.md` の frontmatter description が gh/glab 両対応・トリガー語（"glab" 等）
      を含む内容に更新されている
- [ ] 本文が「プラットフォーム判定 → CLI導入確認 → 未導入ならAskUserQuestionで確認 → 承認時のみ
      インストールスクリプト実行 → 認証案内」の手順に再構成されている
- [ ] ヘッドレス実行では確認が自動拒否されうる旨が明記されている（`.claude/rules/claude-config-headless-awareness.md` 準拠）
- [ ] エラーハンドリング表に「プラットフォーム判定不能」「インストールが拒否された」が追加されている
- [ ] `scripts/install_glab.sh` が新規作成され、`install_gh.sh` と同じ構成
      （事前チェック→OS検出→ディストリビューション検出→インストール実行→検証）で
      macOS(brew)/Debian・Ubuntu(WakeMeOps)/Fedora・RHEL・CentOS(dnf/yum)/Arch(pacman)/Alpine(apk)/
      その他(リリースtarball、`glab`バイナリをfindで探して配置)に対応している
- [ ] `bash -n .claude/skills/task-gh-install/scripts/install_glab.sh` が構文エラーなく通る
- [ ] この実行環境（`gh`/`glab` ともに未導入）で `install_glab.sh` を実行し、クラッシュせず
      「未導入からインストールを試みる」分岐に入ることを確認済み
- [ ] `task-repo-merge-settings/SKILL.md` 手順2・エラーハンドリング表の GitLab 行が
      「未導入なら `task-gh-install` スキル（GitHub/GitLab 両対応）を案内」に更新されている
- [ ] issue #18 の受け入れ条件のうち、ドキュメント整合（用語集）以外をすべて満たす

## 作業内容

1. `task-gh-install/SKILL.md` を全体計画の実施方針1に従って書き換える
2. `task-gh-install/scripts/install_glab.sh` を全体計画の実施方針2に従って新規作成する
3. `bash -n` で構文チェックし、実際に実行して未導入検知〜インストール試行までの分岐を確認する
4. `task-repo-merge-settings/SKILL.md` の該当2箇所を更新する
5. 作業ログに結果を記録する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
