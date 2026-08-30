---
type: ai-asset-design
status: todo
depends_on: []
---

# 仕様書更新: git add の wip/10_tickets/ 配下判定をハードコード許可に変更する設計

## 目的

`.claude/docs/10_spec/チケット駆動ワークフロー.md` を、実装チケット（002）で行う「`git add` の `wip/10_tickets/` 配下判定を `git mv` と同様にハードコード許可にする」変更に整合する内容へ更新する。

## 完了条件（DoD）

- [x] パス判定順序表（現行160-172行目付近）の直後に、「`wip/10_tickets/**` への `git mv`/`git add` はこの判定表を経由せず常に許可される」旨の注記が追加されている
- [x] 182行目「`git add` の対象パス判定にも使う」の記述が、`wip/10_tickets/**` はセッション記憶の判定に到達しない旨に整合する内容へ修正されている
- [x] 191行目「`git add` の対象パスも同じ判定を適用する」の記述に、`wip/10_tickets/**` を除外する旨が追記されている
- [x] 219行目「`git add`（許可パス内に限る）」が、`git mv` の記述と対になる形（`wip/10_tickets/` 配下同士は無条件、それ以外は許可パス内に限る）に修正されている
- [x] `work-ticket-driven` スキルの `references/permission-matrix.md` や、TC022 付近のテストケース記述に影響があれば確認する（`.claude/skills/**` は `ai-asset-design` の allow_paths 外のため、実際の修正は 002 ai-asset-implementation で行う。TC022 は `src/main.ts` 対象で影響なしと確認済み）
- [x] 既存の章立て・用語・他の記述を壊していない

## 作業内容

1. `.claude/docs/10_spec/チケット駆動ワークフロー.md` を Read し、対象箇所（160-172, 182, 191, 219, 540行目付近）を確認する
2. 上記 DoD の各修正を Edit で反映する
3. `.claude/skills/work-ticket-driven/references/permission-matrix.md` を Read し、同様の非対称な記述を確認する（`.claude/skills/**` は本チケットの allow_paths 外のため、修正自体は 002 で行う）
4. 変更差分を確認し、他の記述と矛盾がないか読み直す

## 作業ログ

<!-- 作業中にその都度追記する。後からまとめて書かない -->

### うまくいったこと

- `.claude/docs/10_spec/チケット駆動ワークフロー.md` の判定順序表・セッション記憶・保護パス・Bash allowlist の4箇所に、`wip/10_tickets/**` の `git mv`/`git add` がこの判定表を経由せず常に許可される旨を追記できた
- TC022（未記載パスの git add）は `src/main.ts` を対象としており、`wip/10_tickets/**` の常時許可には影響しないことを確認した

### うまくいかなかったこと

- `.claude/skills/work-ticket-driven/references/permission-matrix.md` は `.claude/skills/**` 配下で `ai-asset-design` の allow_paths 外（WF002 で拒否）だった。当初「本チケットで仕様書と合わせて修正する」想定だったが、実際は type ごとのパス制限により編集できず、002（ai-asset-implementation）側に回すことになった。作業タイプの allow_paths を跨ぐ変更をひとつのチケットに詰め込まない、という当初の設計原則どおりの結果ではあるが、計画段階でこの制約に気づけなかった
