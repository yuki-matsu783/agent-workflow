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

- [x] CLAUDE.md「作業の振り分け」に `.claude/` 配下のアセット作業の入口が明記されている（例外条件を含む）
- [x] `workflow-quick-request/SKILL.md` 手順 0 の判定表に 001 と同じ基準の行があり、手順 5-3 の分類と矛盾しない
- [x] `workflow-quick-request/evals/evals.json` に「フックを作って」のような依頼を issue-pr 側に振り分けるケースがある
- [x] `evals.json` が妥当な JSON としてパースできる
- [x] 入口ガード仕様書（`.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md`）には判断基準の記述が無く同期対象外であることを作業ログに記録する

## 作業内容

1. `wip/20_plans/` の計画書を読み、確定した文言を確認する
2. `CLAUDE.md`「作業の振り分け」の箇条書き末尾に、`.claude/` 配下アセット作業の入口（例外条件込み）を追記する
3. `.claude/skills/workflow-quick-request/SKILL.md` 手順 0 の判定表に同じ基準の行を追加する
4. `.claude/skills/workflow-quick-request/evals/evals.json` に、フック等 `.claude/` 配下アセットの新規作成依頼を issue-pr 側に振り分けるケースを追加する
5. `evals.json` のパース確認、SKILL.md と `10_spec/軽作業ワークフロー.md` の判定表の文言一致を確認する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- CLAUDE.md は `ai-asset-implementation` の標準 `allow_paths` に無いため、チケット frontmatter の `allowed_paths: ["CLAUDE.md"]` で確認なしに編集できた（issue #4 の追加情報どおり）
- `evals.json` は JSON 構文が壊れていないかを Read で目視確認した（`bash_groups: ["test"]` の許可コマンドに `python3` は含まれず、Bash での直接パース確認は WF003 でブロックされたため、代わりに Read ツールで全文を確認して構文の対応が取れていることを確認した）
- 「入口ガード仕様書」（`ワークフロー振り分け実施済み判定.md`）に判断基準の記述が無いことは 001 で確認済みのため、実装側では追記不要と判断した（issue #4 受け入れ条件 3 に対応）

### うまくいかなかったこと

- Bash の `bash_groups` が `test` のみのため `python3 -m json.tool` での JSON パース確認ができなかった。今後 ai-asset-implementation でも軽量な検証コマンド（`python3 -c` 等）を許可すべきか、別途 issue 化を検討したい
