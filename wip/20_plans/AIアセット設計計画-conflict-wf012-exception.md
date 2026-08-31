---
type: plan
title: AIアセット設計計画 コンフリクト解消時のWF012例外
description: WF012にマージ進行中の例外を追加するための要件・仕様の骨子
tags: [work-ai-asset-design-plan, ai-asset-design-plan]
keywords: [WF012, MERGE_HEAD, workflow-boundary, review-state, merge-prep]
---

# AIアセット設計計画: コンフリクト解消時にWF012保護ファイルの編集を許可する

- 作成元チケット: 005-ai-asset-design-plan-設計計画.md
- 作成日: 2026-08-30

## 判断点の結論方針

調査結果（wip/20_plans/調査結果-conflict-wf012-exception.md）を踏まえ、以下を採る。

1. **検出条件**: `git rev-parse -q --verify MERGE_HEAD` が成功する **かつ** 対象ファイル（`review-state.json`/`merge-prep.json`）が `git diff --name-only --diff-filter=U` の一覧に含まれる（実際にunmerged状態）の**両方**を満たすときに限り例外を適用する。単純な`MERGE_HEAD`存在チェックのみだと、doing空の状態（コンフリクト解消が起きる状態そのもの）でBashが無制限になることと衝突し、Claudeが`.git/MERGE_HEAD`を自作して検出条件を満たせてしまうリスクがある（調査結果「2.」）。対象ファイル自体が実際にunmerged状態にあることまで確認することで、単純な偽装（`echo <SHA> > .git/MERGE_HEAD`）では通らないようにする
   - **残るトレードオフ**: doing空の状態はBashコマンドが無制限であるため、`git update-index --index-info`等のgitプラミングコマンドで対象ファイルのunmerged状態そのものを人工的に作り出すことは理論上可能。これは本チケットのスコープ（フック単体でのロジック追加）では解消しきれない構造的な限界であり、仕様書に明記した上で許容する（doing空の状態でBashを再制限することは、コンフリクト解消作業自体を妨げるため採らない）
2. **許可する操作**: Edit/Write/NotebookEditと、Bashによる直接書き換え（`sed -i`等）の両方を対象とする（既存のWF012判定と同じ対象範囲）
3. **内容検証**: PreToolUse（編集前）の時点では編集後の内容を検証できないため、**PostToolUse側で警告のみ**行う（既存のWF-DIFFと同じ「自動revertはしない」方針に合わせる）。編集後に (a) 有効なJSONであること（`jq empty`相当）、(b) コンフリクトマーカー（`<<<<<<<`/`=======`/`>>>>>>>`で始まる行）が残っていないこと、(c) 対象ファイルが`--diff-filter=U`から外れた（解消済み）ことを確認し、いずれか満たさなければ`additionalContext`で警告する。調査結果の選択肢D（機微キー不変チェック）は実装コストと保守負担が高く、`--diff-filter=U`条件自体が既に強い制約であるため、今回は見送り、仕様書に将来の拡張候補として残す
4. **検出範囲**: `MERGE_HEAD`のみ。`CHERRY_PICK_HEAD`等は対象外（調査結果の結論通り。本リポジトリの運用は`git merge`のみを使い`git rebase`/cherry-pickは使わないため）
5. **フック本体の変更が必要**: type定義（`workflow-types.json`）の追加では実現できない。`workflow-boundary.sh`の`wf012()`呼び出し前に検出条件の判定を追加し、`workflow-diff-check.sh`（PostToolUse）に内容検証の警告を追加する、フック本体のロジック変更が必要

## 文書の一覧

| 文書 | 新規/更新 | パス | 骨子 |
|------|----------|------|------|
| 仕様書 | 更新 | `.claude/docs/10_spec/skill-work-ticket-driven.md` | 「ワーク境界の判定とレビュー状態」に例外条件（検出・許可範囲・内容検証・トレードオフ）を追記。WF012のエラーメッセージ仕様への影響も明記 |
| 要件定義書 | 更新 | `.claude/docs/00_requirements/skill-work-ticket-driven.md` | 受け入れ基準に「マージ進行中に限りWF012保護ファイルを編集できる」「マージ進行中でない場合は現行どおり常時拒否」を追加 |
| 用語辞書 | 更新 | `.claude/docs/90_glossary/ワークフロー用語.md` | 「merge-prep.json」節（review-state.jsonも含めて）にWF012例外の存在を追記。keywordsに`MERGE_HEAD`を追加 |

横断文書（`スキル体系.md`）は本変更で階層構造が変わらないため更新不要。

## ヘッドレス実行の扱い

本変更はユーザーへの確認（`ask`/`AskUserQuestion`）を増やすものではなく、既存のexit 2（WF012ブロック）を条件付きで通す変更のみ。ヘッドレス実行での挙動に変化はない（`.claude/rules/claude-config-headless-awareness.md`の対象外の変更）。内容検証の警告（PostToolUse `additionalContext`）もWF-DIFFと同様にブロックしないため、ヘッドレスでの帰結に影響しない。

## 受け入れ条件との対応

| 受け入れ条件 | 対応する文書・記述 |
|-------------|-------------------|
| MERGE_HEAD存在時に限り直接書き換えを許可し、それ以外は現行どおり常時拒否 | 仕様書「ワーク境界の判定とレビュー状態」の例外条件、要件定義書の受け入れ基準 |
| コンフリクトマーカー除去以外の改変を防ぐ検証方法の設計 | 仕様書に内容検証（PostToolUse警告、選択肢A・B・C相当）を明記 |
| 信頼境界上のトレードオフを仕様書に明記 | 仕様書に「残るトレードオフ」節として明記 |
| 既存のWF012保護を壊さないことをテストで確認 | AIアセット実装フェーズでフックのテストに追加（本設計計画のスコープ外、実装計画で扱う） |

## AIアセット設計チケットの一覧

1. **006-ai-asset-design-仕様書へのWF012例外の追記.md**
   - DoD:
     - [ ] `.claude/docs/10_spec/skill-work-ticket-driven.md`「ワーク境界の判定とレビュー状態」に検出条件・許可範囲・内容検証・トレードオフが追記されている
     - [ ] 受け入れ条件4件すべてが仕様書のどこかに対応している
     - [ ] レビュー記録の版が追記されている
2. **007-ai-asset-design-要件定義書と用語辞書の更新.md**
   - DoD:
     - [ ] `.claude/docs/00_requirements/skill-work-ticket-driven.md`の受け入れ基準に例外条件が追加されている
     - [ ] `.claude/docs/90_glossary/ワークフロー用語.md`の該当節が更新され、keywordsに`MERGE_HEAD`が追加されている
     - [ ] レビュー記録の版が追記されている

## 次の計画チケット

- 008-ai-asset-implementation-plan-実装計画.md
