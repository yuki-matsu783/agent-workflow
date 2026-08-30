---
type: ai-asset-design
status: done
depends_on: []
---

# gh CLI 不在時のフォールバック仕様

## 目的

`work-boundary.sh`/`merge-prep.sh` が gh CLI に依存しているため、gh が使えない実行環境では機能停止する（issue #41）。gh 不在時に MCP ツール等で取得した実データをスクリプトに渡すフォールバック経路を仕様化する。

## 完了条件（DoD）

- [x] `.claude/docs/00_requirements/チケット駆動ワークフロー.md` に、gh 不在時のフォールバックと証跡強度低下の明記に関する受け入れ基準が追加されている
- [x] `.claude/docs/10_spec/チケット駆動ワークフロー.md`「ワーク境界の判定とレビュー状態」に、`--pr`/`--external`/`--comment-url`/`--report-file`（`review_decision`/`comment_ids`/`inline_ids`/`unresolved_threads` を含む）の仕様が追記されている
- [x] 同ファイル「マージ前作業の判定と状態」に、`--pr`/`--pr-body-file`/`--posted`/`--external`（notify-issue・ready）の仕様が追記されている
- [x] 状態ファイル（`review-state.json`/`merge-prep.json`）のスキーマに `via: "gh" | "local" | "external"` が追加されている
- [x] 既存の gh CLI が使える環境での動作に影響しないことが明記されている（デフォルト挙動は変えない）
- [x] 両ファイルのレビュー記録に新バージョン行（issue #41）が追加されている

## 作業内容

1. `.claude/docs/00_requirements/チケット駆動ワークフロー.md` を Read し、受け入れ基準・レビュー記録を Edit で追加する
2. `.claude/docs/10_spec/チケット駆動ワークフロー.md` を Read し、両セクションとエラーコード表・状態遷移・レビュー記録を Edit で追加する
3. 002（実装）で使う具体的なフラグ名・データ形式を仕様として確定し、実装がそのまま従える粒度で書く

## 作業ログ

### うまくいったこと

- `complete`（work-boundary.sh）の実データ受け渡しを、当初想定した個別フラグ（`--review-decision`/`--comment-ids`/`--inline-ids`）ではなく `--report-file <path>` 1本にまとめたことで、CLI がシンプルになり、`unresolved_threads` のような構造化データも自然に渡せた
- issue #3 の完了処理での手作業（git rm での reset-wip 代替、git merge-tree での衝突確認、MCP でのコメント投稿・draft 解除）がそのまま「何を渡せば恒久化できるか」の具体的な設計材料になった

### うまくいかなかったこと

- 「証跡強度」の話は抽象的になりがちなので、`--external` は `--local` と何が違うか（実在するPRを扱うか否か）を明記するのに文章量が要った
