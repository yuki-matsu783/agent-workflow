---
type: ai-asset-implementation
status: todo
depends_on: ["007-ai-asset-implementation-AIアセット設計と実装の4スキル.md"]
---

# 呼び出し元スキル（workflow-issue-mr-driven / work-ticket-driven / workflow-quick-request）と evals を更新する

## 目的

新設した 13 スキルを既存のワークフローから呼べるようにし、記述の矛盾をなくす。

## 完了条件（DoD）

- [ ] `.claude/skills/workflow-issue-mr-driven/SKILL.md` の手順 5 初回入口が `work-overall-plan` になり、役割分担表・フロー図・ベストプラクティスが新スキルと整合している
- [ ] `.claude/skills/work-ticket-driven/SKILL.md` の手順 1・2 が `work-overall-plan` / 計画ワークとの分担に合わせて改訂され、type 一覧に 9 type が反映されている
- [ ] `.claude/skills/workflow-quick-request/SKILL.md` の切り替え時のチケット構成の記述が新スキルと整合している
- [ ] 上記 3 スキルの `evals/evals.json` に新入口のケースが追加されている
- [ ] `grep -rn "work-ticket-driven 手順 1\|手順 1 から実施" .claude/skills/` の結果が新しい入口と矛盾しない
- [ ] 13 スキルの `SKILL.md` すべてに `type: skill` があり、節構成が揃っている（`grep -L "^type: skill" .claude/skills/work-*/SKILL.md` が空）

## 作業内容

1. 仕様書「ワークの連鎖規則」「`EnterPlanMode` の扱い」に従い 3 スキルを改訂する
2. evals を追加する
3. 13 スキルの横断チェックを行う

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
