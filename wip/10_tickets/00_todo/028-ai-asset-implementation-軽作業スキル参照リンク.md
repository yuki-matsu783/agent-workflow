---
type: ai-asset-implementation
status: todo
depends_on: ["024-ai-asset-design-軽作業とメタ文書整理.md"]
---

# workflow-quick-request / workflow-issue-mr-driven のSKILL.mdに参照リンクを整備する

## 目的

024で新設した `軽作業ワークフロー.md` への参照リンクを `workflow-quick-request/SKILL.md` に追加する。あわせて、共有メタ文書（ワークフロー振り分け実施済み判定）への参照であることが分かる書式にし、`workflow-issue-mr-driven/SKILL.md` にも対称の1行を追加して整合を明示する。

## 完了条件（DoD）

- [ ] `workflow-quick-request/SKILL.md` に `- 要件: .claude/docs/00_requirements/軽作業ワークフロー.md` / `- 仕様: .claude/docs/10_spec/軽作業ワークフロー.md` の2行が追加されている
- [ ] `workflow-quick-request/SKILL.md` の既存の「振り分け実施済み判定の仕様: ...」の行が「振り分け実施済み判定の仕様（WF101 フックの正。`workflow-issue-mr-driven` と共有するメタ文書）: ...」に更新されている
- [ ] `workflow-issue-mr-driven/SKILL.md` に、同じメタ文書への参照であることを示す対称の1行が追加されている
- [ ] リンク先パスが実在する
- [ ] 各SKILL.mdの本文（手順・振る舞い）は変更していない
- [ ] `.claude/docs/**` は変更していない

## 作業内容

1. `workflow-quick-request/SKILL.md` に専用req/spec参照2行と、既存メタ文書行への注記を追加する
2. `workflow-issue-mr-driven/SKILL.md` に対称のメタ文書参照1行を追加する
3. リンク先ファイルが実在することを確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
