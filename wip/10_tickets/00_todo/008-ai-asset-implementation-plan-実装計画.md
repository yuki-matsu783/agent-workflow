---
type: ai-asset-implementation-plan
status: todo
depends_on: ["007-ai-asset-design-要件定義書と用語辞書の更新.md"]
---

# AIアセット実装計画

## 目的

仕様書・要件定義書をもとに、`workflow-boundary.sh`（例外条件の追加）と`workflow-diff-check.sh`（内容検証の警告）の変更点、テスト方針、実装ステップを実装計画書にまとめ、実装チケット群と次の計画チケット（振り返り）を起こす。

## 完了条件（DoD）

- [ ] wip/20_plans/ に実装計画書が作成され、変更対象ファイル・テスト方針・実装ステップが記載されている
- [ ] 実装チケット群が todo に起票されている
- [ ] 次の計画チケット（retrospective）が todo に起票されている

## 作業内容

1. `work-ai-asset-implementation-plan`の手順に従い、更新済みの仕様書（.claude/docs/10_spec/skill-work-ticket-driven.md）を読み込む
2. `workflow-boundary.sh`の`wf012()`呼び出し前に検出条件（MERGE_HEAD存在 かつ 対象ファイルがunmerged）を追加する変更点を計画する
3. `workflow-diff-check.sh`に内容検証（有効なJSON・マーカー残存なし・unmerged解消済み）の警告を追加する変更点を計画する
4. 既存のWF012保護（マージ進行中でない場合の常時拒否）を壊さないテスト、および例外が正しく働くテストの方針を計画する
5. 実装チケットと振り返りチケットを起こす

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
