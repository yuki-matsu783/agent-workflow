---
name: work-ticket-driven
description: >
  作業ブランチでの作業を「計画 → チケット化 → 1枚ずつ実施 → 記録」のチケット駆動で進める。
  workflow-issue-mr-driven（issue と draft PR を確定してから作業する振り分け）の最終段階としても呼ばれる。
  Use when the user mentions "チケット駆動で", "チケットで進めて", "チケット化して作業して",
  "ワークフローで作業", "ticket workflow", or wants work split into investigation /
  implementation / retrospective tickets under wip/ with hook-enforced phase restrictions.
---

# work-ticket-driven — チケット駆動で作業を進める

作業を「調査 → 実装 → 振り返り」のチケットに分割し、`wip/` 配下で 1 枚ずつ実施する。
フェーズごとのツール利用制限は PreToolUse / PostToolUse フック（`.claude/hooks/workflow-*.sh`）が機械的に強制する。

このスキルにおける「チケット」は、`.claude/docs/10_spec/スキル体系.md` が定義する3層構造（workflow/work/task）の「タスク」に相当する。本スキル自身は3層構造の `work-*` に分類される。**1つの作業タイプ（type）に属するチケット群が1つのワーク**であり、ワーク内は人間の明示的承認なしに進む。ワークが完了した時点（次のチケットの type が変わる、または todo が空になる＝**ワーク境界**）でワーク完了チェックポイントを設け、承認者は人間とする（`workflow-issue-mr-driven` 経由なら PR レビュー、単独なら `AskUserQuestion`。手順 5.5・6 参照）。

- 要件: `.claude/docs/00_requirements/チケット駆動ワークフロー.md`
- 仕様（許可マトリクス・エラーコードの正）: `.claude/docs/10_spec/チケット駆動ワークフロー.md`
- マトリクスの要約: `references/permission-matrix.md`
- 作業を GitHub の issue / PR に紐づけて始めたい場合は、先に `workflow-issue-mr-driven` を使う（このスキルはその最終段階として呼ばれる）

## テンプレート（assets/）

成果物はいずれも対応するテンプレートを **Read で読み込み、Write で新規ファイルとしてコピー**して作成する
（Bash の `cp` は allowlist 外のためブロックされる）。

| テンプレート | 用途 | 作成先 |
|-------------|------|--------|
| `assets/ticket.template.md` | チケット | `wip/10_tickets/00_todo/` |
| `assets/plan.template.md` | 計画書（調査チケットの成果物） | `wip/20_plans/` |
| `assets/report.template.md` | 結果報告（振り返りチケットの成果物） | `wip/30_reports/` |

## 手順 0: 状態確認（冪等性・再開判定）

最初に `wip/` 配下の状態を確認する。

```bash
ls wip/10_tickets/10_doing/ wip/10_tickets/00_todo/ wip/10_tickets/20_done/ 2>/dev/null
```

- **doing にチケットがある** → そのチケットの作業ログを読み、手順 3 の途中から再開する
- **todo にチケットがある（doing は空）** → 手順 2 は完了済み。done の最後のチケットと todo の先頭チケットの `type` を比べる
  - 同じ type、または done が空 → 同じワークの続き。手順 3 から続行する
  - 異なる type → 前のワークは完了済み（ワーク境界を越えた再開）。`workflow-issue-mr-driven` 経由なら、直前ワークのレビューが済んでいる前提で呼ばれているので、そのまま手順 3 から新しいワークを始める。単独実行で前のワークのチェックポイント（手順 6）を通っていなければ、先にそれを行う
  - todo にレビュー指摘対応の追加チケット（直前の done と同じ type）がある → 通常どおり手順 3 から着手する
- **どちらも空 / wip が無い** → 手順 1 から開始する

doing に 2 枚以上ある場合は異常状態。ユーザーに報告し、1 枚に整理してから進める。

## 手順 1: 全体計画の合意と作業領域の初期化

**新しいワークフローを開始するときだけ**、プランモードで「どう進めるか」の全体計画（チケットの分割案・進め方）を立て、ユーザーの承認を得る。承認された計画は `wip/00_overall_plan/`（settings.json の `plansDirectory`）に保存される。

- プランモードを使うのはこの段階のみ。**チケット作業中（doing にチケットがある間）はプランモードは使えない**（フックが WF006 でブロックする）
- 途中で計画の見直しが必要になったら、プランモードではなく investigation チケットとして `wip/20_plans/` に成果物を作る

承認後、作業領域を初期化する:

```bash
mkdir -p wip/10_tickets/00_todo wip/10_tickets/10_doing wip/10_tickets/20_done wip/20_plans wip/30_reports
```

作業ブランチ上であることを `git branch --show-current` で確認する（main 上では作業しない。必要ならブランチ作成をユーザーに提案する）。

**`workflow-issue-mr-driven` から呼ばれた場合**: feature ブランチと draft PR は作成済み。全体計画の冒頭に `- 対象 issue: #N <url>` と `- PR: #M <url>` を書き、issue の受け入れ条件を実装チケットの DoD と振り返りチケットの確認項目に落とす。

## 手順 2: チケット作成

合意した全体計画に基づき、`assets/ticket.template.md` を Read→Write でコピーして各チケットを `wip/10_tickets/00_todo/` に作成する。

- ファイル名: `NNN-<type>-<slug>.md`（NNN は実施順の連番。例: `001-investigation-現状調査.md`）
- type は **`.claude/hooks/workflow-types.json` に定義された作業タイプ**から選ぶ。標準は `investigation` / `implementation` / `retrospective`（原則この順）。AI アセット（フック・スキル等）を扱う作業では `ai-asset-design`（設計: `.claude/docs/` のみ）→ `ai-asset-implementation`（実装: フック・ルール・スキル・settings.json）を使う
- 必要な作業タイプが定義に無い場合は、勝手に既存タイプで代用せず、定義への追加をユーザーに提案する
- 後続チケットの `depends_on` に先行チケットのファイル名を設定する
- 作業タイプの定義外で確認なしに触りたいパスがあれば `allowed_paths` に書く（例: `allowed_paths: ["lib/**"]`）。type 定義への追加であり、deny（`.claude/**` 等）を貫通したり ask を省略したりはできない
- 着手後に doing チケットの `type` を書き換えることはできない（WF008）。タイプを変えたい場合は新しいチケットを作る
- 各チケットに目的と **完了条件（DoD）** をチェックリストで書く

作成したら一式をコミットする:

```bash
git add wip/
git commit -m "chore(ticket): create tickets for <作業名>"
```

## 手順 3: チケットへの着手（todo → doing）

`depends_on` がすべて done にあることを確認し、先頭のチケットを doing に移動してコミットする。
**このコミットが差分チェックの基準点になる**ため、必ず着手直後に行うこと。

```bash
git mv wip/10_tickets/00_todo/NNN-<type>-<slug>.md wip/10_tickets/10_doing/
git commit -m "chore(ticket): start NNN-<slug>"
```

この時点からフックによるフェーズ別制限が有効になる。

## 手順 4: チケットの実施と作業ログ

チケットに書かれた内容を実施する。フェーズごとの制約は `references/permission-matrix.md` を参照。

- **investigation**: Read/Glob/Grep と読み取りコマンドで調査し、`assets/plan.template.md` をコピーして計画書を `wip/20_plans/` に作成する
- **implementation**: `wip/20_plans/` の計画に従い、`allowed_paths` の範囲でコードを変更する。テスト・ビルドで動作を確認する
- **retrospective**: 全チケットの作業ログを読み、`assets/report.template.md` をコピーして結果報告を `wip/30_reports/` に作成する。恒久的な教訓があれば CLAUDE.md やスキルの改訂候補としてユーザーに提示する

作業中は、うまくいったこと・うまくいかなかったことを**その都度**チケットの作業ログ欄に Edit で追記する。

### フックにブロックされた・確認を求められたとき

- stderr の `[WFxxx]` メッセージの「対処:」に従う。**別の手段でブロックを迂回しない**
- **`[WF009]`（想定外のパス）で確認が出たとき**: それは「作業タイプの定義に無いパスを触ろうとしている」という警告。ユーザーが承認するまで待ち、承認されなかったら別の方法を考えるか、チケットの `allowed_paths` や作業タイプ定義の見直しをユーザーに提案する。確認を避けるために迂回しない
- `[WF010]`（毎回確認のパス）は承認済みでも毎回確認が出る。仕様どおりなので気にしなくてよい
- `.claude/**`（settings.json・フック・スキル・設計ドキュメント）は global の **deny**。`allowed_paths` に書いても許可されない。変更が必要なら `ai-asset-design` / `ai-asset-implementation` タイプのチケット化をユーザーに提案する
- チケット作業中のプランモードは WF006 でブロックされる。計画の見直しは investigation チケットで行う
- `[WF-DIFF]` の通知を受けたら、指示に従い許可パス外の差分を基準コミットの状態に戻す
- Bash で使うパスは引用符なし・リポジトリ相対で指定する（クォートされたパスは検証できず拒否される）

## 手順 5: チケットの完了（doing → done）

1. チケットの完了条件（DoD）をすべて満たしたか確認し、チェックを付ける
2. `git status` で基準点からの差分が許可パス内に収まっていることを確認する
3. チケットを done に移動してコミットする

```bash
git mv wip/10_tickets/10_doing/NNN-<type>-<slug>.md wip/10_tickets/20_done/
git add wip/ <allowed_paths内の変更ファイル>
git commit -m "chore(ticket): done NNN-<slug>"
```

done コミット直後は doing が空なのでフックは働かない。issue / PR に紐づけて進めている場合、同じワークの次のチケットが todo に残っていても、ここで `git push` してよい（PR に進捗が反映される。レビュー依頼はワーク境界でのみ行う）。

## 手順 5.5: ワーク境界の判定

done コミットの直後（doing が空）に、判定スクリプトを実行する。**目視で type を比べず、この出力に従う**。

```bash
bash .claude/hooks/work-boundary.sh status
```

| `at_boundary` | 意味 | 次の動き |
|------|------|---------|
| `false` | 同じワークの途中（todo の先頭が直前の done と同じ type） | 手順 3 に戻り、次のチケットに着手する |
| `true`（`todo_head` あり） | **ワーク完了**（次のチケットの type が変わる） | 手順 6 へ |
| `true`（`todo_head` が null） | **最後のワーク完了** | 手順 6 へ |

出力には `review_state`（`none` / `requested` / `completed`）も含まれる。境界で `completed` になっていない間は、次の type のチケットを doing へ移す操作をフックが WF011 で拒否する（`.claude/docs/10_spec/チケット駆動ワークフロー.md`「ワーク境界の判定とレビュー状態」）。

連番は実施順であり type ごとではない。レビュー指摘対応で同じ type の追加チケットを作ると連番が飛ぶ（例: 011 implementation → 012 retrospective の後に 013 implementation）が、それで構わない。`status` の `todo_same_type` にそうした追加チケットが列挙される。

## 手順 6: ワーク完了チェックポイント

1つのワーク（同じ type のチケット群）が完了したことを受け、次のワークに着手する前に以下のチェックポイントを設ける（仕様: `.claude/docs/10_spec/スキル体系.md`「ワーク完了チェックポイント」）。

| 項目 | 内容 |
|------|------|
| 位置 | ワーク境界（手順 5.5 でワーク完了と判定した直後）、次のワークの着手前 |
| レビュー対象 | ワーク開始コミット（その type の最初のチケットの `start` コミット）から HEAD までの全差分 |
| 出力 | 承認 / 差し戻し |
| 承認者 | 人間（呼び出し元により方法が異なる。下表） |

まず、ワークの差分を要約する（`git log --oneline <ワーク開始コミット>..HEAD`、`git diff --stat <ワーク開始コミット>..HEAD`）。

| 呼び出し元 | やること |
|-----------|---------|
| `workflow-issue-mr-driven` 経由（全体計画の冒頭に issue / PR がある） | **ワーク完了報告**（完了した type・チケット一覧・差分要約・todo に残る次の type）を行い、**ここで制御を呼び出し元へ返す**。push・PR 本文更新・レビュー依頼（`work-boundary.sh request`）・レビュー完了の確認（`work-boundary.sh complete`）・差し戻しの判断はすべて `workflow-issue-mr-driven` の手順 5（ワークループ）が行う。本スキルからは行わない |
| 単独（issue / PR の文脈が無い） | `AskUserQuestion` で「type X のワークが完了した。差分を確認して、承認 / 差し戻し（追加チケットで対応）」を確認する。承認なら `bash .claude/hooks/work-boundary.sh request --local` → `bash .claude/hooks/work-boundary.sh complete --local` を続けて実行し、次のワークの手順 3 へ（todo が空なら下記の完了報告）。差し戻しなら指摘内容を DoD に落とした**同じ type の追加チケット**を手順 2 の要領で todo に作り、手順 3 へ（`request` は不要。追加チケットが done になると境界の状態は自動で失効し、再度この手順に戻る） |

**レビュー状態（`wip/10_tickets/review-state.json`）を Edit / Write / Bash で直接書き換えない。** 書き換えは `work-boundary.sh` の `request` / `complete` だけが行い、それ以外の経路はフックが WF012 で拒否する。前提条件を満たせず `request` / `complete` が WF013 / WF014 で止まったら、条件を解消するかユーザーに報告する。ファイルを直して通そうとしない。

**レビュー指摘への対応は、done 済みチケットを doing に戻さない。** 同じ type の新規チケット（例: `013-implementation-レビュー指摘対応.md`。`depends_on` に直前の done チケット）を追加して着手する。done を戻すと差分チェックの基準コミット（着手コミット）がずれ、作業ログの履歴も壊れる。同じ type の追加チケットは、レビューが `completed` になっていなくても着手できる（フックが例外として許可する）。

既存の `retrospective` チケット（実行者自身のセルフレビュー・結果報告の作成）は本チェックポイント（第三者による承認）とは別物であり、統合しない。retrospective 自体も1つのワークなので、その完了時にも本チェックポイントが発生する。

### 完了報告（todo が完全に空になったとき）

- 各チケットの結果（うまくいったこと・いかなかったことの要約）
- 成果物の一覧（`wip/20_plans/`、`wip/30_reports/`、コード変更）
- 振り返りから得られた改善提案
- 各ワークのチェックポイント結果（承認 / 差し戻し回数）。結果報告（`wip/30_reports/`）の「レビュー結果」欄と一致させる

`workflow-issue-mr-driven` 経由なら、最後のワークの完了報告のあと同スキルの手順 6（完了処理: PR 本文の最終整形 → 承認③ → `merge-prep.sh` によるマージ前作業（wip のリセット → コンフリクト確認 → issue コメント）→ draft 解除）に戻る。wip の成果物（チケット・計画・報告・`review-state.json`）はその `reset-wip` で削除されて main には残らないため、後に残したい要約は結果報告を元に PR 本文へ書く。`gh pr ready` を直接実行しない（フックが WF015 で拒否する）。

## エラーハンドリング

- `[WF001]`〜`[WF008]` でブロックされた場合: メッセージの「対処:」に従って復旧する。原因が分からない場合はユーザーに報告する
- `[WF009]` / `[WF010]` はブロックではなくユーザー確認。承認・拒否はユーザーの判断に委ねる
- `[WF011]`〜`[WF014]` はワーク境界・レビュー状態（手順 5.5・6）、`[WF015]`（`gh pr ready` の直接実行）・`[WF016]`（`merge-prep.sh` の前提未充足）は完了処理のマージ前作業に関するもの。いずれも状態ファイル（`review-state.json` / `merge-prep.json`）を直接編集して通そうとせず、メッセージの「対処:」に従う
- フック自体の不具合で作業が完全に止まった場合: **ユーザーの明示的な指示があるときに限り** `WORKFLOW_ENFORCE=0` で無効化できる。自分の判断で無効化しない
- フックの判定ログは `.claude/hooks/workflow.log` に残る。想定外のブロックはこれで調査する

## ベストプラクティス

- チケットは小さく分割する（1 チケット = 1 つの明確な成果物）
- 作業ログは後から書かず、その場で書く（振り返りチケットの入力になる）
- 調査チケットの成果物（実装計画）には、実装チケットで使う `allowed_paths` の案を含める
- 調査チケットの DoD に `gh` の実行を含めない（チケット作業中は WF003 でブロックされる）。GitHub の情報が要るなら、ワーク境界（doing が空のとき）で呼び出し元が取得する
- 同じ type のチケットは連続して並べる（type が交互に入れ替わると、そのたびにワーク境界＝レビュー往復が発生する）
