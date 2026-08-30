---
type: ai-asset-implementation
status: done
depends_on: ["001-ai-asset-design-gh-CLI不在時のフォールバック仕様.md"]
---

# gh CLI 不在時のフォールバック実装

## 目的

001 で確定した仕様に従い、`work-boundary.sh`/`merge-prep.sh` に gh 不在時のフォールバック経路を実装する。

## 完了条件（DoD）

- [x] `work-boundary.sh` に `wb_gh_available()` が追加され、`wb_pr_number()` が gh 不在時に空を返す
- [x] `wb_request` が `--pr <N>` と、gh 不在時の `--external --pr <N> --comment-url <url>` を受け付け、`local: false, via: "external"` として記録する
- [x] `wb_complete` が gh 不在時の `--external --report-file <path>` を受け付け、既存の CHANGES_REQUESTED 拒否ロジックが同様に働く（001 の設計段階で `--review-decision`/`--comment-ids`/`--inline-ids` の個別フラグから `--report-file` 1本にまとめる改善を反映済み）
- [x] `wb_reply` の使い方メッセージに gh 不在時の代替案内が追加されている
- [x] `merge-prep.sh` に `mp_gh_available()` が追加され、全サブコマンドが `--pr <N>` を受け付ける
- [x] `mp_notify` が gh 不在時の `--pr-body-file <path>` と `--posted "N:url"` を受け付ける
- [x] `mp_ready` が gh 不在時の `--external` を受け付け、`gh pr ready` を呼ばずに前提検証後 `state: ready` を記録する
- [x] 両状態ファイルのスキーマに `via` フィールドが追加され、既存のコミット・出力 JSON に反映されている
- [x] `work-ticket-driven`/`workflow-issue-mr-driven` の SKILL.md エラーハンドリング表に、gh 不在時のフラグの使い方が追記されている
- [x] `.claude/hooks/tests/` に gh 不在フォールバックのテストケースが追加され、既存テストの回帰が無い（`test-work-boundary-fallback.sh` 13件、`test-merge-prep-fallback.sh` 11件、いずれも pass。既存の `test-workflow-guard.sh`/`test-workflow-entry.sh` も回帰無し）

## 作業内容

1. `work-boundary.sh` を Edit し、上記のフラグとロジックを実装する
2. `merge-prep.sh` を Edit し、同様に実装する
3. 両 SKILL.md のエラーハンドリング表を Edit で更新する
4. `.claude/hooks/tests/` の既存テストを確認し、新規テストケースを追加する（`bash_groups: ["test"]` で実行可能）
5. `PATH` から `gh` を外した状態で新フラグの経路を手動確認する

## 作業ログ

- `work-boundary.sh` に `wb_gh_available`/`--pr`/`--external`/`--comment-url`/`--report-file` を実装し、`via: gh|local|external` を記録するよう変更した
- `merge-prep.sh` に `mp_gh_available`/`MP_PR_OPT`/`--pr`（全サブコマンド）/`notify-issue --external --pr-body-file --posted`/`ready --external` を実装した
- 実装の過程で `mp_ready` に既存の潜在バグ（`mp_conflict_remedy` が衝突を検知していない場合でも呼ばれ `CONFLICT_FILES` 未定義変数エラーになる）を発見し修正した
- `.claude/hooks/tests/test-work-boundary-fallback.sh`（13ケース）・`test-merge-prep-fallback.sh`（11ケース）を新規追加し、gh を含まない PATH を組み立てた実 git リポジトリで検証。全 pass
- 既存の `test-workflow-guard.sh`（4ケース）・`test-workflow-entry.sh`（45ケース）を再実行し、回帰が無いことを確認した
- `work-ticket-driven`/`workflow-issue-mr-driven` の SKILL.md エラーハンドリング表に gh 不在時のフラグの使い方を追記した
- 別件（ユーザー依頼）として、この実行環境で `gh` CLI を実際にインストール・使用できるか診断した。apt でのインストール自体は成功するが、`api.github.com` 宛ての通信はセッション/組織レベルでゲートされており（`gh` の有無や `GITHUB_TOKEN` の値に関係なく同一の 403）、恒久的なフォールバックの必要性を裏付ける結果となった。診断用の使い捨てスクリプトは実行後に自己削除しリポジトリには残していない

### うまくいったこと

- 仕様書に事前に明記していた `via` フィールドの3値（gh/local/external）と証跡強度のトレードオフの説明が、実装時の判断（`wb_complete`/`mp_ready` の分岐）をそのまま導いてくれた
- テストを「gh を含まない PATH を組み立てた実 git リポジトリ」で構成したことで、モックに頼らず本物の git 操作込みで新フラグの経路を検証できた

### うまくいかなかったこと

- テスト実装の初回で、`--report-file`/`--pr-body-file` 用の一時ファイルを git の作業ツリー内に置いてしまい、`merge-prep.sh` の `mp_dirty`（未コミット変更の検知）が誤って反応した。作業ツリー外に置くよう修正して解決した
- `mp_ready` の `mp_conflict_remedy` 呼び出しが常に評価される作りになっており、未コミット変更などで衝突判定自体をスキップしたケースでテストが失敗して初めて気づいた（本文中のバグ修正で対応）
