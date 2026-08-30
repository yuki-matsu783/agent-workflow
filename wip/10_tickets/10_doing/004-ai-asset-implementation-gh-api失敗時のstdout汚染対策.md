---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-implementation-gh-pr-rest化実装.md"]
---

# gh api 失敗時に stdout へ漏れるエラー JSON への対策

## 目的

002 の実装後、このセッション自身（`gh api` が到達できない実行環境）で `work-boundary.sh request`
を通常モードで実行したところ、`gh api ... --jq '...'` が失敗すると `gh pr view`（GraphQL 版）とは異なり
エラー JSON を**stdout に**出力することが判明した（`gh pr view` は失敗時 stderr のみ）。既存の
`2>/dev/null` は stderr しか捨てないため、`mp_pr_number()` / `wb_pr_number()` はエラー JSON をそのまま
PR 番号として返し、後続の `gh api .../issues/<壊れたPR番号>/comments` の URL 構築が破綻する形で
初めて症状が表面化した（`Post "...％7B%22message%22...": unsupported protocol scheme ""`）。

`wb_complete()` の `reviews` / `comments` / `inl` 取得も同じ理由で `[ -n "..." ]` だけを成功判定に
使っており、失敗時にエラー JSON を正常データとして扱ってしまう（jq 処理でサイレントに空扱いになり、
「取得できなかった」のに「指摘なし」と誤判定しかねない）。

## 完了条件（DoD）

- [ ] `mp_pr_number()` / `wb_pr_number()` が `gh api` の終了コードを確認し、失敗時は出力を使わず空文字列を返す
- [ ] `mp_notify()` の PR 本文取得が `gh api` の終了コードを確認し、失敗時は空扱いにする
- [ ] `wb_complete()` の `reviews` 取得が `gh api` の終了コードを確認し、失敗時は `wb_die WF014` する（既存の空文字列チェックだけの判定から変更）
- [ ] `wb_complete()` の `comments` / `inl` 取得も終了コードを確認し、失敗時は `wb_die WF014` する（成功かつ空配列のときだけ `"[]"` 扱いにする。失敗を「コメント無し」に読み替えない）
- [ ] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件 PASS する

## 作業内容

1. `merge-prep.sh` の `mp_pr_number()` / `mp_notify()` に終了コード確認を追加する
2. `work-boundary.sh` の `wb_pr_number()` / `wb_complete()` に終了コード確認を追加する
3. `test-hooks.sh` を実行し、既存テストが壊れていないことを確認する（挙動を変える箇所があればフィクスチャを追従させる）

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
