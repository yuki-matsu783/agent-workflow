- 対象 issue: #5 https://github.com/yuki-matsu783/agent-workflow/issues/5
- PR: #33 https://github.com/yuki-matsu783/agent-workflow/pull/33

# 計画: issue-pr-driven-workflow に quick-request-workflow の振り返りからの受け口を追加する

## Context

`workflow-quick-request`（旧称 light-task-workflow）の手順 5-3 は、振り返りの結果「振る舞いが変わる」候補が出たとき、ユーザーの合意を得て「その場で `workflow-issue-mr-driven` を Skill ツールで読み込み、手順 1 から始める」と定めており、summary / acceptance / kind / チケット構成（`ai-asset-design` → `ai-asset-implementation`）を引き継ぐと書いてある。

しかし `workflow-issue-mr-driven`（旧称 issue-pr-driven-workflow）側の手順 1（依頼の整理）は「依頼文から抽出する」対話前提の手順しかなく、この引き継ぎを受け取る側の記述が無い。引き継ぎが quick-request 側からの一方的な記述になっており、issue-pr 側だけを読んでも「振り返りから来た依頼をどう扱うか」が分からない。実際に issue #1 はこの経路で作られたが、手順 1 の整理を手動で組み立てる手戻りが発生した（issue #1 の結果報告に見送り事項として記録済み）。

このチケットでは、`workflow-issue-mr-driven` 側に振り返りからの切り替え時の受け口（引き継ぐ項目・省略できる手順・省略できない手順）を明記し、仕様書・要件定義書・evals に反映する。

## 変更方針

1 issue = 1 PR。issue #5 の指示どおり `ai-asset-design`（.claude/docs/ のみ）→ `ai-asset-implementation`（スキル・evals）→ `retrospective` の順でチケットを切る。

### チケット 1: ai-asset-design（仕様書・要件定義書の更新）

対象: `.claude/docs/**` のみ

- `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`
  - 「アルタナティブフロー（代替経路）」に、quick-request 手順 5-3 からの切り替え時は summary / acceptance / kind / チケット構成をそのまま用い、依頼の要約に関する曖昧点の質問を省略してよい（未コミットの変更確認は省略しない）旨を追加する
  - レビュー記録に版を追加
- `.claude/docs/10_spec/issue-PR駆動ワークフロー.md`
  - 「入力（Input）定義」の入力データ表に「振り返りからの引き継ぎ情報」（quick-request 手順 5-3 由来の summary/acceptance/kind/チケット構成、任意）を追加する
  - 「代替フロー」に、振り返りからの切り替え時の扱い（手順 2（依頼の整理）の曖昧点質問を省略し承認①へ進む。手順 1（状態確認）の未コミット変更確認は省略しない）を追加する
  - 「テストシナリオ」に切り替えケース（IP015）を追加する
  - レビュー記録に版を追加

### チケット 2: ai-asset-implementation（SKILL.md・evals の更新）

対象: `.claude/skills/**`

- `.claude/skills/workflow-issue-mr-driven/SKILL.md`
  - 手順 1（依頼の整理）に「振り返りからの切り替え」の小節を追加する。内容:
    - 発生条件: `workflow-quick-request` 手順 5-3 で「issue を作って workflow-issue-mr-driven で進める」と合意した直後に呼ばれた場合
    - 引き継ぐ項目（quick-request 側と項目名を一致させる）: summary / acceptance / kind（改善・最適化 or タスク）/ チケット構成（`ai-asset-design` → `ai-asset-implementation`）
    - 省略できる: 依頼の要約に関する曖昧点の質問（1 回だけ質問するステップ）
    - 省略できない: 手順 0 の未コミットの変更の確認、承認①②③④
    - keywords は summary から自分で組み立てて手順 2（既存 issue 検索）に使う
  - 手順 5（チケット駆動ワークフロー）の「初回のみ…」の説明に、AI アセット（フック・スキル・ルール・エージェント・設定）を扱う作業ではチケット構成を `ai-asset-design` → `ai-asset-implementation` →（必要なら）`retrospective` とすることを標準として明記する
- `.claude/skills/workflow-issue-mr-driven/evals/evals.json`
  - quick-request の振り返りから切り替えて来た依頼を受けたケース（summary/acceptance/kind/チケット構成が既に与えられている状態で、曖昧点を質問せず承認①に進む）を 1 件追加する

### チケット 3: retrospective

- 上記 2 チケットの作業ログを振り返り、`wip/30_reports/` に結果報告を作成する
- issue #5 の受け入れ条件 4 項目（SKILL.md の受け口記載／quick-request 5-3 との項目名整合／仕様書・要件定義書への記載／evals への追加）を確認項目とする

## DoD（実装チケット共通の完了条件）

- [ ] `workflow-issue-mr-driven/SKILL.md` に振り返りからの切り替え時の受け口（引き継ぐ項目・省略できる手順・省略できない手順）が書かれている
- [ ] 引き継ぐ項目名が `workflow-quick-request` 手順 5-3 の記述（summary / acceptance / kind / チケット構成）と一致している
- [ ] 仕様書・要件定義書に入力・代替フローとして記載されている
- [ ] `evals/evals.json` に切り替えケースがある

## 検証方法

- 変更後の `workflow-quick-request` 手順 5-3 と `workflow-issue-mr-driven` 手順 1 を通しで読み、引き継ぐ項目名・省略可否が矛盾なく対応していることを確認する
- `evals/evals.json` が妥当な JSON であることを確認する（`python3 -m json.tool` 等）
- ドキュメントのみの変更のため、既存のフック挙動やスクリプトへの影響はない
