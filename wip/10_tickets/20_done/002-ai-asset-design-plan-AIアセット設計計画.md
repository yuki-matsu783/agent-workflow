---
type: ai-asset-design-plan
status: todo
depends_on: ["001-overall-plan-全体計画.md"]
---

# AI アセット設計計画: git add の対象を許可パスに限定する規約を仕様書に書く

## 目的

全体計画（wip/00_overall_plan/skill-git-add-paths.md）のフェーズ 1 として、仕様書 `.claude/docs/10_spec/チケット駆動ワークフロー.md` のどの節に「チケット運用のコミットでは `git add` の対象を `wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` 全体を指定しない」規約を書くかを決め、要件定義書・用語辞書への影響を確認して、AI アセット設計チケットと次の計画チケットを起こす。

## 完了条件（DoD）

- [x] wip/20_plans/AIアセット設計計画-skill-git-add-paths.md に結論方針・文書の一覧と骨子・横断文書との整合・受け入れ条件との対応が書かれている
- [x] AI アセット設計チケット 1 枚（003-ai-asset-design-チケット駆動ワークフロー仕様書の更新.md）が todo に起票され、DoD が仕様書の骨子 (a)〜(d) と対応している
- [x] 次の計画チケット（004-ai-asset-implementation-plan-AIアセット実装計画.md）が todo に起票されている

## 作業内容

1. `.claude/docs/10_spec/チケット駆動ワークフロー.md` の「チケット運用コマンド」「WF009」「work-ticket-driven の手順」に当たる節を読み、規約を書く節を決める
2. `.claude/docs/00_requirements/` と `.claude/docs/90_glossary/` に影響があるか確認する
3. 設計計画書を書き、設計チケットと次の計画チケットを起こす

## 作業ログ

### うまくいったこと

- 影響範囲を仕様書 1 本（`.claude/docs/10_spec/チケット駆動ワークフロー.md`）に絞れた。要件定義書は `git add` の対象に触れておらず、用語辞書・`フェーズ別ワークスキル.md`・横断文書にも記述なし（grep で確認）
- 規約の置き場所を「Bash コマンドの許可」の allowlist 定義と「処理フロー」3・6 の両方に決めた（手順書だけ読んで再び `git add wip/` を書かないため）
- 受け入れ条件④を TC022b / TC022c として再現可能なテストに落とす方針にした（実装は AI アセット実装フェーズ）

### うまくいかなかったこと

- 特になし。フック本体・type 定義の変更は不要と確定（`wip/` を allow にすると global deny の `wip/00_overall_plan/**` を貫通するため不可）
