---
name: workflow-issue-mr-driven
description: >
  ユーザーの依頼を GitHub の issue と PR（MR）に紐づけてから、チケット駆動ワークフローで実作業を進める。
  既存 issue の検索 → 類似があればそれで対応するか確認 → 人間の承認 → issue の作成/修正（task-gh-issue）
  → feature ブランチと draft PR の作成（task-gh-feature）→ チケット駆動ワークフロー、の順で進める開発の振り分け。
  workflow-quick-request と対になる 2 つの振り分けの一方で、振る舞いが変わる変更（機能追加・バグ修正・リファクタリング）、
  複数モジュールや 4 ファイル以上に及ぶ変更、GitHub に経緯を残したい作業はこちら。
  質問・説明・typo 修正など振る舞いを変えない軽作業は workflow-quick-request を使う。
  Use when the user mentions "issue 駆動で", "issue-MR 駆動", "MR 駆動", "PR 駆動", "issue から作業",
  "issue にしてから進めて", "issue-driven", "#12 をやって", or asks to start development work that
  should be tracked as a GitHub issue and pull request before any code is touched.
---

# workflow-issue-mr-driven — issue と PR に紐づけてから作業する

依頼を受けたら**コードに触る前に** issue を確定し、issue に紐づく feature ブランチと draft PR を作り、その上でチケット駆動ワークフローを実施する。
このスキルは**順序と承認ポイントを司るオーケストレータ**であり、個々の操作は既存スキルに委譲する。

- 要件: `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`
- 仕様（承認ポイント・命名規約・委譲内容の正）: `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`
- 類似 issue の判定基準と `gh` コマンド集: `references/issue-triage.md`
- 対になる振り分け: `workflow-quick-request`（issue / PR を作るまでもない軽作業。判定表は同スキルの手順 0 が正。依頼が軽作業に該当すると分かったら、そちらを Skill ツールで読み込んで切り替える）

```
依頼 ─→ 既存 issue を検索 ─┬─ 類似あり ─→ 承認①「#N で対応する？」─→ 追記案 ─→ 承認② ─→ task-gh-issue（編集）─┐
                           └─ 類似なし ─→ 承認①「新規で作る？」  ─→ 本文案 ─→ 承認② ─→ task-gh-issue（作成）─┤
                                                                                                          ▼
                                                                 task-gh-feature（ブランチ + draft PR）─→ work-ticket-driven（全体計画・チケット作成）
                                                                                                          │
   ┌──────────────────────────────── ワークループ（チケット type ごとに繰り返す）────────────────────────────┘
   │  work-ticket-driven（1 ワーク実施）─→ push ─→ PR 本文更新 ─→ work-boundary.sh request ─→ 応答を終える
   │        ▲                                                                                    │
   │        └── 指摘あり: 同 type の追加チケット ◄── work-boundary.sh complete ◄── 承認④「レビュー完了」の連絡
   │                                                指摘なし: 次のワークへ ──────────────────────────┐
   └────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                          ▼
                                                                  完了処理（PR 本文の最終整形 / 承認③ ready）
```

## 役割分担

| 担当 | やること | 呼び出し方 |
|------|---------|-----------|
| このスキル | 依頼の整理、候補の提示、承認の取得、各スキルへの引き継ぎ、完了処理 | — |
| `task-gh-issue` | issue の検索・作成・編集 | 「検索モード」「作成モード」「編集モード」を指定して手順に従う |
| `task-gh-feature` | feature ブランチの作成・push・draft PR の作成 | 「issue 連携モード」を指定して手順に従う |
| `work-ticket-driven` | `wip/` 配下での実作業（フックで統制）。1 つのワーク（チケット type）が完了するたびに制御を返す | 初回は手順 1 から実施し issue / PR の文脈を渡す。2 回目以降は手順 0 の再開判定から |
| `work-boundary.sh` | ワーク境界の判定（`status`）、レビュー依頼（`request`）、レビュー完了の確認（`complete`）、インライン返信（`reply`）。レビュー状態ファイルを書き換える唯一の経路 | `bash .claude/hooks/work-boundary.sh <subcommand>` |

**GitHub 操作（`gh`、`git push`）はチケット作業の外でのみ行う**。`wip/10_tickets/10_doing/` にチケットがある間はフックが WF003 でブロックする。迂回しない。**レビュー状態（`wip/10_tickets/review-state.json`）を Edit / Write / Bash で直接書き換えない**（フックが WF012 で拒否する）。レビューが完了していないのに次のワークへ着手する操作はフックが WF011 で拒否する。

## 承認ポイント（人間の判断が必要な場所）

| # | タイミング | 確認内容 |
|---|-----------|---------|
| ① | 候補提示のあと | どの issue で対応するか（既存 #N / 新規作成 / 別の候補 / 依頼を分割） |
| ② | issue の本文案・追記案のあと | issue に書く内容。あわせてブランチ名と PR タイトル |
| ③ | 全チケット完了・PR 本文更新のあと | draft PR を ready for review にするか |
| ④ | 各ワーク（チケット type）完了・push のあと | PR 上のレビュー。レビュー完了の連絡を受け、`work-boundary.sh complete` が通るまで次のワークに進まない（type の数だけ発生） |

①②③は `AskUserQuestion` で選択肢として提示する（「Other」で修正を受け取れる）。**承認を得るまで issue の変更・ブランチ作成・実作業に進まない**。

④は **`AskUserQuestion` で待たない**。`request` でレビューを依頼したらチャットで報告して応答を終え、次のユーザー発言（「レビュー完了」等）で再開する。人間が GitHub 上でレビューする時間は 1 ターンに収まらず、ヘッドレス実行では `AskUserQuestion` の応答が得られないためである。取得した指摘への対応要否の確認には `AskUserQuestion` を使ってよい。

## 手順 0: 状態確認（再開判定）

```bash
gh auth status
git branch --show-current
git status --short
gh pr view --json number,url,isDraft,state,body 2>/dev/null
ls wip/10_tickets/00_todo/ wip/10_tickets/10_doing/ wip/10_tickets/20_done/ 2>/dev/null
```

- `gh` が未導入・未認証 → `task-gh-install` スキルまたは `gh auth login` を案内して停止する
- **現在ブランチに open な PR があり、`wip/10_tickets/` に todo / doing のチケットがある** → 再開。手順 1〜4 を飛ばし、PR 本文の `Closes #N` から issue 番号を控えて手順 5 に進む。手順 5 に入る前に `bash .claude/hooks/work-boundary.sh status` を実行し、`at_boundary` と `review_state` で「ワークの途中」「レビュー依頼前」「レビュー待ち（`requested`）」「レビュー済み（`completed`）」のどこにいるかを確定する。`requested` ならレビュー完了の連絡を受けていない限り `complete` を実行せず、応答を終える
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

### 振り返りからの切り替え

`workflow-quick-request` 手順 5-3 で「issue を作って workflow-issue-mr-driven で進める」と合意し、その場でこのスキルが読み込まれた場合は、依頼文からの抽出をやり直さない。

- 引き継ぐ項目（quick-request 側と項目名を一致させる）: `summary` / `acceptance` / `kind`（改善・最適化、または新規作成ならタスク）/ チケット構成（`ai-asset-design` → `ai-asset-implementation`）
- 省略できる: 依頼の要約に関する曖昧点の質問（上記が既に確定しているため、まとめて 1 回質問するステップは不要）
- 省略できない: 手順 0 の未コミットの変更の確認、承認①②③④はすべてこの手順で改めて取る（quick-request 側の合意は「このルートに進むこと」の合意であり、issue の内容や PR の承認ではない）
- `keywords` は quick-request 側から渡されないため、`summary` から自分で組み立てて手順 2（既存 issue の検索）に使う

## 手順 2: 既存 issue の検索（task-gh-issue 検索モード）

`task-gh-issue` スキルの検索モードに従い、open issue を keywords で検索する。0 件なら `--state all` で closed も含めて再検索する。

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
4. `task-gh-issue` スキルの**編集モード**に従い、既存本文の**末尾に追記**する。既存の記述は消さない・書き換えない

### 3B: 新規 issue を作る場合

1. `task-gh-issue` スキルの `assets/issue.template.md` を Read し、手順 1 の内容で本文案を作る（種別・概要・詳細・受け入れ条件・優先度）
2. タイトル・本文案・ブランチ名・PR タイトルをユーザーに提示し、**承認②**を得る。修正があれば反映してから進む
3. `task-gh-issue` スキルの**作成モード**に従い issue を作成する。作成後に修正を頼まれたら編集モードで反映する

### 命名規約（承認②で提示する案）

| 対象 | 規約 | 例 |
|------|------|-----|
| ブランチ | `<prefix>-<N>-<slug>`（区切りはすべてハイフン。スラッシュは使わない）。バグは `fix`、それ以外は `feature`。slug は英小文字・数字・ハイフンで 2〜4 語 | `fix-12-login-empty-password` |
| PR タイトル | `<prefix>: <issue タイトル> (#<N>)`。prefix は `feat` / `fix` / `chore` / `docs` / `refactor` | `fix: 空パスワードで送信できる (#12)` |

## 手順 4: feature ブランチと draft PR の作成（task-gh-feature issue 連携モード）

`task-gh-feature` スキルの **issue 連携モード**に従う。要点:

1. デフォルトブランチを取得して最新化する（承認②で合意済みならベースの再確認は不要）
2. `git checkout -b <branch> <default>` でブランチを作成する
3. PR に差分が必要なため、空コミットを作る: `git commit --allow-empty -m "chore: start #N <slug>"`
4. `git push -u origin <branch>`
5. `task-gh-feature` の `assets/pr.template.md` を土台に、`## 関連 Issue` に `- Closes #N` を書いた本文で **draft PR** を作成する

作成した PR の番号と URL を控え、ユーザーに報告する。

## 手順 5: チケット駆動ワークフロー（ワークループ）

**初回のみ** `work-ticket-driven` スキルを**手順 1 から**実施し、全体計画の合意とチケット全件の作成まで進める。引き継ぐ文脈:

- 全体計画（プランモード）の冒頭に `- 対象 issue: #N <url>` と `- PR: #M <url>` を書く
- issue の受け入れ条件（acceptance）を、実装チケットの DoD と振り返りチケットの確認項目に落とす
- 結果報告（`wip/30_reports/`）の「対象 issue」「PR」欄を埋める
- 対象が AI アセット（フック・スキル・ルール・エージェント・設定）の場合、チケット構成は `ai-asset-design`（`.claude/docs/` の要件・仕様）→ `ai-asset-implementation`（フック・スキル・settings.json）→（必要なら）`retrospective` を標準とする。振り返りからの切り替え（上記）で引き継いだチケット構成もこれに従う

以降、todo と doing が両方空になるまで次を繰り返す。1 回のループが 1 ワーク（同じ type のチケット群）に対応する。

| # | やること | 補足 |
|---|---------|------|
| 5-1 | `work-ticket-driven` を実施する（初回は続けて手順 3 へ、2 回目以降は手順 0 の再開判定から）。1 つのワークが完了すると、完了報告とともに制御が戻る | 境界かどうかは `bash .claude/hooks/work-boundary.sh status` の `at_boundary` で確認する。目視で type を比べない |
| 5-2 | `git push` | doing が空なのでフックは働かない |
| 5-3 | PR 本文を更新する: `task-gh-feature` の `assets/pr.template.md` の「変更点」に完了したワークの要約を追記し、Write で一時ファイルに書いて `gh pr edit M --body-file <path>` | 各ワークの要約が積み上がる形にする |
| 5-4 | レビューを依頼する: レビュー観点を書いた一時ファイルを用意し、`bash .claude/hooks/work-boundary.sh request --body-file <path>` を実行する | スクリプトが `gh pr comment` を投稿し、レビュー状態を `requested` にしてコミット・push する。`gh pr comment` を直接叩かない。前提未充足（未コミット・未 push・PR なし・境界でない）は WF013 で止まるので、条件を解消してから再実行する |
| 5-5 | チャットで「ワーク X を push しレビューを依頼した。完了したら知らせてほしい」と報告し、**応答を終える**（承認④の待機） | `AskUserQuestion` で待たない |
| 5-6 | レビュー完了の連絡（次のユーザー発言）を受けたら `bash .claude/hooks/work-boundary.sh complete` を実行する | スクリプトがコメント・レビューを取得し、`CHANGES_REQUESTED` または返信の無いインラインスレッドがあれば WF014 で止まる。通れば `completed` にしてコミットし、`request` 以降の指摘（自分の投稿を除く）を JSON で返す |
| 5-7 | 返された指摘が 0 件なら、そのまま次のワークへ（5-1）。1 件以上なら内容を提示し、対応要否を `AskUserQuestion` で確認する。インラインスレッドへの返信は `bash .claude/hooks/work-boundary.sh reply <id> "<対応内容>"` | 対応要否の判断は人間に残す。スクリプトは「取得した」ことを保証するだけ |
| 5-8 | 対応が必要なら、`work-ticket-driven` に**同じ type の追加チケット**（指摘内容を DoD に落とす）を作らせて 5-1 に戻る。追加チケットが done になると境界の状態は失効するので、再度 5-2〜5-6 を回す | done 済みチケットを doing に戻さない。同じ type の追加チケットは `completed` でなくても着手できる（フックが例外として許可する） |

WF014 で `complete` が止まった場合（`CHANGES_REQUESTED` のまま／未返信スレッドあり）は、理由を報告して指摘対応（5-7・5-8）に進む。レビュアーが approve / dismiss しない限り状態は進まないので、状態ファイルを直して通そうとしない。

ワークの途中（同じ type のチケットが todo に残っている）でも、done コミット直後なら `git push` してよい（PR に進捗が反映される）。レビュー依頼はワーク境界でのみ行う。

## 手順 6: 完了処理（全ワーク done 後）

ループを抜けた時点で push とレビュー（最後のワークの `complete`）は済んでいる。

1. PR 本文を最終整形する: 「変更内容の概要」「動作確認」を `wip/30_reports/` の要約で埋め、`- Closes #N` を確認して `gh pr edit M --body-file <path>`
2. **承認③**: 「ready for review にする」「draft のまま」「追加作業がある」を確認する。承認されたときだけ `gh pr ready M`（最後のワークが `completed` でなければフックが WF011 で拒否する）
3. issue 側の残課題があれば `gh issue comment N` で記録する（issue のクローズは PR のマージで `Closes #N` が行うため、手動で閉じない）

## 手順 7: 報告

- issue: `#N <url>`（新規 / 追記）
- ブランチと PR: `<branch>` / `#M <url>`（draft or ready）
- 成果物: `wip/20_plans/`、`wip/30_reports/`、コード変更の要約
- 振り返りから得られた改善提案

## エラーハンドリング

| 状況 | 対処 |
|------|------|
| `gh` 未導入 / 未認証 | `task-gh-install` または `gh auth login` を案内して停止 |
| `origin` が GitHub でない | 対象外として報告する（`task-gh-feature` 自体は GitHub/GitLab 両対応だが、本ワークフローの issue 検索・作成・編集は `task-gh-issue` に依存しており、`task-gh-issue` が GitHub 専用の間は本ワークフロー全体として GitLab には未対応） |
| 未コミットの変更がある | 手順 0「未コミットの変更があるとき」に従い、扱いをユーザーに確認する。勝手に stash / コミット / 破棄しない |
| 検索が 0 件 | closed を含めて再検索。それでも 0 件なら 3B へ |
| `gh pr create` が「差分なし」で失敗 | 空コミットを作って再試行 |
| ブランチ名が衝突 | `task-gh-feature` の手順に従い別名を提案 |
| `gh issue edit` / `gh pr create` の失敗 | コマンドと出力を報告して停止。別コマンドで代替しない |
| チケット作業中に `gh` が必要になった | WF003 でブロックされる。迂回せず、チケット完了後に行う |
| 承認①②③で却下 | その段階に留まり、修正案を作り直すか停止する。先の段階に進まない |
| `work-boundary.sh request` が WF013 で止まった | 未充足の条件（未コミット / 未 push / PR なし / 境界でない / 既に requested）を解消して再実行する。境界でないなら次のチケットに着手する |
| `work-boundary.sh complete` が WF014 で止まった | `requested` でないなら `request` から。`CHANGES_REQUESTED` なら同じ type の追加チケットで対応して再度 `request`。未返信スレッドは `reply` で返信してから再実行 |
| 次のチケットへの `git mv` が WF011 で止まった | 前のワークのレビューが未完了。メッセージの対処（`request` または `complete`）に従う。状態ファイルを直接編集しない（WF012） |
| レビュー完了の連絡がないまま「続けて」と言われた | `complete` を実行し、通れば次のワークへ。通らなければ理由を報告して応答を終える |
| ヘッドレス実行（`claude -p` 等）でワーク境界に達した | `request` を実行した時点でそのセッションの応答を完了とする。レビュー結果の反映と次のワークは次回セッション（手順 0 の再開判定）で行う。1 セッションで全ワークを完走することは想定しない |

## ベストプラクティス

- 1 issue = 1 PR = 1 ワークフロー。大きな依頼は issue を分ける
- 承認なしで issue / ブランチ / PR を作らない。承認②でブランチ名と PR タイトルも一緒に確認して往復を減らす
- 既存 issue の本文は追記のみ。過去の経緯を消さない
- issue の受け入れ条件を先に固め、チケットの DoD と結果報告に一貫して使う
- `--body-file` 用の一時ファイルはリポジトリ外（例: `/tmp/`）に置き、残さない
- レビュー依頼（`request --body-file`）には「対象の差分範囲」「見てほしい観点」「次のワーク」を書く。後段のワークで確定したい判断があれば、そこで指摘してもらえるよう明示する
- ワークの粒度が細かすぎてレビュー往復が多いと感じたら、type をまとめるのではなく、レビュー依頼に「軽微なので approve のみで可」と添える
