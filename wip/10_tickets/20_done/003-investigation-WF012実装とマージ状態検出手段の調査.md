---
type: investigation
status: todo
depends_on: ["002-investigation-plan-調査計画.md"]
---

# WF012実装とマージ状態検出手段の調査

## 目的

`workflow-boundary.sh` のWF012実装を把握し、`MERGE_HEAD`等によるマージ進行中の機械的検出の信頼性・検出範囲を調べる。

## 完了条件（DoD）

- [x] 調査観点「WF012実装」「MERGE_HEAD検出の信頼性」「検出範囲（MERGE_HEAD/CHERRY_PICK_HEAD等）」に対する答えが wip/20_plans/調査結果-conflict-wf012-exception.md の「調査サマリ」に書かれている
- [x] 根拠（ファイル・行・コマンド出力）が添えられている
- [x] 答えが出なかった問いは「リスク・未解決事項」に理由つきで残っている

## 作業内容

1. `.claude/hooks/workflow-boundary.sh` のWF012関連コード（`wf012()`、Bash引数のクォート処理、`review-state.json`/`merge-prep.json`の検出条件）をRead/Grepで確認する
2. `git`が`MERGE_HEAD`を作成・削除するタイミングを確認する（`git help merge`、実際に`.git/MERGE_HEAD`の有無を読み取り専用で確認。書き込みは行わない）
3. `MERGE_HEAD`をClaude自身が偽装できないか（作成には実際の`git merge`実行が必要か）を確認する
4. `CHERRY_PICK_HEAD`等の類似状態ファイルの有無と、今回のスコープに含めるべきかを検討する

## 作業ログ

### うまくいったこと

- WF012の実装箇所（Edit/Write分岐・Bash分岐）を特定し、例外を入れる場所を明確にできた

### うまくいかなかったこと

- 重大なリスクを発見した: MERGE_HEADの存在チェックのみでは、コンフリクト解消が起きるdoing空の状態がそのままworkflow-guard.shの制限が完全に外れる状態と一致するため、Claudeが`.git/MERGE_HEAD`を自作して条件を満たせてしまう可能性がある。調査結果の「リスク・未解決事項」に記載し、次チケット・設計フェーズへ引き継いだ
