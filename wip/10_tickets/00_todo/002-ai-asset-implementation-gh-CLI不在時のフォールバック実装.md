---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-gh-CLI不在時のフォールバック仕様.md"]
---

# gh CLI 不在時のフォールバック実装

## 目的

001 で確定した仕様に従い、`work-boundary.sh`/`merge-prep.sh` に gh 不在時のフォールバック経路を実装する。

## 完了条件（DoD）

- [ ] `work-boundary.sh` に `wb_gh_available()` が追加され、`wb_pr_number()` が gh 不在時に空を返す
- [ ] `wb_request` が `--pr <N>` と、gh 不在時の `--external --pr <N> --comment-url <url>` を受け付け、`local: false, via: "external"` として記録する
- [ ] `wb_complete` が gh 不在時の `--external --review-decision <value> [--comment-ids <json>] [--inline-ids <json>]` を受け付け、既存の CHANGES_REQUESTED 拒否ロジックが同様に働く
- [ ] `wb_reply` の使い方メッセージに gh 不在時の代替案内が追加されている
- [ ] `merge-prep.sh` に `mp_gh_available()` が追加され、全サブコマンドが `--pr <N>` を受け付ける
- [ ] `mp_notify` が gh 不在時の `--pr-body-file <path>` と `--posted "N:url"` を受け付ける
- [ ] `mp_ready` が gh 不在時の `--external` を受け付け、`gh pr ready` を呼ばずに前提検証後 `state: ready` を記録する
- [ ] 両状態ファイルのスキーマに `via` フィールドが追加され、既存のコミット・出力 JSON に反映されている
- [ ] `work-ticket-driven`/`workflow-issue-mr-driven` の SKILL.md エラーハンドリング表に、gh 不在時のフラグの使い方が追記されている
- [ ] `.claude/hooks/tests/` に gh 不在フォールバックのテストケースが追加され、既存テストの回帰が無い

## 作業内容

1. `work-boundary.sh` を Edit し、上記のフラグとロジックを実装する
2. `merge-prep.sh` を Edit し、同様に実装する
3. 両 SKILL.md のエラーハンドリング表を Edit で更新する
4. `.claude/hooks/tests/` の既存テストを確認し、新規テストケースを追加する（`bash_groups: ["test"]` で実行可能）
5. `PATH` から `gh` を外した状態で新フラグの経路を手動確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
