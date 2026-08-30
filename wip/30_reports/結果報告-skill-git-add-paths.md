---
type: report
title: 結果報告 スキル手順の git add wip/ を許可パスに揃える
description: work-ticket-driven / work-overall-plan の git add wip/ を仕様書 2.3 の規約に揃え、WF009 の毎チケット確認を解消した結果報告
tags: [work-ticket-driven, report]
keywords: [git add, wip/10_tickets/, WF009, work-ticket-driven, work-overall-plan, test-workflow-guard.sh, TC022b, TC022c, TC022d, permission-matrix, チケット駆動ワークフロー]
---

# 結果報告: スキル手順の git add wip/ を許可パスに揃える

- 対象ブランチ: feature-47-skill-git-add-paths
- 対象 issue: #47 https://github.com/yuki-matsu783/agent-workflow/issues/47
- PR: #48 https://github.com/yuki-matsu783/agent-workflow/pull/48
- 期間: 2026-08-30 〜 2026-08-31
- レビュー結果: overall-plan=承認 / ai-asset-design-plan=承認 / ai-asset-design=承認 / ai-asset-implementation-plan=承認 / ai-asset-implementation=承認（いずれも指摘 0 件）

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 001-overall-plan-全体計画 | 完了 | フェーズ列: AI アセット設計 → AI アセット実装 → 振り返り（調査は発端の軽作業で確認済みのため省略） |
| 002-ai-asset-design-plan-AIアセット設計計画 | 完了 | 更新対象を仕様書 1 本に確定。フック本体・要件定義書・用語辞書は変更不要 |
| 003-ai-asset-design-チケット駆動ワークフロー仕様書の更新 | 完了 | 仕様書 2.2 → 2.3（規約・基本フロー 3/6・TC022b/TC022c・レビュー記録） |
| 004-ai-asset-implementation-plan-AIアセット実装計画 | 完了 | 変更対象 4 ファイル・テスト方針・参照更新を確定。末尾スラッシュの罠を発見し TC022d 案を追加 |
| 005-ai-asset-implementation-テストTC022bとTC022c | 完了 | `test-workflow-guard.sh` に 5 ケース + `check_absent` 追加。現行フックのまま PASS=19 |
| 006-ai-asset-implementation-スキル手順のgit-add修正 | 完了 | SKILL.md 2 本 4 か所 + `permission-matrix.md` 1 文。`git add wip/` 残存 0 件 |
| 007-retrospective-振り返り | 完了 | 本報告 |

## 成果物一覧

- 計画書: wip/20_plans/AIアセット設計計画-skill-git-add-paths.md、wip/20_plans/AIアセット実装計画-skill-git-add-paths.md（全体計画: wip/00_overall_plan/skill-git-add-paths.md）
- ドキュメント変更: `.claude/docs/10_spec/チケット駆動ワークフロー.md`（2.3。`git add` の対象パスの規約、基本フロー 3・6、TC022b/TC022c、レビュー記録）
- アセット変更: `.claude/skills/work-ticket-driven/SKILL.md`（手順 2・5 + 規約段落）、`.claude/skills/work-overall-plan/SKILL.md`（4-1・4-5）、`.claude/skills/work-ticket-driven/references/permission-matrix.md`（規約 1 文）
- テスト: `.claude/hooks/tests/test-workflow-guard.sh`（TC022b-1/2・TC022c-1/2・TC022d・`check_absent`。PASS=19 FAIL=0）

## 受け入れ条件との対応（根拠）

| 受け入れ条件 | 結果 | 根拠 |
|-------------|------|------|
| ① SKILL.md から `git add wip/` が無くなり `git add wip/10_tickets/ <許可パス内の変更ファイル>` に統一 | 達成 | `work-ticket-driven/SKILL.md:88,160`、`work-overall-plan/SKILL.md:75,122`（4-5 は `wip/00_overall_plan/` を明示） |
| ② 他のフェーズ別ワークスキルに残存なし | 達成 | `grep -rn 'git add wip/' .claude/skills` → 0 件（他スキルはコマンド例を持たず手順番号参照のみ） |
| ③ 仕様書に規約が書かれている | 達成 | 仕様書 2.3「Bash コマンドの許可」チケット運用コマンドの規約 + 基本フロー 3・6 |
| ④ 手順どおりのコミットで WF009 が出ない | 達成 | `.claude/hooks/workflow.log`: 本 PR の 001〜006 の done コミット（許可パス明示）がすべて ALLOW（1001・1019・1049・1079・1115・1150 行）。テスト TC022c-1/2 でも固定 |

## うまくいったこと

- 発端の軽作業（質問への回答）で原因・該当箇所・フック判定の妥当性まで特定できていたため、調査フェーズを省略して 6 ワークで完走できた
- 「テストを先に追加して現行フックで PASS させる」順序により、フック変更不要という設計判断を実行で裏付けられた
- 本 PR の作業自体を修正後の手順（許可パス明示）で進め、受け入れ条件④の根拠（workflow.log の ALLOW）をワークの副産物として得た

## うまくいかなかったこと

- doing チケット中の Bash に `git status` や `bash .claude/hooks/work-boundary.sh status` を `&&` で混ぜて WF003 で丸ごとブロックされた（1 回）。チケット操作だけで 1 コマンドにする必要がある
- `scripts/test-hooks.sh` が 120 秒を超えタイムアウト → バックグラウンド実行で完了待ちにした（結果は PASS=194）
- 仕様書と `scripts/test-hooks.sh` でテスト ID の採番が衝突していた（下記残課題）

## 使った AI アセットの棚卸し

| 種類 | 対象 | 判定 | 気付き |
|------|------|------|--------|
| スキル | workflow-issue-mr-driven / work-overall-plan / work-ai-asset-design-plan / work-ai-asset-design-exec / work-ai-asset-implementation-plan / work-ai-asset-implementation-exec / work-ticket-driven / task-gh-issue / task-gh-feature / task-spec | 問題なし | ワークループ・承認・レビュー依頼はすべて手順どおり機能した。work-ticket-driven / work-overall-plan の `git add wip/` は本 PR で修正済み |
| フック | workflow-guard.sh（WF003・WF009）/ workflow-entry.sh / workflow-boundary.sh / work-boundary.sh | 問題なし（判定は正しかった） | WF009 の原因はスキル手順側。WF003 の複合コマンドブロックも仕様どおりだが、doing 中に状態確認コマンドを混ぜられない点は手順書に無い暗黙知だった（改善提案 2） |
| ルール | markdown-frontmatter.md / claude-config-headless-awareness.md | 問題なし | ヘッドレスの帰結（従来手順は自動拒否で失敗していた）を仕様の規約に反映できた |
| CLAUDE.md | 作業の振り分け | 問題なし | 軽作業 → 振り返り → issue 化 → workflow-issue-mr-driven の接続が機能した |

## 改善提案

（重さの区分: 軽微 = 振る舞いが変わらない文言修正 / 振る舞いが変わる = 手順・ロジックの変更）

1. **［軽微］TC022d（末尾スラッシュ無し `git add wip/10_tickets` → WF009）の仕様書追記**: テストは追加済みだが仕様書のテストケース一覧に無い。設計反映として仕様書 2.4 で 1 行追記する
2. **［軽微］work-ticket-driven の手順 5 に「doing 中の Bash はチケット操作だけで構成する」注意を追記**: `git status` / `work-boundary.sh status` を `&&` で混ぜると WF003 になる。done コミットの後に別コマンドで実行する旨を 1 文添える
3. **［軽微］`scripts/test-hooks.sh` のテスト ID `TC022b`（`git add .claude/settings.json` → WF003）の付け替え**: 仕様書 2.3 の TC022b と衝突。`TC022-deny` 等に改名するか、仕様書側に deny ケースとして採番して整合させる
4. **［振る舞いが変わる・見送り済み］Bash 承認のセッション記憶**: `wip/` の記憶単位が `.` になり広すぎるため今回のスコープで不採用と合意済み。必要になったら別 issue

## 残課題・フォローアップ

- 改善提案 1〜3 はいずれも軽微。まとめて 1 件の軽作業（または issue 記録）として扱える。ユーザーの判断待ち
- 仕様書 `チケット駆動ワークフロー.md` に OKF frontmatter が無い（`markdown-frontmatter.md` 準拠の追加は本 issue のスコープ外）
