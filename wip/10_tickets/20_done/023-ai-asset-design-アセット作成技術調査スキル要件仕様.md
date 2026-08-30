---
type: ai-asset-design
status: todo
depends_on: []
---

# アセット作成・技術調査スキル群の要件定義書・仕様書を新設する

## 目的

`task-ai-asset-creator` / `task-investigating-technologies` の2スキルそれぞれに、専用の要件定義書と仕様書を1:1で新設する。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/AIアセット作成.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/AIアセット作成.md`（type: spec）が作成されている
- [x] `.claude/docs/00_requirements/技術調査.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/技術調査.md`（type: spec）が作成されている
- [x] 各requirementsは `task-requirements/assets/requirements.template.md`、各specは `task-spec/assets/spec.template.md` をコピーして作成し、骨格見出しを維持している
- [x] 各ファイルに `.claude/rules/markdown-frontmatter.md` のfrontmatter（type/title/description/tags/keywords）が付与されている
- [x] specは対応するSKILL.mdの手順・判定表・入出力を反映している
- [x] 各文書の「関連するドキュメント」節から、対応するskillのSKILL.mdパスと対になるrequirements/specへの相互リンクが張られている
- [x] `.claude/skills/**` は変更していない

## 作業内容

1. `task-ai-asset-creator/SKILL.md` と `task-investigating-technologies/SKILL.md` を読み、目的・入出力・処理フロー・依存関係を洗い出す
2. `task-requirements/assets/requirements.template.md` をコピーし、各スキルの要件定義書を作成する
3. `task-spec/assets/spec.template.md` をコピーし、各スキルの仕様書を作成する
4. 各ファイルの「関連するドキュメント」に相互リンクを追記する

## 作業ログ

### うまくいったこと

- task-ai-asset-creatorの種類判定基準表・優先順、task-investigating-technologiesの評価軸・3択結論を、それぞれ仕様書のデータ設計節にそのまま転記できた

### うまくいかなかったこと

- なし
