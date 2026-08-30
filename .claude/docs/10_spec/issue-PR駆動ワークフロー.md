# issue-PR 駆動ワークフロースキル 仕様書

## 概要

- **背景**: 要件定義書 `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` に基づき、スキルの処理フロー・承認ポイント・既存スキルへの委譲方法・命名規約を確定する。
- **目的**: 「依頼 → issue 照合 → 承認 → issue 確定 → ブランチ/PR → チケット駆動 → 完了処理」の各段階で、何を入力に何を出力するか、どこで人間が判断するかを実装可能なレベルで固定する。
- **スコープ**:
  - 含む: 処理フロー、承認ポイント、task-gh-issue / task-gh-feature / work-ticket-driven への委譲内容、issue / ブランチ / PR / コミットの命名規約、既存フックとの関係、例外処理、テストシナリオ
  - 含まない: スキル本文（SKILL.md）の文言、task-gh-issue / task-gh-feature の内部手順（各スキルの SKILL.md が正）

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
| `wip/10_tickets/` の状態 | string[] | N | todo / doing / done のチケット一覧。再開判定に使う | 空 |
| デフォルトブランチ | string | Y | `gh repo view --json defaultBranchRef` | |
| 振り返りからの引き継ぎ情報 | object | N | `workflow-quick-request` 手順 5-3 から切り替えて来た場合の summary / acceptance / kind / チケット構成（`ai-asset-design` → `ai-asset-implementation`）。渡された場合は手順 2（依頼の整理）の曖昧点の質問を省略してよい | なし |

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
| feature ブランチ | string | `feature-<N>-<slug>` 等。issue 番号を含む | |
| draft PR | number, url | 本文に `Closes #N` を含む draft PR | |
| 全体計画 | file | `wip/00_overall_plan/` 配下。冒頭に issue / PR を記載 | |
| 結果報告 | file | `wip/30_reports/` 配下。対象 issue / PR を記載 | |
| PR 本文（完了時） | string | 変更内容・動作確認・振り返り要約・`Closes #N` | |

### 出力フォーマット（PR 本文）

task-gh-feature の `assets/pr.template.md` を土台にし、以下を必ず含める:

```markdown
## 変更内容の概要
<!-- issue の受け入れ条件に対して何をしたか -->

## 関連 Issue
- Closes #N
```

### ステータス（スキルの終了状態）

| 状態 | 意味 |
|------|------|
| 完了 | 全ワーク（全チケット）done、push 済み、PR 本文更新済み。ready 化はユーザー判断 |
| 中断（レビュー待ち） | ワーク完了後に push・レビュー依頼を行い、レビュー完了の連絡を待って応答を終えた。次の発言（または次回セッション）で再開する |
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
| ④ | 各ワーク（チケットの作業タイプ）完了・push 後 | PR 上のレビュー。レビュー完了の連絡を受け、コメントを取得して対応要否を確認するまで次のワークに進まない | 指摘なし → 次のワークへ / 指摘あり → 同タイプの追加チケットで対応 / 対応不要と判断 |

①②③は `AskUserQuestion` で選択肢として提示し、「Other」で修正内容を受け取れるようにする。承認を得るまで次の段階に進まない。

④は**レビュー依頼を投稿した時点でスキルの応答を終える**（`AskUserQuestion` で待たない）。人間が GitHub 上でレビューする時間は対話の1ターンに収まらず、ヘッドレス実行では `AskUserQuestion` の応答が得られないためである。レビュー完了の連絡（次のユーザー発言）を受けてからコメントを取得し、取得した指摘への対応要否は `AskUserQuestion` で確認する（自動判定しない）。④はワーク（作業タイプ）の数だけ発生する。

### 基本フロー（ハッピーパス）

1. **状態確認**: `gh auth status`、`git branch --show-current`、`git status --short`、`gh pr view`、`wip/10_tickets/` の一覧を取得する。再開条件（代替フロー 1）に該当しなければ次へ
2. **依頼の整理**: 依頼から `summary` / `kind` / `keywords` / `acceptance` / `out_of_scope` を抽出する。曖昧なら 1 回だけまとめて質問する
3. **既存 issue の検索**（task-gh-issue の検索モード）: `keywords` で open issue を検索し、0 件なら closed も含めて検索する。候補を `references/issue-triage.md` の基準で「類似 / 関連 / 無関係」に分類し、類似・関連を表で提示する
4. **承認①**: 類似ありなら「既存 #N で対応するか」、類似なしなら「新規 issue を作るか」を確認する
5. **issue の確定**
   - 既存 #N: `assets/issue-addendum.template.md` から追記案を作る → **承認②** → task-gh-issue の編集モードで**本文末尾に追記**する（既存の記述は変更しない）
   - 新規: task-gh-issue の `assets/issue.template.md` から本文案を作る → **承認②** → task-gh-issue の作成モードで作成する
   - 承認②では、ブランチ名と PR タイトルの案も同時に確認する（往復を減らす）
6. **ブランチと draft PR の作成**（task-gh-feature の issue 連携モード）: デフォルトブランチを最新化 → `feature-<N>-<slug>` を作成 → 空コミット → push → `Closes #N` を含む draft PR を作成する
7. **チケット駆動ワークフロー（ワークループ）**: 初回のみ `work-ticket-driven` の手順 1 から実施し、全体計画の合意（冒頭に issue / PR を記載、issue の `acceptance` をチケットの DoD に反映）とチケット全件の作成まで進める。以降、todo と doing が両方空になるまで次を繰り返す:
   1. `work-ticket-driven` を実施する。1つのワーク（作業タイプ）が完了すると、完了報告とともに制御が戻る。境界かどうかは `bash .claude/hooks/work-boundary.sh status` の `at_boundary` で確認する（目視の type 比較はしない）
   2. `git push`（doing が空なのでフックは働かない）
   3. `gh pr edit M --body-file` で PR 本文の「変更点」に完了したワークの要約を追記する
   4. `bash .claude/hooks/work-boundary.sh request --body-file <レビュー観点を書いた一時ファイル>` でレビューを依頼する（スクリプトが `gh pr comment` を実行し、レビュー状態を `requested` にしてコミット・push する。`gh pr comment` を直接叩かない）。チャットでレビュー依頼した旨を報告して**応答を終える**（承認④の待機）
   5. レビュー完了の連絡を受けたら、`bash .claude/hooks/work-boundary.sh complete` を実行する（スクリプトがコメント・レビューを取得し、`CHANGES_REQUESTED` や未返信のインラインスレッドがあれば WF014 で拒否する。通れば `completed` にしてコミットし、取得した指摘を JSON で返す）。指摘が 0 件ならそのまま次のワークへ。1 件以上なら対応要否を `AskUserQuestion` で確認する。インラインスレッドへの返信は `work-boundary.sh reply <id> "<対応内容>"`
   6. 対応が必要な指摘があれば、`work-ticket-driven` に同じ作業タイプの追加チケット（指摘内容を DoD に落とす）を作らせ、7-1 に戻る（同じ type の追加チケットは境界でも着手できる。完了後は done 末尾が変わるため、再度 7-2〜7-5 を回して `request` → `complete` する）

   レビュー状態（`wip/10_tickets/review-state.json`）を Edit / Write / Bash で直接書き換えない（フックが WF012 で拒否する）。レビューが完了していない状態で次の type のチケットに着手しようとするとフックが WF011 で拒否し、対処（`request` または `complete`）を返す
8. **完了処理**（全ワーク done 後）: ループ内で push と PR 本文更新は済んでいるため、`wip/30_reports/` の要約で PR 本文を最終整形 → **承認③** → 承認されれば `gh pr ready`
9. **報告**: issue / PR の URL、ブランチ、成果物一覧、振り返りの要約を報告する

### 代替フロー

1. **再開**: 現在ブランチに open な PR があり、`wip/10_tickets/` に todo または doing のチケットがある → 手順 1〜6 を省略し、手順 7（work-ticket-driven の手順 0）に進む。PR 本文の `Closes #N` から issue 番号を復元する
2. **issue 番号の指定あり**: `gh issue view N` で内容を取得し、手順 3 を省略して「既存 #N で対応」として承認①に進む
3. **候補が closed のみ**: 承認①の選択肢に「#N を再オープンして対応」を加える。再オープンは `gh issue reopen N`（承認後）
4. **依頼が複数の問題を含む**: 分割案（issue 1 件ずつ）を提示し、ユーザーが選んだ 1 件で本フローを進める。残りは新規 issue として起票だけ提案する
5. **ワーク途中のチケット完了ごとの push**: 同じ作業タイプの次のチケットが todo に残っている（ワーク境界ではない）場合でも、done コミット直後（doing が空）に `git push` してよい。PR に進捗が反映される。この場合はレビュー依頼（承認④）を行わず、次のチケットの着手に進む
6. **レビュー完了の連絡がないまま「続けて」と言われた**: 基本フロー 7-5（`work-boundary.sh complete`）を実行し、通れば次のワークへ進む。通らない（WF014）なら理由を報告して応答を終える。`complete` を経ずに次の type へ着手しようとしてもフックが WF011 で拒否する
7. **ヘッドレス実行（`claude -p` 等）でワーク境界に達した**: レビュー依頼（7-4）を投稿した時点でそのセッションの応答を完了とする。レビュー結果の反映と次のワークは次回セッション（代替フロー 1 の再開）で行う。1セッションで全ワークを完走することは想定しない
8. **`workflow-quick-request` の振り返り（手順 5-3）からの切り替え**: summary / acceptance / kind / チケット構成が既に引き継がれているため、手順 2（依頼の整理）の曖昧点の質問を省略し、そのまま手順 3（既存 issue の検索）へ進む。手順 1（状態確認）の未コミットの変更の確認は省略しない。チケット構成は引き継がれたとおり `ai-asset-design` → `ai-asset-implementation` を用いる

### 例外フロー

1. **`gh` 未導入 / 未認証**: task-gh-install スキルまたは `gh auth login` を案内して停止する
2. **未コミットの変更あり**: 手順 1（状態確認）の時点で検知し、変更のファイル一覧を示した上で `AskUserQuestion` により扱いを確認する（選択肢: コミットしてから進む / stash に退避して進む / 破棄して進む / 中断）。スキルが自分の判断で stash・コミット・破棄をしてはならない。issue の検索・案の作成は未解消でも進められるが、手順 6（ブランチ作成）に入る前に必ず解消されていること
3. **PR 作成失敗（差分なし）**: `git commit --allow-empty -m "chore: start #N <slug>"` を作って再試行する
4. **ブランチ名の衝突**: task-gh-feature の手順（別名の提案）に従う
5. **`gh issue edit` / `gh pr create` の失敗**: コマンドと出力を報告して停止する。手動での作成を案内してよいが、別コマンドで代替しない
6. **チケット作業中に GitHub 操作が必要になった**: フックが WF003 でブロックする。迂回せず、チケット完了後（doing が空）まで待つ

---

## データ設計

### 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| ブランチ | `<prefix>-<N>-<slug>`（区切りはすべてハイフン。スラッシュは使わない）。prefix は種別から（バグ→`fix`、それ以外→`feature`）。slug は英小文字・数字・ハイフンで 2〜4 語 | `fix-12-login-empty-password` |
| 空コミット | `chore: start #<N> <slug>` | `chore: start #12 login-empty-password` |
| PR タイトル | `<prefix>: <issue タイトル> (#<N>)`。prefix は `feat` / `fix` / `chore` / `docs` / `refactor` | `fix: 空パスワードで送信できる (#12)` |
| PR 本文 | task-gh-feature の `assets/pr.template.md` + `Closes #<N>` | |
| issue 追記見出し | `## 今回の依頼（YYYY-MM-DD）` | `## 今回の依頼（2026-08-30）` |
| 全体計画の冒頭 | `- 対象 issue: #<N> <url>` / `- PR: #<M> <url>` | |

### データモデル（責務の分担）

```
workflow-issue-mr-driven（オーケストレータ）
├── task-gh-issue                 検索 / 作成 / 編集（gh issue list|view|create|edit）
├── task-gh-feature               ブランチ作成 / push / draft PR（git checkout -b, gh pr create --draft）
└── work-ticket-driven   wip/ 配下での実作業（フックによる統制下）
        └── ワーク（作業タイプ）完了ごとにオーケストレータへ戻る
              （push / PR 本文更新 / レビュー依頼 → 承認④ → コメント取得 / 追加チケット）
              全ワーク完了後: PR 本文の最終整形 / ready 確認（承認③）
```

### 状態遷移

```
依頼 ──検索──> 候補提示 ──承認①──> issue 確定案 ──承認②──> issue 確定
   ──task-gh-feature──> ブランチ + draft PR ──work-ticket-driven（全体計画・チケット作成）──┐
                                                                                        ▼
   ┌──────────────────────────────────────────────────────────────────────────────────────┐
   │ ワーク実施 ──ワーク done──> push + PR 本文更新 + レビュー依頼 ──（応答終了）──> 承認④ │
   │      ▲                                                                   │        │
   │      └── 指摘あり: 同タイプの追加チケット ◄── コメント取得 ◄── レビュー完了の連絡 ┘        │
   │                                     指摘なし: 次のワークへ（todo が空ならループ終了）    │
   └──────────────────────────────────────────────────────────────────────────────────────┘
                                                                                        ▼
   ──PR 本文の最終整形──> 承認③ ──> ready for review（or draft のまま）
```

---

## インターフェース定義

### 既存スキルへの委譲内容

| 委譲先 | モード | 渡す情報 | 受け取る情報 |
|--------|--------|---------|-------------|
| task-gh-issue | 検索 | keywords、state（open / all） | 候補 issue の number / title / state / url / body |
| task-gh-issue | 作成 | title、本文（テンプレート記入済み） | issue number / url |
| task-gh-issue | 編集 | issue number、追記セクション | 更新結果 |
| task-gh-feature | issue 連携 | issue number / title、ブランチ名、PR タイトル、ベースブランチ | ブランチ名、PR number / url |
| work-ticket-driven | 通常（初回） | issue number / url、PR number / url、acceptance | 全体計画・チケット全件、続けて最初のワークの完了報告 |
| work-ticket-driven | 再開（2回目以降のワーク） | 直前ワークのレビュー結果（指摘なし / 追加チケットの内容） | ワーク完了報告（完了した作業タイプ・チケット一覧・差分要約・todo に残る次の作業タイプ） |

### 使用する `gh` コマンド（参考）

```bash
gh issue list --state open --search "<keywords>" --limit 20 --json number,title,state,labels,url,body
gh issue view N --json number,title,state,url,body
gh issue create --title "<title>" --body-file <path>
gh issue edit N --body-file <path>
gh pr create --base <default> --head <branch> --title "<title>" --body-file <path> --draft
gh pr view --json number,url,isDraft,state,body
gh pr edit N --body-file <path>
bash .claude/hooks/work-boundary.sh status                       # ワーク境界とレビュー状態の判定（JSON）
bash .claude/hooks/work-boundary.sh request --body-file <path>   # レビュー依頼（内部で gh pr comment）
bash .claude/hooks/work-boundary.sh complete                     # レビュー完了の確認（内部で gh pr view / gh api .../pulls/N/comments）
bash .claude/hooks/work-boundary.sh reply <id> "<対応内容>"      # インラインスレッドへの返信
gh pr ready N
```

- レビュー依頼・コメント取得はスキルが `gh pr comment` / `gh pr view` / `gh api` を直接組み立てず、`work-boundary.sh` に委ねる（`.claude/docs/10_spec/チケット駆動ワークフロー.md`「ワーク境界の判定とレビュー状態」が正）。`complete` は `reviewDecision`（`""` / `APPROVED` / `REVIEW_REQUIRED` / `CHANGES_REQUESTED`）と、返信の無いインラインスレッド（`in_reply_to_id` が null で、その id を `in_reply_to_id` に持つ要素が無いもの）を機械的に検査する

---

## エラーハンドリング

### エラーケース一覧

| ケース | 検知方法 | 対処 |
|--------|---------|------|
| `gh` 未認証 | `gh auth status` が非 0 | task-gh-install / `gh auth login` を案内して停止 |
| リモートが GitHub でない | `git remote get-url origin` が github.com を含まない | 対象外として報告（MR / GitLab は未対応） |
| 未コミットの変更 | `git status --short` が非空 | `AskUserQuestion` で扱い（コミット / stash / 破棄 / 中断）を確認。自動で stash・破棄しない |
| 検索 0 件 | 候補なし | closed も含めて再検索 → それでも 0 件なら新規 issue の案へ |
| PR 作成失敗（差分なし） | `gh pr create` のエラー | 空コミット後に再試行 |
| チケット作業中の `gh` / `git push` | フックの WF003 | 迂回せず、doing が空になるまで待つ |
| 承認却下 | ユーザーの選択 | 却下された段階に留まり、修正案を作り直すか停止する |
| レビュー完了の連絡なしで続行を求められた | ユーザーの発言に「レビュー完了」相当の合図が無い | コメント取得を実行し、未取得の指摘が無いことを確認してから次のワークへ進む |
| ヘッドレス実行でワーク境界に達した | 対話できない環境 | レビュー依頼を投稿してセッションを終える。続きは次回セッションの再開で行う |

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

- **技術的制約**: GitHub / `gh` CLI 前提。フックの Bash allowlist により、doing チケットがある間は `gh` と `git push` が使えない（仕様として許容し、`workflow-guard.sh` は変更しない）。ワーク境界の判定とレビュー状態の遷移は `work-boundary.sh` が決定論的に行い、`workflow-boundary.sh` がレビュー未完了での次ワーク着手（WF011）と状態ファイルの直接書き換え（WF012）を拒否する。本スキルはその出力に従う
- **対話上の制約**: 承認④（ワーク完了ごとのレビュー）は応答を終えて次の発言を待つ方式のため、1つのワークフローが複数ターン・複数セッションにまたがる。ヘッドレス実行では1セッションで完走しない
- **ビジネス的制約**: 特になし
- **外部的制約**: task-gh-issue / task-gh-feature / work-ticket-driven の手順に従う（本スキルは順序と承認を司るだけで、各操作の詳細を再定義しない）

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
| IP001 | 類似 issue あり → 既存で対応 | 依頼 + open issue #12（同じ機能領域・同じ問題） | 候補提示 → 承認① → 追記案 → 承認② → `gh issue edit 12` → `fix-12-*` ブランチ + draft PR → チケット駆動開始 | |
| IP002 | 類似 issue なし → 新規作成 | 依頼 + 無関係な issue のみ | 「類似なし」と報告 → 承認① → 本文案 → 承認② → `gh issue create` → ブランチ + draft PR → チケット駆動開始 | |
| IP003 | 承認①で却下 | 依頼 + 類似 issue、ユーザーが「別の候補」を選択 | issue / ブランチ / PR を作らず候補を再提示する | |
| IP004 | 再開 | feature ブランチ + open PR + `wip/10_tickets/10_doing/` にチケット | 検索・承認をやり直さず work-ticket-driven の手順 0 に進む | |
| IP005 | issue 番号指定 | 「#12 をやって」 | 検索を省略し `gh issue view 12` → 承認①（既存で対応）へ | |
| IP006 | `gh` 未認証 | `gh auth status` 失敗 | task-gh-install / `gh auth login` を案内して停止 | |
| IP007 | 未コミットの変更あり | `git status --short` 非空 | ブランチ作成前にユーザーへ扱いを確認 | |
| IP008 | チケット作業中の `gh` | doing 1 枚で `gh pr edit` | WF003 でブロック。迂回せず完了後に実行 | |
| IP009 | 完了処理 | 最後のワーク done、レビュー完了（指摘なし） | PR 本文の最終整形 → 承認③ → 承認時のみ `gh pr ready` | |
| IP010 | 既存 issue の本文保全 | 既存 #12 に追記 | 追記前の本文が変更されず、末尾に `## 今回の依頼（日付）` が追加される | |
| IP011 | ワーク完了時のレビュー依頼 | investigation の最後のチケットが done、todo の先頭が ai-asset-design | `git push` → PR 本文に investigation の要約を追記 → `gh pr comment` でレビュー依頼 → 応答を終える（次のチケットに着手しない・`AskUserQuestion` で待たない） | |
| IP012 | レビュー完了後のコメント取得（指摘なし） | 「レビュー完了」の発言、PR のコメントは自分の依頼のみ | `gh pr view` / `gh api .../comments` を実行 → 指摘 0 件と報告 → 次のワーク（todo 先頭のチケット）に着手 | |
| IP013 | レビュー完了後のコメント取得（指摘あり） | 「レビュー完了」の発言、インラインコメント 1 件 | コメントを提示 → `AskUserQuestion` で対応要否を確認 → 対応する場合、同じ作業タイプの追加チケットを todo に作成して着手（done チケットを doing に戻さない） | |
| IP014 | レビュー完了の合図なしで続行 | ワーク完了・レビュー依頼済みの状態で「続けて」 | コメント取得を実行し、未取得の指摘が無いことを確認してから次のワークへ進む | |
| IP015 | quick-request の振り返りから切り替え | `workflow-quick-request` 手順 5-3 で合意した summary / acceptance / kind / チケット構成（`ai-asset-design` → `ai-asset-implementation`）を引き継いで開始 | 依頼の要約に関する曖昧点を質問せず、引き継がれた summary / keywords で既存 issue を検索して承認①に進む。未コミットの変更があれば省略せず確認する | |

### テスト実施例

- **テストID**: IP010
  - **前提条件**: open issue #12 が存在し、本文に既存の記述がある
  - **テスト手順**: 依頼を出し、承認①で「#12 で対応」、承認②で追記案を承認する。`gh issue view 12 --json body -q .body` を前後で比較する
  - **期待結果**: 追記前の本文が先頭にそのまま残り、末尾に `## 今回の依頼（YYYY-MM-DD）` セクションが追加されている

---

## 関連するドキュメント

- `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`（要件定義書）
- `.claude/docs/10_spec/チケット駆動ワークフロー.md`（後続の実作業の仕様。Bash allowlist の正）
- `.claude/docs/10_spec/スキル体系.md`（本スキルは3層構造の `workflow-*` に分類される。命名規則・承認方式の正）
- `.claude/skills/task-gh-issue/SKILL.md`、`.claude/skills/task-gh-feature/SKILL.md`（委譲先の手順）

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版 | Hiro |
| 2026-08-30 | 1.1 | スキル体系仕様書への相互参照を追加 | Hiro |
| 2026-08-30 | 1.2 | スキル体系の3層再編（workflow/work/task）に伴い、言及するスキル名を新名称に更新 | Hiro |
| 2026-08-30 | 1.3 | ワーク（作業タイプ）完了ごとに push・レビュー依頼・コメント取得・追加チケットを行うワークループ（承認④）を追加。ブランチ命名規約を `<prefix>-<N>-<slug>`（ハイフン区切り）に変更。ヘッドレス実行時の扱い、IP011〜IP014 を追加（issue #12） | Hiro |
| 2026-08-30 | 1.4 | ワークループのレビュー依頼・コメント取得を `work-boundary.sh`（`request` / `complete` / `reply`）に委ねる形に変更。状態ファイルの直接書き換え禁止（WF012）とレビュー未完了での着手拒否（WF011）を明記（issue #12、ユーザー指示） | Hiro |
| 2026-08-30 | 1.5 | `workflow-quick-request` 手順 5-3 の振り返りからの切り替え時の入力・代替フロー・テストケース（IP015）を追加（issue #5） | Hiro |
