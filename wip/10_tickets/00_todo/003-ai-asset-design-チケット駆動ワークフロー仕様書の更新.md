---
type: ai-asset-design
status: todo
depends_on: ["002-ai-asset-design-plan-AIアセット設計計画.md"]
---

# チケット駆動ワークフロー仕様書に git add の対象パス規約とテストシナリオを追記する

## 目的

設計計画書（wip/20_plans/AIアセット設計計画-skill-git-add-paths.md）の (a)〜(d) に従い、`.claude/docs/10_spec/チケット駆動ワークフロー.md` に「チケット運用のコミットでは `git add` の対象を `wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` 全体を指定しない」規約を書き、処理フローとテストシナリオを揃える（受け入れ条件③④の設計側）。

## 完了条件（DoD）

- [ ] .claude/docs/10_spec/チケット駆動ワークフロー.md の「Bash コマンドの許可」チケット運用コマンドの箇条書きに、`git add` の対象を `wip/10_tickets/` と作業タイプの許可パス内のファイルに限定し `wip/` のようなディレクトリ全体を指定しない規約と、その理由（`wip/` は未記載 → WF009、Bash の承認はセッション記憶されない）が task-spec の型に沿って追記されている
- [ ] 同仕様書の「処理フロー」基本フロー 3・6 のコマンド表記が規約に合わせて `git add wip/10_tickets/`・`git add wip/10_tickets/ <許可パス内の変更ファイル>` になっている
- [ ] 受け入れ条件④がテストシナリオ TC022b（`git add wip/` → ask WF009）・TC022c（`investigation` で `git add wip/10_tickets/ wip/20_plans/x.md` → exit 0。`overall-plan` の例を併記するかは判断して作業ログに書く）に落ちている
- [ ] ヘッドレス実行時の挙動（従来の `git add wip/` は ask が自動拒否されるため失敗する。規約に合わせた手順ではこの問題も解消される）が規約に添えられている
- [ ] レビュー記録に 2.3（issue #47）が追記されている。要件定義書・用語辞書・横断文書は変更不要と設計計画で判断済みのため触らない

## 作業内容

1. `task-spec` を Skill ツールで読み込み、既存仕様書の更新手順に従う
2. 節見出し（「Bash コマンドの許可（deny-by-default）」「基本フロー（ハッピーパス：スキル全体）」「テストケース一覧」「レビュー記録」）を基準に局所的に Edit する
3. TC022b / TC022c の期待値を `workflow-guard.sh` の `wf_validate_add` の判定と読み合わせて確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
