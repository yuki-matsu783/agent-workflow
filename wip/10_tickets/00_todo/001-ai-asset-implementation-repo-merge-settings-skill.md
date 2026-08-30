---
type: ai-asset-implementation
status: todo
depends_on: []
---

# gh/glabでリポジトリのマージ関連設定を変更するスキルを追加する

## 目的

`.claude/skills/task-repo-merge-settings/` に、GitHub/GitLabのマージ関連設定（delete branch on merge・
squash mergeの許可/既定化）を `gh`/`glab` 経由で変更するスキルを新規作成する。ユーザーからの明示的な
起動時のみ使用し、実処理はスクリプトに寄せる（全体計画 `wip/00_overall_plan/deep-dancing-glacier.md` 参照）。

## 完了条件（DoD）

- [ ] `.claude/skills/task-repo-merge-settings/SKILL.md` が作成され、frontmatter の description に
      「ユーザーからの明示的な指示があったときのみ使用し、他のワークフローから自動委譲されない」旨が
      明記されている
- [ ] 本文にも同じ制約が目立つ形で明記されている
- [ ] GitHub/GitLabの対象設定一覧、実行前確認フロー（AskUserQuestion）、CLI未導入・未認証時の
      エラーハンドリングがSKILL.mdに記載されている
- [ ] `scripts/github-merge-settings.sh` が作成され、`--repo` `--show` `--delete-branch-on-merge`
      `--allow-squash-merge` `--allow-merge-commit` `--allow-rebase-merge` を受け付け、指定された
      フラグのみ `gh repo edit` に渡す。`gh` 未導入時は分かりやすいメッセージで終了する
- [ ] `scripts/gitlab-merge-settings.sh` が作成され、`--project` `--show` `--squash-option`
      `--remove-source-branch-after-merge` を受け付け、`glab api` 経由でプロジェクト設定を取得・変更する。
      `glab` 未導入時は分かりやすいメッセージで終了する
- [ ] 両スクリプトとも引数なし/不正な引数でUsageを表示して終了コード非0で終わる
- [ ] この実行環境（gh/glab 未導入）で両スクリプトを実行し、クラッシュせず「未導入」を検知することを確認済み
- [ ] issue #15 の受け入れ条件をすべて満たす

## 作業内容

1. `.claude/skills/task-repo-merge-settings/SKILL.md` を作成する（全体計画のSKILL.md設計に従う）
2. `.claude/skills/task-repo-merge-settings/scripts/github-merge-settings.sh` を作成し実行権限を付与する
3. `.claude/skills/task-repo-merge-settings/scripts/gitlab-merge-settings.sh` を作成し実行権限を付与する
4. 両スクリプトを `--help`（引数なし）および `--show` で実行し、Usage表示・未導入検知を確認する
5. 作業ログに結果を記録する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
