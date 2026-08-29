---
name: issue-pr-driven-workflow
description: >
  ユーザーの依頼を GitHub の issue と PR（MR）に紐づけてから、チケット駆動ワークフローで実作業を進める。
  既存 issue の検索 → 類似があればそれで対応するか確認 → 人間の承認 → issue の作成/修正（gh-issue）
  → feature ブランチと draft PR の作成（gh-feature）→ チケット駆動ワークフロー、の順で進める開発の入口。
  light-task-workflow と対になる 2 つの入口の一方で、振る舞いが変わる変更（機能追加・バグ修正・リファクタリング）、
  複数モジュールや 4 ファイル以上に及ぶ変更、GitHub に経緯を残したい作業はこちら。
  質問・説明・typo 修正など振る舞いを変えない軽作業は light-task-workflow を使う。
  Use when the user mentions "issue 駆動で", "issue-MR 駆動", "MR 駆動", "PR 駆動", "issue から作業",
  "issue にしてから進めて", "issue-driven", "#12 をやって", or asks to start development work that
  should be tracked as a GitHub issue and pull request before any code is touched.
---

# issue-pr-driven-workflow — issue と PR に紐づけてから作業する

依頼を受けたら**コードに触る前に** issue を確定し、issue に紐づく feature ブランチと draft PR を作り、その上でチケット駆動ワークフローを実施する。
このスキルは**順序と承認ポイントを司るオーケストレータ**であり、個々の操作は既存スキルに委譲する。

- 要件: `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`
- 仕様（承認ポイント・命名規約・委譲内容の正）: `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`
- 類似 issue の判定基準と `gh` コマンド集: `references/issue-triage.md`
- 対になる入口: `light-task-workflow`（issue / PR を作るまでもない軽作業。判定表は同スキルの手順 0 が正。依頼が軽作業に該当すると分かったら、そちらを Skill ツールで読み込んで切り替える）

```
依頼 ─→ 既存 issue を検索 ─┬─ 類似あり ─→ 承認①「#N で対応する？」─→ 追記案 ─→ 承認② ─→ gh-issue（編集）─┐
                           └─ 類似なし ─→ 承認①「新規で作る？」  ─→ 本文案 ─→ 承認② ─→ gh-issue（作成）─┤
                                                                                                          ▼
     完了処理（push / PR 本文更新 / 承認③ ready）←─ ticket-driven-workflow ←─ gh-feature（ブランチ + draft PR）
```

## 役割分担

| 担当 | やること | 呼び出し方 |
|------|---------|-----------|
| このスキル | 依頼の整理、候補の提示、承認の取得、各スキルへの引き継ぎ、完了処理 | — |
| `gh-issue` | issue の検索・作成・編集 | 「検索モード」「作成モード」「編集モード」を指定して手順に従う |
| `gh-feature` | feature ブランチの作成・push・draft PR の作成 | 「issue 連携モード」を指定して手順に従う |
| `ticket-driven-workflow` | `wip/` 配下での実作業（フックで統制） | 手順 1 から実施。issue / PR の文脈を渡す |

**GitHub 操作（`gh`、`git push`）はチケット作業の外でのみ行う**。`wip/ticket/doing/` にチケットがある間はフックが WF003 でブロックする。迂回しない。

## 承認ポイント（人間の判断が必要な場所）

| # | タイミング | 確認内容 |
|---|-----------|---------|
| ① | 候補提示のあと | どの issue で対応するか（既存 #N / 新規作成 / 別の候補 / 依頼を分割） |
| ② | issue の本文案・追記案のあと | issue に書く内容。あわせてブランチ名と PR タイトル |
| ③ | 全チケット完了・PR 本文更新のあと | draft PR を ready for review にするか |

承認は `AskUserQuestion` で選択肢として提示する（「Other」で修正を受け取れる）。**承認を得るまで issue の変更・ブランチ作成・実作業に進まない**。

## 手順 0: 状態確認（再開判定）

```bash
gh auth status
git branch --show-current
git status --short
gh pr view --json number,url,isDraft,state,body 2>/dev/null
ls wip/ticket/todo/ wip/ticket/doing/ wip/ticket/done/ 2>/dev/null
```

- `gh` が未導入・未認証 → `gh-install` スキルまたは `gh auth login` を案内して停止する
- **現在ブランチに open な PR があり、`wip/ticket/` に todo / doing のチケットがある** → 再開。手順 1〜4 を飛ばし、PR 本文の `Closes #N` から issue 番号を控えて手順 5（`ticket-driven-workflow` の手順 0）に進む
- 未コミットの変更がある → 下記「未コミットの変更があるとき」に従い、**必ずユーザーに確認する**
- ユーザーが `#N` を指定している → `gh issue view N --json number,title,state,url,body` で内容を取得し、手順 2 を飛ばして「既存 #N で対応」として手順 3A に進む

### 未コミットの変更があるとき

`git status --short` が空でなければ、手順 4（ブランチ作成）は進められない。**自分で判断して stash・コミット・破棄をしない**。変更内容（ファイル一覧と要約）を示した上で、`AskUserQuestion` で扱いを確認する:

| 選択肢 | その後の動き |
|--------|-------------|
| 今の変更をコミットしてから進む | ユーザーと合意したメッセージで現在のブランチにコミットし、手順 1 へ |
| stash に退避して進む | `git stash push -m "<依頼の要約>"` で退避し、手順 1 へ。完了報告で stash が残っていることを伝える |
| 変更を破棄して進む | ユーザーが明示的に選んだ場合のみ `git checkout -- <path>` / 未追跡ファイルの削除を行い、手順 1 へ |
| いったん中断する | 何もせず停止する |

確認は手順 0 の時点で行う（issue の検索・承認を済ませた後にブランチを切れないと分かる、という手戻りを避けるため）。issue の検索や案の作成だけなら未コミットの変更があっても進められるが、手順 4 に入る前に必ず解消されていること。

## 手順 1: 依頼の整理

依頼文から以下を抽出する。曖昧な点は**まとめて 1 回**だけ質問する。

| 項目 | 内容 |
|------|------|
| summary | 1〜2 行の要約 |
| kind | バグ / 機能追加 / タスク / 改善・最適化 / 質問 / その他（issue テンプレートの種別） |
| keywords | 検索語。日本語と英語の両方（例: `ログイン`, `login`, `validation`） |
| acceptance | 受け入れ条件。何ができたら完了か（後でチケットの DoD になる） |
| out_of_scope | 今回やらないこと |

依頼が独立した複数の問題を含む場合は、issue 1 件ずつに分割する案を提示し、ユーザーが選んだ 1 件で進める（1 issue = 1 PR = 1 ワークフロー）。

## 手順 2: 既存 issue の検索（gh-issue 検索モード）

`gh-issue` スキルの検索モードに従い、open issue を keywords で検索する。0 件なら `--state all` で closed も含めて再検索する。

```bash
gh issue list --state open --search "<keywords>" --limit 20 --json number,title,state,labels,url,body
```

候補を `references/issue-triage.md` の基準で **類似 / 関連 / 無関係** に分類し、類似と関連だけを表で提示する:

```
| # | タイトル | 状態 | 一致点 | 判定 |
|---|---------|------|--------|------|
| 12 | ログイン画面のバリデーション | open | ログイン / バリデーション | 類似 |
```

類似が 0 件なら「類似する issue は見つからなかった」と、検索した語と件数を添えて報告する。

## 手順 3: 承認① と issue の確定

### 承認①: どの issue で対応するか

`AskUserQuestion` で確認する。

- 類似あり: 「既存 #N で対応する」「新規 issue を作る」「別の候補を見る」
- 類似なし: 「新規 issue を作る」「既存 issue を指定する」
- 候補が closed のみ: 「#N を再オープンして対応する」を選択肢に加える（再オープンは承認後に `gh issue reopen N`）

### 3A: 既存 issue で対応する場合

1. `gh issue view N --json body -q .body` で現在の本文を取得する
2. `assets/issue-addendum.template.md` を Read し、手順 1 の内容で埋めた**追記セクション**を作る
3. 追記案・ブランチ名・PR タイトル（命名規約は下記）をユーザーに提示し、**承認②**を得る
4. `gh-issue` スキルの**編集モード**に従い、既存本文の**末尾に追記**する。既存の記述は消さない・書き換えない

### 3B: 新規 issue を作る場合

1. `gh-issue` スキルの `assets/issue.template.md` を Read し、手順 1 の内容で本文案を作る（種別・概要・詳細・受け入れ条件・優先度）
2. タイトル・本文案・ブランチ名・PR タイトルをユーザーに提示し、**承認②**を得る。修正があれば反映してから進む
3. `gh-issue` スキルの**作成モード**に従い issue を作成する。作成後に修正を頼まれたら編集モードで反映する

### 命名規約（承認②で提示する案）

| 対象 | 規約 | 例 |
|------|------|-----|
| ブランチ | `<prefix>/<N>-<slug>`。バグは `fix`、それ以外は `feature`。slug は英小文字・数字・ハイフンで 2〜4 語 | `fix/12-login-empty-password` |
| PR タイトル | `<prefix>: <issue タイトル> (#<N>)`。prefix は `feat` / `fix` / `chore` / `docs` / `refactor` | `fix: 空パスワードで送信できる (#12)` |

## 手順 4: feature ブランチと draft PR の作成（gh-feature issue 連携モード）

`gh-feature` スキルの **issue 連携モード**に従う。要点:

1. デフォルトブランチを取得して最新化する（承認②で合意済みならベースの再確認は不要）
2. `git checkout -b <branch> <default>` でブランチを作成する
3. PR に差分が必要なため、空コミットを作る: `git commit --allow-empty -m "chore: start #N <slug>"`
4. `git push -u origin <branch>`
5. `gh-feature` の `assets/pr.template.md` を土台に、`## 関連 Issue` に `- Closes #N` を書いた本文で **draft PR** を作成する

作成した PR の番号と URL を控え、ユーザーに報告する。

## 手順 5: チケット駆動ワークフロー

`ticket-driven-workflow` スキルを**手順 1 から**実施する。引き継ぐ文脈:

- 全体計画（プランモード）の冒頭に `- 対象 issue: #N <url>` と `- PR: #M <url>` を書く
- issue の受け入れ条件（acceptance）を、実装チケットの DoD と振り返りチケットの確認項目に落とす
- 結果報告（`wip/retrospective/`）の「対象 issue」「PR」欄を埋める

チケット作業中は `gh` と `git push` が使えない（WF003）。各チケットの done コミット直後（doing が空）なら `git push` してよく、PR に進捗が反映される。

## 手順 6: 完了処理（全チケット done 後）

doing が空なので GitHub 操作ができる。

1. `git push` で作業ブランチを push する
2. PR 本文を更新する: `gh-feature` の `assets/pr.template.md` に沿って「変更内容の概要」「変更点」「動作確認」を埋め、`wip/retrospective/` の要約と `- Closes #N` を含める。Write で一時ファイルに書き、`gh pr edit M --body-file <path>` で反映する
3. **承認③**: 「ready for review にする」「draft のまま」「追加作業がある」を確認する。承認されたときだけ `gh pr ready M`
4. issue 側の残課題があれば `gh issue comment N` で記録する（issue のクローズは PR のマージで `Closes #N` が行うため、手動で閉じない）

## 手順 7: 報告

- issue: `#N <url>`（新規 / 追記）
- ブランチと PR: `<branch>` / `#M <url>`（draft or ready）
- 成果物: `wip/plan/`、`wip/retrospective/`、コード変更の要約
- 振り返りから得られた改善提案

## エラーハンドリング

| 状況 | 対処 |
|------|------|
| `gh` 未導入 / 未認証 | `gh-install` または `gh auth login` を案内して停止 |
| `origin` が GitHub でない | 対象外として報告する（GitLab の MR は未対応） |
| 未コミットの変更がある | 手順 0「未コミットの変更があるとき」に従い、扱いをユーザーに確認する。勝手に stash / コミット / 破棄しない |
| 検索が 0 件 | closed を含めて再検索。それでも 0 件なら 3B へ |
| `gh pr create` が「差分なし」で失敗 | 空コミットを作って再試行 |
| ブランチ名が衝突 | `gh-feature` の手順に従い別名を提案 |
| `gh issue edit` / `gh pr create` の失敗 | コマンドと出力を報告して停止。別コマンドで代替しない |
| チケット作業中に `gh` が必要になった | WF003 でブロックされる。迂回せず、チケット完了後に行う |
| 承認①②③で却下 | その段階に留まり、修正案を作り直すか停止する。先の段階に進まない |

## ベストプラクティス

- 1 issue = 1 PR = 1 ワークフロー。大きな依頼は issue を分ける
- 承認なしで issue / ブランチ / PR を作らない。承認②でブランチ名と PR タイトルも一緒に確認して往復を減らす
- 既存 issue の本文は追記のみ。過去の経緯を消さない
- issue の受け入れ条件を先に固め、チケットの DoD と結果報告に一貫して使う
- `--body-file` 用の一時ファイルはリポジトリ外（例: `/tmp/`）に置き、残さない
