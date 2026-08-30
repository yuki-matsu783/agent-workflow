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

- [x] `.claude/docs/10_spec/ワークフロー入口ガード.md` の内容（タイトル・本文）が用語マッピングに沿って更新されている
- [ ] ~~`git mv` で `ワークフロー振り分け実施済み判定.md` にリネーム~~ → 見送り（下記「方針変更」参照）。ファイル名は `ワークフロー入口ガード.md` のまま
- [x] `.claude/docs/00_requirements/issue-PR駆動ワークフロー.md` の「入口」表記が更新されている
- [x] `.claude/docs/00_requirements/スキル体系.md` の「入口」表記が更新されている
- [x] `.claude/docs/00_requirements/チケット駆動ワークフロー.md` の「入口」表記が更新されている
- [x] `.claude/docs/10_spec/スキル体系.md` の「入口」表記が更新されている
- [x] `.claude/docs/90_glossary/スキル名.md` の「入口」表記が更新されている
- [x] `.claude/docs/90_glossary/ワークフロー用語.md` の見出し語・本文・keywords の「入口」表記が更新されている
- [x] `.claude/docs/90_glossary/README.md` は変更しない（「入口を提供する」は比喩表現で対象外）
- [x] `grep -rn "入口" .claude/docs/` の結果が README.md の対象外1件＋ファイル名（`ワークフロー入口ガード.md`）への参照のみになっている（確認済み）

### 方針変更: ファイルリネームの見送り

`.claude/docs/**` に対する `git mv` / `git rm` はチケット駆動フックの Bash allowlist で
許可されていない（`mv`/`git mv` は `wip/10_tickets/` 配下同士か `ai-asset-implementation`
タイプでの `.claude/skills/` 配下移動のみ許可。`git rm` も同様に拒否される）。GitHub API
経由でのファイル削除はフックの意図を迂回することになるため行わない。よって仕様書ファイルは
`ワークフロー入口ガード.md` のまま据え置き、**タイトル・本文の用語のみ**更新する。ファイル名を
参照する他ドキュメントのリンクも、リネームは行わず現行ファイル名のまま維持する。

## 作業内容

1. `.claude/docs/10_spec/ワークフロー入口ガード.md` の内容（タイトル・本文）を編集（リネームは見送り）
2. `.claude/docs/00_requirements/*.md` の該当3ファイルを編集
3. `.claude/docs/10_spec/スキル体系.md` を編集
4. `.claude/docs/90_glossary/スキル名.md` / `ワークフロー用語.md` を編集
5. `grep -rn "入口" .claude/docs/` で残存確認

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- `.claude/docs/**` の該当箇所を grep で洗い出してから一括で置換したため、抜け漏れなく進められた
- 置換後に `grep -rn 入口 .claude/docs/` で残存確認したところ、対象外とした2件（README.md の比喩表現、ファイル名参照）のみが残ることを確認できた

### うまくいかなかったこと

- `.claude/docs/**` に対する `git mv` / `git rm` がチケット駆動フックの Bash allowlist で許可されておらず、計画していたファイルリネームができなかった。`ai-asset-design` タイプでは `.claude/docs/**` への書き込みしか許可されず、mv 系コマンドは `wip/10_tickets/` 同士か `ai-asset-implementation` タイプでの `.claude/skills/` 配下移動に限定されている。今後 `.claude/docs/**` のファイルリネームが必要になった場合、workflow-types.json の Bash allowlist 拡張（例: `ai-asset-design` でも `.claude/docs/**` 配下限定の `git mv` を許可する）を検討候補として振り返りに残す
