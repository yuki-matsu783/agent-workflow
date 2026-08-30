---
type: ai-asset-design
status: todo
depends_on: []
---

# gh/glab操作スキル群の要件定義書・仕様書を新設する

## 目的

`task-gh-feature` / `task-gh-install` / `task-gh-issue` / `task-repo-merge-settings` の4スキルそれぞれに、専用の要件定義書（`.claude/docs/00_requirements/`）と仕様書（`.claude/docs/10_spec/`）を1:1で新設する。issue #37 の受け入れ条件①（全skillにrequirements/specsが1:1で存在する）を満たすための第一弾。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/featureブランチとPR作成.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/featureブランチとPR作成.md`（type: spec）が作成されている
- [x] `.claude/docs/00_requirements/CLIインストール.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/CLIインストール.md`（type: spec）が作成されている
- [x] `.claude/docs/00_requirements/issue操作.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/issue操作.md`（type: spec）が作成されている
- [x] `.claude/docs/00_requirements/マージ設定変更.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/マージ設定変更.md`（type: spec）が作成されている
- [x] 各requirementsは `task-requirements/assets/requirements.template.md`、各specは `task-spec/assets/spec.template.md` をコピーして作成し、骨格見出しを維持している
- [x] 各ファイルに `.claude/rules/markdown-frontmatter.md` のfrontmatter（type/title/description/tags/keywords）が付与されている
- [x] specは対応するSKILL.mdの手順・判定表・入出力を反映している
- [x] 各文書の「関連するドキュメント」節から、対応するskillのSKILL.mdパスと対になるrequirements/specへの相互リンクが張られている
- [x] `.claude/skills/**` は変更していない（参照リンク追加は後続の実装チケットで行う）

## 作業内容

1. 対象4スキルのSKILL.mdを読み、目的・入出力・処理フロー・依存関係を洗い出す
2. `task-requirements/assets/requirements.template.md` をコピーし、各スキルの要件定義書を作成する（概要・ユーザーストーリー・受け入れ基準・前提/制約/依存/非機能・関連ドキュメント・レビュー記録）
3. `task-spec/assets/spec.template.md` をコピーし、各スキルの仕様書を作成する（概要・入出力定義・処理フロー・データ設計・インターフェース定義・エラーハンドリング・前提/制約/非機能・テストシナリオ・関連ドキュメント・レビュー記録）。既存の `issue-PR駆動ワークフロー.md` のようにスキルの性質に応じて小節を追加・置換してよい
4. 各ファイルの「関連するドキュメント」に対応するSKILL.mdパスと対のrequirements/specへの相互リンクを追記する
5. `git add` してコミットする準備をする

## 作業ログ

### うまくいったこと

- 既存の `issue-PR駆動ワークフロー.md` の実運用型（承認ポイント表・責務分担・コマンド対応表）をそのまま踏襲でき、4スキル分を統一的なフォーマットで作成できた
- テンプレート骨格（概要→ユーザーストーリー/入出力→処理フロー→データ設計→インターフェース→エラーハンドリング→前提/制約/非機能→テストシナリオ→関連ドキュメント→レビュー記録）を維持しつつ、スキルごとに小節（承認ポイント、命名規約、対象設定表など）を追加・置換する方針が機能した

### うまくいかなかったこと

- なし
