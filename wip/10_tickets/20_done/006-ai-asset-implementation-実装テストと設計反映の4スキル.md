---
type: ai-asset-implementation
status: todo
depends_on: ["005-ai-asset-implementation-調査と設計の4スキル.md"]
---

# 実装・テスト・設計反映の計画 / 実施スキル（4 件）を作成する

## 目的

`work-implementation-plan` / `work-implementation-exec` / `work-design-sync-plan` / `work-design-sync-exec` を作成する。

## 完了条件（DoD）

- [x] 4 スキルの `SKILL.md` が作成され、節構成（1〜7）・frontmatter が `work-overall-plan` と揃っている
- [x] `work-implementation-exec` にテスト（TDD・失敗ケース・テスト ID）を DoD に含める型が書かれている（`work-implementation-plan` 4-3 の DoD の型、`work-implementation-exec` 4-2）
- [x] `work-design-sync-exec` の DoD の型に「実装差分と設計書（`docs/**`）の突き合わせ」（`work-design-sync-plan` 4-2 の差分一覧）「差分・決定事項の書き戻し」（4-3 の DoD の型）が含まれている
- [x] 各スキルにレビュー観点（節 5）と次ワークへの引き継ぎ（節 6）が書かれている
- [x] 各 `evals/evals.json` に 2 件のケースがある
- [x] 山括弧内に日本語を含むプレースホルダが残っていない（`<対象ファイル>` 等の DoD の型は記法）

## 作業内容

1. 005 で作った計画 / 実施スキルを型として読む
2. 4 スキルを作成する
3. evals を書く

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- 設計反映を「差分一覧を 4 分類（一致 / 設計書が古い / 実装漏れ / 設計に無い決定事項）する計画」と「設計書が古い・決定事項だけを書き戻す実施」に分け、**実装漏れを設計書側で消さない**ルールを計画・実施・evals の 3 箇所で固定した
- 実装ワークの作業ログ「仕様からの逸脱」を設計反映の入力と定義し、フェーズ間の受け渡しが作業ログ経由で成立するようにした（`implementation` は `docs/**` に書けない、という type 定義の割り切りと整合）
- `plan.template.md` は実装計画向けに作られているので、`work-implementation-plan` はそのまま使えた

### うまくいかなかったこと

- 「差分なし」のときも設計反映チケットを 1 枚起こす（証跡のため）と決めたが、ワークが 1 枚で終わるとレビュー往復が重く感じる可能性がある。運用で「approve のみで可」と添える前提。振り返りで残課題にする
