---
type: ai-asset-implementation
status: todo
depends_on: ["015-ai-asset-design-振り返り切り替え受け口仕様追加.md"]
---

# workflow-issue-mr-driven SKILL.md と evals に振り返りからの切り替え受け口を実装する

## 目的

001 で確定した仕様に基づき、`workflow-issue-mr-driven/SKILL.md` に振り返りからの切り替え時の受け口（引き継ぐ項目・省略できる手順・省略できない手順）を追加し、AI アセット作業の標準チケット構成を手順 5 に明記する。あわせて `evals/evals.json` に切り替えケースを追加する。

## 完了条件（DoD）

- [x] `workflow-issue-mr-driven/SKILL.md` 手順 1 に「振り返りからの切り替え」の小節が追加されている（発生条件・引き継ぐ項目・省略できる手順・省略できない手順）
- [x] 引き継ぐ項目名が `workflow-quick-request` 手順 5-3 の記述（summary / acceptance / kind / チケット構成）と一致している
- [x] `workflow-issue-mr-driven/SKILL.md` 手順 5 に AI アセット作業の標準チケット構成（`ai-asset-design` → `ai-asset-implementation` →（必要なら）`retrospective`）が明記されている
- [x] `workflow-issue-mr-driven/evals/evals.json` に振り返りからの切り替えケースが 1 件追加され、妥当な JSON である

## 作業内容

1. `.claude/skills/workflow-issue-mr-driven/SKILL.md` 手順 1 に小節を追加する
2. `.claude/skills/workflow-issue-mr-driven/SKILL.md` 手順 5 に標準チケット構成の記載を追加する
3. `.claude/skills/workflow-issue-mr-driven/evals/evals.json` に切り替えケースを追加し、`python3 -m json.tool` で妥当性を確認する

## 作業ログ

### うまくいったこと

- 015 で確定した仕様（要件定義書・仕様書）の文言をそのまま SKILL.md に落とし込めたため、実装判断で迷う点は無かった

### うまくいかなかったこと

- `python3 -m json.tool` での JSON 妥当性確認は `ai-asset-implementation` の bash_groups（`test`）に含まれず WF003 でブロックされた。Read ツールでファイル全体を目視し、括弧・カンマの対応を確認する形で代替した
