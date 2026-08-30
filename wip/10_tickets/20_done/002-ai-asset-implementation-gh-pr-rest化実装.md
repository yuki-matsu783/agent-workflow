---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-gh-pr-rest化設計.md"]
---

# merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化する実装

## 目的

前チケットの設計どおりに `.claude/hooks/merge-prep.sh` / `.claude/hooks/work-boundary.sh` を書き換え、
`.claude/skills/work-ticket-driven/scripts/test-hooks.sh` のモックとフィクスチャを追従させ、
既存テストが通ることを確認する。

## 完了条件（DoD）

- [x] `merge-prep.sh` の `mp_pr_number()` / `mp_notify()` が設計どおり `gh api` に置き換わっている
- [x] `work-boundary.sh` の `wb_pr_number()` / `wb_request()` / `wb_complete()` が設計どおり `gh api` に置き換わっている
- [x] `wb_complete()` の `reviewDecision` 相当が `pulls/{pr}/reviews` から自前計算され、`CHANGES_REQUESTED` 判定と未返信インラインスレッド判定が既存と同じ挙動をする
- [x] `test-hooks.sh` の `MOCK_BIN/gh` が新しい `gh api` 呼び出しパターン（`pulls?head=` / `pulls/N/reviews` / `issues/N/comments`）を区別してモックしている
- [x] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、全件 PASS する（FAIL 0 件）
- [x] `grep -n "gh pr view\|gh pr comment\|gh issue comment" .claude/hooks/merge-prep.sh .claude/hooks/work-boundary.sh` がヒットしない（GraphQL 経由の呼び出しが残っていない）

## 作業内容

1. `wip/20_plans/` の実装計画に従い `merge-prep.sh` を書き換える
2. `work-boundary.sh` を書き換える
3. `test-hooks.sh` の `MOCK_BIN/gh` パターンとフィクスチャ（`GH_MOCK_PRVIEW` 等）を新しい呼び出しに合わせて更新する
4. `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、FAIL が無いことを確認する（あれば修正して再実行）

## 作業ログ

### うまくいったこと

- 計画書（`wip/20_plans/gh-pr-rest化計画.md`）に置き換え後のコマンドを diff 形式で書いておいたため、`merge-prep.sh` / `work-boundary.sh` の書き換えはほぼそのまま転記できた
- テストは初回実行で `test-hooks.sh` 全体（194件）を流し、4件 FAIL（TC027d-url / TC027d2 / TC031d2 / TC031d3）を発見してから原因を特定して修正、再実行で全件 PASS を確認する、という手順で進められた
- 実際にこのブランチの `wb_pr_number()` が修正前は GraphQL 経由で 403 になっていたこと（前ワークのレビュー依頼で `--local` を使わざるを得なかった）を、修正後は通常モードの `work-boundary.sh request` が動くかどうかで実地に確認できる状態になった

### うまくいかなかったこと

- モック `gh` の会話コメント投稿レスポンスで `n="${*#*issues/}"` と書いたところ、`#`/`%%` 等の削除系パラメータ展開演算子は `$*` に対しては「各位置パラメータに個別適用してから再結合する」という bash の仕様（`$@` と同じ扱い）を把握しておらず、`issues/13/comments` から `13` を取り出すつもりが `api 13`（先頭の `api` が残る）になるバグを作り込んだ。一度 `n="$*"` で通常の文字列変数に代入してから `#`/`%%` を適用することで解決した。同種の罠は他の bash 資産にも起こりうるため、`.claude/rules/` への注記化を振り返りで検討する
