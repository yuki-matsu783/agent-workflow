- 対象 issue: #12 https://github.com/yuki-matsu783/agent-workflow/issues/12
- PR: #13 https://github.com/yuki-matsu783/agent-workflow/pull/13

# 全体計画: work完了ごとに人間レビューを挟むフローへ改訂する

## Context

現状、`workflow-issue-mr-driven` は `work-ticket-driven` を1回だけ呼び出し、全チケット（investigation → implementation → retrospective 等）が完了してから初めて `git push` と人間レビュー（PR ready化の承認③）を行う構造になっている。3層仕様（`.claude/docs/10_spec/スキル体系.md`）は本来「ワーク（`work-*`）間に必ずチェックポイントを置く」原則を持つが、実装上は work-ticket-driven の呼び出し全体が「1つのwork」という粒度になっており、チケットtypeごとの区切りでレビューが挟まらない。

参考実装（`MR-driven-workflow/.claude/skills/issue-mr-flow/SKILL.md`）はフェーズ（調査・作業・反映）ごとに「計画→push→人間レビュー→実施→push→人間レビュー」のループを回しており、これに倣って本リポジトリの work 粒度をチケットtype単位に分割し、workflow-issue-mr-driven 側が type 完了ごとに push・レビュー依頼・コメント確認・（指摘があれば）再実行のループを回す形に改める。あわせて、3層仕様の「ワーク完了チェックポイント」の承認者を、未実装の敵対的レビューエージェントから人間（MRレビュー）に置き換え、ブランチ命名規約をハイフン区切り（`<prefix>-<N>-<slug>`）に統一する。

## 決定済みの設計方針

1. **work分割の単位**: 既存チケットtype（`investigation` / `implementation` / `retrospective` / `ai-asset-design` / `ai-asset-implementation`）をそのまま「work」の単位とする
2. **レビュー往復の責務**: push・レビュー依頼・コメント取得・再実行判断は `workflow-issue-mr-driven`（ワークフロー層）の責務とする。`work-ticket-driven` は1つのtypeを完了したら制御を呼び出し元へ返すだけに専念する（ワーク層はタスクの組み合わせに専念）。`work-ticket-driven` が単独で（issue/PR文脈なしに）呼ばれた場合のみ、自前で `AskUserQuestion` によるチェックポイントを完結させる
3. **指摘対応**: レビュー指摘への対応は、done済みチケットを戻すのではなく、**同じtypeの新規チケットを todo に追加**して行う（履歴・基準コミットを壊さない）
4. **レビュー待機**: push・レビュー依頼の投稿後は `AskUserQuestion` でブロックせず、**チャットで報告してターンを終える**。次のユーザー発言（「レビュー完了」等）で再開する。ヘッドレス実行では type 完了時点で応答が終わり、続きは次回セッションになることを許容し、SKILL.mdに明記する
5. **3層仕様書の書き方**: 汎用のwork層定義（承認者＝敵対的レビューエージェント、自動起動は対象外）は残し、`work-ticket-driven` 節に「現状の運用は人間（workflow-*経由時はワークフロー層と同一発火点、単独時はAskUserQuestion）」を個別上書きとして追記する
6. **ブランチ命名規約**: `workflow-issue-mr-driven` の命名規約を `<prefix>/<N>-<slug>` から `<prefix>-<N>-<slug>` に恒久変更する。`task-gh-feature` 単独利用時の一般命名ガイド（SKILL.md 117-129行目、evals.jsonのid=1）は対象外（issue連携モードの入力表のみ変更）
7. **retrospective との関係**: 「セルフレビュー（タスク層）」と「ワーク完了チェックポイント（人間レビュー）」は別物のまま維持する。ただし retrospective も1つのworkになったため、他typeと同様にチェックポイントが発生する点を `report.template.md` の「レビュー結果」欄の説明に反映する

## 変更対象ファイル

| ファイル | 変更内容 |
|---|---|
| `.claude/docs/10_spec/スキル体系.md` | 「ワーク完了チェックポイント」節に work-ticket-driven 固有の運用（人間レビュー・発火点の説明）を追記。3層定義表の汎用文言は変更しない |
| `.claude/docs/00_requirements/スキル体系.md` | Acceptance Criteria に、workflow-*経由/単独時それぞれの承認者置き換えを追記 |
| `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` | 承認ポイントに「work単位のレビュー依頼」を追加、命名規約表・具体例（59, 109, 139, 251行目付近）をハイフン区切りに更新、コメント取得コマンドを追記 |
| `.claude/docs/10_spec/チケット駆動ワークフロー.md` | 基本フロー節に work 境界（type完了→呼び出し元へ制御を返す）の説明を追記 |
| `.claude/skills/work-ticket-driven/SKILL.md` | 手順5と手順6の間に「ワーク境界の判定」を新設。手順6を「呼び出し元がある場合は報告して制御を返す／単独時はAskUserQuestionで完結」に改稿。手順0の再開判定にtype境界の再開を追記 |
| `.claude/skills/work-ticket-driven/assets/report.template.md` | 「レビュー結果」欄の説明コメントを、type単位の人間レビュー結果一覧を書く形に更新 |
| `.claude/skills/work-ticket-driven/evals/evals.json` | type完了時に制御を返して停止する新規ケースを追加 |
| `.claude/skills/workflow-issue-mr-driven/SKILL.md` | 手順5を「初回のみ全体計画+チケット作成→以降はworkループ（push→PR本文更新→レビュー依頼→ターン終了→次発言でコメント取得→指摘があれば追加チケット）」に改稿。手順6は「ready化確認（承認③）専用」に縮小。命名規約表をハイフン区切りに更新。ヘッドレス実行時の扱いをエラーハンドリングに追記 |
| `.claude/skills/workflow-issue-mr-driven/assets/issue-addendum.template.md` | ブランチ名の記入例をハイフン区切りに更新 |
| `.claude/skills/workflow-issue-mr-driven/evals/evals.json` | ブランチ名の期待値をハイフン区切りに更新。「type完了直後のレビュー依頼」「レビュー完了後のコメント取得・再実行」の新規ケースを追加 |
| `.claude/skills/task-gh-feature/SKILL.md` | issue連携モード入力表（242行目付近）のブランチ名例のみハイフン区切りに更新。単独モードの一般ガイドは変更しない |

`.claude/hooks/*.sh`（workflow-guard.sh, workflow-entry.sh, workflow-lib.sh）はブランチ名・work境界のいずれにも依存しないため**変更しない**（doingが空になった時点で自動的にフックが不活性化し push が通るため、既存フックのままで今回のフローを実現できる）。

## 設計変更（010 完了時点、ユーザー指示）

当初「フックは変更しない」としていたが、ユーザーから次の追加指示を受けた:

1. **ワーク境界の判定はスクリプトで決定論的に行う**。フックも使い、想定外の操作（レビュー未完了で次 type に着手する等）は exit 2 で理由を LLM に伝える
2. **レビュー状態を生成 AI が直接書き換えられないようにする**。書き換えは必ずスクリプト経由で機械的に行う

これを受け、`.claude/hooks/work-boundary.sh`（`status` / `request` / `complete`）とレビュー状態ファイル `wip/10_tickets/review-state.json`（git 管理）を新設し、フックに境界判定とブロック（WF011〜）を追加する。`request` / `complete` は `gh` の実操作（コメント投稿・コメント取得）を自身で行い証跡を記録するため、LLM の主張だけでは状態が進まない。状態ファイルへの Edit / Write / リダイレクトはフックが拒否する。設計は 011、実装は 012 で行い、当初の 011（workflow SKILL）は 013 に、012（retrospective）は 014 に改番した。

## チケット分割（008〜014、依存関係: 008→009→010→011→012→013→014）

| # | type | 目的 | DoD概要 |
|---|---|---|---|
| 008 | `investigation` | レビュー往復ロジックの詳細確認、実装方針の確定 | 実装方針書ができている（done） |
| 009 | `ai-asset-design` | 3層仕様書・要件定義書・issue-PR駆動ワークフロー仕様/要件・チケット駆動ワークフロー仕様の改訂 | `.claude/docs/**` が更新され、レビュー記録に追記済み（done） |
| 010 | `ai-asset-implementation` | `work-ticket-driven` 本体の分割実装（手順5.5新設・手順6改稿・手順0更新・report.template.md更新・evals.json更新） | test-hooks.sh 62件パス（done） |
| 011 | `ai-asset-design` | ワーク境界スクリプト・レビュー状態ファイル・フックのブロック条件（WF011〜）・状態ファイル保護の仕様策定 | `チケット駆動ワークフロー.md` に仕様追記、`スキル体系.md` の「フックは関与しない」を更新 |
| 012 | `ai-asset-implementation` | `work-boundary.sh` とフックの実装、`test-hooks.sh` への TC 追加、`work-ticket-driven/SKILL.md` 手順 5.5/6 のスクリプト利用への更新 | 新旧 TC 全件パス、`test-workflow-entry.sh` 回帰なし |
| 013 | `ai-asset-implementation` | `workflow-issue-mr-driven` のワークループ化（`work-boundary.sh` を使う手順）+ ブランチ命名規約変更 | SKILL.md/テンプレート/evals.json 更新、`test-workflow-entry.sh` が通る |
| 014 | `retrospective` | 振り返り・結果報告作成 | `wip/30_reports/` に結果報告作成。ワーク完了チェックポイント（人間レビュー）の運用が実際に機能したかを報告に含める |

ワークの区切りは 008 / 009 / 010 / 011 / 012+013（同 type で1ワーク） / 014 の6つ。テスト更新は変更対象スキルと同じチケットに含める。

## 受け入れ条件との対応

issue #12 の受け入れ条件は上記チケット構成で以下のように満たす:
- work-ticket-driven のtype単位work区切り → 010
- workflow-issue-mr-drivenのworkループ手順 → 011
- スキル体系.mdのワーク完了チェックポイント更新 → 009
- ブランチ命名規約のハイフン化 → 011（および009で仕様書側）
- 既存フック・テストとの整合 → 010・011内のevals.json更新、既存hookテストは無改修で通ることを確認
- 関連仕様書の追従 → 009

## 検証方法

- `bash .claude/hooks/tests/test-workflow-entry.sh` が全件パスすること（無改修で通る想定。念のため実行して確認）
- `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` が全件パスすること
- 新規追加した evals.json のケースを目視でレビューし、SKILL.md本文の手順と矛盾がないか確認する
- 実際に本ワークフロー自身（このissue #12の作業）が、type完了ごとにpush・レビュー依頼のターン終了を行っているかを実地で確認する（010・011適用後、実際にこのブランチ上でその後のtype（例: retrospective）に進む際にドッグフーディングする）
