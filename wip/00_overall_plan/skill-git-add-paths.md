---
type: plan
title: 全体計画 スキル手順の git add wip/ を許可パスに揃える
description: work-ticket-driven / work-overall-plan の手順書にある git add wip/ をフックの許可基準に揃え、WF009 の毎チケット確認を無くす
tags: [work-overall-plan, overall-plan]
keywords: [git add, wip/, WF009, workflow-guard.sh, wf_validate_add, work-ticket-driven, work-overall-plan, チケット駆動ワークフロー, 許可パス, セッション記憶]
---

# 全体計画: スキル手順の git add wip/ を許可パスに揃える

- 対象 issue: #47 https://github.com/yuki-matsu783/agent-workflow/issues/47
- PR: #48 https://github.com/yuki-matsu783/agent-workflow/pull/48
- ブランチ: feature-47-skill-git-add-paths
- 作成日: 2026-08-30

## Context

- `workflow-issue-mr-driven` でチケット駆動の作業をしていると、チケットの作成・完了コミット（`git mv ... && git add wip/ && git commit ...`）のたびに WF009（想定外パスの git add）の人間確認が出る。`.claude/hooks/workflow.log` で 001〜009 の全チケットに同じ ASK が記録されている
- 原因はフックではなくスキルの手順書。`workflow-guard.sh` の `wf_validate_add` は引数ごとに判定し、`wip/` は `wip/10_tickets/*`（無条件許可）にも `workflow-types.json` の allow glob にも一致しないため `unlisted` → ask になる。Bash の承認は PostToolUse（`workflow-diff-check.sh`）が `FILE_PATH` のある Edit/Write に対してのみセッション記憶するため、毎回聞かれる
- フックの判定は妥当（`wip/` には global deny の `wip/00_overall_plan/**` も含まれ、`git add wip/` は許可外パスまでまとめてステージしうる）。直すのは `git add wip/` を指示している手順書の側
- ユーザーとの合意事項（軽作業の振り返り → issue 化）: フックのロジックは変えない。Bash 承認のセッション記憶（記憶単位が `dirname "wip/"` = `.` になり広すぎる）も採らない。スキル手順を `git add wip/10_tickets/ <許可パス内の変更ファイル>` に統一する
- 該当箇所（調査済み）: `.claude/skills/work-ticket-driven/SKILL.md` 手順 2・5（2 か所）、`.claude/skills/work-overall-plan/SKILL.md` 4-1・4-5（2 か所）。他の `work-*` スキルには `git add wip` の記述なし（`grep -rn 'git add wip' .claude/` で確認）

## フェーズ列

| 順 | フェーズ | 計画スキル / 実施スキル | type（計画 / 実施） | 狙い | 省略理由（省略時） |
|----|---------|------------------------|--------------------|------|-------------------|
| - | 調査 | work-investigation-plan / work-investigation-exec | investigation-plan / investigation | - | **省略**。発端の軽作業（質問への回答）で原因の特定・該当箇所の列挙・フック判定の妥当性まで確認済み（上記 Context）。対象は SKILL.md 2 本と仕様書 1 本に閉じる |
| 1 | AI アセット設計 | work-ai-asset-design-plan / work-ai-asset-design-exec | ai-asset-design-plan / ai-asset-design | 仕様書 `.claude/docs/10_spec/チケット駆動ワークフロー.md` に「チケット運用のコミットでは `git add` の対象を `wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` 全体を指定しない」規約を書く。要件定義書・用語辞書に影響があるか確認する | |
| 2 | AI アセット実装 | work-ai-asset-implementation-plan / work-ai-asset-implementation-exec | ai-asset-implementation-plan / ai-asset-implementation | `work-ticket-driven` / `work-overall-plan` の SKILL.md 4 か所を修正し、他の `work-*` スキルに `git add wip/` 相当が無いことを確認する。フックのテストが通ることを確認する | |
| 末尾 | 振り返り | （work-ticket-driven 手順 4） | retrospective | 結果報告・AI アセットの棚卸し。手順どおりのコミットで WF009 が出なかったことを `workflow.log` で確認する | 省略しない |

## 受け入れ条件との対応

| 受け入れ条件 | 満たすフェーズ | 成果物 |
|-------------|--------------|--------|
| ① `work-ticket-driven` と `work-overall-plan` の手順書から `git add wip/` が無くなり、`git add wip/10_tickets/ <許可パス内の変更ファイル>` の形に統一されている（`work-overall-plan` では `wip/00_overall_plan/` を明示） | AI アセット実装 | `.claude/skills/work-ticket-driven/SKILL.md`、`.claude/skills/work-overall-plan/SKILL.md` |
| ② 他のフェーズ別ワークスキルに `git add wip/` 相当の指示が残っていない | AI アセット実装 | 実装チケットの作業ログ（`grep -rn 'git add wip' .claude/skills` の結果） |
| ③ 仕様書に「`git add` の対象を `wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` 全体を指定しない」旨が書かれている | AI アセット設計 | `.claude/docs/10_spec/チケット駆動ワークフロー.md` |
| ④ 手順どおりのチケット作成・完了コミットで WF009 の確認が出ない | 振り返り | `wip/30_reports/` の結果報告（本 PR の作業中の `.claude/hooks/workflow.log` を根拠にする） |

## 判断が必要になりそうな点

- 仕様書のどの節に規約を書くか（「チケット運用コマンド」の節か、`work-ticket-driven` の手順を説明する節か）。AI アセット設計の計画で決める
- 要件定義書（`.claude/docs/00_requirements/チケット駆動ワークフロー.md` 等）や用語辞書に触る必要があるか。AI アセット設計の計画で確認する（無ければ仕様書のみ）
- `merge-prep.sh` 内部の `git add -A -- wip/` はスクリプトが直接実行するものでフックの対象外のため触らない（issue のスコープ外）
- 本 PR の作業自体は修正前の手順書で進むため、チケットのコミットでは先に `git add wip/10_tickets/ <許可パス>` の形を使う（受け入れ条件④の根拠になる）

## 最初の計画チケット

- 002-ai-asset-design-plan-AIアセット設計計画.md
