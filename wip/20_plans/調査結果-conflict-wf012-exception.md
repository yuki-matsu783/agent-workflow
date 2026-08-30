---
type: plan
title: 調査結果 コンフリクト解消時のWF012例外
description: WF012実装・MERGE_HEAD検出手段・内容検証方法の調査結果
tags: [work-investigation-exec, investigation]
keywords: [WF012, MERGE_HEAD, workflow-boundary, review-state, merge-prep, git]
---

# 調査結果: コンフリクト解消時にWF012保護ファイルの編集を許可する

- 作成元チケット: 002-investigation-plan-調査計画.md
- 作成日: 2026-08-30

## 調査サマリ

### 1. WF012実装（`.claude/hooks/workflow-boundary.sh`）

- `wf012()`（56-67行目）は `review-state.json`/`merge-prep.json` への書き換えを常に `exit 2` で拒否する。呼び出し元に条件分岐は無い（`doing`の有無、gitの状態を一切見ない）
- Edit/Write/NotebookEditの場合（93-98行目）: `tool_input.file_path` を相対パス化し、`STATE_REL`/`MP_STATE_REL`と完全一致すれば即`wf012()`。**例外条件を入れるならここに追加する必要がある**
- Bashの場合（99-118行目）: コマンドを`&&`/`;`/`|`/`||`で分割し、各セグメントについて (1) `gh pr ready`検出→WF015、(2) クォート内文字列を`QUOTED`に置換した`sanitized`が読み取り専用コマンド（`READONLY_RE`）またはスクリプト呼び出し（`SCRIPT_RE`）ならスキップ、(3) `sanitized`に`review-state.json`/`merge-prep.json`という文字列がクォート外にそのまま含まれるか、クォート内の値がこの2ファイルのパスそのものなら`wf012()`
- **例外を入れる場合の実装ポイント**: Edit/Write分岐とBash分岐の両方に、「マージ進行中」判定を追加する必要がある。現状はこの判定ロジック自体が存在しない
- 根拠: `.claude/hooks/workflow-boundary.sh:56-120`

### 2. MERGE_HEAD検出の信頼性

- `git`は`git merge`が衝突等で自動コミットまで進めなかったとき、`.git/MERGE_HEAD`（マージしようとしている相手のコミットSHAを指すref）を作成する。`git commit`でマージを完了するか`git merge --abort`/`git reset --merge`で中断すると削除される（git本体の一般的な仕様。今回はドキュメント調査のみで実機検証は行っていない）
- 検出コマンド例: `git rev-parse -q --verify MERGE_HEAD`（存在すれば0、無ければ非0）
- **信頼性上の重大なリスクを発見した**: このリポジトリの`workflow-guard.sh`は`wip/10_tickets/10_doing/`にチケットが無い状態（doing空）だと`wf_init`のガード2で**即exit 0**し、Bashコマンドに対する制限が完全に外れる（`.claude/hooks/workflow-lib.sh:183-184`、`.claude/hooks/workflow-lib.sh:191`）。一方、`merge-prep.sh`のマージ前作業（コンフリクト解消が実際に発生する場面）は「実行はdoingが空のときに限る」（`.claude/docs/10_spec/skill-work-ticket-driven.md:471`）。つまり**コンフリクト解消が起きるのは、必ずBashコマンドの制限が完全に外れている状態と一致する**
  - この状態では、Claudeが`echo <任意のSHA> > .git/MERGE_HEAD`のようなコマンドを実行しても、`workflow-guard.sh`（doing空でinactive）にも`workflow-boundary.sh`（`.git/MERGE_HEAD`というパスは判定対象外）にも引っかからず、素通りしてしまう
  - つまり「`MERGE_HEAD`の存在」だけを条件にすると、doing空の状態（＝コンフリクト解消が起きる状態そのもの）でClaudeが自己申告的に条件を満たせてしまい、WF012が本来防ぎたい「LLMの自己申告だけで状態を進める」問題を再発させかねない
- 根拠: `.claude/hooks/workflow-lib.sh:180-191`（ガード1・2）、`.claude/docs/10_spec/skill-work-ticket-driven.md:471`

### 3. 検出範囲（MERGE_HEAD以外の類似状態）

- gitには`CHERRY_PICK_HEAD`（cherry-pick中）、`REVERT_HEAD`（revert中）、`rebase-merge`/`rebase-apply`ディレクトリ（rebase中）等、同様の「操作進行中」を示す状態がある
- 本リポジトリの設計では、コンフリクト解消は常に`git merge`のみを使う運用（`git rebase`は明示的に禁止。理由: レビューコメントが紐づくコミットを書き換えないため。根拠: `.claude/docs/10_spec/skill-work-ticket-driven.md:568,922`）。cherry-pickやrevertを使う手順もワークフロー中に存在しない
- **結論（設計フェーズへの提案）**: 検出条件は`MERGE_HEAD`のみで十分。`CHERRY_PICK_HEAD`等を含める積極的な理由は現状ない（使われていない操作のための例外を増やすと攻撃面が広がるだけ）

### 4. 内容検証方法の選択肢

`merge-prep.sh`の`git merge-tree --write-tree --name-only --no-messages`（`.claude/hooks/merge-prep.sh:191`）は、作業ツリー・インデックスを変更せずに衝突検知だけを行う設計。これに倣い、WF012の例外でも「許可はするが、書かれた内容を検証する」方向で選択肢を整理する。

| 選択肢 | 実装コスト | 防げること | 防げないこと（限界） |
|--------|-----------|-----------|---------------------|
| A. 有効なJSONであることのみ確認（`jq empty`等） | 低（既存の`wf_jq`をそのまま使える） | 壊れたJSONをコミットすること | キーの値を自由に書き換えられる（`state`を`"ready"`に、`review_decision`を`"APPROVED"`に等） |
| B. コンフリクトマーカー（`<<<<<<<`/`=======`/`>>>>>>>`）が残っていないことのみ確認 | 低（`grep`一発） | マーカー混入したままのコミット | Aと同じくキーの値の恣意的な書き換えは防げない |
| C. 既存キーの集合が変化していないことを確認（`jq 'keys'`の前後比較。ただし「前」をどこから取るかが課題 — マージ前のHEAD側の内容と比較する必要がある） | 中 | キーの追加・削除 | 既存キーの値の書き換えは防げない（例: `state`の値だけ変える） |
| D. 特定の機微なキー（`state`/`review_decision`/`pr`等）の値がマージ前のHEAD側から変化していないことを確認（`git show HEAD:<path>`との比較） | 中〜高（フィールドごとの許可リストを保守する必要） | 状態の恣意的な書き換え（今回の懸念の核） | 新しいキーを追加してそこに偽の状態を書き、別の読み取り経路で参照させる、といった迂遠な迂回は理論上残る（ただし現在の設計ではreview-state.json/merge-prep.jsonの読み取り経路は`work-boundary.sh`/`merge-prep.sh`のjqクエリに限定されているため実害は小さい） |
| E. A+D（有効なJSON + 機微キー不変）を組み合わせる | 中 | B・Cの懸念点をおおむね包含 | 「2. MERGE_HEAD検出の信頼性」で指摘した検出自体の偽装可能性は別問題として残る（内容検証だけでは解決しない） |

- **示唆**: 内容検証（A〜E）は「マージ進行中という検出結果」を前提にした二次防御であり、検出自体（`MERGE_HEAD`の真正性）が偽装されると意味をなさない。したがって設計フェーズでは、検出の強化（「2.」のリスク対応）と内容検証（本節）の両方をセットで決める必要がある
- 根拠: `.claude/hooks/merge-prep.sh:191`（既存の非破壊的検証パターン）

## 変更方針

<!-- 調査チケットの範囲外。AIアセット設計フェーズで決定する -->

## 変更対象ファイル

| ファイル / パス | 変更内容 |
|----------------|---------|
| `.claude/hooks/workflow-boundary.sh` | WF012の判定にマージ進行中の例外条件を追加（設計フェーズで確定） |
| `.claude/docs/10_spec/skill-work-ticket-driven.md` | 例外条件・検証方法・トレードオフの明記 |

**allowed_paths 案**: `[".claude/hooks/**", ".claude/docs/**"]`

## 実装ステップ

<!-- AIアセット実装フェーズで確定 -->

## 検証方法

<!-- AIアセット実装フェーズで確定（フックのテストスクリプトでの確認を想定） -->

## リスク・未解決事項

- **MERGE_HEADのみを条件にする設計はリスクがある**（上記「2. MERGE_HEAD検出の信頼性」参照）。単純な存在チェックだけでは、doing空の状態でClaudeが自己申告的にこの状態を作れてしまう可能性がある。設計フェーズでは、より強い検証（例: 対象ファイルが実際に`git ls-files -u`でunmerged状態にあることの確認、`MERGE_HEAD`の内容が実在するコミットかつ`origin/*`等の到達可能なrefから来ていることの確認、等）を検討する必要がある。ただし実機での検証（実際にunmergedな状態を作って`git ls-files -u`の出力を確認する等）は本チケットのスコープ外（書き込みを伴うため）とし、次の「内容検証方法の選択肢調査」チケットおよびAIアセット設計フェーズに引き継ぐ
- `git ls-files -u -- <path>`（該当パスがunmerged状態か）の実機検証は未実施（読み取り専用の調査という制約上、実際にコンフリクト状態を作って確認していない。加えて`investigation` typeのBash許可リストに`git ls-files`が無いため、ticket-driven作業中は実行そのものができない）
- 内容検証の選択肢D「機微キー不変チェック」は、どのキーを機微とするかの定義（`review-state.json`なら`state`/`review_decision`/`pr`、`merge-prep.json`なら`state`/`ready`等）を設計フェーズで確定する必要がある
