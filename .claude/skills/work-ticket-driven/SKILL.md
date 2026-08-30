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

このスキルにおける「チケット」は、`.claude/docs/10_spec/スキル体系.md` が定義する3層構造（workflow/work/task）の「タスク」に相当する。本スキル自身は3層構造の `work-*` に分類される（ワーク内は人間の明示的承認不要、全チケット完了時点で敵対的レビューエージェントの承認が入る。手順6参照）。

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
- **todo にチケットがある（doing は空）** → 手順 2 は完了済み。手順 3 から続行する
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

done コミット直後は doing が空なのでフックは働かない。issue / PR に紐づけて進めている場合は、次のチケットに着手する前にここで `git push` してよい（PR に進捗が反映される）。

## 手順 6: ワーク完了チェックポイントと完了報告

todo が空になるまで手順 3〜5 を繰り返す。全チケットが done になったら、以下を行う。

### ワーク完了チェックポイント

本ワークにおける「タスク」（＝チケット）がすべて完了したことを受け、報告の前に以下のチェックポイントを設置する（仕様: `.claude/docs/10_spec/スキル体系.md`）。

| 項目 | 内容 |
|------|------|
| 位置 | 全チケット done 直後、結果報告の作成前 |
| レビュー対象 | ワーク開始コミット（最初のチケット着手時のコミット）から現在までの全差分 |
| 出力 | 承認 / 差し戻し（差し戻し時は追加チケットで対応する） |
| 承認者 | 敵対的レビューエージェント |

**現状の運用**: このチェックポイントを自動起動する実装は未整備（今後の課題）。自動化されるまでは、結果報告に「レビュー結果: 未実施（今後の自動化対象）」と明記する。既存の `retrospective` チケット（セルフレビュー・結果報告の作成）とは別物であり、統合しない。

### 完了報告

- 各チケットの結果（うまくいったこと・いかなかったことの要約）
- 成果物の一覧（`wip/20_plans/`、`wip/30_reports/`、コード変更）
- 振り返りから得られた改善提案
- ワーク完了チェックポイントのレビュー結果（上記の運用に従う）

issue / PR に紐づく作業（`workflow-issue-mr-driven` 経由）なら、報告のあと同スキルの手順 6（完了処理: push・PR 本文の更新・ready for review の確認）に戻る。

## エラーハンドリング

- `[WF001]`〜`[WF008]` でブロックされた場合: メッセージの「対処:」に従って復旧する。原因が分からない場合はユーザーに報告する
- `[WF009]` / `[WF010]` はブロックではなくユーザー確認。承認・拒否はユーザーの判断に委ねる
- フック自体の不具合で作業が完全に止まった場合: **ユーザーの明示的な指示があるときに限り** `WORKFLOW_ENFORCE=0` で無効化できる。自分の判断で無効化しない
- フックの判定ログは `.claude/hooks/workflow.log` に残る。想定外のブロックはこれで調査する

## ベストプラクティス

- チケットは小さく分割する（1 チケット = 1 つの明確な成果物）
- 作業ログは後から書かず、その場で書く（振り返りチケットの入力になる）
- 調査チケットの成果物（実装計画）には、実装チケットで使う `allowed_paths` の案を含める
