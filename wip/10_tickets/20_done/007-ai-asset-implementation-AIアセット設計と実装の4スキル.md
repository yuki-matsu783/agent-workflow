---
type: ai-asset-implementation
status: todo
depends_on: ["006-ai-asset-implementation-実装テストと設計反映の4スキル.md"]
---

# AI アセット設計・実装の計画 / 実施スキル（4 件）を作成する

## 目的

`work-ai-asset-design-plan` / `work-ai-asset-design-exec` / `work-ai-asset-implementation-plan` / `work-ai-asset-implementation-exec` を作成し、既存の `ai-asset-design` → `ai-asset-implementation` の運用を型にする。

## 完了条件（DoD）

- [x] 4 スキルの `SKILL.md` が作成され、節構成（1〜7）・frontmatter が `work-overall-plan` と揃っている
- [x] `work-ai-asset-design-exec` の成果物が `.claude/docs/`（要件・仕様・用語辞書・横断文書）で、`task-requirements` / `task-spec` を使う旨が書かれている
- [x] `work-ai-asset-implementation-exec` の成果物がフック・ルール・スキル・`settings.json` で、`task-ai-asset-creator` を使う旨とフックのテスト実行（`bash_groups: test`。リダイレクト・パイプ不可）、ロックアウト時の復旧が書かれている
- [x] 各スキルにレビュー観点（節 5）と次ワークへの引き継ぎ（節 6）が書かれている
- [x] 各 `evals/evals.json` に 2〜3 件のケースがある
- [x] 山括弧内に日本語を含むプレースホルダが残っていない（DoD の型の `<アセットのパス>` 等は記法）

## 作業内容

1. 005・006 のスキルを型として読む
2. 4 スキルを作成する
3. evals を書く

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- この issue 自身（001〜002 で `.claude/docs/` を書き、003〜 でアセットを作る）の作業ログをそのまま型にできた。特に「リダイレクト・パイプ付きのテスト実行が WF003 で弾かれる」「`.claude/docs/` を実装中に直せない」「`CLAUDE.md` は `allowed_paths` が要る」は実際に踏んだ手順を evals に落とした
- 実装計画の「参照更新の一覧」と「ロックアウト対策」（フックの不具合で全ツールが止まる → `git checkout HEAD -- <hook>`）をレビュー観点に含め、メモリに残っていた教訓をスキル側に移した
- AI アセット設計の計画に「1:1:1 原則（#37）との整合」を観点として入れ、後続 issue で文書の置き方を迷わないようにした

### うまくいかなかったこと

- `ai-asset-implementation` の実施ワークで仕様の不備に気付いても `.claude/docs/` を直せない（設計 → 実装の分離の代償）。同 issue 内で `ai-asset-design` の追加チケットを起こす経路をエラーハンドリングに書いたが、その場合 type が交互になりレビュー往復が増える。振り返りで残課題にする
