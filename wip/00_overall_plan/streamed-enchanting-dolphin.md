# 全体計画: 「入口」→「振り分け」/「入口ガード」→「振り分け実施済み判定」への用語統一

- 対象 issue: #22 https://github.com/yuki-matsu783/agent-workflow/issues/22
- PR: #25 https://github.com/yuki-matsu783/agent-workflow/pull/25

## Context

CLAUDE.md「作業の入口」で使われている「入口」という言葉が、実態（依頼を
`workflow-quick-request` / `workflow-issue-mr-driven` のどちらに担当させるか決める仕組み）
と語感がずれているという指摘をユーザーから受けた。相談の結果、「振り分け」の方が実態
（依頼の性質で担当スキルを振り分ける）に合致すると合意した。あわせて、この仕組みを
機械的に強制するフック・仕様書のタイトルである「入口ガード」も、判定の実態に即した
「振り分け実施済み判定」に変更する。

対象は CLAUDE.md 本文、`.claude/docs/**` の要件・仕様・用語集、`.claude/skills/*/SKILL.md`、
`.claude/hooks/workflow-entry.sh` のユーザー向けメッセージ、対応するテストの記述。
フックの制御ロジック（判定条件・ブロック条件）自体は変更しない。`wip/` 配下の完了済み
チケット・報告書・計画書は履歴としてそのまま残し、書き換えない。

## 用語マッピング

| 旧語 | 新語 | 使う場面 |
|------|------|----------|
| 入口ガード（`workflow-entry.sh` とその仕様書を指す固有の名称） | 振り分け実施済み判定 | ドキュメントタイトル、フックのヘッダコメント、仕様書ファイル名 |
| 作業の入口 | 作業の振り分け | CLAUDE.md 見出し、用語集の見出し語 |
| 入口スキル | 振り分けスキル | `workflow-issue-mr-driven` / `workflow-quick-request` を指す語 |
| 入口を宣言する / 入口の宣言 | 振り分けを宣言する / 振り分けの宣言 | WF101 メッセージ、仕様書の説明文 |
| 対になる入口 / 2つの入口 | 対になる振り分け / 2つの振り分け | SKILL.md の相互参照 |
| 入口となるワークフロー / 開発の入口 | 振り分けとなるワークフロー / 開発の振り分け | 要件定義書 |
| 1xx = 入口（エラーコード帯の説明） | 1xx = 振り分け | 仕様書のコード体系表 |

`.claude/docs/90_glossary/README.md` の「本辞書は…という入口を提供する」は、上記の
仕組みとは無関係な一般的な比喩表現なので対象外（変更しない）。

## チケット分割

`.claude/hooks/workflow-types.json` の定義に従い、`.claude/docs/**` の変更（design）と
`.claude/hooks/**` / `.claude/skills/**` / CLAUDE.md の変更（implementation）を分ける。

1. **001-ai-asset-design-用語統一.md**（`ai-asset-design`）
   - 対象: `.claude/docs/10_spec/ワークフロー入口ガード.md`（内容全体の用語置換 + ファイル名を
     `ワークフロー振り分け実施済み判定.md` にリネーム）、`.claude/docs/00_requirements/*.md`
     （issue-PR駆動ワークフロー.md、スキル体系.md、チケット駆動ワークフロー.md）、
     `.claude/docs/10_spec/スキル体系.md`、`.claude/docs/90_glossary/*.md`
     （スキル名.md、ワークフロー用語.md。README.md は対象外の1件を除き変更なし）
   - DoD: 上記ファイル内の「入口」「入口ガード」表記が用語マッピングに従い更新されている。
     ファイルリネームは `git mv` で行い、リネーム後のパスを参照する他ドキュメント内リンクも
     このチケット内で更新する

2. **002-ai-asset-implementation-用語統一.md**（`ai-asset-implementation`）
   - 対象: `.claude/skills/workflow-quick-request/SKILL.md`、
     `.claude/skills/workflow-issue-mr-driven/SKILL.md`、
     `.claude/skills/work-ticket-driven/SKILL.md`、
     `.claude/hooks/workflow-entry.sh`（コメント・WF-ENTRY / WF101 のメッセージ文言。
     `WF_ENTRY_SKILLS` 等のロジック・変数名・制御フローは変更しない）、
     `.claude/hooks/tests/test-workflow-entry.sh`（コメント。アサーション対象がメッセージ文言に
     依存している場合は新文言に追従させる）、`CLAUDE.md`（「作業の入口」セクション。
     `.claude/**` ではないため deny 対象外だが `session_memory.file_level` によりファイル単位の
     確認が入る）
   - スキルリネーム後のファイルパス参照（001 で `ワークフロー入口ガード.md` →
     `ワークフロー振り分け実施済み判定.md` にリネームした分）もあわせて更新する
   - DoD: `bash .claude/hooks/tests/test-workflow-entry.sh` が引き続き全件パスする。
     フックのブロック条件・状態遷移に変更がないこと（差分がメッセージ文言とコメントのみ）を
     `git diff` で目視確認する

3. **003-retrospective-振り返り.md**（`retrospective`）
   - 全チケットの作業ログを読み、結果報告を `wip/30_reports/` に作成する
   - 確認項目: リポジトリ全体で `grep -rn 入口` した際、`wip/` 配下の完了済みドキュメント
     （20_done・30_reports・00_overall_plan、および対象外とした README.md の1件）以外に
     ヒットが残っていないこと

## 検証方法

- 各チケット完了時に `git status` で許可パス内に収まっていることを確認
- 002 完了時に `bash .claude/hooks/tests/test-workflow-entry.sh` を実行し、全シナリオ
  （TE001〜TE014）がパスすることを確認
- 全チケット完了後、`grep -rn "入口" --include=*.md --include=*.sh .` を実行し、
  対象外（`wip/` の完了済み文書、README.md の比喩表現1件）以外に残っていないことを確認
