# subagent 定義ファイル規約

`.claude/agents/<name>.md` の書き方。根拠: https://code.claude.com/docs/en/sub-agents

## ファイル構成

```markdown
---
name: code-reviewer
description: コードの品質・セキュリティをレビューする。Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: inherit
---

（ここから本文 = subagent の system prompt）
```

## frontmatter フィールド

| フィールド | 必須 | 値 | 備考 |
|-----------|------|----|------|
| `name` | ✓ | 小文字とハイフンのみ | ファイル名と一致させる |
| `description` | ✓ | 自由文 | 「何をするか」+「いつ委任するか」。`Use proactively ...` を含めると自動委任されやすい |
| `tools` | — | カンマ区切り文字列 | 省略時は Agent/AskUserQuestion 等を除く全ツールを継承。`mcp__github` のような MCP パターン、`Agent(worker, researcher)` のような subagent 制限も可 |
| `disallowedTools` | — | カンマ区切り文字列 | 除外するツール。`tools` より優先 |
| `model` | — | `sonnet` / `opus` / `haiku` / `fable` / フル ID / `inherit` | 優先順: 環境変数 `CLAUDE_CODE_SUBAGENT_MODEL` > Agent 呼び出し時の指定 > frontmatter > メイン会話のモデル |
| `permissionMode` | — | `default` / `acceptEdits` / `plan` / `dontAsk` / `auto` / `bypassPermissions` | `bypassPermissions` は原則使わない |
| `skills` | — | リスト | 起動時に preload する skill 名 |
| `maxTurns` | — | 整数 | 超過時は途中結果を返す |
| `isolation` | — | `worktree` | 独立した git worktree で実行 |
| `background` | — | `true` / `false` | `true` にすると利用できるツールが制限される |
| `effort` | — | `low` / `medium` / `high` / `xhigh` / `max` | 推論の深さ |
| `memory` | — | `user` / `project` / `local` | 永続メモリのスコープ |

## 本文（system prompt）に書くこと

- 役割・専門領域
- やること / やらないこと（特に破壊的操作の禁止）
- 作業手順
- ツール利用の方針
- 委任元に返す出力形式

## 本文に書かないこと

- Claude Code のシステムプロンプト全体や環境情報（自動で付与される）
- CLAUDE.md のルール（継承される）
- 個別タスクの内容（委任メッセージで渡される）

## 配置場所と優先順位（高 → 低）

1. Managed settings（組織全体）
2. `--agents` CLI フラグ（セッション限定）
3. `.claude/agents/`（プロジェクト。バージョン管理する）
4. `~/.claude/agents/`（個人用）
5. プラグインの `agents/`

同名の場合は上位が勝つ。

## 設計指針

- **最小権限**: 読み取り専用で済む役割に `Write` / `Edit` / `Bash` を与えない
- **description は具体的に**: 曖昧だと自動委任されない。逆に広すぎると無関係な依頼まで委任される
- **組み込み agent と被らせない**: 探索は `Explore`、計画は `Plan`、汎用は `general-purpose` で足りることが多い
- **出力形式を固定する**: 委任元が結果を機械的に扱えるようにする
