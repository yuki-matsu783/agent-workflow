---
type: plan
title: work完了レビュー往復の実装方針
description: チケットtype単位のワーク境界で人間レビューを挟むための、work-ticket-driven / workflow-issue-mr-driven の具体的な手順文言とコマンドを確定する
tags: [work-ticket-driven, plan, review-loop]
keywords: [ワーク境界, 人間レビュー, gh pr view, gh api, pulls comments, ヘッドレス, 追加チケット, 承認④, ブランチ命名, ハイフン区切り]
---

# work完了レビュー往復の実装方針

- 作成元チケット: 008-investigation-レビュー往復ロジック確認.md
- 作成日: 2026-08-30
- 全体計画: `wip/00_overall_plan/gleaming-hopping-moth.md`

## 調査サマリ

- **現状の粒度**: `workflow-issue-mr-driven` 手順5 は `work-ticket-driven` を「手順1から」1回通しで呼び、手順6（push・PR本文更新・承認③）は全チケット done 後に1回だけ行う。`work-ticket-driven` 手順6 も「todo が空になるまで手順3〜5を繰り返す」構造で、type の区切りで呼び出し元に戻らない
- **フックは変更不要**: `workflow-lib.sh` の `wf_init` は doing が 0 枚なら即 `exit 0` するため、done コミット直後（doing が空）は `git push` / `gh` が素通りする。フックはブランチ名も work 境界も一切見ていない
- **調査チケット中は `gh` が使えない**（本チケットで実際に WF003 を確認: `gh pr view 13 --json comments,...` がブロックされた）。よって「レビューコメント取得」は必ず **doing が空の状態＝ワーク境界** で行う。これは今回の設計（レビュー往復は workflow 層の責務で、work-ticket-driven の外で行う）と整合する
- **issue番号の復元**は PR 本文の `Closes #N` から行っており、ブランチ名に依存しない。命名規約のハイフン化はドキュメント・evals の文言変更だけで済む
- **retrospective との関係**: retrospective（タスク層・セルフレビュー）とワーク完了チェックポイント（ワーク層・第三者承認）は別物のまま維持する。ただし retrospective 自体も1つの work になるため、他 type と同様にチェックポイント（人間レビュー）が発生する

## 変更方針

### 責務の分担（3層仕様に照らした整理）

| 層 | スキル | 今回の責務 |
|---|---|---|
| workflow | `workflow-issue-mr-driven` | work 境界ごとの push・PR本文更新・レビュー依頼・**ターン終了**・（次発言で）コメント取得・指摘の要否判断・追加チケット依頼・最終の承認③ |
| work | `work-ticket-driven` | 1つの type に属するチケットを実施し、type が切り替わる（または todo が空になる）時点で**完了報告して制御を返す**。単独呼び出し時のみ `AskUserQuestion` でチェックポイントを自前で完結 |
| task | チケット | 変更なし |

`work-ticket-driven` を workflow から呼ぶ場合、「ワーク完了チェックポイント（work層）」と「ワーク間の人間承認（workflow層）」は**同一の発火点・同一のレビュー行為**になる。二重にレビューを要求しない。

### 選ばなかった代替案

- **work-ticket-driven 内で `AskUserQuestion` によりレビュー待ちをブロックする**: 人間が GitHub で実際にレビューする間セッションを塞ぐ。ヘッドレス実行では応答が得られず自動拒否になる。→ 不採用
- **done チケットを doing に戻して再実施する**: 差分チェックの基準コミット（着手コミット）がずれ、作業ログの履歴も壊れる。→ 不採用。同 type の新規チケットを todo に追加する
- **3層定義表の work 層承認者を一律「人間」に書き換える**: 将来別の `work-*` が敵対的レビューを実装する余地を閉じる。→ 不採用。汎用定義は残し `work-ticket-driven` 節で個別上書き

## 変更対象ファイル

| ファイル / パス | 変更内容 | 担当チケット |
|----------------|---------|-------------|
| `.claude/docs/10_spec/スキル体系.md` | 「ワーク完了チェックポイント」節に work-ticket-driven 固有運用を追記 | 009 |
| `.claude/docs/00_requirements/スキル体系.md` | AC に承認者置き換え（workflow経由／単独）を追記 | 009 |
| `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` | 承認④の追加、基本フロー 7-8 の改稿、代替フロー5の置換、命名規約・具体例のハイフン化（59/109/139/251行目）、`gh` コマンド追記、状態遷移図更新、IP009/新規テストID | 009 |
| `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` | AC に「type 完了ごとの push・レビュー依頼・コメント取得」を追記 | 009 |
| `.claude/docs/10_spec/チケット駆動ワークフロー.md` | 基本フローに「ワーク境界で呼び出し元へ制御を返す」説明を追記 | 009 |
| `.claude/skills/work-ticket-driven/SKILL.md` | 手順0・手順5.5（新設）・手順6（改稿）・冒頭の3層説明 | 010 |
| `.claude/skills/work-ticket-driven/assets/report.template.md` | 「レビュー結果」欄の説明 | 010 |
| `.claude/skills/work-ticket-driven/evals/evals.json` | ワーク境界で停止するケース追加 | 010 |
| `.claude/skills/workflow-issue-mr-driven/SKILL.md` | 冒頭図・承認ポイント表・手順5（改稿）・手順6（縮小）・命名規約表・エラーハンドリング・ヘッドレス節 | 011 |
| `.claude/skills/workflow-issue-mr-driven/assets/issue-addendum.template.md` | ブランチ例のハイフン化 | 011 |
| `.claude/skills/workflow-issue-mr-driven/evals/evals.json` | ブランチ名期待値のハイフン化、レビュー依頼／コメント取得ケース追加 | 011 |
| `.claude/skills/task-gh-feature/SKILL.md` | issue連携モード入力表（242行目付近）のブランチ例のみハイフン化 | 011 |

**allowed_paths 案**: 009 は `ai-asset-design` の既定（`.claude/docs/**`）、010・011 は `ai-asset-implementation` の既定（`.claude/skills/**`）で足りる。追加不要。

## 実装ステップ（手順文言の草案）

### A. `work-ticket-driven/SKILL.md`（010）

**冒頭の3層説明**（現行「全チケット完了時点で敵対的レビューエージェントの承認が入る」を置換）:

> 本スキル自身は3層構造の `work-*` に分類される。**1つの作業タイプ（type）に属するチケット群が1つのワーク**であり、ワーク内は人間の明示的承認なしに進む。ワークが完了した時点（type が切り替わる、または todo が空になる）でワーク完了チェックポイントを設け、承認者は人間とする（`workflow-issue-mr-driven` 経由なら MR レビュー、単独なら `AskUserQuestion`。手順 5.5・6 参照）。

**手順0 追記**:

> - **doing が空で、todo の先頭が done の最後と異なる type** → 前のワークは完了済み。新しいワークの開始として手順3から続行する（`workflow-issue-mr-driven` 経由なら、その手順5のループから呼ばれているはず）
> - **todo にレビュー指摘対応の追加チケット（同 type）がある** → 通常どおり手順3から着手する

**手順5.5（新設）: ワーク境界の判定**

> done に移したチケットの `type` と、todo の先頭（連番最小）チケットの `type` を比べる。
>
> | 状態 | 判定 | 次の動き |
> |---|---|---|
> | todo の先頭が同じ type | 同一ワークの途中 | 手順3へ戻り次のチケットに着手する |
> | todo の先頭が異なる type | **ワーク完了** | 手順6へ |
> | todo が空 | **最後のワーク完了** | 手順6へ |
>
> 判定に使う `type` は各チケットの frontmatter を Read で読む。

**手順6（改稿）: ワーク完了チェックポイントと報告**

> 1. ワーク開始コミット（この type の最初のチケットの `start` コミット）から HEAD までの差分（`git log --oneline` / `git diff --stat <start>..HEAD`）を要約する
> 2. **呼び出し元が `workflow-issue-mr-driven` の場合**（全体計画冒頭に issue / PR が書かれている）: 完了した type・チケット一覧・差分要約・todo に残る次の type を報告し、**ここで制御を呼び出し元へ返す**。push・レビュー依頼・コメント確認は呼び出し元の責務であり、本スキルでは行わない
> 3. **単独で呼ばれた場合**: `AskUserQuestion` で「type X のワークが完了した。差分を確認して承認 / 差し戻し（追加チケットで対応）」を確認する。承認なら次の type の手順3へ（todo が空なら完了報告）。差し戻しなら指摘内容から同 type の追加チケットを手順2の要領で作り、手順3へ
> 4. todo が完全に空になったら、成果物一覧（`wip/20_plans/`、`wip/30_reports/`、コード変更）を最終報告する
>
> **レビュー指摘への対応**: done 済みチケットを doing に戻さない。同 type の新規チケット（例: `013-implementation-レビュー指摘対応.md`。`depends_on` に直前の done チケット）を todo に追加し、手順3から着手する

**`report.template.md`**: `- レビュー結果:` のコメントを「各 type のワーク完了チェックポイント（人間レビュー）の結果。例: investigation=承認 / implementation=差し戻し1回・対応済み / retrospective=承認」に変更する。

### B. `workflow-issue-mr-driven/SKILL.md`（011）

**承認ポイント表**に追加:

> | ④ | 各ワーク（チケット type）完了・push のあと | PR のレビュー。レビュー完了の連絡を受けるまで次のワークに進まない（type の数だけ発生） |

**手順5（改稿）: チケット駆動ワークフロー（ワークループ）**

> 初回のみ `work-ticket-driven` を手順1から実施し、全体計画の合意とチケット全件の作成まで進める（引き継ぐ文脈は現行どおり）。
>
> 以降、todo と doing が両方空になるまで次を繰り返す:
>
> 1. `work-ticket-driven` を実施する（初回は続けて手順3へ、2回目以降は手順0の再開判定から）。1つの type が完了すると制御が戻る
> 2. `git push`（doing が空なのでフックは働かない）
> 3. PR 本文を更新する: `## 変更点` に完了した type の要約を追記し `gh pr edit M --body-file <path>`
> 4. レビューを依頼する: `gh pr comment M --body "<type X のワーク完了。レビュー観点: …>"` を1回投稿し、チャットで「type X を push しレビューを依頼した。完了したら知らせてほしい」と報告して**ターンを終える**（`AskUserQuestion` で待たない）
> 5. （次のユーザー発言でレビュー完了の連絡を受けたら）コメントを取得する:
>    ```bash
>    gh pr view M --json reviewDecision,reviews,comments
>    gh api repos/<owner>/<repo>/pulls/M/comments --jq '.[] | {id, path, line, body, in_reply_to_id, user: .user.login, url: .html_url}'
>    ```
>    レビュー依頼コメント自身と自分の返信は除いて提示し、対応要否を `AskUserQuestion` で確認する（自動判定しない）
> 6. 対応が必要な指摘があれば、`work-ticket-driven` に「type X への追加チケット（指摘内容）」を作らせて手順1へ戻る。対応後は同じ type のワークとして再度 2〜5 を回す。対応不要（または対応完了の合意）なら次の type へ

**手順6（縮小）: 完了処理（全チケット done 後）**

> ループを抜けた時点で push と PR 本文更新は済んでいる。
> 1. PR 本文を最終整形する（`wip/30_reports/` の要約を「変更内容の概要」「動作確認」に反映）
> 2. **承認③**（現行どおり）
> 3. issue 側の残課題があれば `gh issue comment N`

**命名規約表**: `<prefix>-<N>-<slug>` / 例 `fix-12-login-empty-password`。

**エラーハンドリング追記**:

> | ヘッドレス実行（`claude -p` 等）でワーク境界に達した | レビュー依頼を投稿した時点でそのセッションの応答は完了とする。レビュー結果の反映と次の type は次回セッション（手順0の再開判定）で行う。1セッションで全ワークを完走することは想定しない |
> | レビュー完了の連絡がないまま「続けて」と言われた | コメント取得（手順5-5）を実行し、未取得の指摘が無いことを確認してから次の type へ進む。確認せずに進まない |

### C. 仕様書（009）

- `スキル体系.md` ワーク完了チェックポイント表: 位置＝「1つのワーク（work-ticket-driven では1 type 分）の完了直後」、出力＝「承認 / 差し戻し（同 type の追加チケットで対応）」、承認者＝「人間（workflow-* 経由なら MR レビュー、単独なら AskUserQuestion）。汎用定義の『敵対的レビューエージェント』は将来の自動化余地として残す」。workflow 層との発火点一致を1段落で明記
- `issue-PR駆動ワークフロー.md`: 承認④、基本フロー7-8、代替フロー5（「チケット完了ごとの push」→「ワーク完了ごとの push・レビュー依頼」）、`gh pr comment` / `gh api .../pulls/N/comments` を「使用する gh コマンド」に追加、状態遷移図に `(type ごとに) ワーク done ──push+レビュー依頼──> 承認④ ──>` を追加、テスト IP009 の前提を「最後のワーク完了後」に、IP011「ワーク完了時のレビュー依頼」、IP012「レビュー指摘後の追加チケット」を追加
- `チケット駆動ワークフロー.md`: 基本フローに「同 type のチケットが尽きたらワーク完了として呼び出し元に戻る」を追記（フック仕様は変更なし、と明記）

## 検証方法

- `bash .claude/hooks/tests/test-workflow-entry.sh`、`bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が無改修で全件パスすること（010・011 の DoD）
- `gh` コマンドの出力形式は、本チケットの done 直後（doing が空）に PR #13 で実行して確認し、結果を本ファイル末尾「コマンド確認結果」に追記する
- 本 issue 自身の 009 以降のワーク境界で、実際に push → レビュー依頼 → ターン終了 → コメント取得 の流れを実地で行い、012 の結果報告に記録する

## リスク・未解決事項

- `gh pr comment` でのレビュー依頼投稿は、`gh` が人間アカウントで認証されているため投稿者が人間として表示される。本文冒頭に `Claude Code より:` を付けて区別する（参考実装と同じ扱い）
- 同 type の追加チケットが増えると連番が飛ぶ（013 が implementation の追加、014 が retrospective…）。連番は実施順であり type ごとの連番ではないので問題ない、と SKILL.md に一言添える
- ワークが1チケットのみの type（例: retrospective）でも境界が発生し、レビュー往復が type の数だけ起きる。粒度が細かすぎると感じたら type をまとめる（例: ai-asset-design と ai-asset-implementation を1 issue 内で連続させる）のではなく、レビュー依頼コメントで「軽微なので approve のみで可」と伝える運用にする

## コマンド確認結果（008 done 直後、PR #13 で実施）

| コマンド | 結果 |
|---|---|
| `gh pr view 13 --json reviewDecision,reviews,comments` | `{"comments":[],"reviewDecision":"","reviews":[]}`。`reviewDecision` は未レビューで空文字、レビュー後は `APPROVED` / `CHANGES_REQUESTED` / `REVIEW_REQUIRED`。`comments` は PR 全体（会話タブ）のコメント、`reviews` はレビュー本文（`state` / `body` / `author`） |
| `gh api repos/<owner>/<repo>/pulls/13/comments --jq '.[] \| {id, path, line, body, in_reply_to_id, user: .user.login, url: .html_url}'` | 空（インラインコメント未投稿）。1件ごとに `path` / `line` / `in_reply_to_id`（返信なら親 id）が取れるため、「返信の無いスレッド」の抽出は `in_reply_to_id == null` かつ同 id を親に持つ要素が無いもの、で判定できる |

どちらも doing が空の状態で問題なく実行できた（調査チケット中は WF003 でブロックされることも同日確認済み）。
