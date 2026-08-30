---
type: ai-asset-implementation
status: todo
depends_on: ["022-ai-asset-design-ドキュメント作成スキル要件仕様.md"]
---

# ドキュメント作成スキル群のSKILL.mdに要件仕様への参照リンクを追加する

## 目的

022で新設したrequirements/specsへの参照リンクを `task-requirements` / `task-spec` のSKILL.mdに追加する。

## 完了条件（DoD）

- [x] `task-requirements/SKILL.md` に `要件定義書作成.md` への参照リンク2行が追加されている
- [x] `task-spec/SKILL.md` に `仕様書作成.md` への参照リンク2行が追加されている
- [x] リンク先パスが実在する
- [x] 各SKILL.mdの本文（手順・振る舞い）は変更していない
- [x] `.claude/docs/**` は変更していない

## 作業内容

1. 対象2スキルのSKILL.mdに、既存書式で要件/仕様への参照リンクを追加する
2. リンク先ファイルが実在することを確認する

## 作業ログ

### うまくいったこと

- 025と同じ書式をそのまま適用できた

### うまくいかなかったこと

- なし
