---
name: work-ai-asset-implementation-exec
description: >
  AI アセット実装フェーズの実施ワーク。実装計画書に従い、フック・スキル・ルール・エージェント・settings.json を
  task-ai-asset-creator のテンプレートと既存スキルの型で作成・変更し、フックのテスト（bash .claude/hooks/tests/*.sh）で
  確認する。チケット type は ai-asset-implementation。todo_head_type が ai-asset-implementation のときに呼ばれる。
  Use when the user mentions "AI アセットを実装", "フック/スキルを作って", "settings.json を更新して", "implement hook/skill".
title: work-ai-asset-implementation-exec — AI アセット実装実施ワーク
type: skill
tags: [work-skill, ai-asset-implementation, exec-phase]
keywords: [AIアセット実装実施, ai-asset-implementation, フック, スキル, settings.json, hooks/tests, bash_groups test, task-ai-asset-creator, 参照更新, ロックアウト]
---

# work-ai-asset-implementation-exec — AI アセット実装実施ワーク

実装計画書のステップに従って AI アセット実装チケットを順に実施する。アセットを作り、フックのテストを回し、既存スキルの参照と evals を更新する。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・4・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-ai-asset-implementation-plan` |
| チケット type | `ai-asset-implementation`（`.claude/hooks/**`、`.claude/rules/**`、`.claude/skills/**`、`.claude/settings.json` + チケットの `allowed_paths`。`bash_groups: test` でフックのテストスクリプトを実行できる。`.claude/skills/**` の `git mv` も可。`.claude/docs/**` は書けない） |
| 次のワーク | 通常は振り返り（`work-ticket-driven` 手順 4 の retrospective） |
| ワーク境界 | 実装チケットが全部 done になった時点。アセットとテストが人間レビューを受ける |

## 2. 入力

- 実装計画書 `wip/20_plans/AIアセット実装計画-<slug>.md`（変更対象・テスト方針・ステップ・参照更新の一覧）
- 実装チケット群（DoD にテストと参照更新）
- 仕様書 `.claude/docs/10_spec/<名前>.md`
- `task-ai-asset-creator`（`assets/skill-template/`、`hook.template.sh`、`rule.template.md`、`agent.template.md`、`scripts/init-asset.sh`）と型にする既存スキル

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート / 手順 |
|--------|--------|-------------------|
| スキル | `.claude/skills/<name>/SKILL.md`（+ `assets/`・`references/`・`evals/evals.json`） | `task-ai-asset-creator` 手順 2-1、または同層の既存スキルを型にする。frontmatter に `name` / `description` / `title` / `type: skill` / `tags` / `keywords` |
| フック | `.claude/hooks/<name>.sh` + `settings.json` の登録 | `task-ai-asset-creator` 手順 2-3。`workflow-lib.sh` の共通関数を使う |
| ルール / エージェント | `.claude/rules/<name>.md` / `.claude/agents/<name>.md` | `task-ai-asset-creator` 手順 2-2 / 2-4 |
| 設定 | `.claude/hooks/workflow-types.json`、`.claude/settings.json` | 既存の書式に追記 |
| テスト | `.claude/hooks/tests/test-<name>.sh` | 既存テスト（stdin JSON → exit code / 出力の検証、一時ディレクトリをプロジェクトルートに見立てる）と同じ形式 |
| 参照更新 | 既存スキルの SKILL.md・`references/`・`assets/` のコメント・`evals.json` | Edit |

## 4. 手順

### 4-1. チケットに着手する

todo 先頭の `0NN-ai-asset-implementation-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。`allowed_paths`（`CLAUDE.md` 等）が要るチケットか確認する。

### 4-2. 実装する

1. 計画書のステップ順（設定 → フック → テスト → スキル → 参照更新 → evals）に進める
2. フックを変えるときは、変更のたびにテストを回す（`bash .claude/hooks/tests/<name>.sh`。リダイレクトやパイプは付けない）。変更が自分自身のセッションを止める可能性がある（PreToolUse フックの構文エラー等）ため、小さく変えて都度テストする。止まったら `git checkout HEAD -- <hook>` で戻す（`WORKFLOW_ENFORCE=0` はユーザーの明示的な指示があるときだけ）
3. スキルは同層の既存スキルの節構成に揃える。description にトリガー語を複数入れる。テンプレートのプレースホルダ（山括弧内の日本語）を Grep で確認する
4. 参照更新: 計画書の一覧に従い、新しい名前・手順を参照すべき既存スキル・`references/`・`assets/` のコメント・`evals.json` を Edit する。`grep -rn <旧名>` で漏れを確認する
5. 仕様からの逸脱（仕様どおりに書けなかった、仕様に無い判断）は作業ログに書く。`.claude/docs/` は直さない（設計文書の更新は同 issue 内なら `ai-asset-design` の追加チケット、または振り返りの改善提案として残す）

### 4-3. チケットを完了し、境界を判定する

DoD（テストが通っている出力、プレースホルダ無し、参照更新済み）を確認し、`git status` で差分が許可パス内に収まっていることを見て、`work-ticket-driven` 手順 5 のとおり done にしてコミットする。`work-boundary.sh status` が `at_boundary: false` なら次の実装チケットへ（`git push` してよい）、`true` なら完了報告（作成・変更したアセット、テスト結果、参照更新の一覧、逸脱）を返して制御を戻す。

## 5. レビュー観点

- 仕様書の TC 番号がすべてテストとして存在し、既存ケースとあわせて通っているか（テストの出力）
- 差分が計画書の変更対象に収まっているか。フック本体を変えた場合、要件の制約と整合するか
- スキルの節構成・frontmatter・description のトリガー語が同層の既存スキルと揃っているか
- 参照更新に漏れがないか（旧名・旧手順の grep 結果）
- ヘッドレス実行時の挙動が仕様どおりか（`ask` を増やしていないか）

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-ticket-driven`（retrospective。`todo_head_type: retrospective`）
- 渡すもの: アセットの差分、テスト結果、参照更新の一覧、逸脱（結果報告の「うまくいかなかったこと」「改善提案」の入力）
- 差し戻し時は呼び出し元が `ai-asset-implementation` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `.claude/docs/**` への Edit が WF002 で拒否された | 実装では設計文書を直さない。逸脱として作業ログに書き、`ai-asset-design` の追加チケットまたは振り返りの改善提案にする |
| `CLAUDE.md` への Edit が WF009 で確認された | 計画でチケットの `allowed_paths` に入れておくのが原則。入れ忘れなら理由が明確な場合に限り承認し、作業ログに書く |
| テスト実行が WF003 で拒否された | 許可される形は `bash .claude/hooks/tests/<name>.sh` / `bash .claude/skills/<skill>/scripts/<name>.sh`（先頭の `VAR=value` は可）のみ。リダイレクト・パイプ・複合コマンドを外す |
| フックの変更で自分のセッションが止まった（全ツールがブロック） | `git checkout HEAD -- .claude/hooks/<hook>` で直前の状態に戻し、原因を作業ログに書いてから小さくやり直す |
| `.claude/skills/**` の `git mv` が WF003 で拒否された | `ai-asset-implementation` の doing 中のみ許可される。doing チケットの type を確認する。パスは引用符なし・リポジトリ相対で書く |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
