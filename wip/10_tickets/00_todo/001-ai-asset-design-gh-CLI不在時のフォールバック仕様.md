---
type: ai-asset-design
status: todo
depends_on: []
---

# gh CLI 不在時のフォールバック仕様

## 目的

`work-boundary.sh`/`merge-prep.sh` が gh CLI に依存しているため、gh が使えない実行環境では機能停止する（issue #41）。gh 不在時に MCP ツール等で取得した実データをスクリプトに渡すフォールバック経路を仕様化する。

## 完了条件（DoD）

- [ ] `.claude/docs/00_requirements/チケット駆動ワークフロー.md` に、gh 不在時のフォールバックと証跡強度低下の明記に関する受け入れ基準が追加されている
- [ ] `.claude/docs/10_spec/チケット駆動ワークフロー.md`「ワーク境界の判定とレビュー状態」に、`--pr`/`--external`/`--comment-url`/`--review-decision`/`--comment-ids`/`--inline-ids` の仕様が追記されている
- [ ] 同ファイル「マージ前作業の判定と状態」に、`--pr`/`--pr-body-file`/`--posted`/`--external`（ready）の仕様が追記されている
- [ ] 状態ファイル（`review-state.json`/`merge-prep.json`）のスキーマに `via: "gh" | "external"` が追加されている
- [ ] 既存の gh CLI が使える環境での動作に影響しないことが明記されている（デフォルト挙動は変えない）
- [ ] 両ファイルのレビュー記録に新バージョン行（issue #41）が追加されている

## 作業内容

1. `.claude/docs/00_requirements/チケット駆動ワークフロー.md` を Read し、受け入れ基準・レビュー記録を Edit で追加する
2. `.claude/docs/10_spec/チケット駆動ワークフロー.md` を Read し、両セクションとエラーコード表・状態遷移・レビュー記録を Edit で追加する
3. 002（実装）で使う具体的なフラグ名・データ形式を仕様として確定し、実装がそのまま従える粒度で書く

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
