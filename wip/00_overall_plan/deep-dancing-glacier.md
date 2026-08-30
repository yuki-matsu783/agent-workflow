# 全体計画: gh/glabでリポジトリのマージ関連設定を変更するスキルを追加

- 対象 issue: #15 https://github.com/yuki-matsu783/agent-workflow/issues/15
- PR: #16 https://github.com/yuki-matsu783/agent-workflow/pull/16

## Context

ユーザーから、GitHubのPRマージ時・GitLabのMRマージ時に「source branchを削除する」設定と、
GitLab側で「squash mergeとdelete source branchが選択された状態でMRが作られる」設定を、
`gh`/`glab`コマンドで変更できないかという相談があった。調査の結果、`gh repo edit` /
`glab api` 経由でリポジトリ・プロジェクトの既定値として変更可能と分かった（issue #15 の詳細欄参照）。

これを毎回コマンドを手打ちするのではなく、スキルとして再利用可能にしたい、というのが今回の依頼。
ただし、リポジトリ/プロジェクトの設定変更は影響範囲が広い操作のため、レビューでの合意事項として
以下の2点の制約が付いている。

1. **このスキルはユーザーからの明示的な起動があったときのみ使う。** AIが会話の文脈や他のワークフロー
   （`workflow-issue-mr-driven` 等）から自律的に呼び出して設定を書き換えることを禁止する。
2. **可能な限り実処理をスクリプトに寄せる。** AIが `gh`/`glab` のコマンドをその場で自由に組み立てるの
   ではなく、決まった引数を渡して決まったスクリプトを呼ぶだけにする。これにより設定変更の内容を
   予測可能・監査可能にする。

## 変更方針

新規スキル `.claude/skills/task-repo-merge-settings/` を追加する。命名は既存の3層タクソノミー
（`.claude/docs/00_requirements/スキル体系.md`）に合わせ、人間承認・敵対的レビューを要さない
「タスク」層（`task-*`、セルフレビューで進む）とする。既存の `task-gh-install`（`scripts/install_gh.sh`
を呼ぶだけのSKILL.md）と同じ構成パターンを踏襲する。

### ディレクトリ構成

```
.claude/skills/task-repo-merge-settings/
├── SKILL.md
└── scripts/
    ├── github-merge-settings.sh
    └── gitlab-merge-settings.sh
```

### SKILL.md の設計

- **frontmatter の `description`** に「ユーザーからの明示的な指示があったときのみ使用する。他のワーク
  フローから自動的に委譲しない」旨を明記する（既存スキルの `description` は Claude Code のスキル選択に
  使われる実キーなので、ここに書くのが最も確実）。トリガー例は「delete branch on merge を有効にして」
  「squash mergeを既定にして」「マージ設定を変更して」など、明示的な設定変更依頼に限定する。
- 本文冒頭にも同じ制約を目立つ形で明記する（`task-gh-install` にはこの種の注記が無いが、今回は
  「勝手に実行しない」がissueの受け入れ条件であるため明記する）。
- 対象設定の一覧表（GitHub/GitLab、設定名、対応する `gh`/`glab` コマンド、意味）
- 手順:
  1. 対象リポジトリ/プロジェクトとプラットフォーム（GitHub/GitLab）を確認する（`git remote get-url origin`
     のホスト名で判定、またはユーザー指定）
  2. 変更したい設定と値をユーザーの依頼から確定する。曖昧なら `AskUserQuestion` で確認する
  3. 実行前に「これから実行するコマンド（スクリプト呼び出し）と変更内容」を提示し、`AskUserQuestion`
     で確認を取ってから実行する（設定変更は既存ユーザー設定を上書きしうるため）
  4. `gh --version` / `glab --version` と認証状態を確認する。未導入なら GitHub は既存の `task-gh-install`
     を案内、GitLab は `glab` の公式インストール手順を案内して停止する
  5. 対応するスクリプトを `--show` で実行し、変更前の現在値を表示する
  6. 確認された値でスクリプトを実行し、変更後の値を再度 `--show` して報告する
- エラーハンドリング表（CLI未導入・未認証、リポジトリ/プロジェクトが見つからない、権限不足 など）

### scripts/github-merge-settings.sh の設計

`gh repo edit` をラップする。引数はすべて明示的な `--flag=value` 形式（自由なコマンド文字列を
組み立てさせない）。

- `--repo=OWNER/REPO`（必須）
- `--show`（現在値の表示のみ。`gh repo view --json deleteBranchOnMerge,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed,defaultBranchRef`）
- `--delete-branch-on-merge=true|false`
- `--allow-squash-merge=true|false`
- `--allow-merge-commit=true|false`
- `--allow-rebase-merge=true|false`
- 指定されたフラグだけを `gh repo edit` に渡す（未指定の設定は変更しない）
- `gh` 未導入・未認証はスクリプト内で検知し、明確なメッセージで終了する
- 実行後に `--show` 相当の内容を自動で表示する

### scripts/gitlab-merge-settings.sh の設計

`glab api` をラップする（`glab` に repo-edit 相当の専用サブコマンドが無いため）。

- `--project=GROUP/PROJECT`（必須。内部で `/` を `%2F` にURLエンコードして `projects/<id>` を組み立てる）
- `--show`（`glab api projects/<id>` の結果を表示。生JSONをそのまま出す。`jq` があれば整形する）
- `--squash-option=never|always|default_on|default_off`
- `--remove-source-branch-after-merge=true|false`
- `glab api "projects/<id>" -X PUT -f squash_option=... -f remove_source_branch_after_merge=...` を実行
- `glab` 未導入・未認証はスクリプト内で検知し、明確なメッセージで終了する

両スクリプトとも、引数エラー時は使い方（Usage）を表示して終了コード非0で終わる。

## チケット構成

2チケットで足りる規模と判断する（task-* スキルは既存の兄弟スキル（`task-gh-issue` 等）と同様、
`.claude/docs/` に独立の仕様書は作らない方針のため `ai-asset-design` チケットは不要。設計はこの
全体計画で完了させ、実装チケット1本に集約する）。

1. **`001-ai-asset-implementation-repo-merge-settings-skill.md`**（type: `ai-asset-implementation`）
   - 上記設計のとおり `.claude/skills/task-repo-merge-settings/` 一式（SKILL.md・スクリプト2本）を作成する
   - スクリプトは `bash .claude/skills/task-repo-merge-settings/scripts/*.sh --help` 等で構文エラーなく
     動くこと（`gh`/`glab` 自体が無い実行環境でも「未導入」を正しく検知して終了すること）を確認する
   - DoD: issue #15 の受け入れ条件（スキル作成・スクリプト化・明示起動限定の明記・確認フロー・
     CLI未導入時のエラーハンドリング）をすべて満たす
2. **`002-retrospective-振り返り.md`**（type: `retrospective`）
   - 結果報告を `wip/30_reports/` に作成する
   - 今回のブランチ運用（既存ブランチが `main` に完全に取り込み済みだったため `git reset --hard origin/main`
     で最新化してから開始した経緯）も記録する

## 完了後の流れ

全チケット done 後、`workflow-issue-mr-driven` の手順6（完了処理）に戻り、push・PR #16 本文の更新・
承認③（ready for review にするか）を確認する。

## 検証方法

- `bash .claude/skills/task-repo-merge-settings/scripts/github-merge-settings.sh` を引数なし/`--help`で
  実行し、Usageが表示されること
- `gh`/`glab` が未導入のこの実行環境で両スクリプトを `--show` 付きで実行し、「未導入」を検知して
  分かりやすいメッセージで終了する（クラッシュしない）ことを確認する
- SKILL.md の description を読み返し、「明示的な起動時のみ」の制約が一読して分かる文言になっているか確認する
