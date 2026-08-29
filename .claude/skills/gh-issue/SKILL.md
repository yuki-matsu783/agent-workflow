---
name: gh-issue
description: >
  Creates GitHub issues using the `gh` CLI. Use when the user mentions "issue 作って", "チケット Open", "バグ報告",
  "デザイン資料を issue に", "ドキュメントを issue に", "create issue", or asks to create a GitHub issue or ticket.
  Creates from template files when applicable.
---

# gh-issue — `gh` で GitHub Issue を作成する

現在のワークスペースが紐づくリポジトリに、`gh` CLI で issue を作成する。

## 手順 1: リポジトリの検出

`git remote get-url origin` を実行してリポジトリの URL を取得し、`org/repo` 形式のスラブに変換する。

- SSH 形式 (`git@github.com:org/repo.git`) → `org/repo`
- HTTPS 形式 (`https://github.com/org/repo.git`) → `.git` を除去して `org/repo`

リモートが見つからない場合は、ユーザーに `org/repo` を聞く。

## 手順 2: タイトルと本文の収集

**タイトル**はユーザーが必ず指定する。**本文**はテンプレートファイルを優先する。

- **デフォルトテンプレート**: `assets/issue-template.md` を読み込み、ユーザーが記入可能な状態で本文として使う。
- **カスタムテンプレートファイル**: ユーザーがファイルパスを指定した場合（例：「この資料を issue に」「docs/design.md を読んで issue 作って」）、ファイルを読み込んで本文として使う。
- **イラインコンテンツ**: それ以外は、ユーザーのプロンプトやフォローアップメッセージから本文をそのまま使う。

タイトルも本文もない場合は、タイトルを聞いてから、次に本文を聞く。

## 手順 3: issue の作成

```bash
gh issue create --repo ORG/REPO --title "タイトル" --body "本文"
```

`ORG/REPO` は手順 1 で検出したスラブ、`タイトル` と `本文` は手順 2 で収集した内容を指定する。

本文が長い場合は、一時ファイルに書き出して `--body-file` を使う：

```bash
gh issue create --repo ORG/REPO --title "タイトル" --body-file /tmp/gh-issue-body.md
```

## 手順 4: 結果の報告

`gh issue create` が出力した issue の URL と番号をそのまま表示し、ユーザーに確認できるようにする。
