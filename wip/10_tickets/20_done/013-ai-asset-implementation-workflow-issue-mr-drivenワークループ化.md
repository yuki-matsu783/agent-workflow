---
type: ai-asset-implementation
status: todo
depends_on: ["012-ai-asset-implementation-ワーク境界スクリプトとフック.md"]
---

# workflow-issue-mr-driven のワークループ化とブランチ命名規約変更

## 目的

`workflow-issue-mr-driven` の手順5・6を、work（チケットtype）完了ごとにpush・PR本文更新・レビュー依頼・ターン終了、次発言でのコメント取得・再実行を行うループに改稿する。あわせてブランチ命名規約をハイフン区切りに変更する。

## 完了条件（DoD）

- [x] `workflow-issue-mr-driven/SKILL.md`の手順5が、「初回のみ全体計画+チケット作成→以降はworkループ」に改稿されている
- [x] workループの各ステップ（5-1〜5-8: push→PR本文更新→`request`→報告して応答終了→`complete`→指摘の提示と対応要否確認→同typeの追加チケットで再実行）が表で明記されている
- [x] ループ内の境界判定・レビュー依頼・コメント取得は `work-boundary.sh`（`status` / `request` / `complete` / `reply`）を使う手順になっている（`gh pr comment` 直接実行・状態ファイル直接編集の記述が無いことを grep で確認）
- [x] 手順6が「PR本文の最終整形と承認③」に縮小されている
- [x] 命名規約表が `<prefix>-<N>-<slug>` に更新されている
- [x] ヘッドレス実行時の扱い・合図なし続行・WF011〜WF014 の対処がエラーハンドリング表に明記されている
- [x] `assets/issue-addendum.template.md`のブランチ名記入例がハイフン区切りに更新されている
- [x] `evals/evals.json`のブランチ名期待値がハイフン区切りに更新され、id 4（境界でrequestして応答終了）、id 5（completeで指摘0件）、id 6（WF014→追加チケット）を追加
- [x] `task-gh-feature/SKILL.md`のissue連携モード入力表のブランチ名例のみハイフン区切りに更新（単独モードの一般ガイドは変更なし）
- [x] `bash .claude/hooks/tests/test-workflow-entry.sh` PASS=40 FAIL=0（無改修）

## 作業内容

1. 009・010の成果物（改訂済み仕様書・work-ticket-driven新手順）を読む
2. `workflow-issue-mr-driven/SKILL.md`を改訂する（手順5・6・命名規約表・エラーハンドリング）
3. `workflow-issue-mr-driven/assets/issue-addendum.template.md`を更新する
4. `workflow-issue-mr-driven/evals/evals.json`を更新する
5. `task-gh-feature/SKILL.md`のissue連携モード入力表を更新する
6. `bash .claude/hooks/tests/test-workflow-entry.sh`を実行し、無改修で通ることを確認する

## 作業ログ

### うまくいったこと

- 009 / 011 で仕様書に確定した文言（承認④、ワークループ 7-1〜7-6、WF011〜WF014）をそのまま SKILL.md の手順 5（5-1〜5-8 の表）に落とせた。仕様→スキルの順で進めた効果で、SKILL.md 側で新たに判断することがほぼ無かった
- 012 で実装した `work-boundary.sh` を実リポジトリで `status` 実行し、「012 done・013 は同 type → 境界でない」と正しく判定されることを確認した上で 013 に着手した（ドッグフーディング）
- evals.json に「境界でレビュー依頼して応答を終える」「complete で指摘 0 件」「WF014 で止まり追加チケットで対応」の 3 ケースを追加し、スクリプト前提の期待値に揃えた
- `task-gh-feature` は issue 連携モードの入力表のみ変更し、単独モードの一般的な命名ガイド（スラッシュ可）は残した

### うまくいかなかったこと

- 特になし。012 の残課題（`join` の区切り文字が生の 0x1E で入っている件、`test-hooks.sh` の実行時間）は本チケットの範囲外のため 014 の残課題に引き継ぐ
