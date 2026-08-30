---
type: ai-asset-implementation
status: todo
depends_on: ["016-ai-asset-implementation-merge-prepスクリプトとフック.md"]
---

# workflow-issue-mr-driven の完了処理（手順 6）をマージ前作業込みに改訂する

## 目的

`workflow-issue-mr-driven/SKILL.md` の手順 6 を「PR 本文の最終整形 → 承認③ → `merge-prep.sh reset-wip` → `check-conflicts`（承認⑤）→ `notify-issue`（承認⑥）→ `ready` → 報告して停止」に全面改稿し、issue コメント本文のテンプレートと evals を追加する。`task-gh-feature/SKILL.md` の直接 `gh pr ready` の記述に注記を付ける。

## 完了条件（DoD）

- [x] `.claude/skills/workflow-issue-mr-driven/SKILL.md` の役割分担表に `merge-prep.sh`、承認ポイント表に⑤⑥、手順 6 が 015 の仕様と一致する手順（6-1〜6-7）に改稿され、フロー図・エラーハンドリング（WF015 / WF016 / 衝突あり / notify 失敗 / ヘッドレス）・ベストプラクティスが更新されている
- [x] `.claude/skills/workflow-issue-mr-driven/assets/issue-notify.template.md` が新規作成されている（対象 PR・変更の要約・受け入れ条件との対応・成果物・マージ後の扱い）。`markdown-frontmatter.md` の対象外表に追加
- [x] `.claude/skills/workflow-issue-mr-driven/evals/evals.json` の id 3 が新手順に更新され、id 7（reset-wip の前提未充足）・id 8（衝突あり）・id 9（直接 `gh pr ready` が WF015）が追加された。JSON の妥当性は done 後に `jq` で確認（チケット作業中は allowlist 外）
- [x] `.claude/skills/task-gh-feature/SKILL.md` の issue 連携モード末尾の `gh pr ready N` を `merge-prep.sh ready` に置き換え、直接実行が WF015 で拒否される旨（単独利用時を含む）を注記
- [x] `grep -rn "gh pr ready" .claude/skills .claude/docs` で、直接実行を指示する旧記述が残っていない（`merge-prep.sh` の内部実装と WF015 の説明のみ）

## 作業内容

1. SKILL.md の手順 6・承認ポイント・フロー図・役割分担・エラーハンドリングを改稿する
2. 通知テンプレートを新設する
3. evals.json を更新する
4. task-gh-feature の注記を追加する
5. `grep` で残存確認、`jq . evals.json` で妥当性確認

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- 手順 6 を 5-1〜5-8 と同じ表形式（# / やること / 補足）に揃え、各行に対応するサブコマンドと WF コードを書いたので、仕様書（基本フロー 8）と 1 対 1 で突き合わせられる
- 通知テンプレートは `pr.template.md` / `issue.template.md` と同じ「GitHub にそのまま投稿される」扱いにし、`markdown-frontmatter.md` の対象外表にも追加した（frontmatter が本文に出ない）

### うまくいかなかったこと

- `task-gh-feature` を単独で使う場合も `gh pr ready` がフックで常時拒否される副作用がある。単独時は人間が GitHub 上で ready にするか完了処理を通す旨を同スキルに注記したが、単独用途を重視するなら「`wip/merge-prep.json` が無いときは許可」等の緩和を別 issue で検討する余地がある
- `jq` が読み取り系 allowlist に無く、チケット作業中に evals.json の妥当性を機械確認できない。done 後（doing が空）に確認する
