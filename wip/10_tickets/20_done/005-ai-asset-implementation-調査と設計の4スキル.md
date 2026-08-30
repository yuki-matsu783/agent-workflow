---
type: ai-asset-implementation
status: todo
depends_on: ["004-ai-asset-implementation-work-overall-plan.md"]
---

# 調査・設計の計画 / 実施スキル（4 件）を作成する

## 目的

`work-investigation-plan` / `work-investigation-exec` / `work-design-plan` / `work-design-exec` を、004 で確定した SKILL.md の型に合わせて作成する。

## 完了条件（DoD）

- [x] 4 スキルの `SKILL.md` が作成され、節構成（1〜7）・frontmatter が `work-overall-plan` と揃っている
- [x] 計画スキルに「同フェーズの実施チケット群 + 次フェーズの計画チケット 1 枚を起こす」手順（連鎖方式。手順 4-3）と、最後のフェーズなら振り返りチケットを起こす旨が書かれている
- [x] `work-design-exec` の成果物が `docs/**`（`docs/00_requirements/`・`docs/10_spec/` を推奨）で、`task-requirements` / `task-spec` を使う旨が書かれている
- [x] 各スキルにレビュー観点（節 5）と次ワークへの引き継ぎ（節 6）が書かれている
- [x] 各 `evals/evals.json` に 2 件のケースがある
- [x] 山括弧内に日本語を含むプレースホルダが残っていない（`<slug>` / `<next>` / `<問い>` 等は記法）

## 作業内容

1. `work-overall-plan/SKILL.md` を型として読む
2. 4 スキルを作成する
3. evals を書く

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- 計画スキルは「計画書に書くこと」「起こすチケットと DoD の型」「計画チケット自身の DoD の型」の 3 点を型にし、実施スキルは「チケットごとの作業」「境界判定で次へ / 戻す」の 2 点に絞れた。006・007 も同じ構成で書ける
- 実施ワークで「やってはいけないこと」（調査でコードを直す、設計で型定義を書く）を evals の id 1 に入れ、フェーズ逸脱を弾く挙動を固定した
- `plan.template.md` の節の読み替え（「実装ステップ」= チケット一覧、「変更対象ファイル」= 設計書一覧）を各スキルの成果物表に明記し、専用テンプレートを増やさずに済んだ

### うまくいかなかったこと

- `docs/` の構成（`00_requirements` / `10_spec`）はリポジトリに実体が無いため「推奨」止まり。既存構成があればそれに従う、という逃げ道を `work-design-plan` に書いたが、実プロジェクトで最初に使うときに決める必要がある
