---
type: ai-asset-design
status: todo
depends_on: []
---

# workflow-quick-request の要件仕様新設と横断メタ文書の位置づけ整理

## 目的

`workflow-quick-request` 専用の要件定義書・仕様書を新設する。あわせて、特定の1スキルに1:1で紐づかない横断的なメタ文書（スキル体系・用語辞書・ワークフロー振り分け実施済み判定）について、1:1:1原則の対象外であることを明記し、`ワークフロー振り分け実施済み判定.md` のrequirements側の欠落（specのみ存在する非対称）を解消する。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/軽作業ワークフロー.md`（type: requirements）が作成されている
- [x] `.claude/docs/10_spec/軽作業ワークフロー.md`（type: spec）が作成されている
- [x] `.claude/docs/00_requirements/ワークフロー振り分け実施済み判定.md`（type: requirements）が新設されている（既存の `10_spec/ワークフロー振り分け実施済み判定.md` を土台に、WF101強制の背景・目的・スコープを要件定義書フォーマットで記述）
- [x] `.claude/docs/00_requirements/スキル体系.md` / `.claude/docs/10_spec/スキル体系.md` / `.claude/docs/00_requirements/用語辞書.md` / `.claude/docs/10_spec/用語辞書.md` / `.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md` の5ファイルに「本文書は特定の1スキルに1:1で紐づく要件/仕様ではなく、複数スキルが参照する横断的なメタ文書である」旨の一文が追記されている（文言は5文書で統一する）
- [x] `軽作業ワークフロー` のrequirements/specは `task-requirements`/`task-spec` の各テンプレートをコピーして作成し、骨格見出しを維持している
- [x] 各ファイルに `.claude/rules/markdown-frontmatter.md` のfrontmatterが付与されている
- [x] `軽作業ワークフロー.md`（spec）は `workflow-quick-request/SKILL.md` の軽作業判定表・各手順の入出力・振り返りの状態遷移・ヘッドレス時挙動を反映している
- [x] `.claude/skills/**` は変更していない

## 作業内容

1. `workflow-quick-request/SKILL.md` を読み、判定表・手順・振り返りフローを洗い出す
2. `task-requirements/assets/requirements.template.md` / `task-spec/assets/spec.template.md` をコピーし、`軽作業ワークフロー.md` の要件定義書・仕様書を作成する
3. 既存の `.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md` を読み、要件定義書テンプレートをコピーして `.claude/docs/00_requirements/ワークフロー振り分け実施済み判定.md` を新設する
4. 上記5つの横断メタ文書に、1:1:1原則の対象外である旨の一文を追記する（概要セクション末尾など）
5. 各ファイルの「関連するドキュメント」を整理する

## 作業ログ

### うまくいったこと

- 既存の `10_spec/ワークフロー振り分け実施済み判定.md` の背景・目的・スコープをそのままEARS形式の受け入れ基準に変換でき、requirements側の欠落を無理なく解消できた
- 「本文書は特定の1スキルに1:1で紐づく要件/仕様ではなく、複数スキルが参照する横断的なメタ文書である」という統一文言を5文書（スキル体系req/spec、用語辞書req/spec、ワークフロー振り分け実施済み判定spec）に一貫して追記できた
- 既存4文書のレビュー記録にも変更履歴を追加し、変更の痕跡を残せた

### うまくいかなかったこと

- なし
