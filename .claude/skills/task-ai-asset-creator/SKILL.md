---
name: task-ai-asset-creator
description: >
  ユーザーの要望に基づいて、Claude Code のアセット（skill / rule / hook / agent）を作成する。
  まず種類を判定し、既存と重複がないか確認した上で、適切な方法で作成する。
  skill の場合は skill-creator プラグインを活用し、rule/hook/agent の場合はテンプレートをコピーして作成する。
  Use when the user mentions "スキルを作って", "ルールを作って", "フックを作って", "エージェントを作って",
  "サブエージェント作成", "subagent", ".claude/agents", or wants to add any Claude Code asset.
---

# task-ai-asset-creator — アセットを種類に応じて作成する

ユーザーの要望を受け、**skill / rule / hook / agent** のいずれかに分類し、既存と重複を確認してから作成する。

## 手順 0: アセット種類の判定

ユーザーの要望から、作成対象の種類を判定する。

| 種類 | 判定基準 | 例 |
|------|----------|----|
| **skill** | Claude Code が自動的に発火する指示・ワークフロー | "○○するスキルを作って", "○○ skill 作成" |
| **rule** | 継続的に適用されるルール・制約・規約 | "○○のルールを作って", "プラクティス定義", "コーディング規約" |
| **hook** | 特定のイベント発火時に実行されるスクリプト | "PreToolUse で実行するスクリプト", "commit 前に走るフック" |
| **agent** | 独立したコンテキストで特定の役割を担う subagent | "○○専門のエージェントを作って", "レビュー用サブエージェント", "調査を任せる agent" |

### 曖昧な場合の優先順

1. イベント発火 + スクリプト実行 → **hook**
2. 継続的・宣言的な制約・規約 → **rule**
3. 独立した「役割・人格」を持ち、メインの会話から委任される → **agent**
4. それ以外（メインの会話内で手順に沿って進めるもの） → **skill**

skill と agent の見分け方：

- **skill**: メインの会話の中で手順を読み込んで実行する。コンテキストを共有する
- **agent**: 別のコンテキストで動き、結果だけを返す。ツール制限・モデル指定・並列実行が必要なときに向く

ユーザーに種類が不明な場合は直接尋ねる：

> 作りたいものはどれに近いですか？
> - **skill**: 特定のタスクを自動化する指示（例: issue 作成、テスト実行）
> - **rule**: 継続的に適用されるルールや規約（例: コーディング規約、レビュー基準）
> - **hook**: イベント発火時に実行されるスクリプト（例: コミット前チェック、ツール実行前の処理）
> - **agent**: 独立したコンテキストで役割を担う subagent（例: コードレビュアー、調査担当、テスト実行担当）

---

## 手順 1: 既存アセットの照合

作成前に、`.claude/skills/`、`.claude/rules/`、`.claude/hooks/`、`.claude/agents/` 内に類似するものがないか検索する。

### 検索コマンド

```bash
# skill の場合
find .claude/skills -name "*.md" | xargs grep -l -i "該当キーワード" 2>/dev/null

# rule の場合
find .claude/rules -type f 2>/dev/null | xargs grep -l -i "該当キーワード" 2>/dev/null

# hook の場合
find .claude/hooks -type f 2>/dev/null | xargs grep -l -i "該当キーワード" 2>/dev/null

# agent の場合（プロジェクトとユーザーの両方を確認する）
find .claude/agents ~/.claude/agents -name "*.md" 2>/dev/null | xargs grep -l -i "該当キーワード" 2>/dev/null
```

agent は組み込みのもの（`Explore`, `Plan`, `general-purpose`, `claude-code-guide` など）とも役割が被りやすい。
組み込みで足りるなら新規作成せず、その旨を伝える。

### 類似度チェック

見つかった場合、以下を確認する：

- **同じ種類**かつ**同じ役割**を果たしているか
- **同じ名前/ファイル名**が使われていないか
- agent の場合、同名の agent がプロジェクトとユーザー両方にあるとプロジェクト側が優先される

### 既存が見つかった場合の対応

ユーザーに確認する：

> 既に類似のアセット `XXX` が見つかりました。こちらを更新しますか、それとも新規で作成しますか？

- **更新**: 該当ファイルを読み込み、ユーザーの指示に従って編集する
- **新規作成**: 手順 2 に進む

---

## 手順 2: 種類別の作成処理

### 2-1: skill の場合 — skill-creator を活用

`skill-creator@claude-plugins-official` プラグインがインストールされていることを前提とする。

1. `skill-creator` に処理を委任する
2. 必要に応じて `skill-creator` のワークフロー（ドラフト作成 → テスト → 評価 → 反復）に沿って進める

**委任の流れ：**

> skill-creator を使って、このスキルを作成します。以下の情報を基に進めます：
> - 名前: `<スキル名>`
> - 目的: [ユーザーの要望]
> - 発火条件: [判定したトリガー]

### 2-2: rule の場合 — テンプレートをコピーして作成

`assets/rule.template.md` をコピーして新規ルールファイルを作成する。

```bash
bash .claude/skills/ai-asset-creator/scripts/init-asset.sh rule <ルール名>
```

1. テンプレートの各セクションをユーザーの要望に基づいて記入する
2. `.claude/rules/` に保存する

### 2-3: hook の場合 — テンプレートをコピーして作成

`assets/hook.template.sh` をコピーして新規フックスクリプトを作成する。

```bash
bash .claude/skills/ai-asset-creator/scripts/init-asset.sh hook <フック名>
```

1. テンプレートのコメントとシェル部分をユーザーの要望に基づいて記入する
2. `settings.json` の `hooks` セクションに登録する手伝いをする
3. `.claude/hooks/` に保存する

### 2-4: agent の場合 — テンプレートをコピーして作成

`assets/agent.template.md` をコピーして新規 subagent 定義を作成する。

```bash
bash .claude/skills/ai-asset-creator/scripts/init-asset.sh agent <エージェント名>
```

作成先はプロジェクト用の `.claude/agents/<エージェント名>.md`。
ユーザー全体で使いたいと明示された場合のみ `~/.claude/agents/` に置く。

frontmatter と本文をユーザーの要望に基づいて記入する。詳細は `references/agent-rules.md` を参照。

1. **`name`**: 小文字とハイフンのみ。ファイル名と一致させる
2. **`description`**: 何をするか + いつ委任するか。自動委任させたい場合は "Use proactively when ..." を含める
3. **`tools`**: 必要最小限に絞る（読み取り専用のエージェントなら `Read, Grep, Glob` など）。省略時は Agent 等を除く全ツールを継承する
4. **`model`**: 軽い定型作業なら `haiku`/`sonnet`、判断が重いなら `opus`/`fable`。迷ったら `inherit`
5. **本文（system prompt）**: 役割・やらないこと・作業手順・出力形式を書く。CLAUDE.md の内容やタスクの詳細は書かない（継承・委任時に渡される）
6. 使わないオプションのコメント行はテンプレートから削除する

作成後は、テンプレートの `<...>` プレースホルダーが残っていないか確認する：

```bash
grep -n '<[^>]*>' .claude/agents/<エージェント名>.md
```

---

## 手順 3: 設定ファイルへの登録（hook の場合）

hook を作成した後、`.claude/settings.json` に登録するかどうかを確認する。

### 既存の hooks 設定

```json
{
  "hooks": {
    "PreToolUse": [...]
  }
}
```

新しい hook を追加する場合は、既存の matcher と衝突しないよう注意する。

agent は `settings.json` への登録は不要。ファイルを置くだけで次回セッションから認識される
（同一セッション内で作った場合は、再起動するか `/agents` で認識を確認する）。

---

## 手順 4: 結果の報告

作成したアセットの種類、ファイルパス、内容の概要を報告する。

> [種類] アセットを `[ファイルパス]` に作成しました。
>
> 内容の概要:
> - [概要]

agent の場合は、呼び出し方も併せて伝える：

> 使い方:
> - 自動委任: description の条件に合う依頼をすると Claude が判断して委任する
> - 明示的に呼ぶ: 「`<エージェント名>` エージェントで○○して」と依頼する
> - 確認: `/agents` で一覧に表示される

---

## エラーハンドリング

### テンプレートファイルが見つからない場合

`assets/` ディレクトリにテンプレートが存在するか確認する。

### ディレクトリが存在しない場合

`.claude/rules/`、`.claude/hooks/`、`.claude/agents/` が存在しない場合は、自動的に作成する：

```bash
mkdir -p .claude/rules .claude/hooks .claude/agents
```

### 権限エラー

ファイルの書き込みに失敗した場合、ユーザーに適切なパスや権限を確認する。

---

## ベストプラクティス

### 最小限の初期実装

最初は最小限の内容で作成し、ユーザーのフィードバックを受けてから拡張する。

### 明確な発火条件

skill の場合は description に具体的なトリガーを記載し、認知度を高める。
agent の場合も同様に、description に「何をするか」と「いつ委任するか」を両方書く。

### 設定ファイルの整合性

hook を追加する際は既存のフック設定と衝突しないよう注意する。

### agent のツールは最小権限

agent は独立して動くため、暴走時の影響を抑えるために `tools` を絞る。
読み取り専用で済む役割（レビュー、調査）に `Write`/`Edit`/`Bash` を与えない。
