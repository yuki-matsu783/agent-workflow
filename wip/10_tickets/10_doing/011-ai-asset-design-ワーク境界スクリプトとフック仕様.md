---
type: ai-asset-design
status: todo
depends_on: ["010-ai-asset-implementation-work-ticket-driven分割.md"]
---

# ワーク境界スクリプトとフックの仕様策定

## 目的

ワーク境界の判定とレビュー状態の管理を LLM の判断に頼らず、スクリプトで決定論的に判定できるようにする。想定外の操作（レビュー未完了で次 type に着手する等）をフックが exit 2 でブロックし、理由を LLM に伝える仕様を `.claude/docs/10_spec/チケット駆動ワークフロー.md` に確定する。

## 完了条件（DoD）

- [ ] `work-boundary.sh`（仮称）のサブコマンド（`status` / `request` / `complete`）の入出力（JSON 形式・exit code）が仕様書に定義されている
- [ ] レビュー状態ファイル（`wip/10_tickets/review-state.json`、git 管理）のスキーマ（対象 type・境界コミット・状態 `requested` / `completed`・日時）が定義されている
- [ ] フックがブロックする操作と新しいエラーコード（WF011〜。例: 境界でレビュー未完了のまま次 type に着手、境界でないのに request、requested のまま complete を経ずに着手）が、既存の「エラーコード一覧」「エラーメッセージ仕様」の形式で追記されている
- [ ] 「doing が空のときフックは何もしない」という現行の基本フロー（PreToolUse フック 2）との整合が取れている（doing 空でも境界判定だけは行う、という変更点が明記されている）
- [ ] **レビュー状態ファイルを生成 AI が直接書き換えられない**仕様になっている: Edit / Write / NotebookEdit による `review-state.json` への書き込み、および Bash のリダイレクト・`sed -i` 等による書き換えを、doing の有無にかかわらずフックが exit 2 で拒否する（`wip/10_tickets/**` の global allow の例外として定義）。書き換えは `work-boundary.sh` のサブコマンド経由のみ
- [ ] `request` / `complete` が GitHub の実操作を自ら行い、その証跡を状態ファイルに記録する仕様になっている: `request` は `gh pr comment` を自身で実行して投稿コメントの id / URL を記録し、`complete` は `gh pr view` / `gh api .../pulls/N/comments` を自身で実行して取得したコメント id 一覧と `reviewDecision` を記録する。LLM が「依頼した」「確認した」と主張するだけでは状態が進まない
- [ ] `complete` が機械的に拒否する条件（例: `reviewDecision` が `CHANGES_REQUESTED`、返信の無いインラインコメントが残っている、`request` 以降に取得していない新規コメントがある）が定義され、拒否時は exit 2 で理由を出力する。指摘の「対応要否」の判断自体は人間（AskUserQuestion）に残す
- [ ] 単独実行（PR なし）でも `complete` を通せる経路（AskUserQuestion 後に `complete --local` 等）が定義されている。この経路も状態ファイルの書き換えはスクリプトが行う
- [ ] テストケース（TC の追加分）が仕様書のテストシナリオに列挙されている
- [ ] `.claude/docs/10_spec/スキル体系.md`「ワーク完了チェックポイント」の「フックはワーク境界を検知しない」という記述を、新仕様に合わせて更新している

## 作業内容

1. `.claude/hooks/workflow-guard.sh` / `workflow-lib.sh` の構造（`wf_init` の早期 exit、`check_bash`、エラーメッセージ関数）を読み、境界判定をどこに差し込むか決める
2. 状態ファイルのスキーマとスクリプトのサブコマンドを設計する
3. ブロック条件とエラーコード・メッセージ（「対処:」の文言）を設計する
4. `.claude/docs/10_spec/チケット駆動ワークフロー.md` に追記し、`スキル体系.md` の該当記述を更新する
5. レビュー記録に追記する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
