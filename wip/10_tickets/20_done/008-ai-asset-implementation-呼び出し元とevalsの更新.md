---
type: ai-asset-implementation
status: todo
depends_on: ["007-ai-asset-implementation-AIアセット設計と実装の4スキル.md"]
---

# 呼び出し元スキル（workflow-issue-mr-driven / work-ticket-driven / workflow-quick-request）と evals を更新する

## 目的

新設した 13 スキルを既存のワークフローから呼べるようにし、記述の矛盾をなくす。

## 完了条件（DoD）

- [x] `.claude/skills/workflow-issue-mr-driven/SKILL.md` の手順 5 初回入口が `work-overall-plan` になり、役割分担表・フロー図・5-1（`todo_head_type` からスキルを選ぶ）・5-8・切り替え時の引き継ぎ・ベストプラクティスが新スキルと整合している
- [x] `.claude/skills/work-ticket-driven/SKILL.md` の description・冒頭・手順 1（標準の入口は `work-overall-plan`、プランモードは代替経路）・手順 2（連鎖方式。一括作成は単独実行の代替）・手順 4（type 別の説明に 9 type）が改訂されている
- [x] `.claude/skills/workflow-quick-request/SKILL.md` の切り替え時の記述が「フェーズ列（AI アセットの標準）」に更新されている
- [x] `workflow-issue-mr-driven`（id 0 / 7 更新、id 11 / 12 追加）と `work-ticket-driven`（id 0 更新、id 6 追加）の `evals/evals.json` に新入口のケースがある。`workflow-quick-request` の evals は既存ケースが新記述と矛盾しないため変更なし
- [x] `work-ticket-driven の手順 1` 等の旧記述は evals の「〜ではなく」という否定文脈にしか残っていない
- [x] 13 スキルの `SKILL.md` すべてに `type: skill` がある（Grep `**/SKILL.md` で 13 件）。JSON 構文テスト（新設 `tests/test-json-syntax.sh`）PASS=24

## 作業内容

1. 仕様書「ワークの連鎖規則」「`EnterPlanMode` の扱い」に従い 3 スキルを改訂する
2. evals を追加する
3. 13 スキルの横断チェックを行う

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- 呼び出し元の変更は「初回 = `work-overall-plan`」「毎ループ = `todo_head_type` → スキル」の 2 点に集約でき、`workflow-issue-mr-driven` のループ表は 5-1 の 1 行と 5-8 の補足だけの差し替えで済んだ
- `work-ticket-driven` は「チケット運用の正典」と位置づけ直し、フェーズ別スキルからの手順番号参照（3・5・5.5・6）を壊さないよう手順番号は変えなかった
- jq が Bash allowlist 外で使えなかったので、`tests/test-json-syntax.sh`（`workflow-types.json`・`settings.json`・全 evals の構文と必須キー）を新設して `test` グループで実行した。フックが読む JSON が壊れると WF007 で全ツールが止まるため、恒久的に価値のあるテスト

### うまくいかなかったこと

- Grep ツールの `glob` に `work-*/SKILL.md` を渡すと 0 件になり、005〜007 のプレースホルダ検査が実は空振りしていた（`**/work-*/SKILL.md` で再検査し、残りはすべて記法と確認）。検査は `**/` 付きの glob か path 直指定で行う
- `test-json-syntax.sh` は仕様書（`フェーズ別ワークスキル.md`）のテストシナリオに無い追加分。`ai-asset-implementation` では `.claude/docs/` を直せないため、仕様書への追記（TC040 相当）は振り返りの改善提案として残す
