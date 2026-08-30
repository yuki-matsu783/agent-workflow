---
type: ai-asset-implementation
status: todo
depends_on: ["010-ai-asset-implementation-work-ticket-driven分割.md"]
---

# workflow-issue-mr-driven のワークループ化とブランチ命名規約変更

## 目的

`workflow-issue-mr-driven` の手順5・6を、work（チケットtype）完了ごとにpush・PR本文更新・レビュー依頼・ターン終了、次発言でのコメント取得・再実行を行うループに改稿する。あわせてブランチ命名規約をハイフン区切りに変更する。

## 完了条件（DoD）

- [ ] `workflow-issue-mr-driven/SKILL.md`の手順5が、「初回のみ全体計画+チケット作成→以降はworkループ」に改稿されている
- [ ] workループの各ステップ（push→PR本文更新→レビュー依頼投稿→チャット報告してターン終了→次発言でコメント取得→指摘があれば同typeの追加チケットを作らせて再実行）が明記されている
- [ ] 手順6が「PR ready化の確認（承認③）専用」に縮小されている
- [ ] 命名規約表が `<prefix>-<N>-<slug>` に更新されている
- [ ] ヘッドレス実行時の扱い（type完了時点で応答が終わり、続きは次回セッションになることを許容する）がエラーハンドリングまたは専用節に明記されている
- [ ] `workflow-issue-mr-driven/assets/issue-addendum.template.md`のブランチ名記入例がハイフン区切りに更新されている
- [ ] `workflow-issue-mr-driven/evals/evals.json`のブランチ名期待値がハイフン区切りに更新され、「type完了直後のレビュー依頼」「レビュー完了後のコメント取得・再実行」の新規ケースが追加されている
- [ ] `task-gh-feature/SKILL.md`のissue連携モード入力表（242行目付近）のブランチ名例のみハイフン区切りに更新されている（単独モードの一般ガイドは変更しない）
- [ ] `bash .claude/hooks/tests/test-workflow-entry.sh` が無改修のまま全件パスする

## 作業内容

1. 009・010の成果物（改訂済み仕様書・work-ticket-driven新手順）を読む
2. `workflow-issue-mr-driven/SKILL.md`を改訂する（手順5・6・命名規約表・エラーハンドリング）
3. `workflow-issue-mr-driven/assets/issue-addendum.template.md`を更新する
4. `workflow-issue-mr-driven/evals/evals.json`を更新する
5. `task-gh-feature/SKILL.md`のissue連携モード入力表を更新する
6. `bash .claude/hooks/tests/test-workflow-entry.sh`を実行し、無改修で通ることを確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
