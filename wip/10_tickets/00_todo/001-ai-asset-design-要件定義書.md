---
type: ai-asset-design
status: todo
depends_on: []
---

# フェーズ別ワークスキルの要件定義書を作成する

## 目的

issue #39 の受け入れ条件を要件定義書（ユーザーストーリー・When/Shall の受け入れ基準）に落とし、13 スキルと type 追加の要件を固める。

## 完了条件（DoD）

- [ ] `.claude/docs/00_requirements/フェーズ別ワークスキル.md` が `task-requirements` のテンプレートに沿って作成されている
- [ ] 受け入れ基準に issue #39 の受け入れ条件 5 項目がすべて When/Shall 形式で含まれている
- [ ] 前提条件・制約条件に「既存 5 type は据え置き」「`retrospective` は変更しない」「設計書の置き場は `docs/**`」「スキルごとの 1:1:1 文書化は #37」が書かれている
- [ ] 全体計画（`wip/00_overall_plan/sparkling-purring-eagle.md`）の合意事項と矛盾がない

## 作業内容

1. `task-requirements` の `assets/` テンプレートと既存の要件定義書（`スキル体系.md`、`チケット駆動ワークフロー.md`）を読み、書式を揃える
2. 全体計画の Context・合意事項・方針から背景・目的・スコープを書く
3. issue #39 の受け入れ条件と全体計画「判断が必要になりそうな点」を受け入れ基準・制約条件に落とす
4. frontmatter（`type: requirements`、`title`、`description`、`tags`、`keywords`）を付ける

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
