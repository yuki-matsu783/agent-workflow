---
type: ai-asset-implementation-plan
status: todo
depends_on: ["003-ai-asset-design-チケット駆動ワークフロー仕様書の更新.md"]
---

# AI アセット実装計画: work-ticket-driven / work-overall-plan の git add wip/ を許可パスに揃える

## 目的

全体計画（wip/00_overall_plan/skill-git-add-paths.md）のフェーズ 2 として、更新後の仕様書（`.claude/docs/10_spec/チケット駆動ワークフロー.md` 2.3）を正に、`work-ticket-driven` / `work-overall-plan` の SKILL.md 4 か所の修正と TC022b / TC022c のテストスクリプト化の実装計画を書き、実装チケットと振り返りチケットを起こす。

## 完了条件（DoD）

- [x] wip/20_plans/AIアセット実装計画-skill-git-add-paths.md に、変更するスキル（`.claude/skills/work-ticket-driven/SKILL.md` 手順 2・5、`.claude/skills/work-overall-plan/SKILL.md` 4-1・4-5）の一覧と修正後のコマンド、テスト（`.claude/hooks/tests/test-workflow-guard.sh` への TC022b / TC022c 追加）の方針、他の `work-*` スキルに `git add wip/` 相当が無いことの確認手順、実装ステップが書かれている
- [x] AI アセット実装チケット 2 枚（005 テスト、006 スキル手順 + permission-matrix）が todo に起票され、各 DoD が受け入れ条件①②④と対応している
- [x] 振り返りチケット（007-retrospective-振り返り.md）が todo に起票されている（フェーズ列の最後）

## 作業内容

1. 更新後の仕様書の規約（チケット運用コマンド・処理フロー 3・6・TC022b / TC022c）を読む
2. SKILL.md の該当行と `test-workflow-guard.sh` の既存ケースの書き方を確認する
3. 実装計画書を書き、実装チケットと振り返りチケットを起こす

## 作業ログ

### うまくいったこと

- 既存テストの型（`write_ticket` / `cmd_json` / `run` / `check`）を把握し、TC022b / TC022c を `use_real_types` 以降に追加する形に決めた。仕様書の TC022 は `test-workflow-guard.sh` の TG004 と `scripts/test-hooks.sh` の TC022 として実装済みで、設計チケットの積み残し（TC022 未実装）は解消
- 参照更新の漏れを grep で洗い出し、`permission-matrix.md:91` の `git add` 規則行に規約を添える必要を見つけて 006 に含めた。`evals.json` と他の `work-*` スキルは更新不要
- ステップ順は「テスト → スキル → 振り返り」。テストを先に通すことで「フック変更不要」を裏付ける

### うまくいかなかったこと

- `workflow.log` 736 行目から、末尾スラッシュ無しの `git add wip/10_tickets` も未記載（WF009）になることが分かった（`wf_is_ticket_path` の case パターン `wip/10_tickets/*` はスラッシュ必須）。仕様書に TC が無いため、TC022d 案として現行挙動をテストで固定し、仕様書追記は振り返りで棚卸しする（フックは変えない）
- `check` 関数は「文字列を含む」しか検証できず、TC022c の「WF009 を含まない」に使えない。拡張方法は 005 で決める
