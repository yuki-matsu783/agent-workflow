---
type: report
title: 結果報告 merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化
description: gh の GraphQL 自動解決に依存していた箇所を gh api（REST）へ置き換え、実地検証で見つかった stdout 汚染も修正した
tags: [work-ticket-driven, report]
keywords: [merge-prep, work-boundary, gh api, GraphQL, REST, reviewDecision, agent proxy, gh CLI, stdout]
---

# 結果報告: merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化

- 対象ブランチ: claude/festive-clarke-1jz96i
- 対象 issue: #44 https://github.com/yuki-matsu783/agent-workflow/issues/44
- PR: #45 https://github.com/yuki-matsu783/agent-workflow/pull/45
- 期間: 2026-08-30（1日）
- レビュー結果: ai-asset-design=承認（--local） / ai-asset-implementation=承認（--local。002 完了直後の実地検証で追加不具合を発見し、004 として同じワーク内で対応してから改めて承認）/ retrospective=このチケットで実施中

## issue #44 の受け入れ条件との対応

| 受け入れ条件 | 対応 |
|-------------|------|
| `mp_pr_number()` が GraphQL 自動解決を使わず PR 番号を解決できる | ✅ `gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open"` に置き換え（002）。失敗時の stdout 汚染も終了コード確認で対策（004） |
| `mp_notify()` の PR 本文取得（Closes #N 抽出用）が GraphQL を使わない | ✅ `gh api "repos/{owner}/{repo}/pulls/<PR>"` に置き換え（002） |
| `wb_pr_number()` が GraphQL 自動解決を使わない | ✅ `mp_pr_number()` と同一の REST 呼び出しに置き換え（002・004） |
| `wb_complete()` のレビュー判定・コメント取得が GraphQL を使わず、`CHANGES_REQUESTED` 判定と未返信インラインスレッド判定が既存と同等に機能する | ✅ `pulls/<PR>/reviews` + `issues/<PR>/comments` + 既存の `pulls/<PR>/comments` に置き換え、reviewer ごとの最新レビューから `reviewDecision` 相当を自前計算（002）。取得失敗時は `wb_die` で安全に停止するよう強化（004） |
| `gh pr comment` / `gh issue comment` の REST 化を検討し、採用する場合は置き換える | ✅ 採用。`gh api repos/{owner}/{repo}/issues/{number}/comments -f body=...` に置き換え（002） |
| `.claude/docs/10_spec/チケット駆動ワークフロー.md` の該当箇所が実装と一致するよう更新されている | ✅ 「ワーク境界の判定とレビュー状態」「マージ前作業の判定と状態」を更新（001）。あわせて `.claude/docs/10_spec/issue-PR駆動ワークフロー.md` も更新 |
| `test-hooks.sh` の既存テスト（TC024〜TC031）が新しい実装で通る | ✅ 202 PASS / 0 FAIL（002・004。004 で TC028d〜g を追加） |
| 既存の `gh` CLI が制限なく使える環境（ローカル等）での動作に影響しない | ✅ REST 呼び出しへの置き換えのみで、`gh` の認証・実行方式自体は変更していない。モックのフィクスチャ形式（フィールド名・変数名）が変わったが、これはテスト内部の実装詳細であり実際の `gh` の使い方に影響しない |

## 実施したチケットと結果

| チケット | 結果 | 備考 |
|---------|------|------|
| 001-ai-asset-design-gh-pr-rest化設計 | 完了 | 対応表・reviewDecision 自前計算ロジックを確定し、仕様書2ファイルを更新 |
| 002-ai-asset-implementation-gh-pr-rest化実装 | 完了 | merge-prep.sh / work-boundary.sh / test-hooks.sh を書き換え、194 PASS を確認 |
| 004-ai-asset-implementation-gh-api失敗時のstdout汚染対策 | 完了（追加チケット） | 002 完了後の実地検証で発見した stdout 汚染バグを修正。202 PASS を確認 |

## 成果物一覧

- 計画書: `wip/20_plans/gh-pr-rest化計画.md`
- コード変更:
  - `.claude/hooks/merge-prep.sh`（`mp_pr_number()` / `mp_notify()` を REST 化 + 終了コード確認）
  - `.claude/hooks/work-boundary.sh`（`wb_pr_number()` / `wb_request()` / `wb_complete()` を REST 化 + 終了コード確認）
  - `.claude/skills/work-ticket-driven/scripts/test-hooks.sh`（モック `gh` とフィクスチャの追従、失敗パスの回帰テスト追加）
- ドキュメント: `.claude/docs/10_spec/チケット駆動ワークフロー.md`、`.claude/docs/10_spec/issue-PR駆動ワークフロー.md`

## うまくいったこと

- 作業開始前にこのセッション自身（Claude Code Remote 環境）で `GH_DEBUG=api` を使い、`gh pr view` / `gh pr comment` / `gh issue comment` が GraphQL 経由であること、`gh api "repos/{owner}/{repo}/..."` が REST でありプレースホルダがローカル解決されることを実測できたため、設計の根拠が実装前から具体的だった
- 設計チケット（001）で置き換え後の `gh api` コマンドを diff 形式で計画書に書いておいたことで、実装チケット（002）はほぼ転記で進められた
- 002 完了後、そのまま「通常モードで `work-boundary.sh request` を試す」という実地検証を行ったことで、ユニットテストのモックだけでは絶対に発見できない `gh api` の stdout 汚染バグ（gh pr view の GraphQL 版は失敗時 stderr のみだが、gh api は失敗時に stdout へエラー JSON を出す）を本番相当の環境で発見できた
- 発見した不具合を、002 の done を戻さずに同じ type の追加チケット（004）として対応する、というチケット駆動ワークフローの想定パスをそのまま実践できた

## うまくいかなかったこと

- このセッション自体は `gh` が GitHub の REST/GraphQL いずれにも到達できない実行環境（issue #41 のスコープ）だったため、本 issue の修正が「通常モードで実際に動く」ところまではこのセッション内で実地確認できなかった。確認できたのは「REST 呼び出しへの置き換え自体は正しく組み立つ」ことと「失敗時にエラー JSON へ汚染されず安全に空へフォールバックする」ことまで
- 004 の発見は偶然（自分自身のワークで通常モードを試した結果）であり、設計段階（001）で `gh api` の失敗時 stdout 挙動まで検証できていれば、002 の実装時点で最初から対応できていた可能性がある

## 使った AI アセットの棚卸し

| 種類 | 対象 | 判定 | 気付き |
|------|------|------|--------|
| スキル | workflow-issue-mr-driven | 問題なし | 手順どおり issue/PR 確定 → work-ticket-driven の順で進められた |
| スキル | work-ticket-driven | 足りなかった | 「同じ type の追加チケットで対応する」パス（004）は仕様どおり機能したが、追加チケットの根拠が「人間のレビュー指摘」ではなく「自分自身の実地検証で見つけた不具合」だった。手順書は「レビュー指摘への対応」を主眼に書かれており、実装者自身の追加検証で見つけた不具合への対応も同じ経路で良いことは明記されていないが、実際には問題なく機能した |
| フック | workflow-guard.sh（WF003） | 問題なし | `ai-asset-design` フェーズでの jq 動作確認や、境界外での診断コマンドがブロックされたのは想定どおり。ただし「今すぐ手元で1行確認したい」という場面が複数回あり、許可コマンドの外に出るたびに「チケット境界まで待つ」か「別の方法で検証する」かの判断が必要だった |
| フック | work-boundary.sh / merge-prep.sh | 問題なし | 今回の修正対象そのもの。`--local` フォールバックが実行環境の制約（issue #41 のスコープ）に対して機能した |
| CLAUDE.md | 「作業の振り分け」 | 問題なし | `.claude/` 配下の変更として workflow-issue-mr-driven（ai-asset-design → ai-asset-implementation）を使う、という依頼文の指示どおりに進められた |

## 改善提案

- **`gh api` を使う AI アセットの設計・実装時は、失敗時の stdout/stderr の挙動（特にエラー JSON が stdout に漏れるかどうか）を設計チケットの段階で確認する項目として明記する**ことを提案した。`.claude/docs/10_spec/` 等に「gh api はエラー時に stdout へ JSON を出すことがあるため、`2>/dev/null` だけでなく終了コードを確認すること」という一般的な注意書きを残すと、今後同種の `gh api` 呼び出しを追加する際の再発を防げる
  - 対象: `.claude/docs/10_spec/` への一般的な注意書きの追加、または `.claude/rules/` への新設
  - 軽微な文言追加であり振る舞いは変わらない候補として提示したが、**ユーザーの判断により今回は見送り**（対応しない）。今回発見した具体的な対策自体は 004 のコード修正として反映済みのため、一般化した注意書きが無くても再発防止の実質的な効果はある

## 残課題・フォローアップ

- issue #41（gh CLI・GitHub REST への到達手段が一切無い実行環境向けの再設計）は本 issue のスコープ外のまま未着手。今回の実地検証で「REST 化しても issue #41 の環境では依然として `--local` フォールバックが必要」であることを改めて確認した
- `.claude/skills/workflow-issue-mr-driven` 手順0 等、`merge-prep.sh` / `work-boundary.sh` 以外で `gh pr view`（GraphQL 自動解決）を使っている箇所（issue #44 の「スコープ外」として明記済み）は今回対応していない
