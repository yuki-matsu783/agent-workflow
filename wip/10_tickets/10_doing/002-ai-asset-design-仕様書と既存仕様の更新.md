---
type: ai-asset-design
status: todo
depends_on: ["001-ai-asset-design-要件定義書.md"]
---

# フェーズ別ワークスキルの仕様書を作成し、既存仕様・用語辞書を更新する

## 目的

13 スキルと type の対応、各 type の allow_paths、ワークの連鎖規則、SKILL.md の型、テンプレート方針を仕様として確定し、既存の仕様書・用語辞書を整合させる。実装チケット（003〜008）の正となる文書を作る。

## 完了条件（DoD）

- [ ] `.claude/docs/10_spec/フェーズ別ワークスキル.md` が `task-spec` のテンプレートに沿って作成され、次を含む: 13 スキル × type 対応表 / 各 type の `allow_paths`・`bash_groups` / ワークの連鎖規則（誰がどのチケットを起こすか） / SKILL.md の節構成 / テンプレート方針 / `EnterPlanMode` の扱い / テストシナリオ
- [ ] 全体計画「判断が必要になりそうな点」3 点について結論と根拠が仕様書に書かれている
- [ ] `.claude/docs/10_spec/スキル体系.md` の work 層の記述（一覧・ワーク境界）が新スキルを含む形に更新され、レビュー記録に追記されている
- [ ] `.claude/docs/10_spec/チケット駆動ワークフロー.md` の type 一覧に新 type が追加され、`overall-plan` が global deny（`wip/00_overall_plan/**`）を type allow で貫通する旨が書かれている
- [ ] `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` の手順 5 初回入口が `work-overall-plan` になっている
- [ ] `.claude/docs/90_glossary/スキル名.md` に 13 スキル、`チケットtype.md` に 9 type が追加されている
- [ ] 要件定義書（001）の受け入れ基準がすべて仕様のどこかで満たされている

## 作業内容

1. `task-spec` のテンプレートと既存仕様書（`スキル体系.md`、`チケット駆動ワークフロー.md`、`issue-PR駆動ワークフロー.md`）を読む
2. 全体計画の既定案を仕様に落とし、3 つの判断点に結論を出す
3. 新仕様書を作成し、既存仕様書・用語辞書を更新する（各レビュー記録にバージョンを追記）
4. 実装チケットで使う `allowed_paths` に過不足がないか確認する（003〜008 は `ai-asset-implementation` の allow に収まる想定）

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
