---
type: ai-asset-implementation
status: todo
depends_on: []
---

# task-gh-issue を GitHub/GitLab 両対応にする

## 目的

`.claude/skills/task-gh-issue/SKILL.md` を、`git remote get-url origin` のホスト名で
GitHub/GitLab を判定し、検索・作成・編集の3モードすべてで `gh`/`glab` 両方のコマンド体系に
対応させる。あわせて `evals/evals.json` を GitHub/GitLab 両観点に更新する。

## 完了条件（DoD）

- [x] 「手順1: リポジトリの検出」に GitHub/GitLab のホスト判定ロジックが追加されている
- [x] 検索モード（手順2）に `glab issue list` 相当のコマンドが明記されている（open検索・closed含む再検索）
- [x] 作成モード（手順3）に `glab issue create` 相当のコマンドが明記されている（インライン・ファイル読み込みの両方）
- [x] 編集モード（手順4）に `glab issue update` / `close` / `reopen` / `note` 相当のコマンドが明記されている
- [x] エラーハンドリング表に `glab` 未導入・未認証のケースと「origin が GitHub/GitLab どちらでもない」ケースが追加されている
- [x] `evals/evals.json` の期待値が GitHub/GitLab 非依存の書き方に更新され、GitLab のケースが追加されている
- [x] `.claude/skills/task-gh-issue/evals/evals.json` が妥当な JSON である

## 作業内容

1. `wip/00_overall_plan/steady-scribbling-salamander.md` の対応表に従い、SKILL.md の手順1〜4とエラーハンドリング表を書き換える
2. frontmatter の description の GitHub 限定表現を GitHub/GitLab 両対応の表現に更新する
3. `evals/evals.json` の既存3件を GitHub/GitLab 非依存の期待値に更新し、GitLab ケースを1件追加する
4. `python3 -m json.tool` 等で evals.json の JSON 妥当性を確認する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- `task-repo-merge-settings` が既に gh/glab 両対応のリファレンス実装として存在しており、ホスト判定方式（`git remote get-url origin` のホスト名）をそのまま踏襲できた
- `glab issue` の実際のフラグ体系（`--output json`、`--description-file`、`--label`/`--unlabel`、`note` コマンドなど）は WebSearch で GitLab CLI 公式ドキュメント・man ページの内容を確認してから記載したため、推測でコマンドを書かずに済んだ
- 元の SKILL.md がモードごとにセクション分けされていたため、各セクション内に GitHub/GitLab のコマンドを並記する形で機械的に拡張でき、構成自体は変えずに済んだ

### うまくいかなかったこと

- WebFetch で docs.gitlab.com・man ページ系ドメインへの直接アクセスがネットワークプロキシに軒並みブロックされ、WebSearch のスニペットから間接的にフラグを確認する形になった。断定的な一次情報を直接読めたわけではない点は留意が必要
- `evals/evals.json` の JSON 妥当性確認は `ai-asset-implementation` の bash_groups（`test`）に `python3` 等の汎用コマンドが含まれておらず、`python3 -m json.tool` を実行できなかった。Read ツールでの目視確認に留めた
