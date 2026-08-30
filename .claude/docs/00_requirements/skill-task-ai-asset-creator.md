---
type: requirements
title: AIアセット作成 要件定義
description: skill/rule/hook/agentを種類判定し重複確認の上で作成する要件
tags: [task-ai-asset-creator, skill, rule, hook, agent]
keywords: [アセット種類判定, skill-creator, テンプレート, 重複確認]
---

# AIアセット作成 要件定義

## 概要

- **背景**: Claude Codeのアセット（skill/rule/hook/agent）は種類ごとに作成方法・置き場所・設定ファイルへの登録要否が異なり、判定を誤ると意図しない場所に作られたり、既存アセットと重複したりする。
- **目的**: ユーザーの要望から作成対象の種類を判定し、既存との重複を確認した上で、種類に応じた適切な方法（skillは`skill-creator`委任、rule/hook/agentはテンプレートコピー）でアセットを作成できるようにする。
- **スコープ**:
  - 含む: 種類判定（skill/rule/hook/agent）、既存アセットとの重複確認、種類別の作成処理、hookの場合のsettings.json登録
  - 含まない: skill自体の詳細な作成手順（`skill-creator`プラグインに委任）、作成後のアセットの品質レビュー

---

## ユーザーストーリー

**[As a]** Claude Codeのアセットを追加・拡張する開発者として、

**[I want]** 作りたいものがskill/rule/hook/agentのどれに当たるかを判定してもらい、重複なく作成したい、

**[So that]** 種類の判定ミスや既存アセットとの重複を避け、適切な場所・方法でアセットを追加できるため。

### ユーザーストーリーの別パターン

| パターン | フォーマット | 例 |
|---------|------------|-----|
| 条件付き | Unless | Unless 既存の類似アセットが見つかった場合、確認なしに新規作成してはならない |

---

## 受け入れ基準（Acceptance Criteria）

### メインフロー

- When ユーザーがアセットの作成を依頼したとき、Shall 判定基準表（発火方式・継続性・独立性）から種類（skill/rule/hook/agent）を判定しなければならない
- When 種類が判定できたとき、Shall `.claude/skills/`・`.claude/rules/`・`.claude/hooks/`・`.claude/agents/` 内の既存アセットとの重複を検索しなければならない
- When 重複が無いとき、Shall 種類に応じた方法（skillは`skill-creator`委任、rule/hook/agentは対応テンプレートのコピー）で作成しなければならない

### アルタナティブフロー（代替経路）

- When ユーザーの依頼から種類が判定できないとき、Shall 4種類の説明を示してユーザーに直接尋ねなければならない
- When 既存に類似のアセットが見つかったとき、Shall 更新するか新規作成するかをユーザーに確認しなければならない
- When hookを作成したとき、Shall `.claude/settings.json` への登録要否を確認しなければならない

### 例外フロー（エラーケース）

- When agentの役割が組み込みagent（`Explore`/`Plan`/`general-purpose`/`claude-code-guide`等）で足りるとき、Shall 新規作成せずその旨を伝えなければならない
- When 対象ディレクトリ（`.claude/rules/`等）が存在しないとき、Shall 自動的に作成しなければならない
- When テンプレートファイルが `assets/` に見つからないとき、Shall エラーとして報告しなければならない

---

## 前提条件

- skill作成の場合、`skill-creator@claude-plugins-official` プラグインが導入されていること

---

## 制約条件

- **技術的制約**: rule/hook/agentの作成は同梱スクリプト（`scripts/init-asset.sh`）経由でテンプレートをコピーする
- **ビジネス的制約**: 特になし
- **外部的制約**: agentのツールは必要最小限に絞る（暴走時の影響を抑えるため）

---

## 依存関係

- `skill-creator`（プラグイン）: skill作成の委任先
- `.claude/rules/markdown-frontmatter.md`: 作成するrule/skillのfrontmatter規約

---

## 非機能要件

| 項目 | 説明 |
|------|------|
| 判定の一貫性 | 同じ要望であれば常に同じ種類に判定されること（曖昧時の優先順が明確であること） |
| 安全性 | agentのツール権限を必要最小限に絞ること |

---

## 関連するドキュメント

- `.claude/skills/task-ai-asset-creator/SKILL.md`
- `.claude/docs/10_spec/skill-task-ai-asset-creator.md`

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
