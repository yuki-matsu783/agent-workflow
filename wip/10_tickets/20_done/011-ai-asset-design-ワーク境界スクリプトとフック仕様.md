---
type: ai-asset-design
status: todo
depends_on: ["010-ai-asset-implementation-work-ticket-driven分割.md"]
---

# ワーク境界スクリプトとフックの仕様策定

## 目的

ワーク境界の判定とレビュー状態の管理を LLM の判断に頼らず、スクリプトで決定論的に判定できるようにする。想定外の操作（レビュー未完了で次 type に着手する等）をフックが exit 2 でブロックし、理由を LLM に伝える仕様を `.claude/docs/10_spec/チケット駆動ワークフロー.md` に確定する。

## 完了条件（DoD）

- [x] `work-boundary.sh` のサブコマンド（`status` / `request` / `complete` / `reply`）の入出力（JSON 形式・exit code）が仕様書に定義されている
- [x] レビュー状態ファイル（`wip/10_tickets/review-state.json`、git 管理）のスキーマ（`ticket` / `work_type` / `state` / `local` / `pr` / `head_sha` / `request.*` / `complete.*`）が定義されている。「境界コミット」は done 末尾のチケット名（`ticket`）で識別する方式にした（コミットハッシュより、done チケットが増えると自動で失効する性質が扱いやすい）
- [x] フックがブロックする操作と新しいエラーコード（WF011 境界違反 / WF012 状態ファイルの直接書き換え / WF013 request 前提未充足 / WF014 complete 前提未充足）が、既存の「エラーコード一覧」「エラーメッセージ仕様」の形式で追記されている
- [x] 「doing が空のときフックは何もしない」という現行の基本フローとの整合: `workflow-guard.sh` は変更せず、新規フック `workflow-boundary.sh` を別登録して doing が空でも動かす、と明記
- [x] **レビュー状態ファイルを生成 AI が直接書き換えられない**仕様: WF012（Edit / Write / NotebookEdit、Bash の `rm` / `sed -i` / リダイレクト / `git checkout --` 等。読み取りと `work-boundary.sh` 経由のみ許可）。doing の有無を問わない
- [x] `request` / `complete` が GitHub の実操作を自ら行い、証跡（コメント id / URL / HEAD、取得したコメント id 一覧 / `reviewDecision`）を記録する仕様
- [x] `complete` が機械的に拒否する条件（`requested` でない / `CHANGES_REQUESTED` / 未返信インラインスレッド / `--local` 不一致）を定義。「`request` 以降の新規コメント」は拒否条件にせず「取得して出力する」責務にした（新規コメントの有無で拒否すると、レビュアーが approve コメントを書いただけで通らなくなるため）。対応要否の判断は人間に残す
- [x] 単独実行の経路（`request --local` → `complete --local`）を定義。証跡が無く会話上の承認に依存することを明記
- [x] テストケース TC024〜TC028 を列挙（`gh` はモックで固定 JSON を返す方式）
- [x] `スキル体系.md` の「フックはワーク境界を検知しない」を撤回し、新仕様へ更新。`issue-PR駆動ワークフロー.md` のワークループ 7-4/7-5・`gh` コマンド・制約・代替フロー 6 も `work-boundary.sh` 前提に更新

## 作業内容

1. `.claude/hooks/workflow-guard.sh` / `workflow-lib.sh` の構造（`wf_init` の早期 exit、`check_bash`、エラーメッセージ関数）を読み、境界判定をどこに差し込むか決める
2. 状態ファイルのスキーマとスクリプトのサブコマンドを設計する
3. ブロック条件とエラーコード・メッセージ（「対処:」の文言）を設計する
4. `.claude/docs/10_spec/チケット駆動ワークフロー.md` に追記し、`スキル体系.md` の該当記述を更新する
5. レビュー記録に追記する

## 作業ログ

### うまくいったこと

- `workflow-guard.sh` を変更せず、新規フック `workflow-boundary.sh` を別登録する構成にしたので、既存の 62 件の TC に影響を与えずに境界統制を足せる
- 状態ファイルの識別子を「done 末尾のチケット名」にしたことで、追加チケット（差し戻し対応）が done になると状態が自動で失効し、再 `request` が必要になる。差し戻し→対応→再レビューの経路が状態機械として閉じた
- 「同 type の追加チケットは境界でも着手できる」を WF011 の例外として明示し、差し戻し対応の経路をフックが塞がないようにした

### うまくいかなかったこと

- `complete` の拒否条件に当初「request 以降の新規コメントがある」を含めようとしたが、レビュアーが approve 目的で書いたコメントでも通らなくなるため外した。「取得したことを保証し、対応要否は人間に残す」に線を引き直した
- doing があるときは `work-boundary.sh status` 自体が WF003（Bash allowlist 外）になる。境界判定は done 直後にだけ行う運用なので実害は無いが、`status` だけは doing 中も読み取り扱いで通してよいかは 012 の実装時に判断する（許可するなら `workflow-guard.sh` の READONLY_RE を触ることになり「guard は変更しない」に反するため、現時点では許可しない）
