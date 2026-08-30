---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-design-スキル体系仕様.md"]
---

# workflow-* / task-* へのスキルリネームとフック・参照の更新

## 目的

002 で定めた仕様に従い、`.claude/skills/**` の `git mv` を許可する allowlist 拡張をまず行い、フラットな8スキル＋2入口スキルを新名称にリネームする。フック・テスト・CLAUDE.md・ルールの参照も追従させる。

## 完了条件（DoD）

- [x] `workflow-guard.sh` の `wf_validate_mv` が `ai-asset-implementation` type に限り `.claude/skills/**` 内の `git mv` を許可するよう拡張されている
- [x] `issue-pr-driven-workflow`→`workflow-issue-mr-driven`、`light-task-workflow`→`workflow-light-task`、`gh-issue`→`task-gh-issue`、`gh-feature`→`task-gh-feature`、`gh-install`→`task-gh-install`、`ai-asset-creator`→`task-ai-asset-creator`、`investigating-technologies`→`task-investigating-technologies`、`requirements`→`task-requirements`、`spec`→`task-spec` が `git mv` でリネームされている
- [x] 各 `SKILL.md` の frontmatter `name:` が新名称に一致している
- [x] 各スキルの相互参照（SKILL.md本文中の他スキル名）が新名称に更新されている
- [x] `evals/evals.json` の `skill_name` と本文中の他スキル名言及が更新されている
- [x] `workflow-entry.sh` の `WF_ENTRY_SKILLS` とエラーメッセージ文言が新名称に更新されている
- [x] `test-workflow-entry.sh` のモック入力・アサーション文字列が新名称に更新され、全件パスする（PASS=40 FAIL=0）
- [x] `CLAUDE.md` の「作業の入口」表が新名称に更新されている
- [x] `markdown-frontmatter.md` の対象外ファイル表のパスが新名称に更新されている

## 作業内容

1. `workflow-guard.sh` の `wf_validate_mv` を拡張する（001 の方針に従う）
2. 各スキルディレクトリを `git mv` でリネームする
3. 各 `SKILL.md` の `name:` と本文中の相互参照を Edit で更新する
4. `evals/evals.json` を更新する
5. `workflow-entry.sh` / `test-workflow-entry.sh` / `CLAUDE.md` / `markdown-frontmatter.md` を更新する
6. `bash .claude/hooks/tests/test-workflow-entry.sh` を実行して確認する

## 作業ログ

### うまくいったこと

- `wf_validate_mv` の拡張は `TICKET_TYPE` の分岐追加1箇所で済み、1件試験後に残り8件を一括で `git mv` できた
- `test-workflow-entry.sh` は全出現箇所を `replace_all` で一括置換し、40件全件パスした。`ticket-driven-workflow`（004で扱う）文字列だけが意図的に残っている

### うまくいかなかったこと

- 作業中、身に覚えのない `.gitignore` への変更（「参考用のディレクトリ」というコメント＋エントリの追加）が繰り返し WF-DIFF で検出された。ユーザーに確認したところ「受け入れてOK」との回答を得たため、003 の目的外の差分としてそのままコミットに含めた（並行して動いている別セッションによるものと推測される）
- `ai-asset-implementation` type でも `echo` を含む複合コマンドは `READONLY_RE` に `echo` が無く弾かれる（例: `ls ... 2>/dev/null`）。Glob/Read ツールで代替した
