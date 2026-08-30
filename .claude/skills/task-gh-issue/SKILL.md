---
name: task-gh-issue
description: >
  Searches, creates, and edits GitHub issues or GitLab issues using the `gh`/`glab` CLI (auto-detected
  from the origin remote). Use when the user mentions "issue 作って", "issue 検索", "類似 issue",
  "issue を修正", "issue を更新", "issue に追記", "チケット Open", "バグ報告", "デザイン資料を issue に",
  "ドキュメントを issue に", "create issue", "edit issue", or asks to create, find, or update a GitHub
  issue / GitLab issue or ticket. Creates from template files when applicable.
---

# task-gh-issue — `gh`/`glab` で GitHub Issue・GitLab Issue を検索・作成・編集する

現在のワークスペースが紐づくリポジトリに対し、`gh`（GitHub）または `glab`（GitLab）CLI で issue を
扱う。どちらの CLI を使うかは手順1でホストを判定して決める。モードは 3 つ。

- 要件: `.claude/docs/00_requirements/issue操作.md`
- 仕様: `.claude/docs/10_spec/issue操作.md`

| モード | 用途 | 主なコマンド（GitHub / GitLab） |
|--------|------|-------------|
| 検索 | 依頼に類似する issue を探す | `gh issue list --search` / `gh issue view` ⇔ `glab issue list --search` / `glab issue view` |
| 作成 | 新しい issue を作る | `gh issue create` ⇔ `glab issue create` |
| 編集 | 既存 issue の本文・タイトル・ラベル・状態を変える | `gh issue edit` / `gh issue comment` / `gh issue reopen` ⇔ `glab issue update` / `glab issue note` / `glab issue reopen` |

`workflow-issue-mr-driven` から呼ばれる場合はモードが指定される。単独で呼ばれた場合は依頼から判断する（「作って」→ 作成、「探して / ある？」→ 検索、「直して / 追記して」→ 編集）。

## 手順 1: リポジトリの検出とホスト判定

`git remote get-url origin` を実行してリモート URL を取得し、ホスト名で GitHub / GitLab を判定する
（`task-repo-merge-settings` と同じ方式）。

- ホスト名に `github.com` を含む → **GitHub**。`org/repo` 形式のスラグに変換し、以降 `gh` を使う
  - SSH 形式 (`git@github.com:org/repo.git`) → `org/repo`
  - HTTPS 形式 (`https://github.com/org/repo.git`) → `.git` を除去して `org/repo`
- ホスト名に `gitlab.com` を含む → **GitLab**。`group/project`（サブグループがあれば `group/subgroup/project`）形式のスラグに変換し、以降 `glab` を使う
  - SSH 形式 (`git@gitlab.com:group/project.git`) → `group/project`
  - HTTPS 形式 (`https://gitlab.com/group/project.git`) → `.git` を除去して `group/project`
- 自社ホスト（GitHub Enterprise / self-managed GitLab）など判定できない場合は、ユーザーに GitHub/GitLab のどちらか、および `org/repo`（`group/project`）を聞く

リモートが見つからない場合も同様にユーザーに聞く。リポジトリのルートで実行する場合 `--repo`（GitHub）/ `-R`（GitLab）は省略できるが、明示した方が安全。

以降、GitHub の場合は `ORG/REPO`、GitLab の場合は `GROUP/PROJECT` と表記する。

## 手順 2: 検索モード

キーワード（日本語・英語の両方を試す）で open issue を検索し、0 件なら closed も含める。

**GitHub:**

```bash
gh issue list --repo ORG/REPO --state open --search "キーワード" --limit 20 --json number,title,state,labels,url,body
gh issue list --repo ORG/REPO --state all  --search "キーワード" --limit 20 --json number,title,state,labels,url,body
```

- `--search` は GitHub の検索構文（`in:title`、`label:bug` などが使える）
- 件数が少ないリポジトリでは `--limit 50` で全件を眺める方が早い
- 候補の本文を読むときは `gh issue view N --json number,title,state,url,body,labels,comments`

**GitLab:**

```bash
glab issue list --repo GROUP/PROJECT --search "キーワード" --per-page 20 --output json
glab issue list --repo GROUP/PROJECT --all --search "キーワード" --per-page 20 --output json
```

- `glab issue list` は指定しなければ open のみを対象にする。`--all` で closed も含め、`--closed` なら closed のみ
- `--search` は `--in`（既定 `title,description`）で検索対象フィールドを絞れる
- 件数が少ないプロジェクトでは `--per-page 50` で全件を眺める方が早い
- 候補の本文を読むときは `glab issue view N --repo GROUP/PROJECT --output json`（`--comments` でコメントも取得）

結果は番号・タイトル・状態・URL の表で提示する。類似かどうかの判定基準は呼び出し元（`workflow-issue-mr-driven` の `references/issue-triage.md`）に従う。

## 手順 3: 作成モード

### タイトルと本文の収集

**タイトル**はユーザーが必ず指定する。**本文**はテンプレートファイルを優先する。

- **デフォルトテンプレート**: `assets/issue.template.md` を読み込み、ユーザーが記入可能な状態で本文として使う
- **カスタムテンプレートファイル**: ユーザーがファイルパスを指定した場合（例：「この資料を issue に」「docs/design.md を読んで issue 作って」）、ファイルを読み込んで本文として使う
- **インラインコンテンツ**: それ以外は、ユーザーのプロンプトやフォローアップメッセージから本文をそのまま使う

タイトルも本文もない場合は、タイトルを聞いてから、次に本文を聞く。

### 作成

**GitHub:**

```bash
gh issue create --repo ORG/REPO --title "タイトル" --body "本文"
```

本文が長い・複数行の場合は、Write で一時ファイル（リポジトリ外。例: `/tmp/gh-issue-body.md`）に書き出して `--body-file` を使う:

```bash
gh issue create --repo ORG/REPO --title "タイトル" --body-file /tmp/gh-issue-body.md
```

ラベルを付ける場合は `--label "bug"` を追加する。

**GitLab:**

```bash
glab issue create --repo GROUP/PROJECT --title "タイトル" --description "本文"
```

本文が長い・複数行の場合は、Write で一時ファイル（例: `/tmp/gh-issue-body.md`）に書き出して `--description-file` を使う:

```bash
glab issue create --repo GROUP/PROJECT --title "タイトル" --description-file /tmp/gh-issue-body.md
```

ラベルを付ける場合は `--label "bug"` を追加する。

## 手順 4: 編集モード

### 本文への追記（既存の記述を保全する）

既存 issue に依頼内容を追記する場合は、**既存本文を消さず末尾に連結**する。

**GitHub:**

1. 現在の本文を取得する: `gh issue view N --repo ORG/REPO --json body -q .body`
2. 取得した本文の末尾に追記セクションを付けた全文を、Write で一時ファイル（例: `/tmp/gh-issue-body.md`）に書く
3. 反映する:

```bash
gh issue edit N --repo ORG/REPO --body-file /tmp/gh-issue-body.md
```

4. `gh issue view N --json body -q .body` で、既存部分が変わっていないことを確認する

**GitLab:**

1. 現在の本文を取得する: `glab issue view N --repo GROUP/PROJECT --output json` から `description` を読む
2. 取得した本文の末尾に追記セクションを付けた全文を、Write で一時ファイル（例: `/tmp/gh-issue-body.md`）に書く
3. 反映する:

```bash
glab issue update N --repo GROUP/PROJECT --description-file /tmp/gh-issue-body.md
```

4. `glab issue view N --repo GROUP/PROJECT --output json` で、既存部分が変わっていないことを確認する

### タイトル・ラベル・状態

**GitHub:**

```bash
gh issue edit N --repo ORG/REPO --title "新しいタイトル"
gh issue edit N --repo ORG/REPO --add-label "bug" --remove-label "question"
gh issue reopen N --repo ORG/REPO
gh issue close N --repo ORG/REPO
```

**GitLab:**

```bash
glab issue update N --repo GROUP/PROJECT --title "新しいタイトル"
glab issue update N --repo GROUP/PROJECT --label "bug" --unlabel "question"
glab issue reopen N --repo GROUP/PROJECT
glab issue close N --repo GROUP/PROJECT
```

issue のクローズは、PR/MR の `Closes #N` でマージ時に自動で行われる運用なら手動でしない。

### コメント

経緯を本文に混ぜたくない場合（進捗・残課題など）はコメントにする:

**GitHub:**

```bash
gh issue comment N --repo ORG/REPO --body-file /tmp/gh-issue-comment.md
```

**GitLab:**

`glab issue note` はコマンド名が `note`（`note create` ではない）で、短文は `-m`、長文・複数行は標準入力から読み込む:

```bash
glab issue note N --repo GROUP/PROJECT < /tmp/gh-issue-comment.md
```

## 手順 5: 結果の報告

`gh issue create` / `gh issue edit`（GitHub）または `glab issue create` / `glab issue update`（GitLab）が出力した issue の URL と番号をそのまま表示し、ユーザーに確認できるようにする。
一時ファイルを使った場合は作業後に削除する。

## エラーハンドリング

| 状況 | 対処 |
|------|------|
| `gh` が未インストール・未認証 | `task-gh-install` スキルまたは `gh auth login` を案内する |
| `glab` が未インストール | 公式インストール手順（<https://gitlab.com/gitlab-org/cli#installation>。本リポジトリに `glab` 専用のインストールスキルが無ければ案内のみ）を示す |
| `glab` が未認証 | `glab auth login` を案内する |
| origin が GitHub でも GitLab でもない（自社ホスト含む） | 手順1のとおりユーザーに GitHub/GitLab の別と `org/repo`（`group/project`）を確認する。判定できないまま推測で進めない |
| 検索が 0 件 | キーワードを変える（同義語・英語）か、GitHub は `--state all`、GitLab は `--all` で closed を含める |
| `gh issue edit` / `glab issue update` の失敗（権限・番号違い） | コマンドと出力をそのまま報告し、別の方法で代替しない |
