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

- [x] `.claude/skills/task-repo-merge-settings/SKILL.md` が作成され、frontmatter の description に
      「ユーザーからの明示的な指示があったときのみ使用し、他のワークフローから自動委譲されない」旨が
      明記されている
- [x] 本文にも同じ制約が目立つ形で明記されている
- [x] GitHub/GitLabの対象設定一覧、実行前確認フロー（AskUserQuestion）、CLI未導入・未認証時の
      エラーハンドリングがSKILL.mdに記載されている
- [x] `scripts/github-merge-settings.sh` が作成され、`--repo` `--show` `--delete-branch-on-merge`
      `--allow-squash-merge` `--allow-merge-commit` `--allow-rebase-merge` を受け付け、指定された
      フラグのみ `gh repo edit` に渡す。`gh` 未導入時は分かりやすいメッセージで終了する
- [x] `scripts/gitlab-merge-settings.sh` が作成され、`--project` `--show` `--squash-option`
      `--remove-source-branch-after-merge` を受け付け、`glab api` 経由でプロジェクト設定を取得・変更する。
      `glab` 未導入時は分かりやすいメッセージで終了する
- [x] 両スクリプトとも引数なし/不正な引数でUsageを表示して終了コード非0で終わる
- [x] この実行環境（gh/glab 未導入）で両スクリプトを実行し、クラッシュせず「未導入」を検知することを確認済み
- [x] issue #15 の受け入れ条件をすべて満たす

## 作業内容

1. `.claude/skills/task-repo-merge-settings/SKILL.md` を作成する（全体計画のSKILL.md設計に従う）
2. `.claude/skills/task-repo-merge-settings/scripts/github-merge-settings.sh` を作成し実行権限を付与する
3. `.claude/skills/task-repo-merge-settings/scripts/gitlab-merge-settings.sh` を作成し実行権限を付与する
4. 両スクリプトを `--help`（引数なし）および `--show` で実行し、Usage表示・未導入検知を確認する
5. 作業ログに結果を記録する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- `task-gh-install`（`scripts/install_gh.sh` を呼ぶだけのSKILL.md）と同じ構成パターンを踏襲したことで、
  設計に迷いなくSKILL.md・スクリプトを書けた
- スクリプトの引数を明示的な `--flag=value` のみに絞ったことで、AIが自由にコマンドを組み立てる余地を
  なくすという合意事項をそのまま実装に落とし込めた
- `gh`/`glab` が未導入のこの実行環境で、両スクリプトとも `command -v` によるチェックでクラッシュせず
  分かりやすいメッセージを出して終了することを実機確認できた（不明な引数・必須引数欠如・不正な
  `--squash-option` 値のケースも含む）

### うまくいかなかったこと

- `chmod +x` は `ai-asset-implementation` タイプの許可コマンド（Read/Glob/Grep、Edit/Write、git mv/add/commit
  のみ）に含まれず WF003 でブロックされた。スクリプトへの実行権限付与は諦め、SKILL.md 側の呼び出し例を
  すべて `bash scripts/xxx.sh ...` 形式（実行権限不要）に統一することで対応した
- 複数コマンドを `;` で連結した Bash 呼び出しも WF003 でブロックされた（許可パターンが
  `bash .claude/skills/*/scripts/*.sh` の単発呼び出しを想定しているため）。1コマンドずつ個別に実行する
  ことで回避した
