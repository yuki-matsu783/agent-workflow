---
name: task-gh-feature
description: >
  Creates feature branches and PRs using the `gh` CLI. Use when the user mentions "feature branch", "branch", "PR", "pull request",
  "feature branch 作って", "ブランチ切って", "pr 作成", "issue に紐づくブランチ", "draft PR", or "feature branch create".
  Checks the default branch, updates the base, creates the feature branch, and pushes to remote. Has an issue-linked mode
  (branch named after the issue, empty initial commit, draft PR with "Closes #N") used by workflow-issue-mr-driven.
---

# task-gh-feature — feature ブランチ作成と PR 作成

現在のワークスペースが紐づくリポジトリに対し、デフォルトブランチを確認してベースを決定し、feature ブランチを切って PR を作成する。

## 手順 0: 前準備チェック

以下を事前に確認し、問題があればユーザーに伝えて対処する。

### git リポジトリであること

```bash
git rev-parse --is-inside-work-tree
```

リポジトリ外の場合は、まず該当するリポジトリに `cd` するか、ユーザーにワークスペースを確認する。

### `gh` CLI がインストールされていること

```bash
gh auth status
```

`gh` が見つからない、または認証されていない場合は、ユーザーに `gh auth login` を案内する。

### 未コミットの変更がないことを確認

```bash
git status --short
```

未コミットの変更がある場合は、**必ずユーザーに扱いを確認する**。自分の判断で `git stash`・コミット・破棄をしない。変更のファイル一覧を示した上で、`AskUserQuestion` で以下から選んでもらう:

- 今の変更をコミットしてから進む（メッセージをユーザーと合意する）
- `git stash push -m "<用件>"` で退避して進む（完了時に stash が残っていることを伝える）
- 変更を破棄して進む（ユーザーが明示的に選んだ場合のみ）
- いったん中断する

`workflow-issue-mr-driven` から呼ばれた場合は、呼び出し元の手順 0 でこの確認が済んでいるはず。未解消なら呼び出し元に戻して確認する。

- **マージコンフリクト中**の場合は、コンフリクトを解決してから進める。
- **rebase や cherry-pick の途中**の場合も、同様に完了させてから進める。

---

## 手順 1: デフォルトブランチの確認

`gh` CLI でリポジトリのデフォルトブランチを取得する。

```bash
git remote get-url origin
```

でリモート URL を取得し、`org/repo` 形式に変換する。

その後、デフォルトブランチを取得する：

```bash
gh api repos/ORG/REPO --jq '.default_branch'
```

または：

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

**デフォルトブランチが `main`、`master`、`develop`、`trunk` など何であれ、それをベースとして使用する。**

---

## 手順 2: ベースブランチの選択と最新化

デフォルトブランチを表示し、ユーザーに確認を求める：

> デフォルトブランチは `main` です。これをベースにしますか？それとも別のブランチ（例：`develop`）を指定してください。

ユーザーが指定した（またはデフォルトがそのままの）ブランチを checkout して最新化する：

```bash
git checkout BASE_BRANCH
git pull --ff-only origin BASE_BRANCH
```

### エラーハンドリング

- **`git pull --ff-only` が失敗した場合**（フォワードマージ不可の履歴）：
  - ユーザーに `git pull`（通常のマージ）または `git pull --rebase` を確認する。
  - マージコンフリクトが発生した場合は、解決後に進める。

- **ローカルにベースブランチが存在しない場合**：
  ```bash
  git fetch origin BASE_BRANCH:BASE_BRANCH
  git checkout BASE_BRANCH
  ```

- **リモートの追跡が切れている場合**：
  ```bash
  git branch --set-upstream-to=origin/BASE_BRANCH BASE_BRANCH
  git pull
  ```

---

## 手順 3: feature ブランチ名の決定

ユーザーに feature ブランチ名を聞く。命名規約がある場合はそれに従い、なければ以下を推奨する：

> ブランチ名を入力してください（例：`feature/ログイン画面実装`、`fix/バグ修正`、`feat/API追加`）

### 一般的な命名規約

| 種類 | プレフィックス例 |
|------|-----------------|
| 機能追加 | `feature/`、`feat/` |
| バグ修正 | `fix/`、`bugfix/` |
| 改善 | `improve/`、`refactor/` |
| ドキュメント | `docs/` |
| タスク | `task/`、`chore/` |

ブランチ名にはスラッシュ（`/`）とハイフン（`-`）を使用し、スペースは避ける。

### ブランチ名の衝突チェック

```bash
git ls-remote --heads origin BRANCH_NAME
```

リモートに同名ブランチが存在する場合は、ユーザーに確認を促す：

> リモートに `BRANCH_NAME` が既に存在します。別の名前を指定しますか？

---

## 手順 4: feature ブランチの作成

```bash
git checkout -b BRANCH_NAME BASE_BRANCH
```

またはベースブランチですでにチェックアウト済みの場合：

```bash
git checkout -b BRANCH_NAME
```

### 空のコミットについて

ベースブランチから完全に独立した初期状態のブランチが欲しい場合は、空コミットで開始する：

```bash
git checkout -b BRANCH_NAME BASE_BRANCH
git commit --allow-empty -m "WIP: start BRANCH_NAME"
```

---

## 手順 5: リモートへのプッシュ

```bash
git push -u origin BRANCH_NAME
```

### エラーハンドリング

- **パーミッションエラーの場合**：リポジトリへの push 権限があるか確認する。
- **ブランチ保護ルールによる拒否の場合**：リポジトリの設定を確認し、ユーザーに伝える。

---

## 手順 6: PR の作成

### PR のタイトルと本文の収集

ユーザーに PR のタイトルを聞く。

**PR のタイトル**は必須。例：`feat: ログイン画面の実装`

**PR の本文**は以下のいずれかの方法で収集する：

1. **ユーザーが直接指定した場合**：そのまま使う
2. **テンプレートがある場合**：`assets/pr.template.md` を読み込んでテンプレートとして提示する
3. **変更内容を自動収集する場合**：
   ```bash
   git log --oneline BASE_BRANCH..BRANCH_NAME
   ```
   でコミット履歴を取得し、本文の土台とする。

### PR の作成

```bash
gh pr create --repo ORG/REPO --base BASE_BRANCH --head BRANCH_NAME --title "PRタイトル" --body "PR本文"
```

または対話的に作成する（タイトルと本文をプロンプトで聞く）：

```bash
gh pr create --repo ORG/REPO --base BASE_BRANCH --head BRANCH_NAME --web
```

`--web` を使うとブラウザで PR 作成画面が開くため、本文の記述が楽になる。

### PR 作成時のオプション

- **ドラフト PR** にする場合：`--draft` を追加する
  ```bash
  gh pr create --repo ORG/REPO --base BASE_BRANCH --head BRANCH_NAME --title "タイトル" --body "本文" --draft
  ```
- **ラベルを付与する場合**：`--label "ラベル名"` を追加する
- **マイルストーンを指定する場合**：`--milestone "ミロストーン名"` を追加する
- **レビュアーを指定する場合**：`--reviewer "ユーザー名"` を追加する
- **プロジェクトを指定する場合**：`--project "プロジェクト名"` を追加する

---

## 手順 7: 結果の報告

以下の情報をユーザーに表示する：

- 作成した feature ブランチ名
- ベースブランチ
- PR の URL（`gh pr create` の出力から）
- PR 番号（あれば）

---

## issue 連携モード（workflow-issue-mr-driven から呼ばれる場合）

issue 番号・ブランチ名・PR タイトル・ベースブランチは呼び出し元で**承認済み**として渡される。手順 2・3・6 の対話的な確認は省略し、以下を機械的に実行する。

| 入力 | 例 |
|------|-----|
| issue 番号 / タイトル | `#12` / 「空パスワードで送信できる」 |
| ブランチ名 | `fix-12-login-empty-password`（`<prefix>-<N>-<slug>`。区切りはすべてハイフン。単独モードの一般的な命名規約（手順 3）とは異なり、issue 連携モードではスラッシュを使わない） |
| PR タイトル | `fix: 空パスワードで送信できる (#12)` |
| ベースブランチ | デフォルトブランチ（`gh repo view --json defaultBranchRef` の結果） |

1. 手順 0 の前準備チェックを行う（未コミットの変更があれば呼び出し元に戻して確認する）
2. 手順 1〜2 に従いベースブランチを最新化する（`git checkout BASE_BRANCH && git pull --ff-only origin BASE_BRANCH`）
3. 手順 3 の衝突チェック（`git ls-remote --heads origin BRANCH_NAME`）を行い、衝突していれば別名（末尾に `-2` など）を提案して呼び出し元に戻す
4. ブランチを作成し、**空コミットを作る**（この時点では差分が無く、差分ゼロでは `gh pr create` が失敗するため）:

   ```bash
   git checkout -b BRANCH_NAME BASE_BRANCH
   git commit --allow-empty -m "chore: start #N <slug>"
   git push -u origin BRANCH_NAME
   ```

5. `assets/pr.template.md` を Read し、「関連 Issue」に `- Closes #N` を書いた本文を Write で一時ファイル（リポジトリ外。例: `/tmp/gh-pr-body.md`）に作り、**draft** で PR を作成する:

   ```bash
   gh pr create --repo ORG/REPO --base BASE_BRANCH --head BRANCH_NAME --title "PRタイトル" --body-file /tmp/gh-pr-body.md --draft
   ```

6. 手順 7 のとおり、ブランチ名・ベース・PR の URL と番号を報告する（呼び出し元がこれを控える）

作業完了後の PR 本文更新は `gh pr edit N --body-file <path>`、レビュー依頼への切り替えは `gh pr ready N`（いずれも呼び出し元が承認を得てから実行する）。

---

## 考慮すべき状況と対応方法

### 1. デフォルトブランチが `main` ではない場合

GitHub のリポジトリ設定により、デフォルトブランチは `main`、`master`、`develop`、`trunk`、`production` など様々です。`gh api` で正確に取得し、ユーザーに確認を求めてください。

### 2. 複数のリモートがある場合

`git remote -v` で複数のリモートが設定されている場合、`origin` が GitHub 用であることを確認してください。GitHub API のリポジトリ情報は `origin` に対して取得するのが一般的です。

### 3. 保護されたブランチからの PR 作成

一部のリポジトリでは、デフォルトブランチ（`main` 等）への直接プッシュが保護されています。feature ブランチからの PR であれば問題ありませんが、ベースブランチ自体をチェックアウトする際の権限に注意してください。

### 4. 同名ブランチが既に存在する場合

ローカルにもリモートにも同名ブランチが存在する場合：

- **ローカルのみ存在**：`git branch -D BRANCH_NAME` で削除して作り直すか、別名を提案する。
- **リモートのみ存在**：`git fetch origin` してローカルにも存在するか確認し、なければ `git checkout -b BRANCH_NAME origin/BRANCH_NAME` で追跡ブランチを作成するか、別名を提案する。
- **両方存在**：ユーザーに確認を促し、削除または別名を選ばせる。

### 5. ブランチのベースが目的と異なる場合

ユーザーが「main から切って」と言ったのに、実際の開発は `develop` をベースにしたい場合があります。手順 2 で明示的に確認し、ユーザーの意図を確認してください。

### 6. リベースを使いたい場合

ユーザーがリベースを好む場合は、`git pull --rebase` や `git rebase origin/BASE_BRANCH` を使ってください。

### 7. PR が自動マージされる設定の場合

自動マージが有効なリポジトリでは、PR 作成後に `gh pr merge --auto` で自動マージを有効にできる場合があります。

### 8. CI が失敗している場合

PR を作成した後、CI のステータスを確認したい場合は：

```bash
gh pr checks PR_NUMBER
```

で確認し、失敗があればユーザーに伝える。

### 9. ワークツリーやサブモジュールがある場合

ワークツリー内では、`git rev-parse --show-toplevel` でメインリポジトリのルートを確認してください。サブモジュールがある場合は、サブモジュール側でも `git pull` を確認する必要があります。

### 10. `gh` のリポジトリ指定が不要な場合

リポジトリのルートディレクトリで `gh` コマンドを実行すれば、`--repo` フラグを省略できる場合があります。ただし、明示的に指定した方が安全です。
