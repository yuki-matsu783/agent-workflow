---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-用語統一.md"]
---

# 「入口」→「振り分け」/「入口ガード」→「振り分け実施済み判定」用語統一（スキル・フック・CLAUDE.md）

## 目的

`.claude/skills/*/SKILL.md`、`.claude/hooks/workflow-entry.sh` のユーザー向けメッセージ・コメント、
対応するテストの記述、`CLAUDE.md` の「入口」表記を、001 で確定した用語マッピングに従って更新する。
フックの制御ロジック（判定条件・状態遷移・ブロック条件）自体は変更しない。

## 完了条件（DoD）

- [ ] `CLAUDE.md`「作業の入口」見出し・本文が「振り分け」表記に統一されている
- [ ] `.claude/skills/workflow-quick-request/SKILL.md` の「入口」表記が更新されている
- [ ] `.claude/skills/workflow-issue-mr-driven/SKILL.md` の「入口」表記が更新されている
- [ ] `.claude/skills/work-ticket-driven/SKILL.md` の「入口」表記が更新されている
- [ ] `.claude/hooks/workflow-entry.sh` のコメント・`[WF-ENTRY]` / `[WF101]` メッセージ文言が更新されている（`WF_ENTRY_SKILLS` 等の変数名・制御フローは変更しない）
- [ ] `.claude/hooks/tests/test-workflow-entry.sh` のコメントが更新され、メッセージ文言に依存するアサーションがあれば新文言に追従している
- [ ] 001 でリネームした `ワークフロー振り分け実施済み判定.md` へのパス参照がすべて更新されている
- [ ] `bash .claude/hooks/tests/test-workflow-entry.sh` が全シナリオ（TE001〜TE014）パスする
- [ ] `git diff` で、フックの制御ロジック（条件分岐・exit コード）に変更がなく、文言・コメントのみの差分であることを確認した

## 作業内容

1. `CLAUDE.md`「作業の入口」セクションを編集
2. 3つの SKILL.md を編集
3. `.claude/hooks/workflow-entry.sh` のコメント・メッセージ文言を編集
4. `.claude/hooks/tests/test-workflow-entry.sh` を編集
5. `bash .claude/hooks/tests/test-workflow-entry.sh` を実行して確認
6. `grep -rn "入口"` で `.claude/` `CLAUDE.md` に残存が無いか確認

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
