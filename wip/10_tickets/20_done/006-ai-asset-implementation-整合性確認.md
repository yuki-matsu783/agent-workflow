---
type: ai-asset-implementation
status: todo
depends_on: ["005-ai-asset-design-doc用語更新.md"]
---

# 旧名称の残存確認とテスト全件パスの確認

## 目的

リネーム作業全体を横断的に検査し、旧スキル名の残存・リンク切れが無いこと、既存テストが全件パスすることを確認する（005 で `.claude/docs/**` 内の残存は解消済みの想定。本チケットは `.claude/hooks/**`・`.claude/rules/**`・`.claude/skills/**` の範囲を担当）。

## 完了条件（DoD）

- [x] `grep` の結果、`.claude/hooks/.state/*.entry`（Git管理外の状態ファイル）と `.claude/hooks/workflow.log`（Git管理外の実行ログ）、`.claude/docs/10_spec/スキル体系.md` 等の対応表（意図的に旧名称を列挙）を除き、裸の旧名称は残っていない（`task-gh-issue` 等prefix付き文字列内の部分一致による誤検知を除く）
- [x] `bash .claude/hooks/tests/test-workflow-entry.sh` が全件パスする（PASS=40 FAIL=0）
- [x] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件パスする（PASS=62 FAIL=0）
- [x] 仕様書・スキルの相互参照リンク（`.claude/docs/`、`.claude/skills/` へのパス表記）が実在することを確認した

## 作業内容

1. grep で旧名称の残存を確認し、見つかった箇所を修正する
2. 両テストスクリプトを実行する
3. 仕様書内のリンク（`.claude/docs/`、`.claude/skills/` へのパス表記）が実在するか確認する

## 作業ログ

### うまくいったこと

- 横断grepで、003・004で見落としていた実害のあるバグ（`task-ai-asset-creator/scripts/init-asset.sh` の `TEMPLATE_DIR` が旧パス `ai-asset-creator` のままで、実行すると壊れる状態だった）を発見・修正できた。テンプレートコピー系スクリプトは frontmatter の name だけでなく、スクリプト内のパス文字列も確認する必要があると分かった
- SKILL.md 本文中の bash コード例・cp コマンド例・tags フィールドにも旧パスが残っていることがあり、`name:` や見出しの修正だけでは不十分だった

### うまくいかなかったこと

- （特になし。005 で docs 分を切り出していたため、本チケットは hooks/rules/skills の範囲に集中でき、想定より円滑に進んだ）
