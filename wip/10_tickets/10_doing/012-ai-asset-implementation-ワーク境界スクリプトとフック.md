---
type: ai-asset-implementation
status: todo
depends_on: ["011-ai-asset-design-ワーク境界スクリプトとフック仕様.md"]
---

# ワーク境界スクリプトとフックの実装

## 目的

011 で確定した仕様に従い、ワーク境界の判定スクリプトとレビュー状態管理、フックによるブロック（exit 2 + 理由）を実装し、テストで検証する。

## 完了条件（DoD）

- [ ] `.claude/hooks/work-boundary.sh`（仕様で確定した名前）が `status` / `request` / `complete` を実装し、`status` が JSON を出力する
- [ ] `wip/10_tickets/review-state.json` の読み書きが仕様どおりで、ファイルが無い状態（初回）でも `status` が動く
- [ ] PreToolUse フックが、doing が空でも境界判定を行い、仕様のブロック条件に該当する Bash コマンドを exit 2 と「対処:」付きメッセージで拒否する
- [ ] 既存の振る舞い（doing が空なら通常の Bash は素通り、doing があるときの既存判定）が変わっていない
- [ ] `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` に新しい TC が追加され、既存分を含め全件パスする
- [ ] `bash .claude/hooks/tests/test-workflow-entry.sh` が全件パスする（無改修の想定）
- [ ] `work-ticket-driven/SKILL.md` の手順 5.5 / 6 が、目視の type 比較ではなく `work-boundary.sh status` の結果を使う手順に更新されている
- [ ] `.claude/settings.json` のフック登録が必要なら更新されている

## 作業内容

1. 011 の仕様書（`.claude/docs/10_spec/チケット駆動ワークフロー.md` 追記分）を読む
2. `work-boundary.sh` を実装する
3. フック（`workflow-guard.sh` または新規フック）に境界判定とブロックを組み込む
4. `test-hooks.sh` に TC を追加し、全件パスさせる
5. `work-ticket-driven/SKILL.md` の手順 5.5 / 6 を更新する
6. `test-workflow-entry.sh` を実行して回帰が無いことを確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
