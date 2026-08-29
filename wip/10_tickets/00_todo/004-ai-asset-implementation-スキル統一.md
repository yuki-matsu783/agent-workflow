---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-implementation-フック統一.md"]
---

# スキル・テンプレート・evals・ルールの文言統一

## 目的

スキル本文・テンプレート・evals・ルールに残る旧命名の `wip/` 参照を番号付き命名に統一する。

## 完了条件（DoD）

- [ ] `.claude/skills/ticket-driven-workflow/`（SKILL.md の `mkdir -p` と `git mv` 例、permission-matrix.md、assets/*.template.md、evals.json）が新命名になっている
- [ ] `.claude/skills/issue-pr-driven-workflow/SKILL.md`、`evals/evals.json` が新命名になっている
- [ ] `.claude/skills/light-task-workflow/SKILL.md` が新命名になっている
- [ ] `.claude/rules/markdown-frontmatter.md` が新命名になっている
- [ ] `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude CLAUDE.md`（workflow.log と .state を除く）が 0 件

## 作業内容

1. 対応表に従って各ファイルを Edit する
2. grep で残存を確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
