# 全体計画: docs配下に用語辞書ディレクトリを作る

- 対象issue: #11 https://github.com/yuki-matsu783/agent-workflow/issues/11
- PR: #14 https://github.com/yuki-matsu783/agent-workflow/pull/14

## Context

`.claude/docs/` 配下では、スキル名・チケット type・ワークフロー用語の定義が各仕様書・要件定義書に分散している（例: スキル名のリネーム対応表は `10_spec/スキル体系.md`、チケット type の定義は `.claude/hooks/workflow-types.json`）。参照元が一本化されていないため、リネームや用語変更時に更新漏れが起きやすい（issue本文が挙げる 003・004・005 チケットでの旧スキル名残存はその実例）。本issueはこれを防ぐため、用語を一箇所に集約した辞書ディレクトリを新設するもの。

既存の `.claude/docs/00_requirements/` + `10_spec/` のペア構成（issue-PR駆動ワークフロー、スキル体系、チケット駆動ワークフロー、ワークフロー入口ガード）に倣い、今回も要件定義書・仕様書を作成したうえで辞書ディレクトリ本体を作る。`.claude/docs/**` はチケット駆動ワークフローの `ai-asset-design` type でのみ変更できるため、1つの `ai-asset-design` チケットに実装をまとめ、振り返りチケットを続ける2チケット構成とする（既存の類似作業でも投資調査チケットを挟まないケースがあり、本件は要件が issue に明記済みで調査の必要性が低いため踏襲しない）。

## 設計方針

### 配置

`.claude/docs/90_glossary/`（`00_requirements` / `10_spec` と並ぶ番号帯。90番台を「横断参照資料」の位置づけとする）

### ファイル構成

| ファイル | 内容 |
|---|---|
| `.claude/docs/90_glossary/README.md` | 辞書の目的・エントリの書式・既存文書からの参照方法（リンクの張り方）の説明 |
| `.claude/docs/90_glossary/スキル名.md` | `workflow-*` / `work-*` / `task-*` 各スキルの一覧。各エントリは一言説明＋定義元（`10_spec/スキル体系.md` 等）へのリンク。詳細な層定義やリネーム経緯は複製せず、リンクで参照する |
| `.claude/docs/90_glossary/チケットtype.md` | `investigation` / `implementation` / `retrospective` / `ai-asset-design` / `ai-asset-implementation` の一覧。各エントリは一言説明＋定義元（`.claude/hooks/workflow-types.json`）へのリンク |
| `.claude/docs/90_glossary/ワークフロー用語.md` | issue駆動・チケット・DoD・allowed_paths・ワーク完了チェックポイントなど主要なワークフロー用語 |

各エントリは「用語を辞書自身が正として再定義する」のではなく、**一言説明＋既存の正典（各仕様書やJSON定義）へのリンク**とする。これにより「既存仕様書・要件定義書の全文を辞書に合わせて書き換える」（スコープ外）ことなく、参照点だけを一本化できる。

### 参照方法（リンクの張り方）

`10_spec/用語辞書.md` に以下を明記する:

- 仕様書・要件定義書で辞書収録済みの用語を使う場合、初出箇所に `[用語名](../90_glossary/<ファイル>.md#<アンカー>)` 形式のリンクを付ける
- 既存ファイルの一括更新は本チケットのスコープ外（issueのスコープ外節と同じ）。実演として `10_spec/スキル体系.md` など代表1〜2ファイルにこの形式でリンクを1箇所追加し、方式が機能することを示す

### 要件定義書・仕様書

既存ペアと同じ構成で新規作成する:

- `.claude/docs/00_requirements/用語辞書.md`（`type: requirements`、背景・目的・受け入れ基準はissue #11の受け入れ条件に対応させる）
- `.claude/docs/10_spec/用語辞書.md`（`type: spec`、配置・ファイル構成・参照方法・レビュー記録を記載）

いずれも `.claude/rules/markdown-frontmatter.md` のfrontmatter規約（`type`/`title`/`description`/`tags`/`keywords`）に従う。

## チケット分割

1. **008-ai-asset-design-用語辞書新設.md**（type: `ai-asset-design`）
   - `.claude/docs/00_requirements/用語辞書.md` を作成
   - `.claude/docs/10_spec/用語辞書.md` を作成（配置・構成・参照方法を明記）
   - `.claude/docs/90_glossary/README.md` / `スキル名.md` / `チケットtype.md` / `ワークフロー用語.md` を作成
   - 参照方法の実演として、既存仕様書1〜2ファイルに用語辞書へのリンクを追加
   - DoD はissue #11 の受け入れ条件3点に対応させる
2. **009-retrospective-振り返り.md**（type: `retrospective`）
   - 作業ログを元に `wip/30_reports/` へ結果報告を作成
   - ワーク完了チェックポイントは自動化未整備のため「レビュー結果: 未実施（今後の自動化対象）」と明記

## 検証方法

- 作成した各Markdownファイルに `.claude/rules/markdown-frontmatter.md` のfrontmatterが付与されていることを確認する
- `.claude/docs/90_glossary/` 配下の各エントリからリンクした定義元ファイルが実在することを確認する（`ls` / `Read`）
- issue #11 の受け入れ条件3点をすべて満たしていることをDoDで確認する
