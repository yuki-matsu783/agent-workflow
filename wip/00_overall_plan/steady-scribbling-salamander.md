# 全体計画: task-gh-issue を GitHub/GitLab 両対応にする

- 対象 issue: #20 https://github.com/yuki-matsu783/agent-workflow/issues/20
- PR: #21 https://github.com/yuki-matsu783/agent-workflow/pull/21

## Context

`task-gh-issue` スキルは現在 `gh`（GitHub CLI）専用で書かれており、GitLab プロジェクトでは
issue の検索・作成・編集ができない。本リポジトリには既に `task-repo-merge-settings` が
gh/glab 両対応のリファレンス実装として存在し（`git remote get-url origin` のホスト名で
GitHub/GitLab を判定 → 対応 CLI のコマンドに分岐）、同種の変更として `task-gh-install`
（#18、別スキル）も進行中。`task-gh-issue` にも同じパターンを適用し、issue #20 の受け入れ
条件（検索・作成・編集の3モード全対応、エラーハンドリング拡充、evals 更新）を満たす。

`glab issue` の実コマンド体系は WebSearch で確認済み（GitLab CLI 公式ドキュメント・man ページ
由来）:

| 操作 | `gh` | `glab` |
|---|---|---|
| open 検索 | `gh issue list --state open --search "kw" --limit 20 --json ...` | `glab issue list --search "kw" --per-page 20 --output json`（デフォルトが open） |
| closed 含む検索 | `--state all` | `--all`（`--closed` で closed のみ） |
| 詳細取得 | `gh issue view N --json ...` | `glab issue view N --output json`（`--comments` でコメント込み） |
| 作成（インライン） | `gh issue create --title T --body B` | `glab issue create --title T --description B` |
| 作成（ファイル） | `gh issue create --body-file file` | `glab issue create --title T --description-file file` |
| 本文編集（ファイル） | `gh issue edit N --body-file file` | `glab issue update N --description-file file` |
| タイトル変更 | `gh issue edit N --title T` | `glab issue update N --title T` |
| ラベル追加/削除 | `gh issue edit N --add-label X --remove-label Y` | `glab issue update N --label X --unlabel Y` |
| クローズ/再オープン | `gh issue close N` / `gh issue reopen N` | `glab issue close N` / `glab issue reopen N` |
| コメント | `gh issue comment N --body-file file` | `glab issue note N < file`（`-m` は短文向け） |

短縮フラグ（`-t`/`-d`/`-l` 等）は表記揺れを避けるため、SKILL.md 本文ではロングオプション
（`--title`/`--description`/`--label`）に統一する。

## 変更方針

- `task-gh-issue` の SKILL.md に「手順1: リポジトリの検出」で GitHub/GitLab のホスト判定を
  追加し（`task-repo-merge-settings` 手順1と同じ方式: `git remote get-url origin` のホスト名
  に `github.com` を含むか `gitlab.com`（または自ホストの場合は判定できない旨をユーザーに聞く）
  を含むかで分岐）、以降の手順2〜4（検索・作成・編集）を GitHub/GitLab 両方のコマンド例を
  併記する形に書き換える
- 手順5（結果報告）は URL・番号の表示という点で共通のため大きな変更は不要（コマンド名の言及のみ調整）
- エラーハンドリング表に glab 未導入・未認証のケースと「origin が GitHub/GitLab どちらでもない」
  ケースを追加する（`task-repo-merge-settings` の文言を踏襲）
- description の frontmatter は GitHub 限定の記述（"GitHub Issue"）を「GitHub Issue / GitLab
  Issue」に変え、トリガーワードに変化は不要（ツール名は書かれていないため）
- `assets/issue.template.md` はプラットフォーム非依存の本文テンプレートなので変更不要
- `evals/evals.json` は既存3件（すべて `gh issue create` を明示的に期待している）を、
  GitHub/GitLab 非依存の期待値（「issue が作成される」等、コマンド名を明示しない書き方）に更新し、
  GitLab ケースを1件追加する

## 作業チケット

1. `001-ai-asset-implementation-gh-issue-dual-support.md`（type: `ai-asset-implementation`）
   - `.claude/skills/task-gh-issue/SKILL.md` を上記方針で書き換える
   - `.claude/skills/task-gh-issue/evals/evals.json` を更新する
   - DoD: 検索・作成・編集の3モードすべてに GitHub/GitLab 両方のコマンドが明記されている、
     エラーハンドリング表に glab 関連ケースが追加されている、evals.json が GitHub/GitLab 両観点
     を含む
2. `002-retrospective-振り返り.md`（type: `retrospective`）
   - チケット1の作業ログを踏まえ `wip/30_reports/` に結果報告を作成する

## 検証方法

- `.claude/skills/task-gh-issue/evals/evals.json` が妥当な JSON であることを確認（`python3 -m json.tool` 等）
- SKILL.md 内のコマンド例を目視レビューし、`gh`/`glab` の対応行が1対1で揃っているか確認する
- 完了後、issue #20 の受け入れ条件チェックリストと突き合わせる
