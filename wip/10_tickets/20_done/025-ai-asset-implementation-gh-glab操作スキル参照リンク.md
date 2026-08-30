---
type: ai-asset-implementation
status: todo
depends_on: ["021-ai-asset-design-gh-glab操作スキル要件仕様.md"]
---

# gh/glab操作スキル群のSKILL.mdに要件仕様への参照リンクを追加する

## 目的

021で新設した4スキル分のrequirements/specsへの参照リンクを、それぞれのSKILL.mdに追加する。

## 完了条件（DoD）

- [x] `task-gh-feature/SKILL.md` のH1見出し直後・最初の `##` 節より前に `- 要件: .claude/docs/00_requirements/featureブランチとPR作成.md` / `- 仕様: .claude/docs/10_spec/featureブランチとPR作成.md` の2行が追加されている
- [x] `task-gh-install/SKILL.md` に `CLIインストール.md` への同様の2行が追加されている
- [x] `task-gh-issue/SKILL.md` に `issue操作.md` への同様の2行が追加されている
- [x] `task-repo-merge-settings/SKILL.md` に `マージ設定変更.md` への同様の2行が追加されている
- [x] リンク先パスが実在する（021で作成したファイルと一致する）
- [x] 各SKILL.mdの `##` 以降の本文（手順・振る舞い）は変更していない
- [x] `.claude/docs/**` は変更していない

## 作業内容

1. `workflow-issue-mr-driven/SKILL.md` の参照リンク書式を確認する
2. 対象4スキルのSKILL.mdそれぞれに、同じ書式で要件/仕様への参照リンクを追加する
3. リンク先ファイルが実在することを `ls` で確認する

## 作業ログ

### うまくいったこと

- `workflow-issue-mr-driven/SKILL.md` の書式（H1直後、導入文の後、最初の`##`節の前に箇条書き2行）をそのまま4スキルに適用でき、迷いなく進められた
- task-repo-merge-settingsは重要注意書き（`>`ブロック）があったが、その直後・`##対象設定`の前に挿入することで自然に収まった

### うまくいかなかったこと

- なし
