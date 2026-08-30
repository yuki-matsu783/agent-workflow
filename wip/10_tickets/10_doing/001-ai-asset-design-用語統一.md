---
type: ai-asset-design
status: todo
depends_on: []
---

# 「入口」→「振り分け」/「入口ガード」→「振り分け実施済み判定」用語統一（設計ドキュメント）

## 目的

`.claude/docs/**` 配下の要件定義書・仕様書・用語集にある「入口」「入口ガード」表記を、
全体計画の用語マッピングに従って「振り分け」「振り分け実施済み判定」に統一する。
仕様書ファイル `ワークフロー入口ガード.md` は `ワークフロー振り分け実施済み判定.md` に
リネームする。

## 完了条件（DoD）

- [ ] `.claude/docs/10_spec/ワークフロー入口ガード.md` の内容が用語マッピングに沿って更新され、
      `git mv` で `.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md` にリネームされている
- [ ] `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` の「入口」表記が更新されている
- [ ] `.claude/docs/00_requirements/スキル体系.md` の「入口」表記が更新されている
- [ ] `.claude/docs/00_requirements/チケット駆動ワークフロー.md` の「入口」表記が更新されている
- [ ] `.claude/docs/10_spec/スキル体系.md` の「入口」表記（リネーム後のファイル名参照を含む）が更新されている
- [ ] `.claude/docs/90_glossary/スキル名.md` の「入口」表記が更新されている
- [ ] `.claude/docs/90_glossary/ワークフロー用語.md` の見出し語・本文・keywords の「入口」表記が更新されている
- [ ] `.claude/docs/90_glossary/README.md` は変更しない（「入口を提供する」は比喩表現で対象外）
- [ ] `grep -rn "入口" .claude/docs/` の結果が README.md の対象外1件のみになっている

## 作業内容

1. `.claude/docs/10_spec/ワークフロー入口ガード.md` を編集し、`git mv` でリネーム
2. `.claude/docs/00_requirements/*.md` の該当3ファイルを編集
3. `.claude/docs/10_spec/スキル体系.md` を編集（リネーム後のファイルパス参照も更新）
4. `.claude/docs/90_glossary/スキル名.md` / `ワークフロー用語.md` を編集
5. `grep -rn "入口" .claude/docs/` で残存確認

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
