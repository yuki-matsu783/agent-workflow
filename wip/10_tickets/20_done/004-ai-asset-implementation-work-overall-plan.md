---
type: ai-asset-implementation
status: todo
depends_on: ["003-ai-asset-implementation-type定義とフックのテスト.md"]
---

# work-overall-plan スキルを作成する

## 目的

全体計画ワーク（フェーズ列の決定・全体計画の作成・最初の計画チケットの起票）を `work-overall-plan` スキルとして作る。以降の 12 スキルの SKILL.md の型をここで確定する。

## 完了条件（DoD）

- [x] `.claude/skills/work-overall-plan/SKILL.md` が仕様書「SKILL.md の節構成」どおり（1 位置づけ〜7 エラーハンドリング）に作成され、frontmatter に `name` / `description` / `title` / `type: skill` / `tags` / `keywords` がある
- [x] フェーズ列の選び方（ソフトウェア変更 / AI アセット / 省略の目安）と、全体計画の書式（対象 issue・PR・フェーズ列・狙い・受け入れ条件との対応）が書かれている（手順 4-2・4-3、`assets/overall-plan.template.md`）
- [x] `overall-plan` type のチケットの起こし方（4-1）と、最初の計画ワークのチケット 1 枚を起こす手順（4-4）が書かれている
- [x] レビュー観点（人間が全体計画で確認する点）が書かれている（節 5）
- [x] `evals/evals.json` に 4 件のケースがある
- [x] 山括弧内に日本語を含むプレースホルダが残っていない（`<phase>` / `<slug>` / `#N <url>` は記法として意図的に使用）

## 作業内容

1. `task-ai-asset-creator` の skill 作成手順と `assets/skill-template/SKILL.md` を読む
2. 仕様書の節構成で SKILL.md を書く
3. 必要なら `assets/overall-plan.template.md` を置く（仕様書のテンプレート方針に従う）
4. evals を書く

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- 仕様書の節構成（7 節）をそのまま見出しにし、チケット運用の手順は `work-ticket-driven` の手順番号で参照する形にしたので、SKILL.md が薄く保てた（005〜007 の型として流用できる）
- 「既存の全体計画があるとき」（プランモード成果物・再開）を冪等に扱う手順をエラーハンドリング表に置き、evals id 2 で固定した
- 全体計画テンプレートはプランモードの出力と同じ `type: plan` にし、`plansDirectory` の運用と衝突しない

### うまくいかなかったこと

- 既存 SKILL.md には OKF frontmatter（`title` / `type` / `tags` / `keywords`）を付けた前例が無かった。ルール `markdown-frontmatter.md` に従い新スキルには付けるが、既存スキルとの不揃いは #37 の整理に委ねる
- DoD の `grep -n '<[^>]*>'` は `<phase>` 等の記法にも一致するため、検査は「山括弧内に日本語を含むもの」に読み替えた
