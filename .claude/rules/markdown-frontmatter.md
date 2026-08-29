---
paths:
  - "**/*.md"
type: rule
title: markdownのYAML frontmatter規約
description: リポジトリ内markdownドキュメントに付与するOKF（Open Knowledge Format）準拠frontmatterのキー定義・typeの値一覧・対象外ファイル
tags: [markdown, frontmatter, rule]
keywords: [okf, frontmatter, フロントマター, キー定義, タイプ, テンプレート]
---

# markdownのYAML frontmatter規約

リポジトリ内の各 markdown ファイルに、ファイル種別・要約・タグ等を機械可読な形で持たせることで、
将来的な一覧化・検索・ツール連携をしやすくする。

## キー定義

OKF（Open Knowledge Format、<https://okf.md/spec/>）のフィールド定義に沿って各キーの意味を記載する。

| フィールド | 必須/推奨 | 説明 |
|---|---|---|
| `type` | **必須** | コンセプトのタイプを特定する短い文字列。中央登録は無く、値は本リポジトリで自由に定義する（下表「typeの値」参照） |
| `title` | 推奨 | 人間が読みやすい名前 |
| `description` | 推奨 | 1文でコンセプトを要約する |
| `resource` | 推奨 | 対応する実リソース（外部URL等）を一意に識別するURI。対応する実リソースが無いファイルではキー自体を省略してよい |
| `tags` | 推奨 | 横断的カテゴリ分類用の文字列リスト（kebab-case、2〜4個程度） |
| `keywords` | 推奨 | OKF標準にはない拡張フィールド。本文中の頻出語・特徴的な語を検索用途で3〜20個程度リスト形式で記載する |

新規markdown作成時は原則このfrontmatterを付与する。既存のfrontmatterを持つファイル（下記「対象外・特殊対応ファイル」参照）は既存キーを変更せず、不足しているキーのみを追記する。

**値の書き方の注意**: frontmatterの値（plain scalar）に半角コロン＋半角スペース（`: `）を含めない。YAMLがマッピングの区切りと誤認しうるため。`[...]`（flow sequence）内にプレースホルダの説明文をカンマ区切りで書かない。カンマは要素区切りとして解釈され、意図と異なる複数要素になる。プレースホルダの説明は値ではなく行末の `#` コメントで書く（例: `tags: []  # kebab-case, 2〜4個`）。

## テンプレートファイルの命名規則

コピーして使うテンプレート（`assets/*-template.md` の類）は `<名前>.template.md`（シェルスクリプトは `.template.sh`）に統一する。ファイル名の**後ろから2つ目の拡張子**が `template` であることで、`**/*.template.md` という1つのglobパターンだけで「これはテンプレートである」を機械的に判定できる。個別ファイル名のハードコードされた一覧を都度更新する必要が無い。

## typeの値

| type | 対象 |
|---|---|
| `rule` | `.claude/rules/*.md` |
| `skill` | `.claude/skills/*/SKILL.md` |
| `agent` | `.claude/agents/*.md` |
| `requirements` | 要件定義書（`requirements` スキルの成果物） |
| `spec` | 仕様書（`spec` スキルの成果物） |
| `plan` | 調査チケットの成果物（`wip/20_plans/*.md`） |
| `report` | 振り返りチケットの成果物（`wip/30_reports/*.md`） |
| `tech-investigation` | 技術調査レポート（`investigating-technologies` スキルの成果物） |
| `reference` | スキルの `references/*.md`（実装者向けの参照資料） |
| `guide` | `README.md` など案内文書 |

`type` の値は自動判定せず、ファイルごとに内容を見て個別に決定する。上表は現時点の割り当て例であり、新しい用途が増えた場合はこの表に追記する。

## 対象外・特殊対応ファイル

以下は既に別スキーマのfrontmatterを持つか、投稿先の都合でfrontmatterの追加が適さないため、通常のキーをそのまま追加しない。

| ファイル | 扱い | 理由 |
|---|---|---|
| `.claude/skills/ticket-driven-workflow/assets/ticket.template.md` および生成後の `wip/10_tickets/**/*.md` | **対象外**（OKF frontmatter を追加しない） | 既に `type` / `status` / `depends_on` / `allowed_paths` を持つ、フック（`workflow-guard.sh` 等）が機械的に解釈する専用フロントマターを1ブロックだけ持つ。OKF の `type`（文書種別）と意味の異なる同名キーを同じブロックへ足すと、フックがどちらの意味か判別できなくなる |
| `.claude/skills/gh-feature/assets/pr.template.md` | **対象外** | GitHub の PR 本文としてそのまま投稿される。frontmatter を追加すると PR 説明欄に YAML がそのまま表示されてしまう |
| `.claude/skills/gh-issue/assets/issue.template.md` | **対象外** | 同上（GitHub issue 本文として投稿される） |
| `.claude/skills/issue-pr-driven-workflow/assets/issue-addendum.template.md` | **対象外** | 既存 issue 本文の末尾に追記される断片であり、単独の文書ではない |
| `.claude/skills/*/SKILL.md`、`.claude/agents/*.md` | `title` / `type` / `tags` / `keywords` のみ追加。`description` は追加しない | 既存の `description` は Claude Code がスキル/エージェント選択に使う実キーのため、重複させず流用する |

いずれも既存のfrontmatterブロックは1つのまま、新キーを既存キーの下に追記する形にし、既存キーの値・順序は変更しない。

## 新規ファイル作成時のフォーマット例

```yaml
---
type: <上表のtype値>
title: <ファイルの題名>
description: <1行要約>
resource: <対応する実リソースがあれば記載。無ければキー自体を省略>
tags: []                        # kebab-caseのキーワード, 2〜4個
keywords: []                    # 本文の頻出語・特徴語, 3〜20個
---
```

コピーして使うテンプレート（`assets/*.template.md`）は、コピー後の完成形として正しい `type` を
あらかじめ埋め込んである。テンプレートをコピーするだけで `type` の指定は完了し、`title` /
`description` / `tags` / `keywords` を埋めれば OKF 準拠になる。

## スコープ外

frontmatter を横断的に索引化・検索する仕組み（`index.jsonl` 生成、検索スクリプト等）は本リポジトリには無い。
`tags` / `keywords` は将来そうしたツールを導入する場合に備えた一貫性のための記載であり、現時点では
人間が `grep` 等で探す際の手がかりとして使う。
