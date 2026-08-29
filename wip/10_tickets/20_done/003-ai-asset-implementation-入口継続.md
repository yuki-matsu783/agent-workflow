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

- [x] `workflow-entry.sh` に `WF_TICKET_ACTIVE_DIRS` と `wf_tickets_active()` があり、`guard` は `wf_declared || wf_tickets_active` で許可、継続時はログに `CONTINUE(ticket)` を残す
- [x] `prompt` は継続中なら additionalContext を「継続中・宣言不要」の文言に切り替える
- [x] `test-workflow-entry.sh` が `WF_ENTRY_SCRIPT` で対象スクリプトを差し替えられ、TE012（10_doing にチケット → 許可・継続中）、TE013（00_todo のみ → 継続）、TE014（20_done のみ / .gitkeep のみ → WF101）が追加されて全件パス（40 件）
- [x] CLAUDE.md「作業の入口」に継続ルールが追記されている
- [ ] 本セッションの次のプロンプトが `[WF-ENTRY] … 継続中` になり、Skill 未呼び出しで Edit が通る（次のユーザープロンプトで確認する。004 の着手時に結果を記録）

## 作業内容

1. テストスクリプトに `WF_ENTRY_SCRIPT` 差し替えと TE012〜TE014 を追加する
2. 新版の `workflow-entry.sh` を scratchpad に Write し、`WF_ENTRY_SCRIPT` でテストを通す
3. 通ったら本体に Write で反映し、テストを再実行する
4. CLAUDE.md を追記する

## 作業ログ

### うまくいったこと

- 本体を直接編集する方針（ユーザー判断）に合わせ、全文置換ではなく 6 箇所の小さな Edit に分割し、各断片が単独でも構文的に完結するよう順序を決めた（定数 → 関数 → prompt 分岐 → guard 分岐 → 文言）。途中状態でも `wf_tickets_active` 未定義は「偽」として安全側に倒れる
- 002 で追加した `bash_groups: ["test"]` のおかげで、統制下のまま `bash .claude/hooks/tests/test-workflow-entry.sh` を回せた
- `wf_tickets_active` は `for f in dir/*.md; [ -e "$f" ]` で nullglob に依存せず判定できる

### うまくいかなかったこと

- 計画では新版を scratchpad（リポジトリ外）に書いてから検証する手順だったが、ユーザーから「なぜそのパスに作るのか」と指摘された。理由（保存した瞬間から本セッションに効く・構文エラー時の復旧手段が無い）を計画に書いていたが、Write の直前に改めて説明すべきだった。結果として本体直接編集で進めた
- DoD の最後の項目（実セッションでの継続確認）は、このチケット内では検証できない（次のユーザープロンプトが必要）。チケットの DoD として「次のプロンプト」に依存する項目を置くのは設計として弱い
