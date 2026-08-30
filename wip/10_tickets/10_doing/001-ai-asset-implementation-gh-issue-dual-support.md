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

- [ ] 「手順1: リポジトリの検出」に GitHub/GitLab のホスト判定ロジックが追加されている
- [ ] 検索モード（手順2）に `glab issue list` 相当のコマンドが明記されている（open検索・closed含む再検索）
- [ ] 作成モード（手順3）に `glab issue create` 相当のコマンドが明記されている（インライン・ファイル読み込みの両方）
- [ ] 編集モード（手順4）に `glab issue update` / `close` / `reopen` / `note` 相当のコマンドが明記されている
- [ ] エラーハンドリング表に `glab` 未導入・未認証のケースと「origin が GitHub/GitLab どちらでもない」ケースが追加されている
- [ ] `evals/evals.json` の期待値が GitHub/GitLab 非依存の書き方に更新され、GitLab のケースが追加されている
- [ ] `.claude/skills/task-gh-issue/evals/evals.json` が妥当な JSON である

## 作業内容

1. `wip/00_overall_plan/steady-scribbling-salamander.md` の対応表に従い、SKILL.md の手順1〜4とエラーハンドリング表を書き換える
2. frontmatter の description の GitHub 限定表現を GitHub/GitLab 両対応の表現に更新する
3. `evals/evals.json` の既存3件を GitHub/GitLab 非依存の期待値に更新し、GitLab ケースを1件追加する
4. `python3 -m json.tool` 等で evals.json の JSON 妥当性を確認する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
