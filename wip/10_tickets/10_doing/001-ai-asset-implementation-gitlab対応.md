---
type: ai-asset-implementation
status: todo
depends_on: []
---

# task-gh-feature を GitHub/GitLab 両対応にする（スキル実装）

## 目的

`.claude/skills/task-gh-feature/` を `git remote get-url origin` のホスト名で GitHub/GitLab を
自動判定し、対応する CLI（`gh`/`glab`）のコマンドに切り替えるフローに書き換える
（全体計画 `wip/00_overall_plan/composed-discovering-newt.md` の対応方針・コマンド対応表に従う）。

## 完了条件（DoD）

- [ ] `task-gh-feature/SKILL.md` の frontmatter description に GitLab/glab のトリガー語（"glab"、
      "MR"、"merge request" 等）が追加されている
- [ ] 手順0（前準備チェック）にプラットフォーム判定（`task-repo-merge-settings` と同方式。
      判定不能なら `AskUserQuestion` で確認）が追加されている
- [ ] 手順1（デフォルトブランチ取得）・手順6（PR/MR作成）・issue連携モードのコマンドが
      GitHub（`gh`）/GitLab（`glab`）双方で記載されている（全体計画のコマンド対応表に準拠）
- [ ] `glab mr create` に非対話実行のための `--yes` が明記されている
- [ ] 手順7（結果報告）・「考慮すべき状況と対応方法」・エラーハンドリング表が GitLab 観点
      （未導入/未認証/プラットフォーム判定不能）を含む内容に更新されている
- [ ] `task-gh-feature/evals/evals.json` に GitLab（`glab mr create` 系コマンドを期待する）
      シナリオが1件追加されている。既存3件のGitHubシナリオは変更しない
- [ ] `workflow-issue-mr-driven/SKILL.md` のエラーハンドリング表「origin が GitHub でない →
      対象外として報告する（GitLab の MR は未対応）」が、task-gh-feature の GitLab 対応に
      合わせた内容に更新されている
- [ ] issue #23 の受け入れ条件をすべて満たす

## 作業内容

1. `task-gh-feature/SKILL.md` を全体計画のコマンド対応表に従って書き換える
   （frontmatter description → 手順0 → 手順1 → 手順6 → issue連携モード → 手順7 →
   考慮すべき状況 → エラーハンドリング表の順）
2. `task-gh-feature/evals/evals.json` に GitLab シナリオを追加する
3. `workflow-issue-mr-driven/SKILL.md` の該当箇所を更新する
4. SKILL.md 全体を読み直し、GitHub 専用の表現が残っていないか確認する
5. 作業ログに結果を記録する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
