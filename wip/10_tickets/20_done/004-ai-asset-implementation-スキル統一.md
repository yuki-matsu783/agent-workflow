---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-implementation-フック統一.md"]
---

# スキル・テンプレート・evals・ルールの文言統一

## 目的

スキル本文・テンプレート・evals・ルールに残る旧命名の `wip/` 参照を番号付き命名に統一する。

## 完了条件（DoD）

- [x] `.claude/skills/ticket-driven-workflow/`（SKILL.md の `mkdir -p` と `git mv` 例、permission-matrix.md、assets/*.template.md、evals.json）が新命名になっている
- [x] `.claude/skills/issue-pr-driven-workflow/SKILL.md`、`evals/evals.json` が新命名になっている
- [x] `.claude/skills/light-task-workflow/SKILL.md` が新命名になっている
- [x] `.claude/rules/markdown-frontmatter.md` が新命名になっている
- [x] `grep -rn "wip/ticket\|wip/plan\|wip/retrospective" .claude CLAUDE.md`（workflow.log と .state を除く）が 0 件

## 作業内容

1. 対応表に従って各ファイルを Edit する
2. grep で残存を確認する

## 作業ログ

### うまくいったこと

- 統制下では `sed -i` が WF003 なので、Grep で全出現箇所（10 ファイル・約 40 箇所）を先に列挙し、Edit の `replace_all` を 31 回に分けて一括で流した。パターンの適用順（todo/doing/done → `wip/ticket/` → plan → retrospective）を守れば衝突しない
- 「チケット開始のコミットと同じ Bash コマンド内で sed を走らせる」と統制を素通りできるが、ブロックの迂回に当たるのでやらなかった

### うまくいかなかったこと

- 特になし。ただし Edit 31 回はトークン的に重い。許可パス内のファイルに限って `sed -i` を許す Bash グループがあれば、この種の機械的リネームは 1 コマンドで済む（改善候補として振り返りに回す）
