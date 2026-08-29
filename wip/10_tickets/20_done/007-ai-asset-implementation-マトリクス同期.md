---
type: ai-asset-implementation
status: todo
depends_on: ["006-ai-asset-design-仕様追記.md"]
---

# 許可マトリクス要約（permission-matrix.md）の同期

## 目的

仕様書 1.6 で追加した `test` グループと WF001 の `*.md` 限定を、スキル側の要約 `references/permission-matrix.md` に反映する。

## 完了条件（DoD）

- [x] `bash_groups` の説明に `"test"` が追記されている
- [x] 標準タイプ表の `ai-asset-implementation` に `（+ test）` が付いている
- [x] Bash allowlist 表に「フックテスト」行（`bash .claude/hooks/tests/*.sh`、`bash .claude/skills/<skill>/scripts/*.sh`、`test` グループ）がある
- [x] Edit/Write 判定の前段に「doing 配下は `*.md` のみ判定」が書かれている

## 作業内容

1. permission-matrix.md の 4 箇所を Edit する

## 作業ログ

### うまくいったこと

- 006 で仕様書に書いた文言をそのまま要約に写せたので、4 Edit で完了

### うまくいかなかったこと

- 特になし。ただし仕様書と要約の二重管理そのものが手間の源。要約を仕様書から生成するか、要約を廃止して仕様書の該当節を参照させる方が保守しやすい（振り返りで提案）
