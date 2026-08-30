---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-git-add-allow-list-仕様更新.md"]
---

# 実装: wf_validate_add を wf_validate_mv と同様のハードコード判定に揃える

## 目的

`.claude/hooks/workflow-guard.sh` の `wf_validate_add` を、`wip/10_tickets/*` については `wf_validate_mv` と同様に `workflow-types.json` を経由せず常に許可するよう実装し、動作確認する。

## 完了条件（DoD）

- [ ] `git add wip/10_tickets/**` が、`workflow-types.json` の `global.allow_paths` の内容（削除・上書き含む）に関わらず常に allow になる
- [ ] `wip/10_tickets/` 以外の対象パスを含む `git add`（例: `git add wip/10_tickets/10_doing/x.md src/foo.js`）の挙動が変わっていない（`src/foo.js` 側は従来どおり `wf_resolve` 判定を受ける）
- [ ] 既存 `bash .claude/hooks/tests/test-workflow-entry.sh` が通る
- [ ] `wip/10_tickets/**` の常時許可を検証する確認手順（自動テストまたは手動確認コマンド）を実施し、結果を作業ログに残す
- [ ] 001 で更新した仕様書の記述と実装が一致している
- [ ] `.claude/skills/work-ticket-driven/references/permission-matrix.md` の `git add`（77行目付近）の記述を、実装後の挙動（`wip/10_tickets/` 配下同士は無条件許可）に合わせて修正する

## 作業内容

1. `.claude/hooks/workflow-guard.sh` の `wf_validate_mv`（146-163行目）と `wf_validate_add`（166-181行目）を読み比べる
2. `wf_validate_add` 内のトークン判定に、`wip/10_tickets/*` に一致するパスを `wf_resolve` を呼ばず即座に allow 扱いにする分岐を追加する（`wf_validate_mv` と共通化できる場合は小さなヘルパー関数に切り出す）
3. `bash .claude/hooks/tests/test-workflow-entry.sh` を実行し、既存挙動が壊れていないことを確認する
4. `workflow-types.json` の `global.allow_paths` を一時的に空にする、または `PreToolUse` フックへの疑似入力で `git add wip/10_tickets/10_doing/x.md` を実行し、allow されることを手動確認する（確認用に一時変更した設定は元に戻す）
5. `.claude/skills/work-ticket-driven/references/permission-matrix.md` の `git add` の記述を実装内容に合わせて Edit で修正する
6. 確認した内容と結果を作業ログに記録する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
