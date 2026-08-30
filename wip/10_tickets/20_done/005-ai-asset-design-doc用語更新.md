---
type: ai-asset-design
status: todo
depends_on: ["004-ai-asset-implementation-チケット駆動分解.md"]
---

# `.claude/docs/**` に残る旧スキル名（ticket-driven-workflow 等）の更新

## 目的

003・004 は `ai-asset-implementation` type（`.claude/hooks/**`・`.claude/rules/**`・`.claude/skills/**` のみ許可）で実施したため、`.claude/docs/**`（`ai-asset-design` type専用）に残る旧スキル名の言及を更新できなかった。本チケットでその残りを解消する。

## 完了条件（DoD）

- [x] `.claude/docs/10_spec/ワークフロー入口ガード.md`、`.claude/docs/10_spec/issue-PR駆動ワークフロー.md`、`.claude/docs/00_requirements/issue-PR駆動ワークフロー.md`、`.claude/docs/00_requirements/チケット駆動ワークフロー.md`、`.claude/docs/00_requirements/スキル体系.md` 内の `ticket-driven-workflow` 言及が `work-ticket-driven` に更新されている
- [x] 同様に `issue-pr-driven-workflow` / `light-task-workflow` / `gh-issue` / `gh-feature` / `gh-install` / `ai-asset-creator` の残存を新名称に更新した
- [x] grep で残存を再確認した。`.claude/docs/10_spec/スキル体系.md` と `00_requirements/スキル体系.md` は旧名称→新名称の**対応表そのもの**であり、旧名称列は仕様として残す（意図的）。それ以外のファイルに裸の旧名称は残っていない（`task-gh-issue` 等のprefix付き文字列内の部分一致による誤検知を除く）

## 作業内容

1. `.claude/docs/**` 配下を Grep で旧名称の残存を洗い出す
2. 見つかった箇所を Edit で新名称に更新する
3. 更新後に再度 Grep して残存が無いことを確認する

## 作業ログ

### うまくいったこと

- 003・004 の型制約（`ai-asset-implementation` は `.claude/docs/**` を触れない）に気づけたのは003完了後の実地検証のおかげ。計画外だったが、チケット挿入・番号繰り下げで対応できた
- 各仕様書のレビュー記録に更新履歴を追記した（002で相互参照を追加した際に記録漏れがあった `チケット駆動ワークフロー.md` の分もあわせて追記）

### うまくいかなかったこと

- DoD の「grep 結果が空になる」は、対応表ファイル自体（旧名称を列挙している）があるため厳密には成立しない。DoD の書き方が甘かった。実施時に「対応表は対象外」と補足して対応した
