---
type: ai-asset-implementation
status: todo
depends_on: ["030-ai-asset-design-振り返り棚卸しと合意の要件仕様.md"]
---

# 振り返り棚卸しの実装

## 目的

030 で確定した要件・仕様に従い、`work-ticket-driven` スキル・テンプレート・evals を実装し、`workflow-issue-mr-driven` の受け口を一般化する（issue #3）。

## 完了条件（DoD）

- [ ] `.claude/skills/work-ticket-driven/SKILL.md` 手順4の retrospective 箇条書きが、棚卸し（5種類）→ 4観点の振り返り→ 2区分→ 合意 の手順に拡張されている
- [ ] 同ファイル手順6「完了報告」に、合意が「issue を作って workflow-issue-mr-driven で進める」だった場合の動き（完了処理の後に同スキルを手順1から読み込む。引き継ぐ項目: summary/acceptance/kind/チケット構成）が明記されている
- [ ] `.claude/skills/workflow-issue-mr-driven/SKILL.md` 手順1「振り返りからの切り替え」が、`workflow-quick-request` 手順5-3 に加えて `work-ticket-driven` retrospective の合意（完了処理後）からの切り替えも受け付けるよう一般化されている
- [ ] `.claude/skills/work-ticket-driven/assets/report.template.md` の「改善提案」付近に棚卸し表（アセット種別/判定/気付き）が追加されている
- [ ] `.claude/skills/work-ticket-driven/evals/evals.json` に、retrospective の棚卸し・4観点・2区分の合意を検証するケースが追加され、JSON として妥当である

## 作業内容

1. `.claude/skills/work-ticket-driven/SKILL.md` を Edit し、手順4 retrospective と手順6 完了報告を拡張する
2. `.claude/skills/workflow-issue-mr-driven/SKILL.md` の「振り返りからの切り替え」節を Edit し、切り替え元を一般化する
3. `.claude/skills/work-ticket-driven/assets/report.template.md` に棚卸し表を Edit で追加する
4. `.claude/skills/work-ticket-driven/evals/evals.json` を Read し、`workflow-quick-request/evals/evals.json` の id 4・5 を参考にしたケースを Edit で追加、`python3 -m json.tool` で妥当性を確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
