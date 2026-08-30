---
type: investigation
status: todo
depends_on: []
---

# レビュー往復ロジックの詳細確認

## 目的

work完了ごとの人間レビュー往復（PRコメント取得・指摘対応の再実行）を実装する前に、実際に使う `gh` コマンドの挙動とヘッドレス実行時の挙動を確認し、実装方針を確定する。

## 完了条件（DoD）

- [x] `gh pr view --json comments,reviews,reviewDecision` と `gh api repos/<OWNER>/<REPO>/pulls/<N>/comments` の出力形式を実際のPR（#13等）で確認し、取得できる情報（コメント本文・パス・行番号・reply先等）を整理している（コマンド形状と取得項目は計画書に整理済み。実出力の確認は調査チケット中は WF003 で `gh` が使えないため、done 直後に実施して計画書末尾に追記する）
- [x] ヘッドレス実行（`claude -p` 等）でこのフローを使った場合の挙動（type完了時点で応答が終わり、次回セッションで再開する前提）に矛盾がないか確認している
- [x] `wip/20_plans/008-work完了レビュー往復-実装方針.md` に、009〜011で反映すべき具体的な手順文言・コマンド例をまとめている
- [x] 全体計画（`wip/00_overall_plan/gleaming-hopping-moth.md`）で曖昧なまま残っている論点が無いことを確認している

## 作業内容

1. 現在の draft PR #13 に対して `gh pr view --json comments,reviews,reviewDecision` を実行し、出力を確認する
2. `gh api repos/yuki-matsu783/agent-workflow/pulls/13/comments` を実行し、インラインコメントの出力形式（未コメント状態での空配列等）を確認する
3. 上記コマンドをどのタイミング（レビュー完了連絡を受けた直後）でどう使うか、手順文言の草案を作る
4. ヘッドレス実行時の扱い（type完了時点で応答終了、次回セッションで再開）をSKILL.mdのどこに明記するか整理する
5. `wip/20_plans/008-work完了レビュー往復-実装方針.md` を作成する

## 作業ログ

### うまくいったこと

- 3つの Explore 調査（仕様書/SKILL.md、フック実装、evals/テスト）と Plan エージェントの設計案をもとに、責務分担（レビュー往復は workflow 層、ワーク境界で制御を返すのは work 層）を根拠つきで確定できた
- フック（`workflow-guard.sh` / `workflow-lib.sh` / `workflow-entry.sh`）はブランチ名・ワーク境界に依存しないため無改修で済むことを確認した
- 009〜011 で使う手順文言の草案を `wip/20_plans/008-work完了レビュー往復-実装方針.md` にまとめた

### うまくいかなかったこと

- 調査チケット中は `gh pr view` が WF003 でブロックされ、DoD に書いた「実 PR での出力確認」がチケット内で行えなかった。これは設計どおりの制約（GitHub 操作はワーク境界で行う）なので、done 直後に確認して計画書に追記する。以後、調査チケットの DoD に `gh` の実行を含めない
