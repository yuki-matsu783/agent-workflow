# issue-PR 駆動ワークフロースキル 仕様書

## 概要

- **背景**: 要件定義書 `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` に基づき、スキルの処理フロー・承認ポイント・既存スキルへの委譲方法・命名規約を確定する。
- **目的**: 「依頼 → issue 照合 → 承認 → issue 確定 → ブランチ/PR → チケット駆動 → 完了処理」の各段階で、何を入力に何を出力するか、どこで人間が判断するかを実装可能なレベルで固定する。
- **スコープ**:
  - 含む: 処理フロー、承認ポイント、gh-issue / gh-feature / ticket-driven-workflow への委譲内容、issue / ブランチ / PR / コミットの命名規約、既存フックとの関係、例外処理、テストシナリオ
  - 含まない: スキル本文（SKILL.md）の文言、gh-issue / gh-feature の内部手順（各スキルの SKILL.md が正）

---

## 入力（Input）定義

### 入力元

- **入力元**: ユーザーの依頼（会話）、`gh` CLI の出力（issue / PR の一覧・詳細）、Git の状態（ブランチ・作業ツリー）、`wip/` 配下の状態

### 入力データ

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| 依頼内容 | string | Y | ユーザーの依頼文。要約・検索キーワード・種別の抽出元 | |
| 指定 issue 番号 | int | N | ユーザーが `#N` を指定した場合。検索を省略する | なし |
| 既存 issue 一覧 | object[] | Y | `gh issue list --json number,title,state,labels,url,body` の結果 | |
| 現在ブランチ | string | Y | `git branch --show-current` | |
| 現在ブランチの PR | object | N | `gh pr view --json number,url,isDraft,state,body`（無ければ再開ではない） | なし |
| `wip/ticket/` の状態 | string[] | N | todo / doing / done のチケット一覧。再開判定に使う | 空 |
| デフォルトブランチ | string | Y | `gh repo view --json defaultBranchRef` | |

### 入力フォーマット（依頼の整理結果）

スキルが依頼から抽出し、以降の各段階で使い回す内部データ:

```yaml
summary: ログイン画面でパスワード入力欄が空でも送信できてしまう   # 1〜2 行
kind: バグ            # バグ | 機能追加 | タスク | 改善・最適化 | 質問 | その他（issue テンプレートの種別に対応）
keywords: [ログイン, パスワード, バリデーション, login, validation]
acceptance:           # 受け入れ条件。issue に書き、チケットの DoD の元になる
  - 空のパスワードで送信するとエラーメッセージが表示される
  - 既存のログインテストが通る
out_of_scope:
  - パスワード強度チェックの追加
```

---

## 出力（Output）定義

### 出力先

- **出力先**: GitHub（issue / ブランチ / PR）、ローカル Git（ブランチ・コミット）、`wip/` 配下（チケット駆動ワークフローの成果物）、ユーザーへの報告

### 出力データ

| 項目名 | 型 | 説明 | デフォルト値 |
|--------|----|------|-------------|
| issue | number, url | 確定した issue（新規作成 or 追記した既存 issue） | |
| feature ブランチ | string | `feature/<N>-<slug>` 等。issue 番号を含む | |
| draft PR | number, url | 本文に `Closes #N` を含む draft PR | |
| 全体計画 | file | `wip/00_overall_plan/` 配下。冒頭に issue / PR を記載 | |
| 結果報告 | file | `wip/retrospective/` 配下。対象 issue / PR を記載 | |
| PR 本文（完了時） | string | 変更内容・動作確認・振り返り要約・`Closes #N` | |

### 出力フォーマット（PR 本文）

gh-feature の `assets/pr-template.md` を土台にし、以下を必ず含める:

```markdown
## 変更内容の概要
<!-- issue の受け入れ条件に対して何をしたか -->

## 関連 Issue
- Closes #N
```

### ステータス（スキルの終了状態）

| 状態 | 意味 |
|------|------|
| 完了 | 全チケット done、push 済み、PR 本文更新済み。ready 化はユーザー判断 |
| 中断（承認待ち） | 承認ポイントでユーザーが保留・却下した。承認済みの段階までの成果（issue 等）は残る |
| 中断（エラー） | `gh` / `git` の失敗。失敗したコマンドと出力を報告して停止 |

---

## 処理フロー

### 承認ポイント

| # | タイミング | 確認する内容 | 選択肢 |
|---|-----------|-------------|--------|
| ① | 類似 issue の提示後 | どの issue で対応するか | 既存 #N で対応 / 新規 issue を作成 / 別の候補を見る / 依頼を分割する |
| ② | issue 本文（新規）または追記案の提示後 | issue に書く内容、ブランチ名、PR タイトル | 承認 / 修正して承認 / 却下 |
| ③ | 全チケット完了・PR 本文更新後 | draft を ready for review にするか | ready にする / draft のまま / 追加作業 |

承認は `AskUserQuestion` で選択肢として提示し、「Other」で修正内容を受け取れるようにする。承認を得るまで次の段階に進まない。

### 基本フロー（ハッピーパス）

1. **状態確認**: `gh auth status`、`git branch --show-current`、`git status --short`、`gh pr view`、`wip/ticket/` の一覧を取得する。再開条件（代替フロー 1）に該当しなければ次へ
2. **依頼の整理**: 依頼から `summary` / `kind` / `keywords` / `acceptance` / `out_of_scope` を抽出する。曖昧なら 1 回だけまとめて質問する
3. **既存 issue の検索**（gh-issue の検索モード）: `keywords` で open issue を検索し、0 件なら closed も含めて検索する。候補を `references/issue-triage.md` の基準で「類似 / 関連 / 無関係」に分類し、類似・関連を表で提示する
4. **承認①**: 類似ありなら「既存 #N で対応するか」、類似なしなら「新規 issue を作るか」を確認する
5. **issue の確定**
   - 既存 #N: `assets/issue-addendum-template.md` から追記案を作る → **承認②** → gh-issue の編集モードで**本文末尾に追記**する（既存の記述は変更しない）
   - 新規: gh-issue の `assets/issue-template.md` から本文案を作る → **承認②** → gh-issue の作成モードで作成する
   - 承認②では、ブランチ名と PR タイトルの案も同時に確認する（往復を減らす）
6. **ブランチと draft PR の作成**（gh-feature の issue 連携モード）: デフォルトブランチを最新化 → `feature/<N>-<slug>` を作成 → 空コミット → push → `Closes #N` を含む draft PR を作成する
7. **チケット駆動ワークフロー**: `ticket-driven-workflow` の手順 1 から実施する。全体計画の冒頭に issue / PR を記載し、issue の `acceptance` をチケットの DoD に反映する
8. **完了処理**（全チケット done 後。doing が空なので `gh` / `git push` が使える）: `git push` → `gh pr edit --body-file` で PR 本文を更新 → **承認③** → 承認されれば `gh pr ready`
9. **報告**: issue / PR の URL、ブランチ、成果物一覧、振り返りの要約を報告する

### 代替フロー

1. **再開**: 現在ブランチに open な PR があり、`wip/ticket/` に todo または doing のチケットがある → 手順 1〜6 を省略し、手順 7（ticket-driven-workflow の手順 0）に進む。PR 本文の `Closes #N` から issue 番号を復元する
2. **issue 番号の指定あり**: `gh issue view N` で内容を取得し、手順 3 を省略して「既存 #N で対応」として承認①に進む
3. **候補が closed のみ**: 承認①の選択肢に「#N を再オープンして対応」を加える。再オープンは `gh issue reopen N`（承認後）
4. **依頼が複数の問題を含む**: 分割案（issue 1 件ずつ）を提示し、ユーザーが選んだ 1 件で本フローを進める。残りは新規 issue として起票だけ提案する
5. **チケット完了ごとの push**: 各チケットの done コミット直後（doing が空）に `git push` してよい。PR に進捗が反映される。次のチケットの着手前に行う

### 例外フロー

1. **`gh` 未導入 / 未認証**: gh-install スキルまたは `gh auth login` を案内して停止する
2. **未コミットの変更あり**: 手順 1（状態確認）の時点で検知し、変更のファイル一覧を示した上で `AskUserQuestion` により扱いを確認する（選択肢: コミットしてから進む / stash に退避して進む / 破棄して進む / 中断）。スキルが自分の判断で stash・コミット・破棄をしてはならない。issue の検索・案の作成は未解消でも進められるが、手順 6（ブランチ作成）に入る前に必ず解消されていること
3. **PR 作成失敗（差分なし）**: `git commit --allow-empty -m "chore: start #N <slug>"` を作って再試行する
4. **ブランチ名の衝突**: gh-feature の手順（別名の提案）に従う
5. **`gh issue edit` / `gh pr create` の失敗**: コマンドと出力を報告して停止する。手動での作成を案内してよいが、別コマンドで代替しない
6. **チケット作業中に GitHub 操作が必要になった**: フックが WF003 でブロックする。迂回せず、チケット完了後（doing が空）まで待つ

---

## データ設計

### 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| ブランチ | `<prefix>/<N>-<slug>`。prefix は種別から（バグ→`fix`、それ以外→`feature`）。slug は英小文字・数字・ハイフンで 2〜4 語 | `fix/12-login-empty-password` |
| 空コミット | `chore: start #<N> <slug>` | `chore: start #12 login-empty-password` |
| PR タイトル | `<prefix>: <issue タイトル> (#<N>)`。prefix は `feat` / `fix` / `chore` / `docs` / `refactor` | `fix: 空パスワードで送信できる (#12)` |
| PR 本文 | gh-feature の `assets/pr-template.md` + `Closes #<N>` | |
| issue 追記見出し | `## 今回の依頼（YYYY-MM-DD）` | `## 今回の依頼（2026-08-30）` |
| 全体計画の冒頭 | `- 対象 issue: #<N> <url>` / `- PR: #<M> <url>` | |

### データモデル（責務の分担）

```
issue-pr-driven-workflow（オーケストレータ）
├── gh-issue                 検索 / 作成 / 編集（gh issue list|view|create|edit）
├── gh-feature               ブランチ作成 / push / draft PR（git checkout -b, gh pr create --draft）
└── ticket-driven-workflow   wip/ 配下での実作業（フックによる統制下）
        └── 完了後にオーケストレータへ戻る（push / PR 本文更新 / ready 確認）
```

### 状態遷移

```
依頼 ──検索──> 候補提示 ──承認①──> issue 確定案 ──承認②──> issue 確定
   ──gh-feature──> ブランチ + draft PR ──ticket-driven──> 全チケット done
   ──push + PR 本文更新──> 承認③ ──> ready for review（or draft のまま）
```

---

## インターフェース定義

### 既存スキルへの委譲内容

| 委譲先 | モード | 渡す情報 | 受け取る情報 |
|--------|--------|---------|-------------|
| gh-issue | 検索 | keywords、state（open / all） | 候補 issue の number / title / state / url / body |
| gh-issue | 作成 | title、本文（テンプレート記入済み） | issue number / url |
| gh-issue | 編集 | issue number、追記セクション | 更新結果 |
| gh-feature | issue 連携 | issue number / title、ブランチ名、PR タイトル、ベースブランチ | ブランチ名、PR number / url |
| ticket-driven-workflow | 通常 | issue number / url、PR number / url、acceptance | 完了報告（成果物一覧・振り返り） |

### 使用する `gh` コマンド（参考）

```bash
gh issue list --state open --search "<keywords>" --limit 20 --json number,title,state,labels,url,body
gh issue view N --json number,title,state,url,body
gh issue create --title "<title>" --body-file <path>
gh issue edit N --body-file <path>
gh pr create --base <default> --head <branch> --title "<title>" --body-file <path> --draft
gh pr view --json number,url,isDraft,state,body
gh pr edit N --body-file <path>
gh pr ready N
```

---

## エラーハンドリング

### エラーケース一覧

| ケース | 検知方法 | 対処 |
|--------|---------|------|
| `gh` 未認証 | `gh auth status` が非 0 | gh-install / `gh auth login` を案内して停止 |
| リモートが GitHub でない | `git remote get-url origin` が github.com を含まない | 対象外として報告（MR / GitLab は未対応） |
| 未コミットの変更 | `git status --short` が非空 | `AskUserQuestion` で扱い（コミット / stash / 破棄 / 中断）を確認。自動で stash・破棄しない |
| 検索 0 件 | 候補なし | closed も含めて再検索 → それでも 0 件なら新規 issue の案へ |
| PR 作成失敗（差分なし） | `gh pr create` のエラー | 空コミット後に再試行 |
| チケット作業中の `gh` / `git push` | フックの WF003 | 迂回せず、doing が空になるまで待つ |
| 承認却下 | ユーザーの選択 | 却下された段階に留まり、修正案を作り直すか停止する |

### ユーザーへの提示フォーマット（候補 issue）

```
| # | タイトル | 状態 | 一致点 | 判定 |
|---|---------|------|--------|------|
| 12 | ログイン画面のバリデーション | open | ログイン / バリデーション | 類似 |
| 8  | パスワード強度チェック | closed | パスワード | 関連 |
```

---

## 前提条件

- `origin` が GitHub のリポジトリを指し、`gh` が認証済みであること
- チケット駆動ワークフロー（スキル・フック・`workflow-types.json`）が導入済みであること
- デフォルトブランチへの直接 push を前提としない（feature ブランチから PR を出す運用）

---

## 制約条件

- **技術的制約**: GitHub / `gh` CLI 前提。フックの Bash allowlist により、doing チケットがある間は `gh` と `git push` が使えない（仕様として許容し、フックは変更しない）
- **ビジネス的制約**: 特になし
- **外部的制約**: gh-issue / gh-feature / ticket-driven-workflow の手順に従う（本スキルは順序と承認を司るだけで、各操作の詳細を再定義しない）

---

## 非機能要件

| 項目 | 説明 |
|------|------|
| パフォーマンス | issue 検索は `--limit 20`、候補提示は上位 10 件まで |
| セキュリティ | issue / PR 本文にシークレット・個人情報を書かない。`--body-file` の一時ファイルは作業後に残さない |
| 可用性 | GitHub に接続できなくても依頼の整理と issue 案の作成までは進められる |
| 追跡性 | ブランチ名・空コミット・PR 本文・全体計画・結果報告に issue 番号を残す |

---

## テストシナリオ

### テストケース一覧

| テストID | シナリオ | 入力 | 期待出力 | 結果 |
|---------|---------|------|---------|------|
| IP001 | 類似 issue あり → 既存で対応 | 依頼 + open issue #12（同じ機能領域・同じ問題） | 候補提示 → 承認① → 追記案 → 承認② → `gh issue edit 12` → `fix/12-*` ブランチ + draft PR → チケット駆動開始 | |
| IP002 | 類似 issue なし → 新規作成 | 依頼 + 無関係な issue のみ | 「類似なし」と報告 → 承認① → 本文案 → 承認② → `gh issue create` → ブランチ + draft PR → チケット駆動開始 | |
| IP003 | 承認①で却下 | 依頼 + 類似 issue、ユーザーが「別の候補」を選択 | issue / ブランチ / PR を作らず候補を再提示する | |
| IP004 | 再開 | feature ブランチ + open PR + `wip/ticket/doing/` にチケット | 検索・承認をやり直さず ticket-driven-workflow の手順 0 に進む | |
| IP005 | issue 番号指定 | 「#12 をやって」 | 検索を省略し `gh issue view 12` → 承認①（既存で対応）へ | |
| IP006 | `gh` 未認証 | `gh auth status` 失敗 | gh-install / `gh auth login` を案内して停止 | |
| IP007 | 未コミットの変更あり | `git status --short` 非空 | ブランチ作成前にユーザーへ扱いを確認 | |
| IP008 | チケット作業中の `gh` | doing 1 枚で `gh pr edit` | WF003 でブロック。迂回せず完了後に実行 | |
| IP009 | 完了処理 | 全チケット done | `git push` → PR 本文更新 → 承認③ → 承認時のみ `gh pr ready` | |
| IP010 | 既存 issue の本文保全 | 既存 #12 に追記 | 追記前の本文が変更されず、末尾に `## 今回の依頼（日付）` が追加される | |

### テスト実施例

- **テストID**: IP010
  - **前提条件**: open issue #12 が存在し、本文に既存の記述がある
  - **テスト手順**: 依頼を出し、承認①で「#12 で対応」、承認②で追記案を承認する。`gh issue view 12 --json body -q .body` を前後で比較する
  - **期待結果**: 追記前の本文が先頭にそのまま残り、末尾に `## 今回の依頼（YYYY-MM-DD）` セクションが追加されている

---

## 関連するドキュメント

- `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`（要件定義書）
- `.claude/docs/10_spec/チケット駆動ワークフロー.md`（後続の実作業の仕様。Bash allowlist の正）
- `.claude/skills/gh-issue/SKILL.md`、`.claude/skills/gh-feature/SKILL.md`（委譲先の手順）

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版 | Hiro |
