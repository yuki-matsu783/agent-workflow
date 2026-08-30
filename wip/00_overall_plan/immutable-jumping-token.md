# 全体計画: AI アセットの命名を workflow-* / work-* / task-* の3層に再編する

- 対象 issue: #7 https://github.com/yuki-matsu783/agent-workflow/issues/7
- PR: #8 https://github.com/yuki-matsu783/agent-workflow/pull/8

## Context

`.claude/skills/` 配下のスキルは現在フラットに並んでおり、名前から「粒度」「人間承認が要るか」「入口として使えるか」が読み取れない（`gh-issue` も `issue-pr-driven-workflow` も見た目は対等）。ユーザーから、役割に応じた3層構造への再編が要求された:

| 層 | 命名prefix | 定義 | チェックポイントの承認者 |
|---|---|---|---|
| ワークフロー | `workflow-*` | ワークの組み合わせ。ワーク間に必ず人間承認（MRレビュー or AskUserQuestion） | 人間 |
| ワーク | `work-*` | タスクの組み合わせ。ワーク内は人間承認不要。複数タスク完了時点で敵対的レビューエージェントの承認 | 敵対的レビューエージェント（今回は仕様明文化のみ、自動起動の実装は対象外） |
| タスク | `task-*` | 作業レベルのスキル。セルフレビューで進む | 実行者自身 |

今回のスコープは **命名整理＋仕様明文化**。敵対的レビューエージェントを実際に自動起動する実装は次段階の issue に回す。

## 確定した設計判断

- `issue-pr-driven-workflow` → `workflow-issue-mr-driven`
- `light-task-workflow` → `workflow-quick-request`
- `gh-issue` / `gh-feature` / `gh-install` / `ai-asset-creator` / `investigating-technologies` / `requirements` / `spec` → すべて `task-*`（例: `task-gh-issue`）
- `ticket-driven-workflow` → `work-ticket-driven` に改名。**チケットタイプ（investigation/implementation/retrospective/ai-asset-design/ai-asset-implementation）別の実施手順は分割せず、1ファイル内にインラインのまま残す**（Skillツールの意味マッチングと `workflow-types.json` の frontmatter 判定という別系統の仕組みが同じ名前空間に混在するのを避けるため）。SKILL.md 冒頭に「ここでの『チケット』は3層構造の『タスク』に相当する」という対応関係を一文で明記する
- `workflow-types.json` の `types` キー名・チケットの呼称は変更しない（変更コストに対して実益が薄い）
- 既存の `retrospective` チケット（セルフレビュー・結果報告）はそのまま残す。加えて `work-ticket-driven` の手順6（全チケット done 後）に **「ワーク完了チェックポイント」節を新設**し、敵対的レビューエージェントによるレビュー・承認が入る位置と入出力（レビュー対象＝ワーク開始コミットからの全差分、出力＝承認/差し戻し）だけを仕様化する。起動ロジックの実装はしない
- 仕様書は新規ファイル `.claude/docs/10_spec/スキル体系.md`（+ 要件定義書 `.claude/docs/00_requirements/スキル体系.md`）を作成し、既存3仕様書・CLAUDE.md から相互参照を張る
- `workflow-guard.sh` の Bash allowlist（`wf_validate_mv`）は現状 `mv`/`git mv` を `wip/10_tickets/` 配下のみに限定しており、`.claude/skills/**` の改名がブロックされる。**`ai-asset-implementation` type に限り `.claude/skills/**` 内の `git mv` を許可するよう恒久拡張する**

## チケット分割

| # | type | 目的 | 主な成果物 | depends_on |
|---|------|------|-----------|-----------|
| 001 | investigation | 現行10スキルの相互参照・依存関係を棚卸し、リネーム対応表・影響ファイル一覧を確定する | `wip/20_plans/001-*.md`（対応表・影響範囲） | — |
| 002 | ai-asset-design | 3層モデルの要件定義書・仕様書を新規作成。既存3仕様書・CLAUDE.md へ相互参照を追記。`work-ticket-driven` への用語対応・ワーク完了チェックポイントの位置と入出力を明文化 | `.claude/docs/00_requirements/スキル体系.md`、`.claude/docs/10_spec/スキル体系.md`、既存3仕様書・CLAUDE.md の更新 | 001 |
| 003 | ai-asset-implementation | (0) `workflow-guard.sh` の `wf_validate_mv` を拡張し `ai-asset-implementation` type で `.claude/skills/**` の `git mv` を許可 → (1) 8スキル＋2入口を `git mv` でリネームし各 `SKILL.md` の `name:`・相互参照・`evals.json` を更新 → (2) `workflow-entry.sh` の `WF_ENTRY_SKILLS`、`test-workflow-entry.sh` のアサーション、`CLAUDE.md`「作業の入口」表、`markdown-frontmatter.md` の対象外パス表を新名称に更新 | 上記スキル群の改名、フック・テスト・CLAUDE.md の更新 | 002 |
| 004 | ai-asset-implementation | `ticket-driven-workflow` を `work-ticket-driven` に改名。用語対応の一文追加、ワーク完了チェックポイント節の新設、003 で改名済みの `task-*`／`workflow-*` への相互参照更新 | `work-ticket-driven` ディレクトリ一式、`references/permission-matrix.md`・`assets/*.template.md`（report テンプレートへのレビュー結果欄追加） | 003 |
| 005 | ai-asset-implementation | 横断的整合性確認: 旧スキル名の残存が無いことを grep で確認、`test-hooks.sh`/`test-workflow-entry.sh` の全件パス確認、仕様書間のリンク切れ確認 | 修正差分、確認ログ | 004 |
| 006 | retrospective | 結果報告。使った AI アセットの棚卸しと、今回見えた課題（敵対的レビューエージェントの自動化など）の恒久対応要否をユーザーに提示 | `wip/30_reports/006-*.md` | 005 |

## 検証方法

- `bash .claude/hooks/tests/test-workflow-entry.sh` 全件パス
- `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh`（旧 `ticket-driven-workflow/scripts/test-hooks.sh`）全件パス
- `grep -rn "issue-pr-driven-workflow\|light-task-workflow\|ticket-driven-workflow\|gh-issue\|gh-feature\|gh-install\|ai-asset-creator\|investigating-technologies\b" .claude CLAUDE.md` で旧名称の残存が無いことを確認（`wip/` 配下の完了済みチケット・ログは対象外）
