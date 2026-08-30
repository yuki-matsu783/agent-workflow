---
name: task-repo-merge-settings
description: >
  GitHubリポジトリ・GitLabプロジェクトのマージ関連設定（マージ時のsource branch自動削除、squash mergeの
  許可・既定化）を `gh`/`glab` コマンドで変更する。**ユーザーからの明示的な指示があったときのみ使用する。**
  「delete branch on merge を有効にして」「squash mergeを既定にして」「マージ設定を変更して」「PRをマージ
  したらブランチを消えるようにして」など、リポジトリ/プロジェクトのマージ規定を明示的に書き換えたい依頼
  にのみ反応すること。他のワークフロー（workflow-issue-mr-driven 等）から自動的に委譲したり、会話の流れ
  や推測だけで自律的に呼び出したりしてはならない。
  Use ONLY when the user explicitly asks to change repository/project merge settings (e.g. "enable delete
  branch on merge", "make squash merge the default", "change merge settings"). Do NOT invoke this
  proactively, as a side effect of another workflow, or based on conversational context alone.
---

# task-repo-merge-settings — gh/glabでリポジトリのマージ関連設定を変更する

> **重要**: このスキルは、ユーザーが明示的に「マージ設定を変更してほしい」と依頼したときにのみ使う。
> AI が他の作業の一環として自律的に判断し、勝手にリポジトリ/プロジェクトの設定を書き換えることは禁止する。
> 実処理は本スキル同梱のスクリプトに寄せてあり、AI はスクリプトへの入力（対象リポジトリ・変更する設定）を
> 決めて呼び出すだけにする。コマンドをその場で自由に組み立てない。

- 要件: `.claude/docs/00_requirements/マージ設定変更.md`
- 仕様: `.claude/docs/10_spec/マージ設定変更.md`

## 対象設定

| プラットフォーム | 設定 | 対応コマンド | 意味 |
|---|---|---|---|
| GitHub | Automatically delete head branches | `gh repo edit --delete-branch-on-merge` | PRマージ後にsource branchを自動削除 |
| GitHub | Allow squash merging 等のマージ方式許可 | `gh repo edit --allow-squash-merge` / `--allow-merge-commit` / `--allow-rebase-merge` | リポジトリで使えるマージ方式を制限し、squash mergeを既定/強制にできる |
| GitLab | Squash commits when merge request is accepted（既定値） | `glab api projects/:id -X PUT -f squash_option=...` | MR作成時の「Squash commits」の既定状態（`never`/`always`/`default_on`/`default_off`） |
| GitLab | Delete source branch when merge request is accepted（既定値） | `glab api projects/:id -X PUT -f remove_source_branch_after_merge=...` | MR作成時の「Delete source branch」の既定状態 |

GitLabの `glab` には `gh repo edit` に相当する専用サブコマンドが無いため、`glab api` でプロジェクト設定
APIを直接叩く。

## 手順 1: 対象と変更内容の確認

1. `git remote get-url origin` でリモートURLを取得し、ホスト名から GitHub / GitLab のどちらかを判定する
   （判定できない、あるいはユーザーが別のリポジトリ/プロジェクトを指定した場合は聞く）
2. ユーザーの依頼から、変更したい設定と値を確定する。複数の解釈がありうる場合（例: 「マージ設定を良い感じ
   にして」のような曖昧な依頼）は、`AskUserQuestion` で対象設定と値を具体的に確認する。**推測で決め打ちしない**
3. 実行前に、これから呼び出すスクリプトのコマンドラインと変更内容（設定名・変更前後の値）を提示し、
   `AskUserQuestion` で実行の可否を確認する。設定変更は既存のプロジェクト運用を上書きしうるため、
   確認を省略しない

## 手順 2: CLIの導入・認証確認

- GitHub: `gh --version` と `gh auth status` を確認する。未導入なら `task-gh-install` スキルを案内、
  未認証なら `gh auth login` を案内して停止する
- GitLab: `glab --version` と `glab auth status` を確認する。未導入なら `task-gh-install` スキル
  （GitHub/GitLab 両対応）を案内する。未認証なら `glab auth login` を案内して停止する

いずれのスクリプトも、CLI未導入・未認証を内部で検知し、コマンドを実行せずに分かりやすいメッセージで
終了する。

## 手順 3: 現在値の確認

変更前に対応するスクリプトを `--show` 付きで実行し、現在の設定値を表示してユーザーに伝える。

```bash
bash .claude/skills/task-repo-merge-settings/scripts/github-merge-settings.sh --repo=OWNER/REPO --show
bash .claude/skills/task-repo-merge-settings/scripts/gitlab-merge-settings.sh --project=GROUP/PROJECT --show
```

## 手順 4: 設定の変更

手順1で確認・合意した値だけを指定してスクリプトを実行する。指定しなかった設定は変更されない。

```bash
# 例: GitHubでマージ後にブランチを自動削除し、squash mergeのみ許可する
bash .claude/skills/task-repo-merge-settings/scripts/github-merge-settings.sh \
  --repo=OWNER/REPO \
  --delete-branch-on-merge=true \
  --allow-squash-merge=true \
  --allow-merge-commit=false \
  --allow-rebase-merge=false

# 例: GitLabでMR作成時にsquashとremove-source-branchを既定でONにする
bash .claude/skills/task-repo-merge-settings/scripts/gitlab-merge-settings.sh \
  --project=GROUP/PROJECT \
  --squash-option=always \
  --remove-source-branch-after-merge=true
```

両スクリプトとも、変更を適用した直後に変更後の値を自動で表示する。それをそのままユーザーへの報告に使う。

## エラーハンドリング

| 状況 | 対処 |
|------|------|
| `gh` / `glab` が未導入 | `task-gh-install`（GitHub/GitLab 両対応）を案内して停止する |
| `gh auth status` / `glab auth status` が未認証 | `gh auth login` / `glab auth login` を案内して停止する |
| リポジトリ/プロジェクトが見つからない・権限不足 | スクリプトの標準エラー出力をそのまま報告し、対象指定（`--repo`/`--project`）が正しいか確認する |
| 引数が不正・必須引数が無い | スクリプトがUsageを表示して終了する。Usageに従って引数を修正する |
| origin が GitHub でも GitLab でもない | 対象外として報告する |
| ユーザーの依頼が曖昧（対象設定や値が特定できない） | 推測で実行せず、`AskUserQuestion` で確認する |

## ベストプラクティス

- 常にユーザーの明示的な指示を得てから実行する。会話の流れや他の作業の都合だけで判断して実行しない
- 個別PR/MR作成時のフラグ指定（`gh pr merge --delete-branch` や `glab mr create --squash-before-merge`
  など）はこのスキルの対象外。既存の `task-gh-feature` 等でカバーする
- 設定変更前に必ず現在値を提示し、変更後の値も確認する（手順3・4）
- スクリプトへの入力は明示的な `--flag=value` のみとし、AIがシェルコマンド文字列を自由に組み立てない
