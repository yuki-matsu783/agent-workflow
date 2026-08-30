---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-アセット作業振り分け基準.md"]
allowed_paths: ["CLAUDE.md"]
---

# アセット作業振り分け基準（実装）

## 目的

001 の計画書に従い、CLAUDE.md「作業の振り分け」・`workflow-quick-request/SKILL.md` 手順 0 の判定表・`evals/evals.json` に `.claude/` 配下アセット作業の振り分け基準を反映する（issue #4）。

## 完了条件（DoD）

- [ ] CLAUDE.md「作業の振り分け」に `.claude/` 配下のアセット作業の入口が明記されている（例外条件を含む）
- [ ] `workflow-quick-request/SKILL.md` 手順 0 の判定表に 001 と同じ基準の行があり、手順 5-3 の分類と矛盾しない
- [ ] `workflow-quick-request/evals/evals.json` に「フックを作って」のような依頼を issue-pr 側に振り分けるケースがある
- [ ] `evals.json` が妥当な JSON としてパースできる
- [ ] 入口ガード仕様書（`.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md`）には判断基準の記述が無く同期対象外であることを作業ログに記録する

## 作業内容

1. `wip/20_plans/` の計画書を読み、確定した文言を確認する
2. `CLAUDE.md`「作業の振り分け」の箇条書き末尾に、`.claude/` 配下アセット作業の入口（例外条件込み）を追記する
3. `.claude/skills/workflow-quick-request/SKILL.md` 手順 0 の判定表に同じ基準の行を追加する
4. `.claude/skills/workflow-quick-request/evals/evals.json` に、フック等 `.claude/` 配下アセットの新規作成依頼を issue-pr 側に振り分けるケースを追加する
5. `evals.json` のパース確認、SKILL.md と `10_spec/軽作業ワークフロー.md` の判定表の文言一致を確認する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
