# 全体計画: ticket-driven-workflow の振り返りに AI アセット棚卸しを追加し light-task-workflow と揃える

- 対象 issue: #3 https://github.com/yuki-matsu783/agent-workflow/issues/3
- PR: #42 https://github.com/yuki-matsu783/agent-workflow/pull/42

## Context

`workflow-quick-request`（light-task-workflow）は手順 5 で「使った AI アセットの棚卸し（5種類）→ 4観点の振り返り→ 軽微/振る舞いが変わる の2区分→ AskUserQuestion で合意」という一連の振り返りフローを持つが、`work-ticket-driven`（ticket-driven-workflow）の retrospective チケットは「結果報告を作成し、恒久的な教訓があれば提示する」としか書かれておらず、棚卸しの観点・重さの分け方・合意の取り方が定まっていない。issue #1 の結果報告では light 側の形式を手動で流用しており、2つの振り返りの入口で形式が揃っていない状態を issue #3 で解消する。

変更は「設計（要件・仕様）→ 実装（スキル・テンプレート・evals）」の順で、AI アセット変更の標準チケット構成（`ai-asset-design` → `ai-asset-implementation`）に従う。最後に本 PR 自身の retrospective チケットを、追加した新フォーマットを使って実施する（ドッグフーディング）。

## チケット構成

### 030-ai-asset-design-振り返り棚卸しと合意の要件仕様（type: ai-asset-design, allowed: `.claude/docs/**`）

- `.claude/docs/00_requirements/チケット駆動ワークフロー.md`
  - メインフローに、retrospective チケットで AI アセット（スキル/フック/ルール/エージェント/CLAUDE.md の5種）を棚卸しし、4観点（足りなかった/邪魔だった/無かった/問題なし）で振り返り、候補を「軽微」「振る舞いが変わる」の2区分に分けてユーザーに合意を得る受け入れ基準を追加
  - アルタナティブフローに、合意が「issue を作って workflow-issue-mr-driven で進める」だった場合、完了処理（マージ前作業・draft 解除）の後に `workflow-issue-mr-driven` を読み込んで手順1から新しい issue の作業を開始する旨を追加
  - レビュー記録に新バージョン行を追加（issue #3 を明記）
- `.claude/docs/10_spec/チケット駆動ワークフロー.md`
  - 新セクション「retrospective の棚卸しと合意」を追加し、`.claude/docs/10_spec/軽作業ワークフロー.md`「振り返り候補の重さの区分」表と**文言を一致させた**棚卸し表・4観点・2区分テーブルを掲載する（issue の受け入れ条件「観点・文言が一致している」に対応）
  - work-ticket-driven の手順6「完了報告」に対応する箇所に、上記の issue 化ルートの処理フローを追記
  - レビュー記録に新バージョン行を追加
- 既存の `.claude/docs/10_spec/軽作業ワークフロー.md`・要件定義書は変更しない（issue のスコープ外）

### 031-ai-asset-implementation-振り返り棚卸しの実装（type: ai-asset-implementation, allowed: `.claude/skills/**`, depends_on: 030）

- `.claude/skills/work-ticket-driven/SKILL.md`
  - 手順4の retrospective 箇条書きを拡張し、`workflow-quick-request` 手順5-1〜5-3 と同じ構成（棚卸し→振り返り→合意）をこのスキル用に書く（参照ではなく、ticket-driven 側の文脈—— PR/issue 前提・`AskUserQuestion`可否・ヘッドレス扱い——に合わせて具体化する）
  - 手順6「完了報告（todo が完全に空になったとき）」に、retrospective の合意が「issue を作って workflow-issue-mr-driven で進める」だった場合の動き（`workflow-issue-mr-driven` の完了処理が終わった後、同スキルを Skill ツールで読み込み手順1から開始する。引き継ぐ項目は summary/acceptance/kind/チケット構成）を追記
- `.claude/skills/workflow-issue-mr-driven/SKILL.md`
  - 手順1「振り返りからの切り替え」の受け口を一般化し、`workflow-quick-request` 手順5-3 だけでなく `work-ticket-driven` の retrospective 合意（完了処理の後）からの切り替えも同じ扱いで受けることを明記する（引き継ぐ項目は変更なし）
- `.claude/skills/work-ticket-driven/assets/report.template.md`
  - 「改善提案」の前後に棚卸し表（アセット種別/判定/気付き）の欄を追加
- `.claude/skills/work-ticket-driven/evals/evals.json`
  - retrospective の棚卸し・4観点・2区分の合意を検証するケースを1〜2件追加（`workflow-quick-request/evals/evals.json` の id 4・5 相当を work-ticket-driven 版として作成）

### 032-retrospective-振り返り（type: retrospective, allowed: `wip/30_reports/**`, depends_on: 031）

- 031 で拡張した手順・テンプレートに従い、本ワークフロー自身の結果報告を `wip/30_reports/` に作成する（新設した棚卸し表を実際に使う）
- 使った AI アセット（`workflow-issue-mr-driven`、`work-ticket-driven`、`task-gh-issue`、`task-gh-feature`、発火したフック）を棚卸しし、4観点で振り返り、候補があれば2区分で `AskUserQuestion` により合意する

## 検証

- 各チケット完了時に対象ファイルの Markdown が壊れていないか目視確認（このリポジトリに自動テストの対象となるコードはなく、`.claude/hooks/tests/` はフック本体の変更を伴わないため対象外）
- `.claude/docs/10_spec/軽作業ワークフロー.md`「振り返り候補の重さの区分」と、新設する `.claude/docs/10_spec/チケット駆動ワークフロー.md` の対応表を並べて文言差分が無いことを確認する
- `work-ticket-driven/evals/evals.json` が JSON として妥当か（`python3 -m json.tool` 等）確認する
