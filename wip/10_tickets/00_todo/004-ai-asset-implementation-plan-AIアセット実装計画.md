---
type: ai-asset-implementation-plan
status: todo
depends_on: ["003-ai-asset-design-チケット駆動ワークフロー仕様書の更新.md"]
---

# AI アセット実装計画: work-ticket-driven / work-overall-plan の git add wip/ を許可パスに揃える

## 目的

全体計画（wip/00_overall_plan/skill-git-add-paths.md）のフェーズ 2 として、更新後の仕様書（`.claude/docs/10_spec/チケット駆動ワークフロー.md` 2.3）を正に、`work-ticket-driven` / `work-overall-plan` の SKILL.md 4 か所の修正と TC022b / TC022c のテストスクリプト化の実装計画を書き、実装チケットと振り返りチケットを起こす。

## 完了条件（DoD）

- [ ] wip/20_plans/AIアセット実装計画-skill-git-add-paths.md に、変更するスキル（`.claude/skills/work-ticket-driven/SKILL.md` 手順 2・5、`.claude/skills/work-overall-plan/SKILL.md` 4-1・4-5）の一覧と修正後のコマンド、テスト（`.claude/hooks/tests/test-workflow-guard.sh` への TC022b / TC022c 追加）の方針、他の `work-*` スキルに `git add wip/` 相当が無いことの確認手順、実装ステップが書かれている
- [ ] AI アセット実装チケット N 枚が todo に起票され、各 DoD が受け入れ条件①②④と対応している
- [ ] 振り返りチケット（retrospective）が todo に起票されている（フェーズ列の最後）

## 作業内容

1. 更新後の仕様書の規約（チケット運用コマンド・処理フロー 3・6・TC022b / TC022c）を読む
2. SKILL.md の該当行と `test-workflow-guard.sh` の既存ケースの書き方を確認する
3. 実装計画書を書き、実装チケットと振り返りチケットを起こす

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
