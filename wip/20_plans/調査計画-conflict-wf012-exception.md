---
type: plan
title: 調査計画 コンフリクト解消時のWF012例外
description: WF012の実装・マージ進行中の検出手段・内容検証方法の選択肢を調べる
tags: [work-investigation-plan, investigation-plan]
keywords: [WF012, MERGE_HEAD, workflow-boundary, review-state, merge-prep]
---

# 調査計画: コンフリクト解消時にWF012保護ファイルの編集を許可する

- 作成元チケット: 002-investigation-plan-調査計画.md
- 作成日: 2026-08-30

## 調査観点

1. `workflow-boundary.sh` のWF012実装（`review-state.json`/`merge-prep.json` の検出・保護ロジック、Bash引数のクォート処理を含む）の現状はどうなっているか
2. `git` が実際にマージ進行中であることをシェルスクリプトから機械的に検出する手段（`MERGE_HEAD`の存在確認等）は、どの程度信頼できるか。Claude自身がこの状態を偽装できてしまわないか
3. 検出条件を`MERGE_HEAD`のみとするか、`CHERRY_PICK_HEAD`等の類似操作（cherry-pick中のコンフリクト）も含めるべきか
4. 許可された編集が「コンフリクトマーカーの除去（マージの完了）」以外の内容改変でないことを、どこまで機械的に検証できるか。現実的な選択肢（有効なJSONであることのみ確認、diffの行数上限、マーカー行の減少のみ許可、等）とそれぞれの限界

## 対象と方法

| 観点 | 読む場所 | 方法 |
|------|---------|------|
| 1 | `.claude/hooks/workflow-boundary.sh`（`wf012()`/`wf_quoted_targets_state()`/Bashコマンド判定部） | Read/Grep |
| 2 | `git help merge`、`.git/MERGE_HEAD`の生成条件、他OSSでの類似実装例（あれば） | Read/Bash（`git status`の内部動作確認。書き込みは行わない） |
| 3 | `git`のドキュメント（`CHERRY_PICK_HEAD`/`REVERT_HEAD`等の一覧） | Read |
| 4 | `merge-prep.sh`の既存の検証パターン（`git merge-tree`の使い方）、jqでのJSON妥当性検証の可否 | Read/Grep |

書き込みは行わない。

## 調査チケットの一覧

1. **003-investigation-WF012実装とマージ状態検出手段の調査.md**（観点1・2・3）
   - DoD:
     - [ ] 調査観点「WF012実装」「MERGE_HEAD検出の信頼性」「検出範囲（MERGE_HEAD/CHERRY_PICK_HEAD等）」に対する答えが調査結果に書かれている
     - [ ] 根拠（ファイル・行・コマンド出力）が添えられている
     - [ ] 答えが出なかった問いは「リスク・未解決事項」に理由つきで残っている
2. **004-investigation-内容検証方法の選択肢調査.md**（観点4）
   - DoD:
     - [ ] 調査観点「内容検証方法の選択肢」に対する答え（選択肢一覧と限界）が調査結果に書かれている
     - [ ] 根拠（ファイル・行・コマンド出力）が添えられている
     - [ ] 答えが出なかった問いは「リスク・未解決事項」に理由つきで残っている

## 成果物の形

`wip/20_plans/調査結果-conflict-wf012-exception.md` に、上記4観点それぞれの「調査サマリ」を書く。AIアセット設計フェーズはこれを入力に、`.claude/docs/`の要件・仕様（例外条件・検証方法・トレードオフ）を確定する。
