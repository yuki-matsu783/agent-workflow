---
name: gh-issue
description: >
  Searches, creates, and edits GitHub issues using the `gh` CLI. Use when the user mentions "issue 作って",
  "issue 検索", "類似 issue", "issue を修正", "issue を更新", "issue に追記", "チケット Open", "バグ報告",
  "デザイン資料を issue に", "ドキュメントを issue に", "create issue", "edit issue", or asks to create,
  find, or update a GitHub issue or ticket. Creates from template files when applicable.
---

# gh-issue — `gh` で GitHub Issue を検索・作成・編集する

現在のワークスペースが紐づくリポジトリに対し、`gh` CLI で issue を扱う。モードは 3 つ。

| モード | 用途 | 主なコマンド |
|--------|------|-------------|
| 検索 | 依頼に類似する issue を探す | `gh issue list --search` / `gh issue view` |
| 作成 | 新しい issue を作る | `gh issue create` |
| 編集 | 既存 issue の本文・タイトル・ラベル・状態を変える | `gh issue edit` / `gh issue comment` / `gh issue reopen` |

`issue-pr-driven-workflow` から呼ばれる場合はモードが指定される。単独で呼ばれた場合は依頼から判断する（「作って」→ 作成、「探して / ある？」→ 検索、「直して / 追記して」→ 編集）。

## 手順 1: リポジトリの検出

`git remote get-url origin` を実行してリポジトリの URL を取得し、`org/repo` 形式のスラブに変換する。

- SSH 形式 (`git@github.com:org/repo.git`) → `org/repo`
- HTTPS 形式 (`https://github.com/org/repo.git`) → `.git` を除去して `org/repo`

リモートが見つからない場合は、ユーザーに `org/repo` を聞く。リポジトリのルートで実行する場合 `--repo` は省略できるが、明示した方が安全。

## 手順 2: 検索モード

キーワード（日本語・英語の両方を試す）で open issue を検索し、0 件なら closed も含める。

```bash
gh issue list --repo ORG/REPO --state open --search "キーワード" --limit 20 --json number,title,state,labels,url,body
gh issue list --repo ORG/REPO --state all  --search "キーワード" --limit 20 --json number,title,state,labels,url,body
```

- `--search` は GitHub の検索構文（`in:title`、`label:bug` などが使える）
- 件数が少ないリポジトリでは `--limit 50` で全件を眺める方が早い
- 候補の本文を読むときは `gh issue view N --json number,title,state,url,body,labels,comments`

結果は番号・タイトル・状態・URL の表で提示する。類似かどうかの判定基準は呼び出し元（`issue-pr-driven-workflow` の `references/issue-triage.md`）に従う。

## 手順 3: 作成モード

### タイトルと本文の収集

**タイトル**はユーザーが必ず指定する。**本文**はテンプレートファイルを優先する。

- **デフォルトテンプレート**: `assets/issue-template.md` を読み込み、ユーザーが記入可能な状態で本文として使う
- **カスタムテンプレートファイル**: ユーザーがファイルパスを指定した場合（例：「この資料を issue に」「docs/design.md を読んで issue 作って」）、ファイルを読み込んで本文として使う
- **インラインコンテンツ**: それ以外は、ユーザーのプロンプトやフォローアップメッセージから本文をそのまま使う

タイトルも本文もない場合は、タイトルを聞いてから、次に本文を聞く。

### 作成

```bash
gh issue create --repo ORG/REPO --title "タイトル" --body "本文"
```

本文が長い・複数行の場合は、Write で一時ファイル（リポジトリ外。例: `/tmp/gh-issue-body.md`）に書き出して `--body-file` を使う:

```bash
gh issue create --repo ORG/REPO --title "タイトル" --body-file /tmp/gh-issue-body.md
```

ラベルを付ける場合は `--label "bug"` を追加する。

## 手順 4: 編集モード

### 本文への追記（既存の記述を保全する）

既存 issue に依頼内容を追記する場合は、**既存本文を消さず末尾に連結**する。

1. 現在の本文を取得する: `gh issue view N --repo ORG/REPO --json body -q .body`
2. 取得した本文の末尾に追記セクションを付けた全文を、Write で一時ファイル（例: `/tmp/gh-issue-body.md`）に書く
3. 反映する:

```bash
gh issue edit N --repo ORG/REPO --body-file /tmp/gh-issue-body.md
```

4. `gh issue view N --json body -q .body` で、既存部分が変わっていないことを確認する

### タイトル・ラベル・状態

```bash
gh issue edit N --repo ORG/REPO --title "新しいタイトル"
gh issue edit N --repo ORG/REPO --add-label "bug" --remove-label "question"
gh issue reopen N --repo ORG/REPO
gh issue close N --repo ORG/REPO
```

issue のクローズは、PR の `Closes #N` でマージ時に自動で行われる運用なら手動でしない。

### コメント

経緯を本文に混ぜたくない場合（進捗・残課題など）はコメントにする:

```bash
gh issue comment N --repo ORG/REPO --body-file /tmp/gh-issue-comment.md
```

## 手順 5: 結果の報告

`gh issue create` / `gh issue edit` が出力した issue の URL と番号をそのまま表示し、ユーザーに確認できるようにする。
一時ファイルを使った場合は作業後に削除する。

## エラーハンドリング

- `gh` が未インストール・未認証: `gh-install` スキルまたは `gh auth login` を案内する
- 検索が 0 件: キーワードを変える（同義語・英語）か、`--state all` で closed を含める
- `gh issue edit` の失敗（権限・番号違い）: コマンドと出力をそのまま報告し、別の方法で代替しない
