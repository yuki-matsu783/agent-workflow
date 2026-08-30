---
type: ai-asset-implementation
status: todo
depends_on: ["003-ai-asset-implementation-type定義とフックのテスト.md"]
---

# work-overall-plan スキルを作成する

## 目的

全体計画ワーク（フェーズ列の決定・全体計画の作成・最初の計画チケットの起票）を `work-overall-plan` スキルとして作る。以降の 12 スキルの SKILL.md の型をここで確定する。

## 完了条件（DoD）

- [ ] `.claude/skills/work-overall-plan/SKILL.md` が仕様書「SKILL.md の節構成」どおりに作成され、frontmatter に `name` / `description` / `title` / `type: skill` / `tags` / `keywords` がある
- [ ] フェーズ列の選び方（ソフトウェア変更 / AI アセット / 省略可のフェーズ）と、全体計画の書式（対象 issue・PR・フェーズ列・各フェーズの狙い）が書かれている
- [ ] `overall-plan` type のチケットの起こし方と、最初の計画ワークのチケット 1 枚を起こす手順が書かれている
- [ ] レビュー観点（人間が全体計画で確認する点）が書かれている
- [ ] `evals/evals.json` に 2 件以上のケースがある
- [ ] `grep -n '<[^>]*>' SKILL.md` でテンプレートのプレースホルダが残っていない

## 作業内容

1. `task-ai-asset-creator` の skill 作成手順と `assets/skill-template/SKILL.md` を読む
2. 仕様書の節構成で SKILL.md を書く
3. 必要なら `assets/overall-plan.template.md` を置く（仕様書のテンプレート方針に従う）
4. evals を書く

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
