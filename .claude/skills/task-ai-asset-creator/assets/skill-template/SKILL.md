---
name: <スキル名>
description: >
  <スキルの概要を1〜2文で記載>
  Use when the user mentions "<トリガーになるユーザーの言葉>", "<別のトリガー>",
  "skill" related terms. Always check for existing skills before creating new ones,
  and create from the template in assets/.
---

# <スキル名> — <スキルの概要をここに記載>

<スキルの説明を簡潔に記載する。ユーザーが何をしたいときにこのスキルが発火するかを記述する。>

## 手順 0: 既存スキルの照合

作成前に、既存のスキルと類似するものがないか確認する。

### 既存スキルの検索

ワークスペース内の以下を検索する：

```bash
find .claude/skills -name "SKILL.md" | xargs grep -l -i "<検索キーワード>" 2>/dev/null
```

### 類似度チェック

見つかった既存スキルについて、以下の観点で確認する：

- **同じ機能**を提供していないか
- **同じトリガー言葉**が使われていないか
- **同じ目的**で作成されていないか

類似するものが見つかった場合は、ユーザーに知らせて確認する：

> 既に類似のスキル `XXX` が見つかりました。こちらを更新しますか、それとも新規で作成しますか？

- **更新を選択された場合**: 該当のスキルを読み込み、ユーザーの指示に従って編集する
- **新規作成を選択された場合**: 手順 1 に進む

### 類似ドキュメントが完全にない場合

テンプレートをコピーして新規作成に進む。

---

## 手順 1: テンプレートのコピー

`ai-asset-creator` の `assets/skill-template/` をベースに新しいスキルディレクトリを作成する。

```bash
cp -r .claude/skills/ai-asset-creator/assets/skill-template/ .claude/skills/<スキル名>/
```

---

## 手順 2: SKILL.md の更新

作成された `SKILL.md` の frontmatter と本文を以下の要件に合わせて編集する：

- **frontmatter `name`**: スキル名を記載
- **frontmatter `description`**: トリガーとなるユーザーの言葉を記載
- **本文**: スキル固有の手順やロジックを記述

---

## 手順 3: アセット・参照・スクリプトの更新

必要に応じて以下をカスタマイズする：

- `assets/`: スキルで使用するテンプレートファイル
- `references/`: 規約やガイドライン
- `scripts/`: 初期化や補助スクリプト
- `evals/`: テストケース

---

## 手順 4: settings.json への登録

必要に応じて `.claude/settings.json` にスキルの設定を追加する。

---

## エラーハンドリング

- テンプレートディレクトリが存在しない場合: `ai-asset-creator` の `assets/skill-template/` を確認する
- 既存のスキルと完全に同じ名前がある場合: 上書きせず、更新を提案する
- 権限エラーが発生した場合: `chmod` は `block-chmod.sh` フックによりブロックされる可能性があるため、`git update-index --chmod=+x` を使用する

## ベストプラクティス

- description にトリガーとなるユーザーの言葉を複数含める
- 手順は番号付きで明確に記述する
- エラーメッセージは具体的に記載する
- 既存アセットとの重複チェックを必ず行う
