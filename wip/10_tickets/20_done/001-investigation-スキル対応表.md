---
type: investigation
status: todo
depends_on: []
---

# 現行スキルの相互参照棚卸しとリネーム対応表の確定

## 目的

`workflow-*` / `work-*` / `task-*` へのリネーム対象10スキルについて、参照元（フック・settings.json・CLAUDE.md・docs・他スキルSKILL.md・evals.json・rules）を再確認し、リネーム対応表と影響ファイル一覧を確定する。あわせて `workflow-guard.sh` の `wf_validate_mv` 拡張方針（003 で実施する変更内容）を具体化する。

## 完了条件（DoD）

- [x] `wip/20_plans/001-*.md` に、旧名称→新名称の対応表（10スキル）が記載されている
- [x] 影響ファイルごとに「変更が必要な箇所」が具体的に列挙されている（ファイルパス＋該当箇所の要約）
- [x] `workflow-guard.sh` の `wf_validate_mv` をどう拡張するか（許可条件・実装方針）が具体的に書かれている
- [x] 003・004 チケットの作業内容がこの計画書を見れば実施できる粒度になっている

## 作業内容

1. 対応表を作る: `issue-pr-driven-workflow`→`workflow-issue-mr-driven`、`light-task-workflow`→`workflow-quick-request`、`gh-issue`→`task-gh-issue`、`gh-feature`→`task-gh-feature`、`gh-install`→`task-gh-install`、`ai-asset-creator`→`task-ai-asset-creator`、`investigating-technologies`→`task-investigating-technologies`、`requirements`→`task-requirements`、`spec`→`task-spec`、`ticket-driven-workflow`→`work-ticket-driven`
2. Grep で各旧名称の出現箇所を洗い出す（`.claude/hooks/`、`.claude/settings.json`、`CLAUDE.md`、`.claude/docs/`、`.claude/skills/*/SKILL.md`、`.claude/skills/*/evals/evals.json`、`.claude/rules/`）
3. `.claude/hooks/workflow-guard.sh` の `wf_validate_mv` の現在のロジックを読み、`ai-asset-implementation` type に限り `.claude/skills/**` 内の `git mv` を許可する拡張方針を具体化する（doing チケットの type をどう判定に使うか）
4. `wip/20_plans/001-*.md` に計画書としてまとめる

## 作業ログ

### うまくいったこと

- 事前のPlan agentによる調査（フェーズ1〜3）で影響範囲の大枠が把握済みだったため、grepと `workflow-guard.sh` の直接確認だけで対応表・拡張方針を確定できた
- `wf_validate_mv` は `TICKET_TYPE` というグローバル変数を既に持っているため、拡張は分岐追加1箇所で済むことを確認した

### うまくいかなかったこと

- `workflow-entry.sh` / `test-workflow-entry.sh` / `markdown-frontmatter.md` に `ticket-driven-workflow` という文字列が混在しており、003（フラットスキル）と004（work-ticket-driven）の作業境界をまたぐため、同じファイルを2回に分けて編集する二度手間が発生する設計になった。003・004のDoDにその旨を明記して対処した
