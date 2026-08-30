---
type: overall-plan
status: todo
depends_on: []
---

# 全体計画: スキル手順の git add wip/ を許可パスに揃える（#47）

## 目的

issue #47（`work-ticket-driven` / `work-overall-plan` の手順にある `git add wip/` が WF009 の確認を毎チケット発生させる）に対し、使うフェーズ列を決めて全体計画を書き、最初の計画チケットを起こす。

## 完了条件（DoD）

- [x] 全体計画 wip/00_overall_plan/skill-git-add-paths.md にフェーズ列・省略理由・受け入れ条件との対応が書かれている
- [x] 最初の計画チケット 002-ai-asset-design-plan-AIアセット設計計画.md が todo に起票されている

## 作業内容

1. 依頼の種類（AI アセットの変更）から標準フェーズ列を選び、省略するフェーズと理由を決める
2. 全体計画を `assets/overall-plan.template.md` から Write する
3. 最初の計画チケットを 1 枚だけ起こす

## 作業ログ

### うまくいったこと

- AI アセットの標準フェーズ列から調査を省略（発端の軽作業で原因・該当箇所・フック判定の妥当性を確認済み）し、AI アセット設計 → AI アセット実装 → 振り返り の 3 フェーズに決めた
- 受け入れ条件①〜④をフェーズと成果物に 1 対 1 で対応づけた（③ = 仕様書 / ①② = SKILL.md / ④ = 振り返りの結果報告）

### うまくいかなかったこと

- 本ワークの手順書（work-overall-plan 4-1・4-5）自体が `git add wip/` を指示しており、そのまま実行すると WF009 の確認が出る（この issue の対象そのもの）。チケットのコミットでは `git add wip/10_tickets/ wip/00_overall_plan/` と許可パスを明示して回避した
