---
type: spec
title: AIアセット作成 仕様
description: skill/rule/hook/agent判定〜作成の入出力・処理フロー
tags: [task-ai-asset-creator, skill, rule, hook, agent]
keywords: [アセット種類判定, skill-creator, テンプレート, init-asset.sh, settings.json]
---

# AIアセット作成 仕様書

## 概要

- **背景・目的**: `.claude/docs/00_requirements/skill-task-ai-asset-creator.md` を参照。
- **スコープ**: `task-ai-asset-creator` スキルの種類判定・重複確認・作成・登録の入出力と処理フローを定義する。

---

## 入力（Input）定義

### 入力元

- **入力元**: ユーザーの依頼文言

### 入力データ

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| 種類 | enum(skill/rule/hook/agent) | Y | 判定基準表または直接質問で確定 | - |
| 名前 | string | Y | ファイル名・アセット名 | - |
| 目的・内容 | string | Y | ユーザーの要望 | - |

### 入力フォーマット

対話ヒアリングによる自然言語入力。

---

## 出力（Output）定義

### 出力先

- **出力先**: `.claude/skills/`・`.claude/rules/`・`.claude/hooks/`・`.claude/agents/`（プロジェクト用）

### 出力データ

| 項目名 | 型 | 説明 | デフォルト値 |
|--------|----|------|-------------|
| 作成されたアセット | file | 種類に応じた形式（skill: ディレクトリ+SKILL.md、rule: .md、hook: .sh、agent: .md） | 各テンプレート |
| settings.json登録 | json | hookの場合のみ | 未登録 |

### ステータス（スキルの終了状態）

| 状態 | 意味 |
|------|------|
| 作成完了 | 種類・ファイルパス・概要を報告 |
| 更新完了 | 既存アセットを編集して報告 |
| 見送り | 組み込みagentで足りる場合、作成せず報告 |

---

## 処理フロー

### 基本フロー

1. 判定基準表（下記データ設計）から種類を判定する。曖昧な場合は優先順（hook→rule→agent→skill）で判断するか、直接質問する
2. `.claude/skills/`・`.claude/rules/`・`.claude/hooks/`・`.claude/agents/`（agentはユーザーディレクトリも）内を検索し、既存との重複を確認する
3. 重複が無ければ種類別の作成処理を行う（下記インターフェース定義）
4. hookの場合、`.claude/settings.json` への登録要否を確認する
5. 作成したアセットの種類・ファイルパス・概要を報告する

### 代替フロー

1. 種類が判定できない → 4種類の説明を示し、`AskUserQuestion` 相当でユーザーに直接尋ねる
2. 既存に類似アセットがある → 更新か新規作成かをユーザーに確認する

### 例外フロー

1. agentの役割が組み込みagentで足りる → 新規作成せずその旨を伝える
2. 対象ディレクトリが存在しない → `mkdir -p` で自動作成する
3. テンプレートファイルが見つからない → エラーとして報告する
4. ファイル書き込みに権限エラー → 適切なパス・権限をユーザーに確認する

---

## データ設計

### 種類判定基準

| 種類 | 判定基準 | 例 |
|------|----------|----|
| skill | Claude Codeが自動発火する指示・ワークフロー | "○○するスキルを作って" |
| rule | 継続的に適用されるルール・制約・規約 | "○○のルールを作って" |
| hook | 特定イベント発火時に実行されるスクリプト | "PreToolUseで実行するスクリプト" |
| agent | 独立したコンテキストで役割を担うsubagent | "○○専門のエージェントを作って" |

### 曖昧な場合の優先順

1. イベント発火 + スクリプト実行 → hook
2. 継続的・宣言的な制約・規約 → rule
3. 独立した「役割・人格」を持ち委任される → agent
4. それ以外（メイン会話内で手順に沿って進める） → skill

---

## インターフェース定義

### 種類別の作成処理

| 種類 | 作成方法 | 保存先 |
|------|---------|--------|
| skill | `skill-creator` プラグインに委任 | `.claude/skills/<name>/` |
| rule | `bash scripts/init-asset.sh rule <name>` でテンプレートコピー | `.claude/rules/<name>.md` |
| hook | `bash scripts/init-asset.sh hook <name>` でテンプレートコピー | `.claude/hooks/<name>.sh` |
| agent | `bash scripts/init-asset.sh agent <name>` でテンプレートコピー | `.claude/agents/<name>.md`（プロジェクト用）/ `~/.claude/agents/`（明示時のみ） |

### 既存スキルへの委譲内容

| 呼び出し元/連携先 | 用途 |
|-----------|------|
| `skill-creator`（プラグイン） | skill作成のドラフト→テスト→評価→反復 |

---

## エラーハンドリング

### エラーコード一覧

| 状況 | 対処 |
|------|------|
| テンプレートが見つからない | `assets/` ディレクトリの存在を確認 |
| 対象ディレクトリが無い | 自動作成（`mkdir -p`） |
| 権限エラー | パス・権限をユーザーに確認 |
| 組み込みagentで代替可能 | 新規作成せず案内 |

---

## 前提条件

`.claude/docs/00_requirements/skill-task-ai-asset-creator.md` の前提条件を参照。

## 制約条件

`.claude/docs/00_requirements/skill-task-ai-asset-creator.md` の制約条件を参照。

## 非機能要件

`.claude/docs/00_requirements/skill-task-ai-asset-creator.md` の非機能要件を参照。

---

## テストシナリオ

### テストケース一覧

| テストID | シナリオ | 入力 | 期待出力 | 結果 |
|---------|---------|------|---------|------|
| TC001 | ruleの新規作成 | "コーディング規約のルールを作って" | `.claude/rules/` にテンプレートベースのファイルが作成される | |
| TC002 | hookの新規作成と登録確認 | "コミット前チェックのフックを作って" | `.claude/hooks/` に作成され、settings.json登録が確認される | |
| TC003 | 組み込みagentで代替可能 | "調査担当のagentを作って"（Exploreで足りる） | 新規作成せず案内される | |
| TC004 | 既存アセットとの重複 | 既存skillと同じ役割の依頼 | 更新/新規作成の確認が行われる | |

---

## 関連するドキュメント

- `.claude/skills/task-ai-asset-creator/SKILL.md`
- `.claude/docs/00_requirements/skill-task-ai-asset-creator.md`

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-30 | 1.0 | 初版（issue #37） | Hiro |
