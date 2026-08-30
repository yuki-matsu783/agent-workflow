---
type: ai-asset-implementation
status: todo
depends_on: ["011-ai-asset-design-ワーク境界スクリプトとフック仕様.md"]
---

# ワーク境界スクリプトとフックの実装

## 目的

011 で確定した仕様に従い、ワーク境界の判定スクリプトとレビュー状態管理、フックによるブロック（exit 2 + 理由）を実装し、テストで検証する。

## 完了条件（DoD）

- [x] `.claude/hooks/work-boundary.sh` が `status` / `request` / `complete` / `reply` を実装し、`status` が JSON を出力する
- [x] `wip/10_tickets/review-state.json` の読み書きが仕様どおりで、ファイルが無い状態（初回）でも `status` が動く（TC024 系）
- [x] PreToolUse フック `workflow-boundary.sh`（新規）が、doing が空でも境界判定を行い、WF011 / WF012 を exit 2 と「対処:」付きで返す（TC025 / TC026 系）
- [x] 既存の振る舞いが変わっていない（`workflow-guard.sh` 無改修、既存 62 件を含め全件パス）
- [x] `test-hooks.sh` に TC024〜TC028（68 件）を追加し、PASS=130 FAIL=0
- [x] `bash .claude/hooks/tests/test-workflow-entry.sh` PASS=40 FAIL=0（無改修）
- [x] `work-ticket-driven/SKILL.md` の手順 5.5 / 6 を `work-boundary.sh status` / `request --local` / `complete --local` を使う手順に更新
- [x] `.claude/settings.json` に PreToolUse（`Edit|Write|NotebookEdit|Bash`）で `workflow-boundary.sh` を登録

## 作業内容

1. 011 の仕様書（`.claude/docs/10_spec/チケット駆動ワークフロー.md` 追記分）を読む
2. `work-boundary.sh` を実装する
3. フック（`workflow-guard.sh` または新規フック）に境界判定とブロックを組み込む
4. `test-hooks.sh` に TC を追加し、全件パスさせる
5. `work-ticket-driven/SKILL.md` の手順 5.5 / 6 を更新する
6. `test-workflow-entry.sh` を実行して回帰が無いことを確認する

## 作業ログ

### うまくいったこと

- 011 の仕様（状態機械・ブロック条件・TC 一覧）がそのまま実装の設計図になり、`work-boundary.sh`（約 230 行）と `workflow-boundary.sh`（約 150 行）を一発で書けた。`workflow-guard.sh` は無改修
- `gh` をモック（`PATH` 先頭の偽 `gh` が固定 JSON を返す）にし、bare リポジトリを origin にすることで、非 `--local` の `request`（push・コメント投稿）と `complete`（CHANGES_REQUESTED 拒否・未返信スレッド拒否・自分の投稿と request 以前のコメントの除外）までネットワークなしでテストできた
- 初回実行で失敗した 8 件は全て 1 原因（テスト用リポジトリ内でフックが書く `workflow.log` が未追跡になり `request` のクリーン判定に落ちる）で、テスト側に `.gitignore` を置いて解消

### うまくいかなかったこと

- `jq` の `join` の区切り文字を `""` のエスケープで書いたつもりが、生の 0x1E 文字としてファイルに入った（`workflow-guard.sh` はエスケープ表記）。jq の文字列リテラルとしては有効でテストも通るが、目に見えない文字が残っており可読性が悪い。Edit で当該文字を指定できず直せなかったため、013 か次回の保守で `--arg rs "${WF_RS}"` 方式に書き換えることを残課題にする
- `test-hooks.sh` の実行が 120 秒を超えるようになった（境界フックが `work-boundary.sh status` を子プロセスで呼び、その中で jq を複数回起動するため）。Bash ツールでは `timeout` を延ばしてバックグラウンド実行する必要がある。フックの実行時間そのものは 1 呼び出しあたり体感で問題ないが、`status` の jq 呼び出しを 1 回にまとめる最適化は将来課題
