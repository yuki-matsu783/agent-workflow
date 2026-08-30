---
name: work-ai-asset-implementation-plan
description: >
  AI アセット実装フェーズの計画ワーク。.claude/docs/ の仕様書をもとに、変更するフック・スキル・ルール・settings.json
  の一覧、テスト（.claude/hooks/tests/）の追加方針、実装ステップを実装計画書（wip/20_plans/）にまとめ、
  AI アセット実装チケット群と次の計画チケット（通常は振り返り）を起こす。チケット type は ai-asset-implementation-plan。
  Use when the user mentions "AI アセット実装の計画", "フック/スキルの実装計画", "ai asset implementation plan".
title: work-ai-asset-implementation-plan — AI アセット実装計画ワーク
type: skill
tags: [work-skill, ai-asset-implementation, plan-phase]
keywords: [AIアセット実装計画, ai-asset-implementation-plan, フック, スキル, settings.json, hooks/tests, テストID, 実装チケット, 振り返りチケット]
---

# work-ai-asset-implementation-plan — AI アセット実装計画ワーク

仕様書をアセット（フック・スキル・ルール・エージェント・`settings.json`）に落とすための**変更対象・テスト方針・ステップ**を決め、実装計画書を書き、AI アセット実装チケット群と次の計画チケットを起こす。アセット本体は書かない。

- 要件 / 仕様: `.claude/docs/00_requirements/フェーズ別ワークスキル.md` / `.claude/docs/10_spec/フェーズ別ワークスキル.md`
- チケット運用: `work-ticket-driven` の手順 3・5・5.5・6 とエラーハンドリング。本スキルは再掲しない

## 1. 位置づけ

| 項目 | 内容 |
|------|------|
| 前のワーク | `work-ai-asset-design-exec` |
| チケット type | `ai-asset-implementation-plan`（`wip/20_plans/**` に書ける） |
| 次のワーク | `work-ai-asset-implementation-exec`（type `ai-asset-implementation`） |
| ワーク境界 | 計画チケットが done になった時点。実装計画が人間レビューを受ける |

## 2. 入力

- 仕様書 `.claude/docs/10_spec/<名前>.md`（入出力・処理フロー・エラーコード・テストシナリオの TC 番号と置き場所）
- 要件定義書（制約条件: フック本体を変えない等）
- 既存アセットの構造（`.claude/hooks/*.sh` の関数構成、`workflow-types.json`、`.claude/hooks/tests/*.sh` のテストの書き方、`task-ai-asset-creator` のテンプレート）
- 全体計画（受け入れ条件との対応）

## 3. 成果物とテンプレート

| 成果物 | 作成先 | テンプレート |
|--------|--------|-------------|
| 実装計画書 | `wip/20_plans/AIアセット実装計画-<slug>.md` | `work-ticket-driven/assets/plan.template.md` をそのまま使う |
| AI アセット実装チケット群 | `wip/10_tickets/00_todo/0NN-ai-asset-implementation-<slug>.md`（1 枚以上） | `work-ticket-driven/assets/ticket.template.md` |
| 次の計画チケット | 通常 `0NN-retrospective-振り返り.md`（AI アセット実装はフェーズ列の最後） | 同上 |

## 4. 手順

### 4-1. 着手する

todo 先頭の `0NN-ai-asset-implementation-plan-…` を `work-ticket-driven` 手順 3 のとおり doing に移してコミットする。

### 4-2. 実装計画書を書く

`plan.template.md` を Read し、`wip/20_plans/AIアセット実装計画-<slug>.md` に Write する。書くこと:

- **変更対象ファイル**: アセットごとに新規 / 変更、パス、変更内容。種類（skill / rule / hook / agent / settings）と、作成に使うもの（`task-ai-asset-creator` の `init-asset.sh`・`skill-template`、既存スキルの型）
- **allowed_paths 案**: `ai-asset-implementation` type の標準（`.claude/hooks|rules|skills/**`、`.claude/settings.json`）で足りなければ書く。`CLAUDE.md` は標準に無いので、触るならチケットの `allowed_paths` に書く
- **テスト方針**: 仕様書の TC 番号をどのテストスクリプト（`.claude/hooks/tests/test-*.sh`。無ければ新設）に置くか、既存テストの回帰確認（`bash .claude/hooks/tests/*.sh` を全部回す）
- **実装ステップ**: 1 ステップ = テストが通る単位。順序は「type 定義 / 設定 → フック → テスト → スキル → 呼び出し元の参照更新 → evals」を基本にする
- **参照更新の一覧**: 新しいスキル名・type を参照すべき既存スキル（`workflow-*`・`work-ticket-driven`・`references/`・`assets/` のコメント）と `evals.json`
- **リスク・未解決事項**: フック自体を変えるときはロックアウト（フックの不具合で全ツールが止まる）への備え（`WORKFLOW_ENFORCE=0` はユーザー指示があるときだけ、`git checkout HEAD -- <hook>` での復旧手順）

### 4-3. チケットを起こす

1. AI アセット実装チケット群（`type: ai-asset-implementation`）。1 チケット = 1 アセット群（例: 「type 定義とテスト」「スキル 4 件」「呼び出し元と evals」）。DoD の型:
   ```markdown
   - [ ] <アセットのパス> が仕様書 <節> のとおり作成（変更）されている
   - [ ] テスト <TC 番号> が <テストスクリプト> に追加され、既存ケースとあわせて通る（bash .claude/hooks/tests/<name>.sh）
   - [ ] SKILL.md の frontmatter（name / description / title / type / tags / keywords）とテンプレートのプレースホルダが確認されている（スキルの場合）
   - [ ] 参照更新（<既存スキル・evals>）が済んでいる
   ```
2. 次の計画チケット: 通常は振り返り（`type: retrospective`）。フェーズ列に次があればその計画チケット

### 4-4. 完了する

計画チケットの DoD を確認し、`work-ticket-driven` 手順 5 のとおり done にしてコミットし、`work-boundary.sh status` で `at_boundary: true`・`todo_head_type: ai-asset-implementation` を確認して完了報告を返す。

計画チケットの DoD の型:

```markdown
- [ ] wip/20_plans/AIアセット実装計画-<slug>.md に変更対象・allowed_paths 案・テスト方針（TC 番号 → テストスクリプト）・実装ステップ・参照更新の一覧が書かれている
- [ ] AI アセット実装チケット N 枚が todo に起票され、各 DoD にテストと参照更新がある
- [ ] 次の計画チケット（通常は振り返りチケット）が todo に起票されている
```

## 5. レビュー観点

- 変更対象が仕様書と 1:1 で対応し、フック本体の変更の要否が要件の制約と一致しているか
- テスト方針が仕様書の TC 番号を網羅し、既存テストの回帰確認を含むか
- ステップの順序（設定 → フック → テスト → スキル → 参照更新）と 1 チケットの大きさ
- 参照更新の一覧に漏れがないか（`grep -rn <旧名 / 旧手順>` の結果を添える）
- フック変更時のロックアウト対策

## 6. 次のワークへの引き継ぎ

- 次に読み込まれるスキル: `work-ai-asset-implementation-exec`
- 渡すもの: 実装計画書と実装チケット群
- 差し戻し時は呼び出し元が `ai-asset-implementation-plan` type の追加チケットを起こす

## 7. エラーハンドリング

| 状況 | 対処 |
|------|------|
| `.claude/hooks/**` 等へ書こうとして WF002 で拒否された | 計画 type は `.claude/**` に書けない。実装チケットで書く |
| テストスクリプトを試しに動かしたくなった（WF003） | 計画 type に `test` グループは無い。既存テストは Read で把握し、実行は実装チケットで行う |
| 仕様書に TC 番号が無い | 設計の不備。仕様書の該当節を引用して計画書に TC の案を書き、レビュー観点で人間に示す（必要なら呼び出し元に `ai-asset-design` の追加チケットを提案） |

フックの WF001〜WF016 でブロックされたときの対処は `work-ticket-driven` のエラーハンドリングに従う。
