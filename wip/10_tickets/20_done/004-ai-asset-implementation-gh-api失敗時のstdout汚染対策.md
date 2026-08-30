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

- [x] `mp_pr_number()` / `wb_pr_number()` が `gh api` の終了コードを確認し、失敗時は出力を使わず空文字列を返す
- [x] `mp_notify()` の PR 本文取得が `gh api` の終了コードを確認し、失敗時は空扱いにする
- [x] `wb_complete()` の `reviews` 取得が `gh api` の終了コードを確認し、失敗時は `wb_die WF014` する（既存の空文字列チェックだけの判定から変更）
- [x] `wb_complete()` の `comments` / `inl` 取得も終了コードを確認し、失敗時は `wb_die WF014` する（成功かつ空配列のときだけ `"[]"` 扱いにする。失敗を「コメント無し」に読み替えない）
- [x] `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件 PASS する

## 作業内容

1. `merge-prep.sh` の `mp_pr_number()` / `mp_notify()` に終了コード確認を追加する
2. `work-boundary.sh` の `wb_pr_number()` / `wb_complete()` に終了コード確認を追加する
3. `test-hooks.sh` を実行し、既存テストが壊れていないことを確認する（挙動を変える箇所があればフィクスチャを追従させる）

## 作業ログ

### うまくいったこと

- この不具合は自分でモックを書いたユニットテストでは検出できず、002 完了後にこのセッション自身で
  実際の `gh api` を通常モードで叩いて初めて発見できた。「テストが通る」＝「実環境で動く」ではないことを
  再確認する良い機会になった
- 修正は `2>/dev/null` によるエラー抑制を「終了コードの確認」に置き換えるだけの局所的な変更で、
  既存のテスト構造（`test-hooks.sh` のモック `gh` は常に exit 0 を返す設計）を変えずに対応できた
  （`GH_MOCK_NO_PR=1` のケースのみ `pulls?head=` パターンで `exit 1` を返すよう既に用意されていたため、
  `mp_pr_number` / `wb_pr_number` の新しい終了コード確認はこの既存フィクスチャでそのまま検証できた）

### うまくいかなかったこと

- 当初 `wb_complete()` の `reviews` / `comments` / `inl` 取得失敗を再現するモックのバリエーションを
  追加していなかったが、目視レビューだけでは不安が残ったため `GH_MOCK_FAIL_REVIEWS` /
  `GH_MOCK_FAIL_COMMENTS` / `GH_MOCK_FAIL_INLINE`（該当エンドポイントだけエラー JSON を stdout に出して
  `exit 1` する）をモックに追加し、TC028d〜f として実際に WF014 で止まること・`review_state` が
  `requested` のまま進まないことを検証した（202 PASS）。失敗を戻すのに `write_state` ヘルパーで
  `requested` 状態へ都度リセットする必要があり、後続の merge-prep テスト（TC029〜）が前提とする
  `completed` 状態への復帰（TC028g）を忘れずに挟む必要があった
