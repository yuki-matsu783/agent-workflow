---
type: investigation
status: todo
depends_on: []
---

# WF012 誤反応の原因調査と修正方針の確定

## 目的

issue #29 のとおり、`workflow-boundary.sh` の WF012 判定が引用符内の `review-state.json` 文字列に誤反応する原因を確認し、実装計画としてまとめる。

## 完了条件（DoD）

- [ ] `wip/20_plans/WF012修正計画.md` が作成され、修正対象箇所（`workflow-boundary.sh` の該当行）と追加するテストケース（`test-hooks.sh` の TC025 系）の一覧が具体的に記載されている
- [ ] issue #29 の受け入れ条件3点それぞれが、どのロジックでどう満たされるかが計画書に明記されている

## 作業内容

1. `.claude/hooks/workflow-boundary.sh` の (a)(b) レビュー状態ファイル保護ブロック（58〜73行目付近）を確認する
2. `.claude/hooks/workflow-guard.sh` の `check_bash` のクォート除去前処理（`sanitized`）を確認する
3. `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` の TC025 系の既存テストケースを確認する
4. `wip/00_overall_plan/cheerful-sleeping-widget.md` に記載済みの修正方針（`wf_quoted_targets_state()` の追加によるクォート内パス検出）を実装レベルの計画に落とし、`wip/20_plans/WF012修正計画.md` として作成する

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

-

### うまくいかなかったこと

-
