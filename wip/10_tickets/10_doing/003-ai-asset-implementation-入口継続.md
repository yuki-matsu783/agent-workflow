---
type: ai-asset-implementation
status: todo
depends_on: ["002-ai-asset-implementation-フック統一.md"]
allowed_paths: ["CLAUDE.md"]
---

# 入口ガードの継続ロジック + テスト + CLAUDE.md

## 目的

`workflow-entry.sh` に「`wip/10_tickets/00_todo/` または `10_doing/` にチケットがある間は issue-pr-driven-workflow の継続とみなし、宣言不要」のロジックを追加する。

## 完了条件（DoD）

- [ ] `workflow-entry.sh` に `WF_TICKET_ACTIVE_DIRS` と `wf_tickets_active()` があり、`guard` は `wf_declared || wf_tickets_active` で許可、継続時はログに `CONTINUE(ticket)` を残す
- [ ] `prompt` は継続中なら additionalContext を「継続中・宣言不要」の文言に切り替える
- [ ] `test-workflow-entry.sh` が `WF_ENTRY_SCRIPT` で対象スクリプトを差し替えられ、TE012（10_doing にチケット → 許可・継続中）、TE013（00_todo のみ → 継続）、TE014（20_done のみ → WF101）が追加されて全件パス
- [ ] CLAUDE.md「作業の入口」に継続ルールが追記されている
- [ ] 本セッションの次のプロンプトが `[WF-ENTRY] … 継続中` になり、Skill 未呼び出しで Edit が通る

## 作業内容

1. テストスクリプトに `WF_ENTRY_SCRIPT` 差し替えと TE012〜TE014 を追加する
2. 新版の `workflow-entry.sh` を scratchpad に Write し、`WF_ENTRY_SCRIPT` でテストを通す
3. 通ったら本体に Write で反映し、テストを再実行する
4. CLAUDE.md を追記する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
