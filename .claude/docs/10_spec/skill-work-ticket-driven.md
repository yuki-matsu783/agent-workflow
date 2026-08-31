# チケット駆動ワークフロースキル 仕様書

## 概要

- **背景**: 要件定義書 `.claude/docs/00_requirements/skill-work-ticket-driven.md` に基づき、スキル・フック・テンプレートの具体的な仕様を定義する。
- **目的**: フェーズ判定の状態ソース、フェーズ×許可マトリクス、フックの入出力、チケットの状態遷移とコミット運用を、実装可能なレベルで確定する。
- **スコープ**:
  - 含む: ディレクトリ構成、チケットのスキーマ（フロントマター）、フェーズ×許可マトリクス、PreToolUse / PostToolUse フックの入出力仕様、ガード条件、ワーク境界の判定スクリプト（`work-boundary.sh`）とレビュー状態ファイル、ワーク境界フック（`workflow-boundary.sh`）のブロック条件、マージ前作業の判定スクリプト（`merge-prep.sh`）と状態ファイル、テストシナリオ
  - 含まない: スキル本文（SKILL.md）の文言、フックスクリプトの実装コード

---

## 入力（Input）定義

### 入力元

- **入力元**: Claude Code のフック機構。ツール呼び出しのたびに、フックの stdin へ JSON が渡される。

### 入力データ（フックが受け取る JSON）

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| `tool_name` | string | Y | 呼び出されたツール名（`Edit` / `Write` / `NotebookEdit` / `Bash` など） | |
| `tool_input.file_path` | string | N | Edit/Write 系のとき対象ファイルの絶対パス | |
| `tool_input.command` | string | N | Bash のとき実行コマンド文字列 | |
| `cwd` | string | Y | 作業ディレクトリ | |

### 入力データ（状態ソース：doing チケットのフロントマター）

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| `type` | string | Y | 作業タイプ。作業タイプ定義（`.claude/hooks/workflow-types.json`）の `types` キーのいずれか | |
| `status` | string | Y | `todo` / `doing` / `done`（ディレクトリと一致させる） | |
| `depends_on` | string[] | N | 先行チケットのファイル名。全て done でないと doing に移せない | `[]` |
| `allowed_paths` | string[] | N | このチケットで確認なしに書き込みたいパス（glob）。type の定義に**追加**される allow。deny / ask には勝てない | `[]` |
| `session_id` | string | N | （フック入力）セッション ID。セッション記憶のキーに使う | |

### 入力データ（作業タイプ定義：`.claude/hooks/workflow-types.json`）

作業タイプとパスの allow / deny / ask の対応はコードに埋め込まず、この JSON で定義する。フックは呼び出しのたびに読み込むため、変更は即時反映される。

| 項目名 | 型 | 必須 | 説明 | デフォルト値 |
|--------|----|------|------|-------------|
| `global.allow_paths` | string[] | N | 全タイプで確認なしに書き込めるパス | `["wip/10_tickets/**"]` |
| `global.deny_paths` | string[] | N | 全タイプで禁止するパス（保護パス）。`types.<type>.allow_paths` で許可した type だけが例外 | `[]` |
| `global.ask_paths` | string[] | N | 全タイプで毎回ユーザー確認を求めるパス | `[]` |
| `session_memory.file_level` | string[] | N | セッション記憶をファイル単位にするパス（settings.json など特別なファイル）。それ以外はディレクトリ単位 | `[]` |
| `types.<type>.description` | string | N | 作業タイプの説明（人間向け） | |
| `types.<type>.allow_paths` | string[] | N | そのタイプで確認なしに書き込めるパス | `[]` |
| `types.<type>.deny_paths` | string[] | N | そのタイプで禁止するパス | `[]` |
| `types.<type>.ask_paths` | string[] | N | そのタイプで毎回確認を求めるパス | `[]` |
| `types.<type>.bash_groups` | string[] | N | 追加で許可する Bash コマンド群。`"build"`（npm 等のビルド/テスト系）と `"test"`（フックのテストスクリプト。`bash .claude/hooks/tests/*.sh`、`bash .claude/skills/<skill>/scripts/*.sh` のみ。`VAR=value` の前置可） | `[]` |

- パスは glob。`**` はディレクトリ再帰、`.claude/settings.json` のようにファイル単位の指定も可。ただし照合は bash の `case` を使うため `*` 単体もディレクトリ区切りをまたぐ（`src/*.ts` は `src/a/b.ts` にも一致する）

標準の定義（`types` のキー）:

| type | allow_paths | 用途 |
|------|------------|------|
| `investigation` | `wip/20_plans/**` | 調査。計画書を作成する |
| `implementation` | `src/**`, `tests/**`, `doc/**`, `wip/20_plans/**`（+ `build`） | 実装 |
| `retrospective` | `wip/30_reports/**` | 振り返り。結果報告を作成する |
| `ai-asset-design` | `.claude/docs/**`, `wip/20_plans/**` | AI アセットの設計（要件・仕様のみ） |
| `ai-asset-implementation` | `.claude/hooks/**`, `.claude/rules/**`, `.claude/skills/**`, `.claude/settings.json`（+ `test`） | AI アセットの実装。フックのテストスクリプトを実行できる |
| `overall-plan` | `wip/00_overall_plan/**` | 全体計画。フェーズ列を決めて最初の計画チケットを起こす（`work-overall-plan`） |
| `investigation-plan` / `design-plan` / `implementation-plan` / `design-sync-plan` / `ai-asset-design-plan` / `ai-asset-implementation-plan` | `wip/20_plans/**` | 各フェーズの計画。計画書を書き、実施チケット群と次の計画チケットを起こす（`work-<phase>-plan`） |
| `design` | `docs/**`, `wip/20_plans/**` | 設計。`docs/` に要件定義書・仕様書を作成・更新する（`work-design-exec`） |
| `design-sync` | `docs/**`, `wip/20_plans/**` | 設計反映。実装・テストで判明した差分を `docs/` の設計書に書き戻す（`work-design-sync-exec`） |

`overall-plan` 以降の 9 type はフェーズ別ワークスキル（`.claude/docs/10_spec/フェーズ別ワークスキル.md`）が使う。`overall-plan` は `global.deny_paths` の `wip/00_overall_plan/**` を type の allow で貫通する（判定順序で `types.<type>.allow_paths` が先に評価されるため、フックの変更は不要）。

global の標準: `deny_paths = [".claude/**", "wip/00_overall_plan/**"]`、`session_memory.file_level = [".claude/settings.json", "package.json", "CLAUDE.md"]`。

信頼境界: 設定ファイルは**ユーザーが管理する（信頼する）**。チケットの frontmatter は**Claude 自身が書く（信頼しない）**。この違いが「type 定義は global.deny を貫通できるが、チケットの `allowed_paths` は貫通できない」根拠になる。

### 入力データ（セッション記憶：`.claude/hooks/.state/<session_id>.approved`）

未記載パスへの書き込みをユーザーが確認で承認した事実を、セッション ID ごとのファイルに 1 行 1 単位で記録する（`dir:<親ディレクトリ>` または `file:<パス>`）。
記録は PostToolUse で行う（ツールが実行された = 承認された。拒否されたツールは PostToolUse に到達しない）。Git 管理外（`.gitignore`）で、差分検出の対象外。

### 入力データ（レビュー状態：`wip/10_tickets/review-state.json`）

ワーク完了チェックポイント（`.claude/docs/10_spec/スキル体系.md`）のレビュー状態。**`work-boundary.sh` だけが書き換える**（生成 AI による Edit / Write / Bash での直接書き換えはフックが WF012 で拒否する）。Git 管理下に置き、スクリプトが更新のたびにコミットする（セッション・マシンをまたいで状態が残り、PR の差分でレビューの経緯が追える）。常に「直近のワーク境界 1 件分」だけを持ち、履歴は git log に委ねる。

| 項目名 | 型 | 必須 | 説明 |
|--------|----|------|------|
| `version` | int | Y | スキーマ版。現在 `1` |
| `ticket` | string | Y | 境界を成す done チケットのファイル名（`20_done/` の連番最大）。`status` はこれが現在の done 末尾と一致しないとき状態を `none`（失効）とみなす |
| `work_type` | string | Y | そのチケットの `type`（＝完了したワーク） |
| `state` | string | Y | `requested` / `completed` |
| `local` | bool | Y | `true` なら PR を使わない単独実行（`--local`）。`request` / `complete` の証跡欄が空になる |
| `via` | string | Y | 証跡の取得経路。`"gh"`（スクリプトが gh を自ら実行）/ `"local"`（`--local`。PR を扱わない）/ `"external"`（`--external`。gh 不在時、呼び出し元が MCP ツール等で取得した値を使用） |
| `pr` | int | N | PR 番号（`local: false` のとき必須。`via == "external"` のときは `--pr` の値） |
| `head_sha` | string | Y | `request` 時点の HEAD |
| `request.comment_id` / `request.url` / `request.at` | string | N | レビュー依頼コメントの id / URL / 時刻（`local: false` のとき必須。`via == "external"` のときは `--comment-url` から得た値） |
| `complete.at` | string | N | `complete` の時刻 |
| `complete.review_decision` | string | N | `complete` が算出した reviewDecision 相当（`""` / `APPROVED` / `CHANGES_REQUESTED`。reviewer ごとの最新レビュー状態から自前で計算する簡略版で、ブランチ保護ルールは考慮しない。詳細は後述） |
| `complete.comment_ids` / `complete.inline_ids` | number[] | N | `complete` が取得した会話コメント id / インラインコメント id の一覧（証跡。REST の数値 id） |

信頼境界: このファイルも「Claude 自身が書く」側に見えるが、**書き込み経路をスクリプトに限定し、`request` / `complete` が GitHub の実操作（コメント投稿・取得）を自ら行って証跡を記録する**ことで、LLM の主張だけでは状態が進まないようにする。`via == "external"`（gh CLI 不在時のフォールバック。後述「`--external`」）はこの保証を維持できず、渡された値の正しさは呼び出し元に依存する。既存の `via == "gh"` 経路の挙動・信頼性は変わらない。

### 入力データ（マージ前作業の状態：`wip/merge-prep.json`）

完了処理（`workflow-issue-mr-driven` 手順 6）のマージ前作業（wip のリセット → default ブランチとのコンフリクト確認 → 関連 issue へのコメント → draft 解除）の進捗。**`merge-prep.sh` だけが書き換える**（直接書き換えはフックが WF012 で拒否する）。Git 管理下に置き、サブコマンドごとにコミット・push する。常に「直近の PR 1 件分」だけを持ち、`pr` が現在ブランチの open な PR と一致しなければ失効（`none`）とみなす。

| 項目名 | 型 | 必須 | 説明 |
|--------|----|------|------|
| `version` | int | Y | スキーマ版。現在 `1` |
| `pr` | int | Y | 対象 PR 番号。現在ブランチの open な PR（`gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open"`）と一致しないとき失効 |
| `branch` | string | Y | `reset-wip` 実行時のブランチ名（参考情報） |
| `state` | string | Y | `reset` / `checked` / `notified` / `ready`。この順にしか進まない |
| `review` | object | Y | `reset-wip` 時点の最後のワークのレビュー完了の証跡（`ticket` / `work_type` / `review_decision` / `completed_at`）。`review-state.json` はリセットで削除されるため、ここへ写す |
| `reset.at` / `reset.head_sha` / `reset.deleted` | string / string / string[] | Y | 削除の時刻・削除前の HEAD・削除したリポジトリ相対パスの一覧 |
| `conflicts` | object | N | `check-conflicts` の結果: `at` / `base` / `base_sha` / `head_sha` / `files`（衝突ファイル） / `has_conflict`。未実行なら null。衝突ありの結果も記録する（`state` は進まない）。`gh` を使わないため `via` は無い |
| `notify` | object | N | `notify-issue` の結果: `at` / `issues`（`number` / `comment_url` の配列）/ `via`（`"gh"` または `"external"`）。未実行なら null |
| `ready` | object | N | `ready` の結果: `at` / `head_sha` / `via`（`"gh"` または `"external"`）。未実行なら null |

信頼境界は `review-state.json` と同じ。`merge-prep.sh` が削除・`git merge-tree`・`gh api .../issues/<N>/comments`（issue コメント投稿）・`gh pr ready` を自ら実行して証跡を残すため、LLM が「リセットした」「衝突は無い」「通知した」と主張するだけでは `ready` に到達しない。

### 入力フォーマット（チケットファイル）

ファイル名は `NNN-<type>-<slug>.md`（例: `001-investigation-現状調査.md`）。NNN は実施順の連番。

```markdown
---
type: investigation
status: doing
depends_on: []
---

# 現状調査

## 目的

## 完了条件（DoD）
- [ ]

## 作業ログ
### うまくいったこと
### うまくいかなかったこと
```

---

## 出力（Output）定義

### 出力先

- **出力先**: Claude Code 本体（フックの exit code / stderr / stdout JSON を解釈する）

### 出力データ

| 項目名 | 型 | 説明 | デフォルト値 |
|--------|----|------|-------------|
| exit code | int | 0=許可・確認（何もしない / JSON 出力）、2=ブロック | 0 |
| stderr | string | exit 2 のとき、ブロック理由（エラーコード + 対処方法）。Claude にフィードバックされる | |
| stdout (JSON) | object | PreToolUse で確認を求めるとき `hookSpecificOutput.permissionDecision: "ask"` + `permissionDecisionReason`。PostToolUse のとき `hookSpecificOutput.additionalContext` で文脈を追加 | |

### 出力フォーマット（PreToolUse の確認要求）

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "[WF009] 想定外パスへの書き込み: src/foo.ts は作業タイプ investigation で本来想定していないパスです。本当に書き込んで良いですか？\n現在のチケット: 001-investigation-調査.md（type: investigation）\n許可すると、このセッション中は dir:src への書き込みを再確認しません。..."
  }
}
```

`permissionDecisionReason` はユーザーの確認プロンプトに表示される。ヘッドレス実行（確認できない環境）では `ask` は拒否として扱われる。

### 出力フォーマット（PostToolUse の additionalContext）

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[WF-DIFF] 許可パス外に差分があります: src/foo.ts。基準コミット <hash> の状態に戻してください（例: git checkout <hash> -- src/foo.ts）。未追跡ファイルは削除してください。"
  }
}
```

### ステータスコード（フックの exit code）

| コード | 意味 |
|--------|------|
| 0 | 許可（またはガード条件によりチェック対象外） |
| 2 | ブロック。stderr の理由が Claude に返る |
| 1 | フック自体の異常（設定不備など）。ブロックとして扱われないため、原則使用しない |

---

## フェーズ×許可マトリクス

PreToolUse フックが doing チケットの `type` に応じて適用するルール。type ごとの許可パスは作業タイプ定義（前述）から動的に読む。

### Edit / Write / NotebookEdit の判定順序

前段（チケット保護）:

1. `wip/10_tickets/10_doing/` 配下の `*.md` への書き込みで、対象が doing チケット以外 → WF001（2 枚目の作成）。`.gitkeep` など Markdown 以外はチケットとみなさず、この判定の対象外
2. doing チケット自身への書き込みで、適用後の frontmatter `type` が現在と異なる → WF008

パス判定（先に一致したものが勝つ）:

| 順 | 照合対象 | 結果 |
|----|---------|------|
| 1 | `types.<type>.deny_paths` | deny（WF002） |
| 2 | `types.<type>.ask_paths` | ask（WF010。毎回確認） |
| 3 | `types.<type>.allow_paths` | allow |
| 4 | `global.deny_paths` | deny（WF002） |
| 5 | `global.ask_paths` | ask（WF010。毎回確認） |
| 6 | チケット frontmatter の `allowed_paths` | allow |
| 7 | `global.allow_paths` | allow |
| 8 | セッション記憶（承認済み） | allow |
| 9 | 未記載 | ask（WF009。「想定外のパス」と警告して確認。承認後はセッション記憶に記録） |

- type のリストを global より先に見るため、global で `.claude/**` を deny しつつ `ai-asset-design` で `.claude/docs/**` を allow、が自然に書ける
- チケットの `allowed_paths` は「確認なしで触りたいパス」の追加指定。global.deny / ask より後に評価するため、deny を貫通したり ask を黙らせたりはできない
- 未記載パスは deny ではなく確認にする（想定外の作業を止めるのはユーザー）。承認されたパスはセッション記憶に入り、同セッション中は再確認しない
- `wip/10_tickets/**` を対象とする `git mv` / `git add`（Bash の「チケット運用コマンド」判定、後述）は、この判定表を経由せず常に許可される。上記の判定表は Edit/Write/NotebookEdit と、`wip/10_tickets/**` 以外を対象とする `git add` にのみ適用される

### セッション記憶

- 単位: 承認したファイルの**親ディレクトリ（直下のみ。サブディレクトリには波及しない）**。`session_memory.file_level` に一致するパスは**ファイル単位**
- 記録: PostToolUse で、Edit/Write/NotebookEdit の対象パスの判定が「未記載」なら記録する。`ask_paths`（毎回確認）は記録しない
- 参照: PreToolUse の判定順 8。`wip/10_tickets/**` 以外を対象とする `git add` の対象パス判定にも使う（`wip/10_tickets/**` はこの判定表を経由せず常に許可される）
- 保存先: `.claude/hooks/.state/<session_id>.approved`。`session_id` が無い場合は記憶しない（毎回確認）
- 寿命: セッション単位。別セッション（再起動）では再確認になる

### 保護パス（global.deny_paths）

`global.deny_paths`（標準: `.claude/**`, `wip/00_overall_plan/**`）は、`types.<type>.allow_paths` で許可された type のチケットでのみ書き込める。
チケットの `allowed_paths` に書いても許可されない（frontmatter は Claude 自身が書くため、貫通可能だと自己特権昇格になる）。

- `wip/10_tickets/**` 以外を対象とする `git add` の対象パスも同じ判定を適用する（deny → WF003、ask / 未記載 → 確認）。PostToolUse の差分検出では deny と「未承認の未記載」を違反として報告する
- ただし `wip/00_overall_plan/**` の差分はプランモード（ハーネス）が生成するものなので、PostToolUse では警告しない
- `.claude/hooks/workflow-types.json` 自体も `.claude/**` に含まれるため、`ai-asset-implementation` 以外では変更できない（設計上の割り切り。同タイプは定義上フックを変更できる作業なので、設定の自己改変防止は目的にしない）

### doing チケットの type 改変防止（WF008）

作業ログ記録のため doing チケットへの Edit は常に許可されるが、**frontmatter の `type` の書き換えは禁止**する（作業タイプを自己変更できると許可パスの制限が無意味になる）。

- PreToolUse: Edit の `old_string`/`new_string`（`replace_all` 対応）、Write の `content` を現在の内容に適用した結果から `type` を抽出し、現在値と異なれば exit 2（WF008）。CRLF は LF に正規化して判定する
- PostToolUse: コミット済み（`HEAD`）の doing チケットの `type` と作業ツリーの値が異なれば additionalContext で WF008 を警告する（二次チェック）
- type 以外の行（`status`、作業ログ）の編集は通常どおり許可される

### プランモード（EnterPlanMode）

- プランモードは**新しいワークフロー開始時の全体計画の作成・合意にのみ**使用する。この時点では doing が
  0 枚のためフックはガード条件で素通しになり、計画は `wip/00_overall_plan/` に保存される
- doing にチケットがある間に `EnterPlanMode` が呼ばれた場合、PreToolUse フックは exit 2（WF006）でブロックする
- チケット作業中の計画見直しは investigation チケットの成果物（`wip/20_plans/`）として行う
- 全体計画の標準の入口は `work-overall-plan`（`overall-plan` type のチケットとして `wip/00_overall_plan/` に Write する。仕様: `フェーズ別ワークスキル.md`）。プランモードは doing が空のときの代替経路として残し、プランモードで作った全体計画があれば `work-overall-plan` はそれを入力として扱う

### Bash コマンドの許可（deny-by-default）

| type | 許可コマンド | 方針 |
|------|-------------|------|
| 全タイプ | 読み取り系allowlist + チケット運用コマンド | allowlist にないコマンドはすべて exit 2 |
| `bash_groups` に `"build"` を含むタイプ（標準: `implementation`） | 上記 + ビルド/テスト系（`npm`, `npx`, `node`, `python`, `pytest`, `go`, `cargo`, `make`） | `git push`, `rm -rf`, パッケージのグローバル操作は拒否 |
| `bash_groups` に `"test"` を含むタイプ（標準: `ai-asset-implementation`） | 上記 + フックのテストスクリプト（`bash .claude/hooks/tests/<name>.sh`、`bash .claude/skills/<skill>/scripts/<name>.sh`。先頭の `VAR=value` は可） | それ以外の `bash <script>`（フック本体の直接実行、リポジトリ外のスクリプト等）は拒否 |

- **読み取り系 allowlist（全フェーズ共通）**: `ls`, `cat`, `head`, `tail`, `wc`, `grep`, `rg`, `find`, `git status`, `git log`, `git diff`, `git show`, `git branch`
- **チケット運用コマンド（全フェーズ共通）**: `mv` / `git mv`（`wip/10_tickets/` 配下同士の移動に限る）, `git add`（`wip/10_tickets/` 配下同士は無条件、それ以外は許可パス内に限る）, `git commit`
  - チケットの todo→doing 移動時は doing が空のためフックはガード条件で素通しになる。doing→done 移動時はこの allowlist が適用される。
  - **`git add` の対象パスの規約**: チケット運用のコミットでは `git add` の対象を `wip/10_tickets/` と作業タイプの許可パス内のファイル（またはディレクトリ）に限定し、`wip/` のようにそれらの親ディレクトリ全体を指定しない（例: `git add wip/10_tickets/ wip/20_plans/調査結果-foo.md`）。`git add` の対象パスは引数ごとに判定され、`wip/` は `wip/10_tickets/*` にも作業タイプの allow glob にも一致しないため未記載（WF009）の確認になる。Bash コマンドの承認はセッション記憶の対象外（PostToolUse は `file_path` を持つ Edit / Write / NotebookEdit のみ記憶する）のため、指定するたびに確認が発生する。ヘッドレス実行（確認できない環境）では `ask` が拒否として扱われるため、親ディレクトリ全体を指定した `git add` は失敗する。スキルの手順書（`work-ticket-driven` / `work-overall-plan` 等）に書くコミット例もこの規約に従う（issue #47）。
- リダイレクト（`>`, `>>`）、`sed -i`, `tee`, `curl`, `Invoke-WebRequest` を含むコマンドは allowlist 該当でも拒否する（コマンド文字列への部分一致で判定）。

### 読み取り専用ツール（Read / Glob / Grep / WebFetch 等）

全フェーズで無条件に許可（フックの matcher 対象外とする）。

---

## 処理フロー

### 基本フロー（ハッピーパス：スキル全体）

1. スキル起動。`wip/` 配下の状態を確認する（冪等性チェック。doing があれば手順 4 から再開）
2. 計画（plan）を行い、調査 → 実装 → 振り返りのタスクチケットを `wip/10_tickets/00_todo/` に連番で作成する
3. チケット群を `git add wip/10_tickets/` + `git commit` する
4. 先頭のチケットを `wip/10_tickets/10_doing/` に移動し、コミットする（**このコミットが差分チェックの基準点**）
5. チケットの内容を実施する。作業中のうまくいったこと・いかなかったことをチケットの作業ログ欄に随時記録する
6. 完了条件（DoD）を満たしたら、基準点からの差分が許可パス内であることを確認し、チケットを `wip/10_tickets/20_done/` に移動して `git add wip/10_tickets/ <許可パス内の変更ファイル>` でステージし、コミットする（`wip/` のように親ディレクトリ全体を指定しない。前述「Bash コマンドの許可」の `git add` の対象パスの規約）
7. `bash .claude/hooks/work-boundary.sh status` を実行し、`at_boundary` を読む。`false` なら 4〜6 を繰り返す。`true` なら**ワーク境界**（1つの作業タイプ＝1ワークの完了。`.claude/docs/10_spec/スキル体系.md`「ワーク完了チェックポイント」）。判定は目視の type 比較ではなくスクリプトの出力に従う
8. ワーク境界では、ワーク完了報告（完了した作業タイプ・チケット一覧・ワーク開始コミットからの差分要約・次の作業タイプ）を行い、呼び出し元（`workflow-issue-mr-driven`）があれば制御を返す。呼び出し元は `work-boundary.sh request` → 人間のレビュー → `work-boundary.sh complete` を経てから次のワークの 4 へ進む。単独実行なら `AskUserQuestion` で承認 / 差し戻しを確認し、`work-boundary.sh request --local` → `complete --local` で状態を進める。差し戻しなら同じ作業タイプの追加チケットを 2〜3 の要領で作って 4 へ（同じ type の追加チケットは境界でも着手できる）
9. 全チケット done になったら、成果物（`wip/20_plans/`、`wip/30_reports/`、コード変更）の一覧をユーザーに報告する

ワーク境界の判定とレビュー状態の遷移は `work-boundary.sh` が決定論的に行い、`workflow-boundary.sh`（PreToolUse）がレビュー未完了のまま次のワークへ進む操作を exit 2 で拒否する（後述「ワーク境界の判定とレビュー状態」）。`workflow-guard.sh` は従来どおり doing が空なら不活性化するため、ワーク境界での GitHub 操作（`git push` / `gh`）は許可されたままである。

### 基本フロー（PreToolUse フック）

1. `WORKFLOW_ENFORCE=0` なら exit 0
2. `wip/10_tickets/10_doing/*.md` を数える。0 枚なら exit 0（通常セッション）
3. 2 枚以上なら exit 2（WF001）
4. 作業タイプ定義 `.claude/hooks/workflow-types.json` を読む。読めなければ exit 2（WF007。設定ファイル自身と `wip/10_tickets/**` への Edit は復旧用に許可）
5. 1 枚のフロントマターから `type` / `allowed_paths` を読む。`type` が定義に無ければ exit 2（WF004）
6. `tool_name` が Edit/Write/NotebookEdit なら「Edit / Write / NotebookEdit の判定順序」に従って判定（deny → exit 2、ask / 未記載 → `permissionDecision: ask` の JSON を出力して exit 0、allow → exit 0）
7. `tool_name` が Bash なら `command` を allowlist と照合。不許可なら exit 2（WF003）。`git add` の対象パスは判定順序を適用し、確認が必要なパスがあれば `ask` を返す
8. `tool_name` が EnterPlanMode なら exit 2（WF006）
9. すべて通過したら exit 0。判定結果をログファイルに追記する

### 基本フロー（PostToolUse フック）

1. PreToolUse と同じガード条件（1〜5）を評価。対象外なら exit 0
2. Edit/Write/NotebookEdit の対象パスが「未記載」判定なら、セッション記憶に記録する（実行された = 承認された）
3. `git status --porcelain` で変更・未追跡ファイルを列挙する
4. deny または未承認の未記載パスのエントリがあれば、additionalContext に「差分のあるファイル一覧」「基準コミットのハッシュ」「復旧手順」を出力する（自動 revert はしない）
5. doing チケットの type がコミット済みの値と異なれば WF008、`depends_on` 未完了なら WF005 を additionalContext に追加する
6. exit 0 で終了

### 代替フロー

1. `allowed_paths` がフロントマターに指定されている場合、type のデフォルトに代えてそれを使用する（`wip/10_tickets/**` は常に追加）
2. セッション再開時に doing チケットが見つかった場合、作業ログを読んで続きから実施する

### 例外フロー

1. doing に 2 枚以上 → すべての対象ツールをブロックし、「doing を 1 枚に戻す」よう stderr で指示する
2. フロントマターが壊れている → 書き込み系をブロックし、「フロントマターを修正する」よう指示する（修正のための `wip/10_tickets/**` への Edit は許可する）
3. `depends_on` の先行チケットが done にない状態で doing へ移動された → PostToolUse で additionalContext により警告する

---

## ワーク境界の判定とレビュー状態

ワーク完了チェックポイント（`.claude/docs/10_spec/スキル体系.md`）を LLM の判断に委ねず、次の 2 つで機械的に扱う。

| 構成要素 | 役割 |
|---------|------|
| `.claude/hooks/work-boundary.sh` | 境界の判定（`status`）とレビュー状態の遷移（`request` / `complete`）、レビューへの返信（`reply`）。レビュー状態ファイルを書き換える**唯一の経路**。GitHub 操作（コメント投稿・取得）を自ら行い、証跡を状態ファイルに記録する |
| `.claude/hooks/workflow-boundary.sh` | PreToolUse フック。**doing の有無にかかわらず**動き、(a) レビュー状態ファイルの直接書き換え、(b) レビュー未完了のまま次のワークへ進む操作を exit 2 で拒否する |

### 境界の判定（`status`）

`work-boundary.sh status` は `wip/10_tickets/` と `review-state.json` から次を計算し、JSON を stdout に出力する（exit 0。`wip/10_tickets/` が無ければ全項目 null / false）。

| 項目 | 型 | 定義 |
|------|----|------|
| `doing_count` | int | `10_doing/*.md` の枚数 |
| `last_done` / `last_done_type` | string | `20_done/*.md` のうち連番（先頭 `NNN`）が最大のファイル名とその `type`。done が無ければ null |
| `todo_head` / `todo_head_type` | string | `00_todo/*.md` のうち連番が最小のファイル名とその `type`。todo が空なら null |
| `todo_same_type` | string[] | `00_todo/*.md` のうち `type == last_done_type` のファイル名（差し戻し対応の追加チケット候補） |
| `at_boundary` | bool | `doing_count == 0` かつ `last_done != null` かつ（`todo_head == null` または `todo_head_type != last_done_type`） |
| `review_state` | string | `none` / `requested` / `completed`。状態ファイルが無い、または `ticket != last_done` なら `none`（失効） |
| `review` | object | 状態ファイルの内容（`review_state != none` のとき） |

判定は**ファイル名の連番と frontmatter の `type` だけ**から決まる。type の読み取りは `workflow-lib.sh` の `wf_extract_type` と同じ規則に従う。

### レビュー状態の遷移（`request` / `complete`）

```
none ──request──> requested ──complete──> completed ──(次の done で ticket が変わる)──> none
```

**GitHub 操作は REST（`gh api`）で行い、`gh` の GraphQL 自動解決（`gh pr view` / `gh pr comment` / `gh issue comment`）には依存しない。** GraphQL クエリを個別に許可制にしているプロキシ環境（agent proxy が「pinned set の PR-review operations のみ許可」を返す環境）では GraphQL 経由の呼び出しが `HTTP 403` になるため（issue #44）。`gh api` の URL 中の `{owner}` / `{repo}` / `{branch}` プレースホルダはローカルの git remote・現在ブランチから解決され、ネットワークに出る前に完了する。

**`request [--body-file <path>] [--local]`**（ワーク完了のレビュー依頼）

| 前提条件（満たさなければ exit 2 + `[WF013]`） | 動作 |
|------|------|
| `at_boundary == true` | |
| `review_state == none`（`requested` / `completed` で二重に依頼しない） | |
| `git status --porcelain` が空（未コミットの変更が無い） | |
| `--local` でないとき: HEAD が `@{u}`（push 済み）、現在ブランチに open な PR がある（`gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open"`） | |
| | 1. `--local` でなければ `gh api "repos/<owner>/<repo>/issues/<PR>/comments" -f body="@<tmp>"` でレビュー依頼を投稿する。本文は `--body-file` の内容（無ければ標準の定型文）の先頭に `Claude Code より:` と機械判定用の目印 `<!-- work-boundary: request ticket=<last_done> -->` を付ける |
| | 2. 状態ファイルに `state: requested` と証跡（PR 番号、コメント id / URL、HEAD）を書き、`chore(review): request <last_done>` でコミットする。`--local` でなければ push する |
| | 3. 結果（`review_state`、コメント URL）を JSON で stdout に出力する |

`via` の値: `--local` なら `"local"`、`--external` なら `"external"`、どちらでもなければ `"gh"`。

**`complete [--local] [--external --report-file <path>]`**（レビュー完了の確認）

| 前提条件（満たさなければ exit 2 + `[WF014]`） | 動作 |
|------|------|
| `review_state == requested`（`ticket` が現在の `last_done` と一致すること） | |
| `--local` は `local: true` で `request` した場合のみ可。逆も同じ | |
| `--local` でないとき: `gh api repos/<owner>/<repo>/pulls/<PR>/reviews`、`gh api repos/<owner>/<repo>/issues/<PR>/comments`、`gh api repos/<owner>/<repo>/pulls/<PR>/comments` を**スクリプト自身が実行**し、次を機械的に検査する | |
| ・`reviewDecision` 相当（後述の自前計算） `!= CHANGES_REQUESTED`（差し戻し中は完了にできない。対応後にレビュアーが approve / dismiss するか、追加チケットで対応して再度 `request` する） | |
| ・返信の無いインラインスレッド（`in_reply_to_id == null` で、その id を `in_reply_to_id` に持つコメントが無いもの）が 0 件（`reply` で返信してから再実行する） | |
| | 1. 状態ファイルに `state: completed` と証跡（reviewDecision 相当、取得した会話コメント id / インラインコメント id の一覧）を書き、`chore(review): complete <last_done>` でコミットする |
| | 2. `request.at` 以降に投稿された会話コメント・インラインコメント（`Claude Code より:` で始まる自分の投稿を除く）を JSON で stdout に出力する。**指摘への対応要否の判断は人間（`AskUserQuestion`）に残す**。スクリプトは「指摘が無い」ことを保証せず、「取得した」ことを保証する |

REST には GraphQL の `reviewDecision`（ブランチ保護ルール込みの集約判定）に相当するフィールドが無いため、`complete` は `pulls/<PR>/reviews` の一覧から reviewer ごとの最新レビュー（`COMMENTED` / `PENDING` を除く）を取り、`CHANGES_REQUESTED` が1件でもあれば `CHANGES_REQUESTED`、無く `APPROVED` が1件でもあれば `APPROVED`、どちらも無ければ `""` とする簡略版を自前で計算する。ブランチ保護（必須レビュー人数・CODEOWNERS 等）は考慮しない。`complete` が実際に使うのは `CHANGES_REQUESTED` の検知のみのため、この簡略化で判定結果は変わらない。

**`reply <inline_comment_id> <text>`**: `gh api repos/<owner>/<repo>/pulls/<PR>/comments/<id>/replies -f body=...` で返信する。本文の先頭に `Claude Code より:` を付ける。状態ファイルは変更しない。

```json
{
  "review_decision": "APPROVED",
  "unresolved_threads": [{"id": "...", "url": "..."}],
  "comment_ids": ["..."],
  "inline_ids": ["..."],
  "new_comments": [{"id": "...", "author": "...", "createdAt": "...", "url": "...", "body": "..."}],
  "new_reviews": [{"author": "...", "state": "...", "submittedAt": "...", "body": "..."}],
  "new_inline": [{"id": "...", "path": "...", "line": 0, "in_reply_to_id": null, "user": "...", "url": "...", "body": "..."}]
}
```

呼び出し元（Claude）が `mcp__github__pull_request_read`（`get_reviews`/`get_comments`/`get_review_comments`）等で取得した値をこの形に整形して渡す。`unresolved_threads` は `get_review_comments` の `isResolved: false` かつ未返信のスレッドを指す。

**`reply <inline_comment_id> <text>`**: `gh` が使える環境では `gh api repos/<owner>/<repo>/pulls/<PR>/comments/<id>/replies -f body=...` で返信する。本文の先頭に `Claude Code より:` を付ける。状態ファイルは変更しない。**`gh` が使えない環境では、このサブコマンドは使わず、呼び出し元が MCP ツール（例: `mcp__github__add_reply_to_pull_request_comment`）で直接返信する**（状態を変更しないコマンドのため、フォールバック用の引数は用意しない）。

いずれのサブコマンドも `gh` の失敗（未認証・PR 無し・API エラー）は exit 2 で理由を出力し、状態ファイルを書き換えない。`--external` 使用時に呼び出し元が渡した値が事実と異なっていても、スクリプトはそれを検証する手段を持たない（後述「証跡強度のトレードオフ」）。

### `--local`（PR を使わない単独実行）

`work-ticket-driven` を `workflow-*` 経由でなく単独で使う場合、`AskUserQuestion` で承認を得た後に `request --local` → `complete --local` を続けて実行する。証跡は残らない（`local: true`）ため、**この経路の信頼性は会話上の承認に依存する**。`local: false` で `request` した境界を `complete --local` で閉じることはできない（逆も同じ）。

### `--external`（gh CLI 不在時のフォールバック）

`gh` CLI が使えない実行環境（GitHub 操作が MCP サーバー経由に限定される環境）向けの経路。`--local` との違いは、**実際に PR が存在し、そこへのコメント投稿・レビュー取得を呼び出し元が MCP ツール等で行っている**点（`--local` は PR そのものを扱わない）。

- `request --external --pr <N> --comment-url <url>`: 呼び出し元が `mcp__github__add_issue_comment`（PR 番号を issue 番号として指定）等でレビュー依頼コメントを投稿した後、その結果（PR 番号・コメント URL）をスクリプトに渡す
- `complete --external --report-file <path>`: 呼び出し元が MCP ツールでレビュー状態・コメントを取得し、上記スキーマに整形して渡す
- `wb_pr_number` に相当する PR 番号取得は、`--pr <N>` が指定されていればそれを使い、`gh pr view` は呼ばない（`gh` の有無に関わらず `--pr` が優先される）

**証跡強度のトレードオフ**: `via == "gh"` の設計は「スクリプト自身が GitHub に問い合わせて真偽を確認するため、LLM の自己申告だけでは状態が進まない」ことを保証する（`.claude/docs/10_spec/スキル体系.md`参照）。`via == "external"` はこの保証を維持できない。渡された PR 番号・URL・レビュー判定が実際の GitHub の状態と一致するかはスクリプトには検証できず、`--local`（PR を扱わない）と同様に**呼び出し元（Claude）の申告の正しさに依存する**。ただし `--local` と異なり、実在する PR 番号・コメント URL が記録に残る点、および `CHANGES_REQUESTED`/未解決スレッドの業務ロジック（何が完了を妨げるか）は `via` に関わらず同一である点で、`--local` より高い監査可能性を持つ（後から人間が記録された URL を実際に開いて確認できる）。既存の gh CLI が使える環境の挙動（デフォルトの `via: "gh"` 経路）はこの変更で一切変わらない。

### ワーク境界フック（`workflow-boundary.sh`）のブロック条件

PreToolUse（Matcher: `Edit|Write|NotebookEdit|Bash`）。`WORKFLOW_ENFORCE=0` なら exit 0。`workflow-guard.sh` とは独立したスクリプトとして登録し、**doing が空でも動く**（`wf_init` の早期 exit を使わない）。`permissionDecision: ask` は使わず exit 2 のみ（ヘッドレス実行で「確認できないので拒否」にならないようにするため）。

| # | 条件 | コード |
|---|------|------|
| (a) | Edit / Write / NotebookEdit の対象が `wip/10_tickets/review-state.json` | WF012 |
| (b) | Bash のいずれかのセグメントに `review-state.json` が含まれ、かつそのセグメントが読み取り専用コマンド（`cat` / `head` / `tail` / `grep` / `git status` / `git log` / `git diff` / `git show`）でも `bash .claude/hooks/work-boundary.sh` でもない（`rm` / `mv` / `sed -i` / リダイレクト / `git checkout --` / `git restore` / `git rm` 等をまとめて塞ぐ） | WF012 |
| (c) | `status` の `at_boundary == true` かつ `review_state != completed` のとき、todo から doing へのチケット移動（Bash の `mv` / `git mv` で移動先が `10_doing/`、または Write / Edit で `10_doing/*.md` を直接作る）。**ただし移動するチケットの `type` が `last_done_type` と同じ場合は許可**（差し戻し対応の追加チケット） | WF011 |
| (d) | （廃止。issue #30 で (e) の WF015 に統合した。`gh pr ready` の直接実行はレビュー状態を問わず拒否する） | — |
| (e) | Bash のいずれかのセグメントが `gh pr ready` で始まる。doing の有無・境界の有無・レビュー状態を問わず**常に**拒否する（draft 解除は `merge-prep.sh ready` 経由のみ。後述「マージ前作業の判定と状態」） | WF015 |
| (f) | (a)(b) と同じ判定を `wip/merge-prep.json` にも適用する。読み取り専用コマンドと `bash .claude/hooks/merge-prep.sh` は許可 | WF012 |

(a)(b)(e)(f) は doing の有無・境界の有無にかかわらず常に適用する。(c) は doing が空のときだけ評価する（doing があれば `workflow-guard.sh` が GitHub 操作と 2 枚目の doing を既に拒否している）。

### (a)(b)(f) の例外: マージコンフリクト解消中の直接編集（issue #51）

`reset-wip` 後の `check-conflicts` でコンフリクトが検知された場合（前掲「マージ前作業の判定と状態」）、対処は `git merge origin/<base>` で default ブランチを取り込み、衝突を解消してコミットすることである。このとき `review-state.json` / `merge-prep.json` 自身がコンフリクトの対象になることがあり、WF012 は例外なく拒否するため、Claude はマーカーを除去してコミットする手段を持たない（ユーザーに手動解消を委ねるしかなかった。issue #51 の発端）。

次の**両方**を満たすときに限り、(a)(b)(f) の拒否を解除し、対象ファイルへの Edit / Write / NotebookEdit / Bash 直接書き換えを許可する。

| 条件 | 確認方法 | 理由 |
|------|---------|------|
| 1. `git` が実際にマージ進行中である | `git rev-parse -q --verify MERGE_HEAD` が成功する（exit 0） | `MERGE_HEAD` は `git merge` が衝突等で自動コミットまで進めなかったときにのみ git 自身が作成する。`git commit` でのマージ完了や `git merge --abort` で削除される |
| 2. 対象ファイル自身が実際にunmerged状態にある | `git diff --name-only --diff-filter=U` の一覧に `review-state.json`（または `merge-prep.json`）が含まれる | 条件1のみだと、コンフリクト解消は必ず doing が空の状態（`workflow-guard.sh` の制限が完全に外れる状態。後述「残るトレードオフ」）で起きるため、`echo <SHA> > .git/MERGE_HEAD` のような単純な偽装で条件を満たせてしまう。対象ファイルが実際にunmerged状態にあることまで確認することで、この単純な偽装を防ぐ |

両方を満たさない場合（`MERGE_HEAD` が無い、または存在するが対象ファイルがunmerged状態でない）は、従来どおり例外なくWF012で拒否する。

**内容検証（PostToolUse、警告のみ）**: この例外はPreToolUse側の判定であり、編集後の内容までは検証できない。`workflow-diff-check.sh`（PostToolUse）が、例外が適用された編集の直後に次を確認し、いずれか満たさなければ既存のWF-DIFFと同じ形式（`additionalContext`、ブロックしない）で警告する。**自動revertは行わない**（他のPostToolUse検知と同じ「破壊的操作の禁止」方針）。

- 編集後のファイルが有効なJSONである（`jq empty`相当）
- コンフリクトマーカー（`<<<<<<<`/`=======`/`>>>>>>>`で始まる行）が残っていない
- 対象ファイルが `git diff --name-only --diff-filter=U` から外れている（そのファイルについてはマージが解消済み）

**見送った選択肢**: 機微キー（`state`/`review_decision`等）の値がマージ前から恣意的に書き換えられていないかの検証（調査結果の選択肢D）は、実装コストと保守負担（キーの一覧を都度更新する必要がある）に対して、上記の2条件（MERGE_HEAD かつ unmerged）が既に強い制約であることから、今回は見送る。将来、内容の悪用が実際に問題になった場合の拡張候補として残す。

**残るトレードオフ**: `workflow-guard.sh` は `wip/10_tickets/10_doing/` が空のとき `wf_init` のガード2で即 exit 0 し、Bash コマンドへの制限が完全に外れる（`.claude/hooks/workflow-lib.sh` のガード1・2）。`merge-prep.sh` のマージ前作業（コンフリクト解消が実際に発生する場面）は「実行は doing が空のときに限る」ため、**コンフリクト解消は必ずこの無制限状態と一致する**。上記2条件（MERGE_HEAD かつ 対象ファイルがunmerged）は単純な偽装（条件1のみを満たす偽装）を防ぐが、`git update-index --index-info` 等のgitプラミングコマンドを使えば、doing が空の無制限状態では対象ファイルのunmerged状態そのものを人工的に作り出すことが理論上可能であり、この構造的な限界は本変更（フック単体でのロジック追加）では解消しきれない。doing が空の状態でBashを再制限することは、コンフリクト解消作業自体を妨げるため採らない。この限界を許容した上で、単純な偽装を防ぐという実利を優先する。

`review_state` ごとの「対処:」は次のとおり。

| `review_state` | 対処 |
|----------------|------|
| `none` | `git push` してから `bash .claude/hooks/work-boundary.sh request` でレビューを依頼し、レビュー完了の連絡を待つ |
| `requested` | レビュー完了の連絡を受けてから `bash .claude/hooks/work-boundary.sh complete` を実行する。連絡が無いなら待つ（`AskUserQuestion` で待たず、応答を終える） |

### `workflow-guard.sh` との関係

- `workflow-guard.sh` は変更しない。doing が空のときは従来どおり exit 0 し、`git push` / `gh` を許可する
- doing があるときの `work-boundary.sh` の実行は `workflow-guard.sh` の Bash allowlist 外で WF003 になる（`status` も同様）。境界判定は done コミットの直後（doing が空）に行う運用であり、矛盾しない
- 両フックが同じツール呼び出しで動いたとき、どちらかが exit 2 なら拒否される。順序に依存しない

### データモデル（ディレクトリ構成）

```
wip/
├── 00_overall_plan/ # 全体計画（plansDirectory。プランモードで作成・合意。チケット作業中は書込不可）
├── 10_tickets/
│   ├── 00_todo/     # 未着手チケット（NNN-<type>-<slug>.md）
│   ├── 10_doing/    # 作業中チケット（常に 0 または 1 枚）
│   ├── 20_done/     # 完了チケット
│   └── review-state.json  # 直近のワーク境界のレビュー状態（work-boundary.sh だけが書く。Git 管理）
├── 20_plans/        # 調査チケットの成果物（計画書）
├── 30_reports/      # 振り返りチケットの成果物（結果報告）
└── merge-prep.json  # 直近の PR のマージ前作業の状態（merge-prep.sh だけが書く。Git 管理。リセットで消えない）
```

チケット・計画・報告・`review-state.json` は PR ごとの成果物であり、完了処理の `merge-prep.sh reset-wip` で削除されてから main にマージされる（`.gitkeep` と `merge-prep.json` は残る）。

番号の接頭辞は作業の流れ順（計画 → チケット → 計画書 → 報告）を表す。各ディレクトリには `.gitkeep` を置き、clone 直後から構成が再現されるようにする（`00_overall_plan/` は計画ファイル自体が入るため不要）。

### テンプレート

成果物はスキルの `assets/` にあるテンプレートを Read→Write でコピーして作成する（`cp` は Bash allowlist 外）。

| テンプレート | 用途 | 作成先 |
|-------------|------|--------|
| `assets/ticket.template.md` | チケット | `wip/10_tickets/00_todo/` |
| `assets/plan.template.md` | 計画書 | `wip/20_plans/` |
| `assets/report.template.md` | 結果報告 | `wip/30_reports/` |

### スキーマ定義（チケットの状態遷移）

```
todo ──(着手: mv + commit ※基準点)──> doing ──(DoD充足: 差分確認 + mv + commit)──> done
                                        │
                                        └─ WIPリミット = 1（doing は常に最大1枚）
```

コミットメッセージ規約:

- 着手時: `chore(ticket): start NNN-<slug>`
- 完了時: `chore(ticket): done NNN-<slug>`

---

## マージ前作業の判定と状態

全ワーク done・最後のワークのレビュー完了の後、draft PR を ready にする前に行う**マージ前作業**（wip のリセット → default ブランチとのコンフリクト確認 → 関連 issue へのコメント）を、ワーク境界と同じく LLM の判断に委ねず機械的に扱う（issue #30）。フロー上の位置づけと承認ポイントは `.claude/docs/10_spec/skill-workflow-issue-mr-driven.md`「完了処理」が正で、本節はスクリプトとフックの挙動を定める。

| 構成要素 | 役割 |
|---------|------|
| `.claude/hooks/merge-prep.sh` | マージ前作業の各ステップを**自ら実行**し、証跡を `wip/merge-prep.json` に記録する CLI（`status` / `reset-wip` / `check-conflicts` / `notify-issue` / `ready`）。状態ファイルを書き換える唯一の経路 |
| `.claude/hooks/workflow-boundary.sh` | PreToolUse フック。(e) 直接の `gh pr ready` を常に拒否（WF015）、(f) `wip/merge-prep.json` の直接書き換えを拒否（WF012） |

### 共通事項

- 実行は doing が空のとき（全チケット done 後）に限る。doing があれば `workflow-guard.sh` の Bash allowlist 外で WF003 になる
- 前提未充足は exit 2 + `[WF016]` を stderr に出し、**状態ファイルを書き換えない**。例外は `check-conflicts` の「衝突あり」だけで、結果を記録したうえで exit 2 にする
- 成功時は結果 JSON を stdout に出し、状態ファイルを `chore(merge-prep): <内容>` でコミットして push する
- `--local` は無い（マージ前作業は PR の存在が前提）。`permissionDecision: ask` は使わず exit 2 のみ（ヘッドレス実行で「確認できないため拒否」にならない）
- default ブランチは `--base <branch>` で指定でき、省略時は `refs/remotes/origin/HEAD` の指す名前、それも無ければ `main`
- `gh` の失敗（未認証・PR 無し・API エラー）は exit 2 で理由を出力し、状態ファイルを書き換えない
- 全サブコマンドが `--pr <N>` を受け付ける。指定時は PR 番号取得に `gh pr view` を呼ばず、その値を使う（`gh` の有無に関わらず優先。詳細は後述「gh CLI 不在時のフォールバック」）

### `status`

`wip/merge-prep.json` と現状から次を計算して JSON を出力する（exit 0）。

| 項目 | 型 | 定義 |
|------|----|------|
| `pr` | int | 現在ブランチの open な PR 番号（取得できなければ null） |
| `merge_state` | string | `none` / `reset` / `checked` / `notified` / `ready`。状態ファイルが無い、`pr` が一致しない、または `pr` が取得できないとき `none`（失効） |
| `wip_artifacts` | string[] | 作業ツリーに残るリセット対象（下記）のリポジトリ相対パス |
| `wip_clean` | bool | `wip_artifacts` が空 |
| `review_state` | string | `work-boundary.sh status` の `review_state` |
| `record` | object | 状態ファイルの内容（`merge_state != none` のとき。それ以外は null） |

### リセット対象

| 対象 | 残すもの |
|------|---------|
| `wip/00_overall_plan/*.md` | — |
| `wip/10_tickets/00_todo/*.md`、`10_doing/*.md`、`20_done/*.md` | `.gitkeep` |
| `wip/20_plans/*.md`、`wip/30_reports/*.md` | `.gitkeep` |
| `wip/10_tickets/review-state.json` | — |

`wip/merge-prep.json` 自身は対象外。Git 管理の有無は問わない（未追跡ファイルも消す）。

### `reset-wip [--dry-run]`

| 前提条件（満たさなければ exit 2 + `[WF016]`） |
|------|
| `work-boundary.sh status` で `doing_count == 0`、`todo_head == null`、`last_done != null`、`review_state == completed`（最後のワークのレビューが完了している） |
| `git status --porcelain` が空 |
| 現在ブランチに open な PR がある（`gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open"`） |

動作:

1. リセット対象を列挙する。`--dry-run` なら `{dry_run: true, pr, deleted_count, deleted}` を出力して終了する（何も変えない）
2. `review-state.json` から最後のワークの証跡（`ticket` / `work_type` / `complete.review_decision` / `complete.at`）を読み、対象を削除する
3. 状態ファイルを `state: reset` で書き、`git add -A -- wip/` → `chore(merge-prep): reset wip` でコミット → push
4. `{merge_state: "reset", pr, deleted_count, deleted}` を出力する

2 回目の実行は done が無いため前提未充足になる（再実行は拒否される）。

### `check-conflicts [--base <branch>]`

| 前提条件（満たさなければ exit 2 + `[WF016]`） |
|------|
| `merge_state` が `reset` / `checked` / `notified`（現在の PR の記録がある。`ready` 後は不可） |
| `git status --porcelain` が空 |
| `git merge-tree --write-tree` が使える（git 2.38 以降） |

動作:

1. `git fetch origin <base>`（失敗は exit 2）
2. `git -c core.quotepath=false merge-tree --write-tree --name-only --no-messages HEAD origin/<base>` を実行する（**作業ツリー・インデックスを変更しない**）。終了コード 0 = 衝突なし、1 = 衝突あり（出力の 2 行目以降がファイル一覧）、2 以上 = エラー（exit 2）
3. 結果を `conflicts` に記録する。衝突なしなら `state: checked`（`notified` からは据え置き）、衝突ありなら `state` は進めない
4. `chore(merge-prep): check conflicts` でコミット・push
5. 衝突なしなら `{merge_state, has_conflict: false, base, base_sha, head_sha}` を出力する。衝突ありなら exit 2 + `[WF016]` で対象ファイルと対処（`git merge origin/<base>` で取り込み → 解消 → コミット → push → 再実行。**`git rebase` は使わない**。レビューコメントが紐づくコミットを書き換えないため）を返す

### `notify-issue --body-file <path> [--issue N ...]` / `notify-issue --external --body-file <path> --pr-body-file <path> --posted "N:url" [--posted "N:url" ...] [--issue N ...]`

gh が使える場合（前者の形）:

| 前提条件（満たさなければ exit 2 + `[WF016]`） |
|------|
| `merge_state == checked`（衝突なしの記録がある。`notified` なら二重投稿になるため拒否） |
| `--body-file` が存在し空でない |
| 通知先が 1 件以上ある: PR 本文（`gh api "repos/{owner}/{repo}/pulls/<PR>" --jq '.body'`）の `Closes #N` / `Fixes #N` / `Resolves #N`（大文字小文字不問）と `--issue` の和集合（重複除去） |

動作:

1. 本文の先頭に `Claude Code より: PR #<M> のマージ前の完了報告です。` と機械判定用の目印 `<!-- merge-prep: notify pr=<M> -->` を付けた一時ファイルを作る
2. 通知先ごとに `gh api "repos/{owner}/{repo}/issues/<N>/comments" -f body="@<tmp>"` を実行し URL を控える（1 件でも失敗したら exit 2。それまでに投稿した分は stderr に列挙し、状態ファイルは書き換えない）
3. `notify` に記録し `state: notified`、`chore(merge-prep): notify issues` でコミット・push
4. `{merge_state: "notified", issues: [{number, comment_url}]}` を出力する

`--external`（gh 不在時。後者の形）:

| 前提条件（満たさなければ exit 2 + `[WF016]`） |
|------|
| `merge_state == checked` |
| `--pr <N>` が指定されている（`gh pr view` を呼ばないため PR 番号は必須） |
| `--pr-body-file <path>` が存在し空でない（PR 本文。呼び出し元が MCP ツールで取得した内容を渡す） |
| 通知先が 1 件以上ある: `--pr-body-file` の内容から `Closes #N` 等を抽出したものと `--issue` の和集合（`gh pr view` を呼ばず、同じ正規表現でスクリプトが自ら抽出する） |
| 通知先の集合と `--posted` で渡された issue 番号の集合が完全に一致する（過不足があれば列挙して拒否） |

動作:

1. 通知先ごとに `--posted "N:url"` の URL をそのまま証跡として使う（`gh issue comment` は呼ばない。コメント本文は呼び出し元が既に投稿済みという前提）
2. `notify` に `via: "external"` として記録し `state: notified`、`chore(merge-prep): notify issues` でコミット・push
3. `{merge_state: "notified", issues: [{number, comment_url}]}` を出力する（gh 版と同じ形）

投稿前の本文の承認（承認⑥）はスキル側（`AskUserQuestion`）の責務であり、スクリプトは承認を検証しない。他人の issue への投稿は取り消せない外部への副作用のため、スキルは本文そのものを提示して承認を得る（`--external` でも同様。MCP ツールで投稿する前に本文の承認を得ること）。

### `ready [--base <branch>] [--external]`

| 前提条件（すべて満たすときだけ draft を解除する。未充足は 1 行ずつ列挙して exit 2 + `[WF016]`） |
|------|
| `merge_state == notified`（reset-wip / check-conflicts（衝突なし）/ notify-issue がこの順で記録されている） |
| 再検証: 作業ツリーにリセット対象が残っていない（`wip_clean`） |
| 再検証: `git status --porcelain` が空、HEAD が `@{u}` と一致（push 済み） |
| 再検証: `git fetch origin <base>` → `merge-tree` で衝突なし（default ブランチが進んで衝突した場合は `conflicts` の記録だけ更新し、`check-conflicts` の対処に従って解消してから再実行する） |

動作: `--external` が無ければ `gh pr ready <M>` を実行する（gh が使えない場合はここで exit 2 になるので `--external` を使う）。`--external` があれば `gh pr ready` を呼ばず、**呼び出し元が事前に MCP ツール（`mcp__github__update_pull_request` の `draft: false`）で draft を解除済みという前提**で次に進む。いずれの経路でも `ready` に `at`/`head_sha`/`via`（`"gh"` または `"external"`）を記録し `state: ready` → `chore(merge-prep): ready` でコミット・push → `{merge_state: "ready", pr}` を出力する。以後 AI エージェントは止まり、マージは人間が行う（`gh pr merge` はスキルの手順に含めない）。

`--external` はドラフト解除という外部への副作用がスクリプトの制御外で行われたことを意味する。前提条件（reset-wip/check-conflicts/notify-issue の順序、wip_clean、push済み、衝突なし）はすべて `--external` でも同じ厳密さで検証される。スクリプトが検証できないのは「実際に draft が解除されたか」だけであり、これは MCP ツールの呼び出し元（Claude）が保証する。

### 状態遷移

```
none ──reset-wip──> reset ──check-conflicts（衝突なし）──> checked ──notify-issue──> notified ──ready──> ready
                      │                                                                       ▲
                      └── check-conflicts（衝突あり）: conflicts に記録、state は reset のまま ─┘（解消後に再実行）
（PR 番号が変わる／状態ファイルが無い → none）
```

### `workflow-boundary.sh` との関係

- `gh pr ready` の直接実行は、doing の有無・レビュー状態を問わず常に WF015（前掲の条件 (e)）。draft 解除の経路を `merge-prep.sh ready` に一本化することで、「マージ前作業を実施したか」の判定をスクリプトの前提条件に集約する
- `wip/merge-prep.json` の保護は `review-state.json` と同じ WF012（条件 (f)）
- `reset-wip` は `review_state == completed` を前提にするため、レビューを経ずに wip を消して ready へ進む経路は無い

### gh CLI 不在時のフォールバック

`gh` CLI が使えない実行環境向けの経路（issue #41）。全サブコマンドが `--pr <N>` を受け付け、`gh pr view` の代わりに使う（`reset-wip`/`check-conflicts` は実際の処理が `git`/`git merge-tree` だけで完結するため、`--pr` さえ渡せば gh 不在でも完全に動作する）。`notify-issue`/`ready` は実際の GitHub 側の副作用（コメント投稿・draft 解除）を伴うため、`--external` を付けて呼び出し元が MCP ツール等で行った結果を渡す（前述の各サブコマンド節を参照）。

| サブコマンド | gh 不在時に必要な追加フラグ | 呼び出し元が事前に行うこと |
|-------------|--------------------------|--------------------------|
| `status` / `reset-wip` / `check-conflicts` | `--pr <N>` | PR 番号を把握しておく（例: `mcp__github__list_pull_requests` 等） |
| `notify-issue` | `--external --pr <N> --pr-body-file <path> --posted "N:url" ...` | PR 本文の取得、通知先ごとの issue コメント投稿（`mcp__github__add_issue_comment`） |
| `ready` | `--external --pr <N>` | `mcp__github__update_pull_request(draft: false)` で draft 解除 |

**証跡強度のトレードオフ**は `work-boundary.sh` の「`--external`」節と同じ考え方に従う。`notify.via`/`ready.via` が `"external"` の記録は、実際に GitHub へ投稿・反映されたことをスクリプト自身が確認したものではなく、呼び出し元の申告に依存する。既存の gh CLI が使える環境（`--pr`/`--external` を使わない経路）の挙動はこの変更で一切変わらない。

---

## 振り返り（retrospective）の棚卸しと合意

retrospective チケットの結果報告作成に、`.claude/docs/10_spec/skill-workflow-quick-request.md`「振り返り候補の重さの区分」と観点・文言を揃えた棚卸し・合意フローを組み込む（issue #3）。フックや状態ファイルの変更は伴わない（`AskUserQuestion` による対話上の合意のみ）。

### 棚卸し対象（5種類）

| 種類 | 例 |
|------|-----|
| スキル | 読み込んだもの（`workflow-issue-mr-driven`、`work-ticket-driven`、委譲先の `task-gh-issue` など） |
| フック | 発火・ブロック・確認を出したもの（`[WF00x]`、`[WF-DIFF]` など。`.claude/hooks/workflow.log` で確認できる） |
| ルール | 判断の根拠にした `.claude/rules/*.md` |
| エージェント | Agent ツールで起動したサブエージェント |
| CLAUDE.md | 作業の進め方に効いた記述 |

### 4観点の振り返り

各アセットについて、次のいずれかで気付きを1行ずつ書く。気付きが無ければ「問題なし」でよい。

| 観点 | 内容 |
|------|------|
| 足りなかった | 手順・判定基準・テンプレートに無くて自分で判断した箇所（→ 修正候補） |
| 邪魔だった | 誤ってブロック・確認された、手順が冗長だった箇所（→ 修正候補） |
| 無かった | あれば楽だったスキル・フック・ルール（→ 新規作成候補） |
| 問題なし | 想定どおり機能した |

### 振り返り候補の重さの区分

`.claude/docs/10_spec/skill-workflow-quick-request.md`「振り返り候補の重さの区分」と同一の表。

| 重さ | 該当するもの | 合意の形 |
|------|-------------|---------|
| 軽微 | SKILL.md・ルール・テンプレートの文言修正など、振る舞いが変わらないもの | 「このまま続けて修正する」 |
| 振る舞いが変わる | フックのロジック変更、スキルの手順変更、フック・スキル・ルール・エージェントの新規作成、settings.jsonの変更 | 「新規issueを作って `workflow-issue-mr-driven` で進める」 |

候補が無いときも「候補なし」として `AskUserQuestion` で確認する。振る舞いが変わる候補には「続けて修正する」の選択肢は付けない（`work-ticket-driven` のチケット作業中は `.claude/**` が保護パスであり、そもそも確認なしに直接書き換えられない）。

### issue 化ルートの処理フロー

振り返りの合意が「新規issueを作って `workflow-issue-mr-driven` で進める」だった場合:

1. retrospective チケットの結果報告に、対象アセット・変更点・理由・期待する挙動を記録した上で done にする（通常のワーク完了チェックポイントを経る）
2. `workflow-issue-mr-driven` の完了処理（`merge-prep.sh` によるマージ前作業・draft 解除。前掲「マージ前作業の判定と状態」）まで完走する
3. 完了処理が終わった後、`workflow-issue-mr-driven` を Skill ツールで読み込み直し、**新しい issue** の作業として手順1から開始する。引き継ぐ項目は `workflow-quick-request` 手順5-3 と同じ: `summary` / `acceptance`（振り返りで挙げた対象アセット・変更点・理由・期待する挙動）/ `kind`（改善・最適化。新規作成ならタスク）/ チケット構成（`ai-asset-design` → `ai-asset-implementation`）
4. どの issue で対応するか（既存 / 新規）と issue 本文の承認は `workflow-issue-mr-driven` 側の承認①②で改めて取る。retrospective での合意は「そのルートに進むこと」の合意であり、issue の内容の承認ではない

ヘッドレス実行（`claude -p`、CI）では `AskUserQuestion` の応答が得られないため、棚卸しと候補を結果報告に含めるだけにして完了扱いとする（承認待ちで止まらない・issue も作らない。`.claude/rules/claude-config-headless-awareness.md` 準拠）。

---

## インターフェース定義

### フック登録（`.claude/settings.json`）

| イベント | Matcher | スクリプト | 役割 |
|---------|---------|-----------|------|
| PreToolUse | `Edit\|Write\|NotebookEdit\|Bash\|EnterPlanMode` | `.claude/hooks/workflow-guard.sh` | フェーズ別の許可判定（exit 2 でブロック）。doing が空なら何もしない |
| PreToolUse | `Edit\|Write\|NotebookEdit\|Bash` | `.claude/hooks/workflow-boundary.sh` | 状態ファイル（`review-state.json` / `merge-prep.json`）の保護（WF012）、ワーク境界の統制（WF011）、直接の `gh pr ready` の拒否（WF015）。doing が空でも動く |
| PostToolUse | `Edit\|Write\|NotebookEdit\|Bash` | `.claude/hooks/workflow-diff-check.sh` | 許可パス外の差分検出 → additionalContext |
| （フック外） | — | `.claude/hooks/work-boundary.sh` | Bash から明示的に呼ぶ CLI。境界判定とレビュー状態の遷移 |
| （フック外） | — | `.claude/hooks/merge-prep.sh` | Bash から明示的に呼ぶ CLI。マージ前作業の実行と記録、draft 解除 |

### リクエスト/レスポンス例

**PreToolUse 入力例（ブロックされるケース）**:
```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "c:/work/repo/src/main.ts" },
  "cwd": "c:/work/repo"
}
```

**PreToolUse 出力例（stderr / exit 2）**:
```
[WF002] パス違反: src/main.ts への書き込みは現在のフェーズでは許可されていません
現在のチケット: 001-investigation-現状調査.md（type: investigation）
許可パス: wip/20_plans/**, wip/10_tickets/**
対処: 成果物は許可パス配下に作成してください。このパスへの変更がチケットの目的上どうしても必要な場合は、勝手に回避せず、チケットのフロントマター allowed_paths への追加をユーザーに提案してください。
```

---

## エラーハンドリング

### エラーコード一覧

| コード | エラータイプ | 説明 |
|--------|-------------|------|
| WF001 | WIP リミット違反 | `wip/10_tickets/10_doing/` に 2 枚以上のチケットがある |
| WF002 | パス違反 | 現在のフェーズで許可されていないパスへの Edit/Write |
| WF003 | コマンド違反 | 現在のフェーズで許可されていない Bash コマンド |
| WF004 | 状態不正 | doing チケットのフロントマターが読めない / `type` が不正 |
| WF005 | 依存違反 | `depends_on` の先行チケットが未完了（PostToolUse で警告） |
| WF006 | プランモード違反 | doing にチケットがある状態で `EnterPlanMode` が呼ばれた |
| WF007 | 設定不正 | 作業タイプ定義 `.claude/hooks/workflow-types.json` が無い / JSON として不正 |
| WF008 | チケット改変 | doing チケットの frontmatter `type` を書き換えようとした（PreToolUse でブロック。PostToolUse でも警告） |
| WF009 | 想定外パス | 未記載パスへの書き込み / `git add`。ブロックではなくユーザー確認（`permissionDecision: ask`） |
| WF010 | 要確認パス | `ask_paths` に一致するパスへの書き込み。毎回ユーザー確認 |
| WF011 | ワーク境界違反 | ワーク境界でレビューが完了していない（`review_state != completed`）のに、次のワークのチケットを doing へ移した（`workflow-boundary.sh`） |
| WF012 | 状態ファイルの直接書き換え | `wip/10_tickets/review-state.json` または `wip/merge-prep.json` を、それぞれ `work-boundary.sh` / `merge-prep.sh` 以外の経路（Edit / Write / Bash）で書き換えようとした（`workflow-boundary.sh`。doing の有無を問わず） |
| WF013 | レビュー依頼の前提未充足 | `work-boundary.sh request` の前提条件（境界である・未依頼である・未コミットが無い・push 済み・PR がある）を満たさない（スクリプト自身が exit 2） |
| WF014 | レビュー完了の前提未充足 | `work-boundary.sh complete` の前提条件（`requested` である・`CHANGES_REQUESTED` でない・返信の無いインラインスレッドが無い・`--local` の整合）を満たさない（スクリプト自身が exit 2） |
| WF015 | マージ依頼の統制違反 | `gh pr ready` を Bash から直接実行しようとした。draft 解除は `merge-prep.sh ready` 経由のみ（`workflow-boundary.sh`。doing・境界・レビュー状態を問わず常に） |
| WF016 | マージ前作業の前提未充足 | `merge-prep.sh` の各サブコマンド（`reset-wip` / `check-conflicts` / `notify-issue` / `ready`）の前提条件を満たさない、または `check-conflicts` / `ready` の再検証で default ブランチとの衝突を検知した（スクリプト自身が exit 2） |

### エラーメッセージ（PreToolUse exit 2 時の stderr 仕様）

#### 共通フォーマット

```
[WFxxx] <エラー概要>: <対象>
現在のチケット: <doingチケットのファイル名>（type: <type>）
対処: <Claude が次に取るべき具体的行動>
```

設計原則:

- **1 行目は必ず `[WFxxx]` で始める**。ログ集計・ユニットテストでの機械判定に使う
- **「対処:」行を必ず含める**。Claude がユーザーに聞き返さず自力で復旧できる具体性を持たせる（「〜は禁止です」だけで終わらせない）
- パスはリポジトリルートからの相対パスで表記する
- 許可コマンドの全列挙はしない（長くなるため要約にとどめ、詳細はスキル本文に委ねる）
- 機密情報（環境変数の値など）はメッセージに含めない

#### プレースホルダ

| プレースホルダ | 内容 |
|---------------|------|
| `{ticket}` | doing チケットのファイル名（例: `001-investigation-現状調査.md`） |
| `{type}` | doing チケットの `type` 値 |
| `{file_path}` | ブロック対象のファイルパス（リポジトリ相対） |
| `{command}` | ブロック対象の Bash コマンド文字列 |
| `{allowed_paths}` | 現在有効な許可パス（カンマ区切り） |
| `{count}` / `{ticket_files}` | doing のチケット枚数 / ファイル名一覧 |
| `{memory_unit}` | セッション記憶の単位（`dir:<親ディレクトリ>` または `file:<パス>`） |
| `{source}` | 判定の根拠（`type.ask_paths` / `global.ask_paths` など） |

#### メッセージテンプレート

**WF001（WIP リミット違反）** — 対象ツールすべてで返す:

```
[WF001] WIPリミット違反: wip/10_tickets/10_doing/ にチケットが {count} 枚あります（上限 1 枚）
対象: {ticket_files}
対処: 現在作業中の 1 枚だけを doing に残し、他は wip/10_tickets/00_todo/（未着手に戻す）または wip/10_tickets/20_done/（完了済み）へ移動してから、元の操作をやり直してください。
```

**WF002（パス違反）** — Edit / Write / NotebookEdit で返す:

```
[WF002] パス違反: {file_path} への書き込みは現在のフェーズでは許可されていません
現在のチケット: {ticket}（type: {type}）
許可パス: {allowed_paths}
対処: 成果物は許可パス配下に作成してください。このパスへの変更がチケットの目的上どうしても必要な場合は、勝手に回避せず、チケットのフロントマター allowed_paths への追加をユーザーに提案してください。
```

**WF003（コマンド違反）** — Bash で返す:

```
[WF003] コマンド違反: このコマンドは現在のフェーズでは許可されていません
コマンド: {command}
現在のチケット: {ticket}（type: {type}）
対処: ファイルの読み取りは Read/Glob/Grep ツールを使ってください。ファイルの作成・編集は Bash ではなく Edit/Write ツールで許可パスに対して行ってください。チケットの移動・コミットは git mv / git add / git commit のみ許可されています。
```

**WF004（状態不正）** — 書き込み系ツールすべてで返す:

```
[WF004] 状態不正: doing チケットのフロントマターを解釈できません
対象: {ticket}
対処: {ticket} を開き、フロントマターに type: investigation / implementation / retrospective のいずれかと status: doing が記載されているか確認・修正してください（wip/10_tickets/ 配下への Edit はこの状態でも許可されています）。
```

**WF002（deny_paths の変形）** — `types.<type>.deny_paths` / `global.deny_paths` に一致した場合はそれぞれ専用の文言で返す:

```
[WF002] パス違反: {file_path} は作業タイプ {type} で禁止されたパス（deny_paths）です
現在のチケット: {ticket}（type: {type}）
対処: このパスは現在の作業タイプでは変更できません。変更が必要な場合は勝手に回避せず、適切な作業タイプでのチケット化をユーザーに提案してください。
```

```
[WF002] パス違反: {file_path} は保護パス（global.deny_paths）で、作業タイプ {type} では許可されていません
現在のチケット: {ticket}（type: {type}）
対処: 保護パス（.claude/ 配下など）への変更は、.claude/hooks/workflow-types.json でそのパスを allow_paths に持つ作業タイプのチケットでのみ行えます。必要な場合は勝手に変更せず、該当タイプでのチケット化をユーザーに提案してください（チケットの allowed_paths に追加しても許可されません）。
```

**WF009（想定外パス）** — 未記載パスへの Edit / Write / `git add` で `permissionDecision: ask` として返す（警告調。ユーザーが判断する）:

```
[WF009] 想定外パスへの書き込み: {file_path} は作業タイプ {type} で本来想定していないパスです。本当に書き込んで良いですか？
現在のチケット: {ticket}（type: {type}）
許可すると、このセッション中は {memory_unit} への書き込みを再確認しません。想定外であれば拒否し、チケットの allowed_paths や作業タイプ定義の見直しを検討してください。
```

**WF010（要確認パス）** — `ask_paths` に一致するパスへの Edit / Write で `permissionDecision: ask` として返す:

```
[WF010] 要確認パス: {file_path} は毎回確認が必要なパス（{source}）です。書き込みを許可しますか？
現在のチケット: {ticket}（type: {type}）
```

**WF007（設定不正）** — 書き込み系ツールすべてで返す（設定ファイル自身と `wip/10_tickets/**` への Edit は除く）:

```
[WF007] 設定不正: 作業タイプ定義 .claude/hooks/workflow-types.json が存在しないか、JSON として解釈できません
現在のチケット: {ticket}
対処: .claude/hooks/workflow-types.json を開き、types がオブジェクト（キー = 作業タイプ名）として定義されているか確認・修正してください（このファイルへの Edit はこの状態でも許可されています）。
```

**WF008（チケット改変）** — doing チケットへの Edit / Write で返す:

```
[WF008] チケット改変: doing チケットの type を書き換えることはできません（{type} → {new_type}）
現在のチケット: {ticket}（type: {type}）
対処: 作業タイプの変更が必要な場合は、このチケットを完了または wip/10_tickets/00_todo/ に戻し、適切な type の新しいチケットを作成してユーザーの合意を得てください。作業ログの追記など type 以外の編集は許可されています。
```

**WF006（プランモード違反）** — EnterPlanMode で返す:

```
[WF006] プランモード違反: チケット作業中はプランモードを使用できません
現在のチケット: {ticket}（type: {type}）
対処: プランモードは新しいワークフローを開始する際の全体計画（wip/00_overall_plan/）の作成・合意にのみ使用します。計画の検討・修正は investigation チケットの成果物として wip/20_plans/ に Edit/Write で行ってください。
```

**WF011（ワーク境界違反）** — `workflow-boundary.sh` が Bash（`mv` / `git mv`）または `10_doing/*.md` への Write / Edit で返す。doing が無いので「現在のチケット」行の代わりに境界の情報を出す:

```
[WF011] ワーク境界違反: ワーク {last_done_type} は完了していますが、レビューが {review_state} のため次のワークに着手できません
直前の done: {last_done}（type: {last_done_type}）／todo 先頭: {todo_head}（type: {todo_head_type}）
対処: {review_state に応じた文（下記）}。同じ type（{last_done_type}）の追加チケットで差し戻しに対応する場合はそのまま着手できます。
```

| `review_state` | 対処の文 |
|----------------|---------|
| `none` | `git push` してから `bash .claude/hooks/work-boundary.sh request` でレビューを依頼し、レビュー完了の連絡を待ってください（AskUserQuestion で待たず、応答を終えてください） |
| `requested` | レビュー完了の連絡を受けてから `bash .claude/hooks/work-boundary.sh complete` を実行してください。連絡がまだなら応答を終えて待ってください |

**WF012（状態ファイルの直接書き換え）** — `workflow-boundary.sh` が Edit / Write / NotebookEdit / Bash で返す。`{state_file}` は `wip/10_tickets/review-state.json` または `wip/merge-prep.json`、`{script}` はそれぞれ `work-boundary.sh`（`request` / `complete`）/ `merge-prep.sh`（`reset-wip` / `check-conflicts` / `notify-issue` / `ready`）:

```
[WF012] 状態ファイルの直接書き換え: {state_file} は {script} 以外から書き換えできません
対象: {file_path または command}
対処: 状態は bash .claude/hooks/{script} のサブコマンド（{subcommands}）でのみ遷移します。状態を進めたい場合はそのサブコマンドを実行し、前提条件（[WF013] / [WF014] / [WF016]）が満たせないならユーザーに報告してください。ファイルを編集・削除・復元して状態を作らないでください。
```

この拒否は、`git` が実際にマージ進行中（`MERGE_HEAD` が存在する）**かつ**対象ファイル自身がunmerged状態（`git diff --name-only --diff-filter=U` に含まれる）の両方を満たすときだけ解除される（前掲「(a)(b)(f) の例外」）。それ以外は常にこのメッセージで拒否する。

**WF013（レビュー依頼の前提未充足）** — `work-boundary.sh request` が返す（満たさない条件を 1 行ずつ列挙する）:

```
[WF013] レビュー依頼の前提未充足: request を実行できません
未充足: {条件のリスト。例: ワーク境界ではありません（todo 先頭 012-implementation-… は直前の done と同じ type） / 未コミットの変更があります / HEAD が push されていません / 現在のブランチに open な PR がありません / 既に requested です}
対処: 未充足の条件を解消してから再実行してください。境界でない場合は次のチケットに着手してください。既に requested の場合はレビュー完了の連絡を待って complete を実行してください。
```

**WF014（レビュー完了の前提未充足）** — `work-boundary.sh complete` が返す:

```
[WF014] レビュー完了の前提未充足: complete を実行できません
未充足: {条件のリスト。例: review_state が requested ではありません（none） / reviewDecision が CHANGES_REQUESTED です / 返信の無いインラインスレッドがあります: <id> <path>:<line> … / --local の指定が request と一致しません}
対処: CHANGES_REQUESTED なら指摘を同じ type の追加チケットで対応し、push 後に再度 request してください（または対応不要と合意できたらレビュアーに approve / dismiss を依頼してください）。未返信スレッドは bash .claude/hooks/work-boundary.sh reply <id> "<対応内容>" で返信してから再実行してください。
```

**WF015（マージ依頼の統制違反）** — `workflow-boundary.sh` が Bash で返す（doing・境界・レビュー状態を問わず常に）:

```
[WF015] マージ依頼の統制違反: gh pr ready は直接実行できません（draft の解除は merge-prep.sh ready 経由のみ）
対象: {command}
対処: bash .claude/hooks/merge-prep.sh ready を実行してください。前提（reset-wip / check-conflicts / notify-issue の記録と再検証）が満たせず [WF016] で止まる場合は、未充足の条件を解消するか、ユーザーに報告してください。迂回して ready にしないでください。
```

**WF016（マージ前作業の前提未充足）** — `merge-prep.sh` の各サブコマンドが返す（満たさない条件を 1 行ずつ列挙する）:

```
[WF016] マージ前作業の前提未充足: {subcommand} を実行できません
未充足: {条件のリスト。例: todo にチケットが残っています（016-…） / 最後のワークのレビューが completed ではありません（requested） / 未コミットの変更があります / 現在のブランチに open な PR がありません / merge_state が checked ではありません（reset） / default ブランチ main と衝突しています: .claude/docs/README.md, … / 通知先の issue がありません / HEAD が push されていません}
対処: {subcommand に応じた文。例: 残りのチケットを完了しレビューを completed にしてから reset-wip を実行してください / git merge origin/main で取り込み、衝突を解消してコミット・push した後に check-conflicts を再実行してください（git rebase は使わない） / --issue で通知先を指定してください / 先行するサブコマンド（reset-wip → check-conflicts → notify-issue）を順に実行してください}
```

- WF005（依存違反）と WF-DIFF（許可パス外の差分）は PreToolUse ではなく PostToolUse の additionalContext で通知する（出力フォーマットは「出力（Output）定義」参照）。ブロックはしない
- WF011 / WF012 / WF015 は `workflow-boundary.sh`、WF013 / WF014 は `work-boundary.sh`、WF016 は `merge-prep.sh` が出す。いずれも `ask` を使わず exit 2 のみ（ヘッドレス実行で「確認できないため拒否」にならない）

---

## 前提条件

- 対象プロジェクトが Git リポジトリであり、作業ブランチ上で実行されること
- Git Bash が利用可能であること（Windows 環境）
- `wip/` が `.gitignore` されていないこと（基準点コミット・差分検出に Git を使うため）
- `wip/10_tickets/{00_todo,10_doing,20_done}/`、`wip/20_plans/`、`wip/30_reports/` が `.gitkeep` で Git に載っていること（無ければスキルの手順 1 の `mkdir -p` で作られる）

---

## 制約条件

- **技術的制約**: フックはステートレス。状態は doing チケットのフロントマターのみから取得する。フロントマターのパースは外部依存なし（grep/sed 程度）で行える単純な形式に限定する
- **ビジネス的制約**: 特になし
- **外部的制約**: Claude Code のフック仕様（PreToolUse の exit 2 ブロック、PostToolUse の additionalContext）に準拠

---

## 非機能要件

| 項目 | 説明 |
|------|------|
| パフォーマンス | ガード条件（doing 0 枚 → exit 0）を最初に評価し、通常セッションでは実質ノーオペレーションにする |
| セキュリティ | フックのログ・エラーメッセージに機密情報を出力しない |
| 可用性 | `WORKFLOW_ENFORCE=0` で全チェックを無効化できる。フック不具合時の緊急脱出手段 |
| テスト容易性 | stdin に JSON を与えて exit code / stderr / stdout を検証できる構造。判定ログを `.claude/hooks/workflow.log` に残す |

---

## テストシナリオ

### テストケース一覧

| テストID | シナリオ | 入力 | 期待出力 | 結果 |
|---------|---------|------|---------|------|
| TC001 | doing 0 枚（通常セッション） | Edit / 任意パス | exit 0 | |
| TC002 | doing 2 枚 | Edit / 任意パス | exit 2 + WF001 | |
| TC003 | 調査中に wip/20_plans へ Write | Write / `wip/20_plans/調査.md` | exit 0 | |
| TC004 | 調査中に src へ Edit（未記載） | Edit / `src/main.ts` | exit 0 + `permissionDecision: ask`（WF009） | |
| TC005 | 調査中にチケットへ Edit（作業ログ） | Edit / `wip/10_tickets/10_doing/001-*.md` | exit 0 | |
| TC006 | 調査中に読み取り Bash | Bash / `git log --oneline` | exit 0 | |
| TC007 | 調査中に書き込み Bash | Bash / `echo x > src/a.ts` | exit 2 + WF003 | |
| TC008 | 調査中に sed -i | Bash / `sed -i 's/a/b/' src/a.ts` | exit 2 + WF003 | |
| TC009 | フロントマター破損 | Edit / `src/main.ts`（type 不正） | exit 2 + WF004 | |
| TC010 | WORKFLOW_ENFORCE=0 | Edit / `src/main.ts`（調査中） | exit 0 | |
| TC011 | 許可パス外の差分検出 | PostToolUse / `src/a.ts` に diff あり | exit 0 + additionalContext（WF-DIFF） | |
| TC012 | チケットの allowed_paths（追加 allow） | Edit / `lib/**` を追加した状態で `lib/util.ts` と `src/main.ts` | どちらも exit 0 | |
| TC015 | チケットの allowed_paths は global.deny を貫通しない | `allowed_paths: [".claude/**"]` で `.claude/settings.json` | exit 2 + WF002 | |
| TC020 | セッション記憶（ディレクトリ単位） | `src/main.ts` を承認（PostToolUse）後に `src/other.ts` ／ `src/sub/deep.ts` ／ `lib/util.ts` | allow ／ ask ／ ask | |
| TC020e | セッション記憶はセッション単位 | 別 session_id で `src/other.ts` | ask（WF009） | |
| TC021 | ask_paths は毎回確認 | `global.ask_paths: ["config/**"]` で承認後に再度 Edit | 毎回 ask（WF010） | |
| TC021c | file_level はファイル単位で記憶 | `package.json` 承認後に `package.json` ／ `README.md` | allow ／ ask | |
| TC022 | 未記載パスの git add | Bash / `git add src/main.ts` | ask（WF009） | |
| TC022b | 親ディレクトリ全体の git add は未記載扱い | Bash / `git add wip/`（`investigation`）／ `git add wip/`（`overall-plan`） | どちらも ask（WF009。`wip/` は `wip/10_tickets/*` にも type の allow にも一致しない） | `test-workflow-guard.sh`（issue #47） |
| TC022c | 規約どおりの git add は確認なし | Bash / `git mv …10_doing/001-….md …20_done/ && git add wip/10_tickets/ wip/20_plans/調査結果.md && git commit -m x`（`investigation`）／ `git add wip/10_tickets/ wip/00_overall_plan/`（`overall-plan`） | どちらも exit 0（ask なし） | `test-workflow-guard.sh`（issue #47） |
| TC011d | 承認済みパスの差分は違反にしない | PostToolUse / 承認済み `src/main.ts` に diff | additionalContext なし | |
| TC013 | チケット作業中のプランモード | EnterPlanMode（doing 1 枚） | exit 2 + WF006 | |
| TC013b | 全体計画時のプランモード | EnterPlanMode（doing 0 枚） | exit 0 | |
| TC014 | チケット作業中の全体計画への Edit | Edit / `wip/00_overall_plan/plan.md` | exit 2 + WF002 | |
| TC015b | 保護パスへの Edit（フック自体） | Edit / `.claude/hooks/workflow-guard.sh` | exit 2 + WF002 | |
| TC016 | `ai-asset-design` の許可範囲 | Edit / `.claude/docs/spec.md` ／ `.claude/hooks/*`・`settings.json` | 前者 exit 0、後者 exit 2 + WF002 | |
| TC017 | `ai-asset-implementation` の許可範囲 | Edit / `.claude/hooks/*`・`settings.json` ／ `.claude/docs/*` | 前者 exit 0、後者 exit 2 + WF002 | |
| TC017e | frontmatter で global.deny 内のパスを追加 | `ai-asset-implementation` + `allowed_paths: [".claude/docs/**"]` で `.claude/docs/*` | exit 2 + WF002 | |
| TC007c | 調査中のテストスクリプト実行 | Bash / `bash .claude/hooks/tests/test-workflow-entry.sh`（`investigation`） | exit 2 + WF003 | `test` グループ無し |
| TC023 | `test` グループのテストスクリプト実行 | Bash / `bash .claude/hooks/tests/*.sh`、`VAR=x bash .claude/skills/<skill>/scripts/*.sh`（`ai-asset-implementation`） | exit 0 | |
| TC023c/d | `test` グループでも対象外のスクリプト | Bash / `bash .claude/hooks/workflow-guard.sh`、`bash scripts/deploy.sh` | exit 2 + WF003 | |
| TC018 | 作業タイプ定義が無い | Edit / `wip/20_plans/*` ／ `.claude/hooks/workflow-types.json` | 前者 exit 2 + WF007、後者 exit 0 | |
| TC019 | doing チケットの type 書き換え | Edit / `type: investigation` → `type: ai-asset-implementation`、Write で type 変更、type 行削除 | exit 2 + WF008 | |
| TC019b | doing チケットの type 以外の編集 | Edit / 作業ログ追記、`status` 変更 | exit 0 | |
| TC019f | doing に 2 枚目を Write | Write / `wip/10_tickets/10_doing/999-*.md` | exit 2 + WF001 | |
| TC019g | doing に Markdown 以外を Write | Write / `wip/10_tickets/10_doing/.gitkeep` | exit 0 | チケットとみなさない |
| TC-post-008 | コミット済み type との不一致 | PostToolUse / sed で type を書き換えた状態 | exit 0 + additionalContext（WF008） | |
| TC024 | `status`: 境界でない（同 type が todo 先頭） | done `001-investigation`、todo 先頭 `002-investigation` | `at_boundary: false` | `work-boundary.sh` |
| TC024b | `status`: 境界（type が変わる） | done `002-investigation`、todo 先頭 `003-implementation` | `at_boundary: true`、`review_state: none` | |
| TC024c | `status`: 境界（todo 空） | done のみ | `at_boundary: true` | |
| TC024d | `status`: done 無し / doing あり | todo のみ ／ doing 1 枚 | `at_boundary: false` | |
| TC024e | `status`: 状態ファイルの失効 | 状態ファイルの `ticket` が done 末尾と不一致 | `review_state: none` | |
| TC025 | 状態ファイルの直接書き換え（Edit / Write） | Edit / `wip/10_tickets/review-state.json`（doing 0 枚・1 枚の両方） | exit 2 + WF012 | `workflow-boundary.sh` |
| TC025b | 状態ファイルの直接書き換え（Bash） | Bash / `rm …review-state.json`、`sed -i … review-state.json`、`echo x > …review-state.json`、`git checkout -- …review-state.json` | exit 2 + WF012 | |
| TC025c | 状態ファイルの読み取り・スクリプト経由 | Bash / `cat …review-state.json`、`git diff …review-state.json`、`bash .claude/hooks/work-boundary.sh status` | exit 0 | |
| TC026 | 境界でレビュー未依頼のまま着手 | Bash / `git mv wip/10_tickets/00_todo/003-implementation-… wip/10_tickets/10_doing/`（`review_state: none`） | exit 2 + WF011（対処に request） | |
| TC026b | 境界で requested のまま着手 | 同上（`review_state: requested`） | exit 2 + WF011（対処に complete） | |
| TC026c | 境界で completed なら着手できる | 同上（`review_state: completed`、`ticket` 一致） | exit 0 | |
| TC026d | 境界でも同 type の追加チケットは着手できる | Bash / `git mv wip/10_tickets/00_todo/004-investigation-指摘対応.md wip/10_tickets/10_doing/`（done 末尾 `002-investigation`、`review_state: requested`） | exit 0 | |
| TC026e | 境界でない着手は統制しない | Bash / `git mv …00_todo/002-investigation-… …10_doing/`（done 末尾 `001-investigation`） | exit 0 | |
| TC026f | 境界で doing に Write | Write / `wip/10_tickets/10_doing/003-implementation-….md`（`review_state: none`） | exit 2 + WF011 | |
| TC026g | 境界で `gh pr ready` | Bash / `gh pr ready 13`（todo 空、`review_state: requested`） | exit 2 + WF015（issue #30 で WF011 から変更） | |
| TC026h | WORKFLOW_ENFORCE=0 | TC026 と同じ入力 | exit 0 | |
| TC027 | `request` の前提未充足 | 境界でない ／ 未コミットあり ／ 既に requested | exit 2 + WF013（状態ファイル不変） | `gh` はモック |
| TC027b | `request --local` | 境界・クリーン | 状態ファイルが `requested` / `local: true` になり、コミットされる | |
| TC028 | `complete` の前提未充足 | `review_state: none` ／ `CHANGES_REQUESTED` ／ 未返信スレッドあり ／ `--local` 不一致 | exit 2 + WF014（状態ファイル不変） | `gh` はモック |
| TC028b | `complete --local` | `requested` / `local: true` | 状態ファイルが `completed` になり、コミットされる | |
| TC029 | `merge-prep.json` の保護と `gh pr ready` の常時拒否 | Edit / Write / `rm` / `sed -i` / リダイレクト / `git checkout --` で `wip/merge-prep.json` ／ `gh pr ready 13`（doing 0 枚・1 枚、`review_state` が `completed` / `requested` / `none` の各状態） | 前者 exit 2 + WF012、後者は常に exit 2 + WF015。`cat` / `bash .claude/hooks/merge-prep.sh status` は exit 0。`WORKFLOW_ENFORCE=0` は exit 0 | `workflow-boundary.sh` |
| TC030 | `reset-wip` | todo あり ／ `review_state: none` ／ 未コミットあり ／ PR なし → 前提未充足。`--dry-run` → 一覧のみ。本実行 → 削除・状態ファイル・コミット・push。再実行 | 前提未充足は exit 2 + WF016（状態ファイル不変・成果物不変）。`--dry-run` は成果物不変。本実行後は成果物が消え `.gitkeep` が残り、`merge_state: reset`、`chore(merge-prep): reset wip` が push 済み。再実行は WF016 | `gh` はモック |
| TC031 | `check-conflicts` / `notify-issue` / `ready` | bare リモートの `main` と衝突する／しないコミット ／ 本文なし・通知先なし・二重通知 ／ notify 前の `ready`・全記録後の `ready` | 衝突ありは exit 2 + WF016 + ファイル名（`conflicts.has_conflict: true` を記録）、解消後は `checked`。`notify-issue` は `notified` とコメント URL を記録、二重は WF016。`ready` は未充足を列挙して exit 2、全記録後は `gh pr ready` を実行して `ready` | `gh` はモック、`merge-tree` は実物 |
| TC032 | WF012例外: MERGE_HEAD かつ 対象ファイルがunmerged | 実際に `git merge` でコンフリクトを起こした状態（`MERGE_HEAD` 存在・`review-state.json`/`merge-prep.json` が `--diff-filter=U` に含まれる）で Edit / Write / `sed -i` | exit 0（WF012を拒否しない） | `workflow-boundary.sh` |
| TC033 | WF012例外が適用されない場合 | (a) `MERGE_HEAD` が無い通常時、(b) `MERGE_HEAD` はあるが対象ファイルはunmergedでない（他ファイルの衝突）の2パターンで Edit | いずれも exit 2 + WF012（従来どおり） | `workflow-boundary.sh` |
| TC034 | 例外適用後の内容検証（PostToolUse警告） | TC032の例外でファイルを編集した直後、(a) 不正なJSON、(b) コンフリクトマーカー残存、(c) 正常に解消（マーカー除去・有効なJSON） | (a)(b) は exit 0 + additionalContext で警告（ブロックしない）、(c) は警告なし | `workflow-diff-check.sh` |

`gh` を伴うケース（TC027 / TC028 の非 `--local`、TC030 / TC031）は、`PATH` の先頭にモックの `gh` を置いて固定の JSON を返す方式でテストする（ネットワークに出ない）。default ブランチとの衝突判定（TC031）はモックせず、bare リモートに `main` を push して実物の `git merge-tree` で検証する。

### テスト実施例

- **テストID**: TC004
  - **前提条件**: `wip/10_tickets/10_doing/001-investigation-調査.md` が存在し `type: investigation`
  - **テスト手順**: `echo '{"tool_name":"Edit","tool_input":{"file_path":"src/main.ts"},"cwd":"."}' | .claude/hooks/workflow-guard.sh`
  - **期待結果**: exit code 2、stderr に `[WF002]` と対処方法が出力される

---

## 関連するドキュメント

- `.claude/docs/00_requirements/skill-work-ticket-driven.md`（要件定義書）
- `.claude/docs/10_spec/skill-workflow-issue-mr-driven.md`（前段のワークフロー。GitHub 操作は doing が空のときにのみ行う、という制約の根拠として本仕様の Bash allowlist を参照する）
- `.claude/docs/10_spec/skill-workflow-quick-request.md`（対になる振り分け。「振り返り候補の重さの区分」は本仕様の retrospective 節と文言を揃える）
- `.claude/docs/10_spec/スキル体系.md`（本スキルは3層構造の `work-*` に分類される。チケット＝タスクの用語対応、ワーク完了チェックポイント、`wf_validate_mv` の `git mv` 許可拡張の正）
- `.claude/docs/10_spec/フェーズ別ワークスキル.md`（`overall-plan` / `<phase>-plan` / `design` / `design-sync` の各 type を使うフェーズ別ワークスキルの仕様。TC032〜TC039）
- Claude Code フック仕様（PreToolUse / PostToolUse）

## レビュー記録

| 日付 | バージョン | 変更内容 | 変更者 |
|------|----------|---------|--------|
| 2026-08-29 | 1.0 | 初版（許可マトリクス素案を含む） | Hiro |
| 2026-08-29 | 1.1 | PreToolUse exit 2 時のエラーメッセージ仕様（共通フォーマット・テンプレート）を追加 | Hiro |
| 2026-08-30 | 1.2 | 保護パス（`.claude/**`・`wip/00_overall_plan/**`）と WF006（チケット作業中のプランモード禁止）、テンプレート3種（チケット/計画書/結果報告）を追加 | Hiro |
| 2026-08-30 | 1.3 | 作業タイプ定義を `.claude/hooks/workflow-types.json` に外出し（`ai-asset-design` / `ai-asset-implementation` を追加）。保護パスの貫通は設定由来の許可のみ。WF007（設定不正）・WF008（doing チケットの type 改変防止）を追加 | Hiro |
| 2026-08-30 | 1.4 | パス判定を allow / deny / ask の 3 区分に再設計。未記載パスは deny ではなく警告付き確認（WF009）とし、承認結果をセッション記憶（ディレクトリ単位、`file_level` はファイル単位）に記録。`ask_paths`（毎回確認、WF010）を追加。チケットの `allowed_paths` は追加 allow に変更 | Hiro |
| 2026-08-30 | 1.5 | `wip/` のディレクトリ構成を番号付き命名（`10_tickets/{00_todo,10_doing,20_done}`、`20_plans`、`30_reports`）に統一し、`.gitkeep` で Git に載せる前提を追加（issue #1） | Hiro |
| 2026-08-30 | 1.5 | issue-PR 駆動ワークフロー仕様への相互参照を追加。結果報告テンプレートに「対象 issue」「PR」欄を追加（フック・許可マトリクスの変更なし） | Hiro |
| 2026-08-30 | 1.6 | `bash_groups` に `"test"`（フックのテストスクリプト実行）を追加し `ai-asset-implementation` に付与。doing 配下の WF001 判定を `*.md` に限定（`.gitkeep` を許容）。TC007c / TC019g / TC023 を追加（issue #1） | Hiro |
| 2026-08-30 | 1.7 | スキル体系仕様書への相互参照を追加。本スキルは3層構造の `work-*` に分類される（issue #7） | Hiro |
| 2026-08-30 | 1.8 | 基本フロー（スキル全体）にワーク境界（作業タイプ単位のワーク完了）と、呼び出し元への制御の返却 / 単独時の承認確認を追加。フック・許可マトリクスの変更なし（issue #12） | Hiro |
| 2026-08-30 | 1.9 | ワーク境界の判定とレビュー状態を機械化: `work-boundary.sh`（`status` / `request` / `complete` / `reply`）、レビュー状態ファイル `wip/10_tickets/review-state.json`、ワーク境界フック `workflow-boundary.sh`（WF011 / WF012）、スクリプトのエラー WF013 / WF014、TC024〜TC028 を追加。1.8 の「フックは関与しない」を撤回（issue #12、ユーザー指示） | Hiro |
| 2026-08-30 | 2.0 | マージ前作業（wip リセット → コンフリクト確認 → 関連 issue コメント → draft 解除）を機械化: `merge-prep.sh`（`status` / `reset-wip` / `check-conflicts` / `notify-issue` / `ready`）、状態ファイル `wip/merge-prep.json`、フック条件 (e)(f)（直接の `gh pr ready` を WF015 で常時拒否、`merge-prep.json` を WF012 で保護）、WF016、TC029〜TC031 を追加。(d) を (e) に統合し TC026g の期待値を WF015 に変更（issue #30） | Hiro |
| 2026-08-30 | 2.1 | 「retrospective の棚卸しと合意」節を追加: AI アセットの棚卸し（5種類）・4観点の振り返り・軽微/振る舞いが変わるの2区分・issue化ルートの処理フローを、`workflow-quick-request` 側と文言を揃えて定義。フック・許可マトリクスの変更なし（issue #3） | Hiro |
| 2026-08-30 | 2.2 | gh CLI 不在時のフォールバックを追加: `work-boundary.sh`/`merge-prep.sh` の全サブコマンドに `--pr <N>` を追加し、`request`/`complete`/`notify-issue`/`ready` に `--external`（＋ `--comment-url`/`--report-file`/`--pr-body-file`/`--posted`）を追加。状態ファイルに `via: "gh" \| "local" \| "external"` を追加し、証跡強度のトレードオフを明記。既存の gh 前提の挙動は変更なし（issue #41） | Hiro |
| 2026-08-30 | 2.2 | フェーズ別ワークスキル用の 9 type（`overall-plan` / 計画 6 種 / `design` / `design-sync`）を標準の定義に追加。`overall-plan` の global deny 貫通と、全体計画の標準の入口が `work-overall-plan` になることを追記。フック・判定順序の変更なし（issue #39。main 側の 2.1（issue #3）との衝突を解消して繰り下げ） | Hiro |
| 2026-08-30 | 2.3 | 「Bash コマンドの許可」に `git add` の対象パスの規約（`wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` のような親ディレクトリ全体を指定しない。Bash の承認はセッション記憶されず、ヘッドレスでは拒否になる）を追加し、基本フロー 3・6 のコマンド表記を規約に揃えた。TC022b / TC022c を追加。フック・判定順序の変更なし（issue #47） | Hiro |
| 2026-08-31 | 2.4 | WF012（(a)(b)(f)）に、マージ進行中（`MERGE_HEAD` 存在 かつ 対象ファイルがunmerged）に限る例外を追加: 例外を満たさない場合は従来どおり常時拒否。例外適用後の内容検証（有効なJSON・マーカー残存なし・unmerged解消済み）は`workflow-diff-check.sh`（PostToolUse）の警告のみとし、機微キー不変チェックは見送り。doing空でBashが無制限であることに起因する残存リスクをトレードオフとして明記。TC032〜TC034を追加（issue #51） | Hiro |
