# 全体計画: light-task-workflow に非デフォルトブランチ確認を追加

- 対象 issue: #9 https://github.com/yuki-matsu783/agent-workflow/issues/9
- PR: #10 https://github.com/yuki-matsu783/agent-workflow/pull/10

## Context

`light-task-workflow` の手順1（状態確認）は、チケットの有無・未コミット変更の有無は確認するが、
現在ブランチがデフォルトブランチかどうかは確認しない。フィーチャーブランチや別作業用ブランチに
いたまま軽作業を続けてしまう、あるいは古い状態のデフォルトブランチのまま軽作業を進めてしまう
ケースがある。issue #9 はこれを手順1に確認フローとして追加することを求めている。

## 変更方針

`light-task-workflow/SKILL.md` の手順1に以下を追加する。

1. `git branch --show-current` に加えて `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
   でデフォルトブランチを取得する（`gh-feature/SKILL.md` 54-76行目と同じ取得コマンドに揃える）
2. 現在ブランチがデフォルトブランチと異なる場合、`AskUserQuestion` で次を確認する
   - このまま現在のブランチで実施する
   - デフォルトブランチに切り替えて実施する → 選択時は `git checkout <default>` → `git pull` で
     最新化してから手順2に進む
   - 中断する
3. ヘッドレス実行（`claude -p`、CI）では確認できないため、**確認せず現在のブランチのまま進める**。
   既存の手順5（振り返り、118行目）が採るのと同じ「ヘッドレスでは承認待ちで止まらず安全側の
   動作を続行する」方針に揃える（ブランチ切り替えという状態変更を伴う操作を、確認できないまま
   自動実行しない）。この方針を SKILL.md に明記する（`.claude/rules/claude-config-headless-awareness.md`
   の対象アセットであり、ヘッドレス時の挙動明記が求められるため）

この確認は「ファイル変更を伴う場合のみ実施する」という既存の手順1の前提を維持する
（質問・説明だけの依頼では省略でよい）。

`.claude/docs/10_spec/ワークフロー入口ガード.md` は入口フック（`workflow-entry.sh`）の仕様であり、
スコープ外に「入口スキルの中身（各 SKILL.md）」を明記している（9行目）。今回の変更はフックを
伴わない SKILL.md 内の手順追加のみなので、この仕様書への追記は不要と判断する。

## チケット構成

1 チケットのみで足りる規模と判断する（`.claude/skills/**` の変更は `ai-asset-implementation`
タイプ、`.claude/docs/**` の変更は無いため `ai-asset-design` チケットは不要）。

1. **`001-ai-asset-implementation-非デフォルトブランチ確認.md`**（type: `ai-asset-implementation`）
   - `light-task-workflow/SKILL.md` の手順1にブランチ確認フローを追加する
   - DoD: issue #9 の受け入れ条件（確認フロー明記・切替時の checkout→pull 明記・ヘッドレス時挙動明記）を満たす
2. **`002-retrospective-振り返り.md`**（type: `retrospective`）
   - 結果報告を `wip/30_reports/` に作成する

## 完了後の流れ

全チケット done 後、`issue-pr-driven-workflow` の手順6（完了処理）に戻り、push・PR #10 本文の更新・
承認③（ready for review にするか）を確認する。
