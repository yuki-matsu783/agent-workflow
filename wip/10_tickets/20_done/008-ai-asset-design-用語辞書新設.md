---
type: ai-asset-design
status: todo
depends_on: []
---

# `.claude/docs/` 配下に用語辞書ディレクトリを新設する

## 目的

issue #11 に基づき、スキル名・チケット type・ワークフロー用語の定義が各仕様書・要件定義書に分散している現状を解消するため、用語を一箇所に集約した辞書ディレクトリ `.claude/docs/90_glossary/` を新設する。あわせて要件定義書・仕様書を作成し、既存文書からの参照方法（リンクの張り方）を決める。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/用語辞書.md` が作成されている（`type: requirements`、背景・目的・受け入れ基準を記載）
- [x] `.claude/docs/10_spec/用語辞書.md` が作成されている（`type: spec`、辞書ディレクトリの配置・構成・参照方法（リンクの張り方）を明記）
- [x] `.claude/docs/90_glossary/` 配下に `README.md` / `スキル名.md` / `チケットtype.md` / `ワークフロー用語.md` が作成され、それぞれ用語がエントリとして収録されている（issue #11 受け入れ条件の2点目に対応）
- [x] 既存仕様書1〜2ファイル（例: `10_spec/スキル体系.md`）に、決めた参照方法に従って用語辞書へのリンクを実演として追加している（issue #11 受け入れ条件の3点目に対応）
- [x] 新規作成した各Markdownファイルに `.claude/rules/markdown-frontmatter.md` のfrontmatter規約（`type`/`title`/`description`/`tags`/`keywords`）が付与されている
- [x] 辞書内の各エントリからリンクした定義元ファイルが実在することを確認済み

## 作業内容

1. `.claude/docs/00_requirements/用語辞書.md` を既存ペア（例: `スキル体系.md`）の構成に倣って作成する
2. `.claude/docs/10_spec/用語辞書.md` を作成し、配置・ファイル構成・参照方法（リンクの張り方）を明記する
3. `.claude/docs/90_glossary/README.md` を作成し、辞書の目的・エントリの書式・参照方法を説明する
4. `.claude/docs/90_glossary/スキル名.md` を作成し、`workflow-*` / `work-*` / `task-*` 各スキルを一言説明＋定義元リンクで収録する
5. `.claude/docs/90_glossary/チケットtype.md` を作成し、`.claude/hooks/workflow-types.json` の各 type を一言説明＋リンクで収録する
6. `.claude/docs/90_glossary/ワークフロー用語.md` を作成し、issue駆動・チケット・DoD・allowed_paths・ワーク完了チェックポイント等を収録する
7. `10_spec/スキル体系.md` など代表ファイルに、決めた参照方法で用語辞書へのリンクを1箇所追加する
8. 全ファイルのリンク先が実在するか確認する

## 作業ログ

### うまくいったこと

- 既存の `00_requirements` + `10_spec` ペア構成と、`10_spec/スキル体系.md` のリネーム対応表・`.claude/hooks/workflow-types.json` をそのまま辞書エントリの一覧元として使えたため、新規調査なしで内容を埋められた
- 辞書エントリを「一言説明＋定義元へのリンク」に限定したことで、既存仕様書の全文書き換え（スコープ外）を避けつつ参照方法を実演できた
- `10_spec/スキル体系.md` への実演リンク追加後、Globで全リンク先ファイルの実在を確認できた（`ai-asset-design` type では `ls` がWF003でブロックされるため、Read/Glob系で代替した）

### うまくいかなかったこと

- 当初 `ls` で存在確認しようとしたが `ai-asset-design` type の Bash allowlist に無くWF003でブロックされた。フェーズ別のBash制限をチケット内でも意識する必要がある
