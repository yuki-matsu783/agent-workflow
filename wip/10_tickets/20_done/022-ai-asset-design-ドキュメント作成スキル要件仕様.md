---
type: ai-asset-design
status: todo
depends_on: []
---

# ドキュメント作成スキル群の要件定義書・仕様書を新設する

## 目的

`task-requirements` / `task-spec` の2スキルそれぞれに、専用の要件定義書と仕様書を1:1で新設する。この2スキル自体が要件定義書・仕様書の作成手順を定義するスキルであり、他スキルと同様に自己言及的にrequirements/specsを持つ状態にする。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/要件定義書作成.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/要件定義書作成.md`（type: spec）が作成されている
- [x] `.claude/docs/00_requirements/仕様書作成.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/仕様書作成.md`（type: spec）が作成されている
- [x] 各requirementsは `task-requirements/assets/requirements.template.md`、各specは `task-spec/assets/spec.template.md` をコピーして作成し、骨格見出しを維持している
- [x] 各ファイルに `.claude/rules/markdown-frontmatter.md` のfrontmatter（type/title/description/tags/keywords）が付与されている
- [x] specは対応するSKILL.mdの手順・テンプレート項目・入出力を反映している
- [x] 各文書の「関連するドキュメント」節から、対応するskillのSKILL.mdパスと対になるrequirements/specへの相互リンクが張られている
- [x] `.claude/skills/**` は変更していない

## 作業内容

1. `task-requirements/SKILL.md` と `task-spec/SKILL.md` を読み、目的・入出力・処理フロー・依存関係（task-specがtask-requirementsの成果物を土台にする関係）を洗い出す
2. `task-requirements/assets/requirements.template.md` をコピーし、`要件定義書作成.md` を要件定義書として作成する
3. `task-spec/assets/spec.template.md` をコピーし、`要件定義書作成.md` の仕様書を作成する
4. 同様に `仕様書作成.md` の要件定義書・仕様書を作成する
5. 各ファイルの「関連するドキュメント」に相互リンクを追記する

## 作業ログ

### うまくいったこと

- task-requirements/task-spec自体を対象にする自己言及的なケースだったが、他スキルと同じテンプレート・フォーマットで違和感なく作成できた
- 両スキルの依存関係（specがrequirementsの成果物を土台にする）を、それぞれの「関連するドキュメント」に相互リンクとして明記できた

### うまくいかなかったこと

- なし
