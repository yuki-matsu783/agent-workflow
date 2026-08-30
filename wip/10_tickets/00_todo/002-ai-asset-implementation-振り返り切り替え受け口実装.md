---
type: ai-asset-implementation
status: todo
depends_on: ["001-ai-asset-design-振り返り切り替え受け口仕様追加.md"]
---

# workflow-issue-mr-driven SKILL.md と evals に振り返りからの切り替え受け口を実装する

## 目的

001 で確定した仕様に基づき、`workflow-issue-mr-driven/SKILL.md` に振り返りからの切り替え時の受け口（引き継ぐ項目・省略できる手順・省略できない手順）を追加し、AI アセット作業の標準チケット構成を手順 5 に明記する。あわせて `evals/evals.json` に切り替えケースを追加する。

## 完了条件（DoD）

- [ ] `workflow-issue-mr-driven/SKILL.md` 手順 1 に「振り返りからの切り替え」の小節が追加されている（発生条件・引き継ぐ項目・省略できる手順・省略できない手順）
- [ ] 引き継ぐ項目名が `workflow-quick-request` 手順 5-3 の記述（summary / acceptance / kind / チケット構成）と一致している
- [ ] `workflow-issue-mr-driven/SKILL.md` 手順 5 に AI アセット作業の標準チケット構成（`ai-asset-design` → `ai-asset-implementation` →（必要なら）`retrospective`）が明記されている
- [ ] `workflow-issue-mr-driven/evals/evals.json` に振り返りからの切り替えケースが 1 件追加され、妥当な JSON である

## 作業内容

1. `.claude/skills/workflow-issue-mr-driven/SKILL.md` 手順 1 に小節を追加する
2. `.claude/skills/workflow-issue-mr-driven/SKILL.md` 手順 5 に標準チケット構成の記載を追加する
3. `.claude/skills/workflow-issue-mr-driven/evals/evals.json` に切り替えケースを追加し、`python3 -m json.tool` で妥当性を確認する

## 作業ログ

### うまくいったこと

-

### うまくいかなかったこと

-
