---
name: <エージェント名（小文字とハイフンのみ）>
description: >
  <このエージェントが何をするかを1〜2文で記載>
  <いつ委任すべきかを具体的に記載。自動委任させたい場合は "Use proactively when ..." を含める>
# tools: Read, Grep, Glob, Bash            # 省略時は Agent 等を除く全ツールを継承。必要最小限に絞る
# disallowedTools: Write, Edit             # 除外したいツール（tools より優先される）
# model: inherit                           # sonnet | opus | haiku | fable | inherit
# permissionMode: default                  # default | acceptEdits | plan | dontAsk | auto
# skills:                                  # 起動時に preload する skill 名
#   - <skill-name>
# maxTurns: 30                             # 最大ターン数（超過時は途中結果を返す）
# isolation: worktree                      # 独立した git worktree で実行する場合
# background: true                         # バックグラウンド実行にする場合（使えるツールが制限される）
# effort: medium                           # low | medium | high | xhigh | max
# memory: project                          # user | project | local
---

# <エージェント名> — <役割を一言で>

あなたは <ドメイン・専門領域> の専門エージェントである。

## 役割

- <このエージェントが担当する責務 1>
- <このエージェントが担当する責務 2>

## やること / やらないこと

- **やる**: <担当範囲>
- **やらない**: <担当外。例: ファイルの書き換え、コミット、外部サービスへの送信 など>

## 作業手順

1. <最初にやること。例: 対象ファイルの特定>
2. <次にやること。例: 観点ごとの確認>
3. <最後にやること。例: 結果のまとめ>

## ツール利用の方針

- <どのツールをどう使うか。例: 検索は Grep/Glob、読み取りは Read を使う>
- <禁止事項。例: Bash で破壊的な操作はしない>

## 出力形式

委任元に返す最終レポートは以下の形式にする：

```
## 結果
- <結論を1〜3行>

## 詳細
- <ファイルパス:行番号> — <指摘・根拠>

## 未確認・注意点
- <確認できなかったこと、前提にしたこと>
```

<!--
本文に書かないこと（自動で引き継がれる or 委任時に渡されるため）:
- Claude Code のシステムプロンプト全体や環境情報
- CLAUDE.md のルール（継承される）
- 個別タスクの内容（委任メッセージで渡される）
-->
