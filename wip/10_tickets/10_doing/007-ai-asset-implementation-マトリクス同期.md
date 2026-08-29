---
type: ai-asset-implementation
status: todo
depends_on: ["006-ai-asset-design-仕様追記.md"]
---

# 許可マトリクス要約（permission-matrix.md）の同期

## 目的

仕様書 1.6 で追加した `test` グループと WF001 の `*.md` 限定を、スキル側の要約 `references/permission-matrix.md` に反映する。

## 完了条件（DoD）

- [ ] `bash_groups` の説明に `"test"` が追記されている
- [ ] 標準タイプ表の `ai-asset-implementation` に `（+ test）` が付いている
- [ ] Bash allowlist 表に「フックテスト」行（`bash .claude/hooks/tests/*.sh`、`bash .claude/skills/<skill>/scripts/*.sh`、`test` グループ）がある
- [ ] Edit/Write 判定の前段に「doing 配下は `*.md` のみ判定」が書かれている

## 作業内容

1. permission-matrix.md の 4 箇所を Edit する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
