- 対象 issue: #4 https://github.com/yuki-matsu783/agent-workflow/issues/4
- PR: #43 https://github.com/yuki-matsu783/agent-workflow/pull/43

# 全体計画: CLAUDE.md「作業の入口」に .claude/ 配下アセット作業の振り分け基準を明記する

## Context

`workflow-quick-request`（軽作業）の判定表は「振る舞いが変わるか／ファイル数」などの汎用基準で切り分けており、`.claude/` 配下のアセット（スキル・フック・ルール・エージェント・settings.json）の作成・変更について直接の記述が無い。実際に issue #1 の作業で、`workflow-quick-request` 自体の新設（8 ファイル）が本来 `workflow-issue-mr-driven` 側に当たるのに軽作業側で通ってしまった実績がある（`workflow-quick-request/SKILL.md` 手順 5-3 では「フック・スキル・ルール・エージェントの新規作成、settings.json の変更」を「振る舞いが変わる」と分類済みだが、手順 0 の判定表に反映されていない）。

本作業は、CLAUDE.md「作業の振り分け」と `workflow-quick-request` 手順 0 の判定表に `.claude/` 配下アセット作業の基準を明記し、5-3 の重さ分けと整合させることで、この判断のぶれを無くす。issue #4 の本文がそのまま対応内容を網羅しているため、issue 本文への追記は行わない。

## 調査で確認した対象ファイルと現状

| ファイル | 現状 | 変更要否 |
|---------|------|---------|
| `CLAUDE.md`（「作業の振り分け」セクション） | `.claude/` 配下アセット作業の入口の明記なし | 追記する |
| `.claude/skills/workflow-quick-request/SKILL.md`（手順 0 の判定表） | 「対象」観点の行が無い | 行を追加する |
| `.claude/docs/10_spec/軽作業ワークフロー.md`（`### 軽作業判定表`、SKILL.md 手順 0 と 1:1 対応する仕様） | 同じ判定表があり、SKILL.md と同じ行が無い | SKILL.md と同じ行を追加し整合を保つ |
| `.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md`（issue が名指しする「入口ガード仕様書」） | 判断基準（判定表の中身）の記述は無い。フック WF101 の入出力・状態遷移のみを扱う横断メタ文書で、スコープ外に「振り分けスキルの中身」を明記している | 変更不要（`grep` で「判断基準」「判定表」該当なしを確認済み） |
| `.claude/docs/00_requirements/軽作業ワークフロー.md` | 判定基準表を「成果物・振る舞い・規模・検証・追跡・ユーザーの指定」と汎用的に参照するのみで、行を列挙していない | 変更不要（行追加は仕様書・SKILL.md 側で閉じる） |
| `.claude/skills/workflow-quick-request/evals/evals.json` | 「フックを作って」のような依頼を issue-pr 側に振り分けるケースが無い | ケースを追加する |

`### 振り返り候補の重さの区分` 表（`軽作業ワークフロー.md`）と SKILL.md 手順 5-3 は既に「フック・スキル・ルール・エージェントの新規作成、settings.json の変更」＝振る舞いが変わる、で一致しており、追加する判定表の行はこの分類と矛盾しない。

## チケット構成

`.claude/` 配下のアセット（`.claude/docs/`）を変更するため `ai-asset-design` → `ai-asset-implementation` の標準構成を使う。CLAUDE.md は `ai-asset-implementation` の `allow_paths` に無いため、実装チケットの frontmatter `allowed_paths` に `CLAUDE.md` を追加して扱う（issue #4 の追加情報に明記された対処）。

### 001-ai-asset-design-アセット作業振り分け基準.md（type: ai-asset-design）

- 目的: `.claude/docs/10_spec/軽作業ワークフロー.md` の `### 軽作業判定表` に「対象」の行を追加し、SKILL.md に書く行と `### 振り返り候補の重さの区分` との整合を計画書に固定する
- 成果物: `wip/20_plans/` に計画書（追加する表の行の文言、CLAUDE.md に追記する文言案を含む）＋ `.claude/docs/10_spec/軽作業ワークフロー.md` の編集
- 追加する行（案）:
  - `軽作業判定表` に観点「対象」を追加: 軽作業側「`.claude/` 配下のアセット以外」／ workflow-issue-mr-driven 側「`.claude/` 配下のアセット（スキル・フック・ルール・エージェント・settings.json）の作成・変更。例外: SKILL.md・ルール・テンプレートの typo・文言修正など振る舞いが変わらないものは軽作業でよい」
- DoD:
  - [ ] `軽作業判定表` に「対象」の行が追加されている
  - [ ] 追加した基準が `### 振り返り候補の重さの区分`（軽微 / 振る舞いが変わる）と矛盾しない
  - [ ] CLAUDE.md に追記する文言案が計画書にある

### 002-ai-asset-implementation-アセット作業振り分け基準反映.md（type: ai-asset-implementation, depends_on: 001, allowed_paths: ["CLAUDE.md"]）

- 目的: 001 の計画に従い、CLAUDE.md・SKILL.md・evals.json に反映する
- 変更内容:
  1. `CLAUDE.md`「作業の振り分け」セクションに `.claude/` 配下アセット作業は `workflow-issue-mr-driven`（`ai-asset-design` → `ai-asset-implementation`）で進める旨と、typo・文言修正など振る舞いが変わらないものは `workflow-quick-request` でよい旨の箇条書きを追加する（既存の箇条書き群の末尾に追加。表そのものは変更しない）
  2. `.claude/skills/workflow-quick-request/SKILL.md` 手順 0 の判定表に、001 で固定した「対象」の行を追加する
  3. `.claude/skills/workflow-quick-request/evals/evals.json` に、フック等 `.claude/` 配下アセットの新規作成依頼を `workflow-issue-mr-driven` 側に振り分けるケース（id: 6）を追加する
- DoD（issue #4 の受け入れ条件に対応）:
  - [ ] CLAUDE.md「作業の振り分け」に `.claude/` 配下のアセット作業の入口が明記されている（例外条件を含む）
  - [ ] `workflow-quick-request/SKILL.md` 手順 0 の判定表に同じ基準の行があり、5-3 の分類と矛盾しない
  - [ ] （確認事項）入口ガード仕様書（`ワークフロー振り分け実施済み判定.md`）には判断基準の記述が無く同期対象外であることを結果報告に明記する
  - [ ] `evals.json` に「フックを作って」のような依頼を issue-pr 側に振り分けるケースがある

### 003-retrospective-振り返り.md（type: retrospective, depends_on: 002）

- 目的: 作業ログを振り返り、`wip/30_reports/` に結果報告を作成する
- DoD:
  - [ ] 各チケットの結果（うまくいったこと・いかなかったこと）を要約している
  - [ ] issue #4 の受け入れ条件 4 項目それぞれについて対応状況を記載している
  - [ ] 恒久的な教訓があれば改善提案として記載している

## ワーク構成とレビュー往復

`ai-asset-design`（001）と `ai-asset-implementation`（002）はそれぞれ別ワークなので、001 完了時と 002 完了時にワーク境界（`workflow-issue-mr-driven` 手順 5 の push → レビュー依頼 → 完了確認）が発生する。`retrospective`（003）完了時にも同様。

## 検証方法

- `.claude/skills/workflow-quick-request/evals/evals.json` が妥当な JSON であること（`python3 -m json.tool` 等でパース確認）
- 追加した判定表の行が Markdown として崩れていないこと（目視）
- SKILL.md と `10_spec/軽作業ワークフロー.md` の判定表の行が文言レベルで一致していること（目視 diff）
