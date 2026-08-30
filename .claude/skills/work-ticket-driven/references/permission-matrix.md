# フェーズ×許可マトリクス（要約）

正は `.claude/docs/10_spec/skill-work-ticket-driven.md`。
**作業タイプとパスの allow / deny / ask は `.claude/hooks/workflow-types.json` で定義**し、フックが呼び出しのたびに読み込む。
タイプの追加・変更はこの JSON を編集する（コード変更不要）。

## 作業タイプ定義（workflow-types.json）

```json
{
  "global": {
    "allow_paths": ["wip/10_tickets/**"],
    "deny_paths": [".claude/**", "wip/00_overall_plan/**"],
    "ask_paths": []
  },
  "session_memory": { "file_level": [".claude/settings.json", "package.json", "CLAUDE.md"] },
  "types": {
    "<type名>": {
      "description": "説明",
      "allow_paths": ["glob"], "deny_paths": [], "ask_paths": [],
      "bash_groups": ["build"]
    }
  }
}
```

- `allow` = 確認なしで触ってよい / `deny` = 触ってはならない / `ask` = 毎回ユーザーに確認
- パスは glob。`**` はディレクトリ再帰、`.claude/settings.json` のようにファイル単位の指定も可（`*` 単体もディレクトリ区切りをまたぐ点に注意）
- `bash_groups` に `"build"` を含むタイプだけ、ビルド/テスト系コマンド（npm 等）が使える
- `bash_groups` に `"test"` を含むタイプだけ、フックのテストスクリプト（`bash .claude/hooks/tests/*.sh`、`bash .claude/skills/<skill>/scripts/*.sh`。先頭の `VAR=value` は可）を実行できる

### 標準タイプ

| type | allow_paths | 用途 |
|------|------------|------|
| `investigation` | `wip/20_plans/**` | 調査。計画書を作成 |
| `implementation` | `src/**`, `tests/**`, `doc/**`, `wip/20_plans/**`（+ build） | 実装 |
| `retrospective` | `wip/30_reports/**` | 振り返り。結果報告を作成 |
| `ai-asset-design` | `.claude/docs/**`, `wip/20_plans/**` | AI アセットの設計（要件・仕様のみ） |
| `ai-asset-implementation` | `.claude/hooks/**`, `.claude/rules/**`, `.claude/skills/**`, `.claude/settings.json`（+ test） | AI アセットの実装。フックのテストを実行できる |

### フェーズ別ワークスキル用タイプ

仕様: `.claude/docs/10_spec/フェーズ別ワークスキル.md`。計画 type（`<phase>-plan`）は同じ許可範囲だがフェーズごとに分ける（`work-boundary.sh status` の `todo_head_type` からスキルを一意に選ぶため）。

| type | allow_paths | 用途 |
|------|------------|------|
| `overall-plan` | `wip/00_overall_plan/**`（global deny を type allow で貫通） | 全体計画。フェーズ列を決め、最初の計画チケットを起こす（`work-overall-plan`） |
| `investigation-plan` / `design-plan` / `implementation-plan` / `design-sync-plan` / `ai-asset-design-plan` / `ai-asset-implementation-plan` | `wip/20_plans/**` | 各フェーズの計画。計画書を書き、実施チケット群と次の計画チケットを起こす（`work-<phase>-plan`） |
| `design` | `docs/**`, `wip/20_plans/**` | 設計。`docs/` に要件定義書・仕様書を作成（`work-design-exec`） |
| `design-sync` | `docs/**`, `wip/20_plans/**` | 設計反映。実装差分を `docs/` の設計書に書き戻す（`work-design-sync-exec`） |

実施 type の `investigation` / `implementation` / `ai-asset-design` / `ai-asset-implementation` は上の標準タイプをそのまま使う（`work-<phase>-exec`）。

## Edit / Write / NotebookEdit の判定順序

前段: `wip/10_tickets/10_doing/` に doing チケット以外の `*.md` を書く → **WF001**（`.gitkeep` など Markdown 以外はチケットとみなさない）。doing チケットの `type` が変わる編集 → **WF008**。

| 順 | 照合対象 | 結果 |
|----|---------|------|
| 1 | `types.<type>.deny_paths` | **WF002**（exit 2） |
| 2 | `types.<type>.ask_paths` | **WF010** 確認（毎回） |
| 3 | `types.<type>.allow_paths` | 許可 |
| 4 | `global.deny_paths` | **WF002**（exit 2） |
| 5 | `global.ask_paths` | **WF010** 確認（毎回） |
| 6 | チケット frontmatter `allowed_paths` | 許可 |
| 7 | `global.allow_paths` | 許可 |
| 8 | セッション記憶（承認済み） | 許可 |
| 9 | 未記載 | **WF009** 「想定外のパス」と警告して確認。承認後はセッション記憶へ |

- type のリストを global より先に見るので、global で `.claude/**` を deny しつつ ai-asset 系で `.claude/docs/**` 等を allow できる
- チケットの `allowed_paths` は「確認なしで触りたいパス」の追加。deny を貫通したり ask を黙らせたりはできない（チケットは Claude 自身が書くため）
- `wip/10_tickets/**` を対象とする `git mv` / `git add` は、この判定表を経由せず常に許可される（下記「Bash の allowlist」参照）。この表は Edit/Write/NotebookEdit と、`wip/10_tickets/**` 以外を対象とする `git add` にのみ適用される

## セッション記憶

- 単位: 承認したファイルの**親ディレクトリ（直下のみ）**。`session_memory.file_level` に一致するパスはファイル単位
- 記録: PostToolUse で行う（ツールが実行された = ユーザーが承認した）。`ask_paths` は記録しない
- 保存先: `.claude/hooks/.state/<session_id>.approved`（Git 管理外）。別セッションでは再確認になる

## プランモード（EnterPlanMode）

- doing にチケットがある間は **WF006** でブロック
- プランモードは新しいワークフロー開始時の全体計画（`wip/00_overall_plan/`）の作成・合意にのみ使う

## Bash の allowlist（deny-by-default）

| 分類 | コマンド | 対象 |
|------|---------|------|
| 読み取り系 | `ls` `cat` `head` `tail` `wc` `grep` `rg` `find` `pwd`, `git status/log/diff/show/branch` | 全タイプ |
| チケット運用 | `mv` / `git mv`（`wip/10_tickets/` 配下同士のみ）, `git add`（`wip/10_tickets/` 配下同士は無条件許可。それ以外は対象パスに上の判定を適用。deny → WF003、ask/未記載 → 確認。対象は `wip/10_tickets/` と許可パス内のファイルに限定し、`wip/` のような親ディレクトリ全体を指定しない — glob に一致せず未記載の確認になる）, `git commit` | 全タイプ |
| ビルド/テスト | `npm` `npx` `node` `python` `pytest` `go` `cargo` `make` | `bash_groups` に `build` を含むタイプ |
| フックテスト | `bash .claude/hooks/tests/<name>.sh`, `bash .claude/skills/<skill>/scripts/<name>.sh`（先頭の `VAR=value` は可。それ以外の `bash <script>` は拒否） | `bash_groups` に `test` を含むタイプ |

- リダイレクト（`>` / `>>`）を含むコマンドは allowlist 該当でも一律拒否
- 複合コマンド（`&&` `;` `\|` `\|\|`）は分割して全セグメントを判定。1つでも不許可なら拒否
- パスは引用符なし・リポジトリ相対で指定する（クォートされたパスは検証不能として拒否される）

## 読み取り専用ツール

Read / Glob / Grep / WebFetch 等はフックの matcher 対象外。全フェーズで無条件に使用可。

## エラーコード

| コード | 内容 | 返却元 |
|--------|------|--------|
| WF001 | WIP リミット違反（doing 2枚以上 / 2枚目の作成） | PreToolUse（exit 2） |
| WF002 | deny パスへの Edit/Write | PreToolUse（exit 2） |
| WF003 | 許可されていない Bash コマンド | PreToolUse（exit 2） |
| WF004 | doing チケットの type が定義に無い | PreToolUse（exit 2） |
| WF005 | depends_on の先行チケット未完了 | PostToolUse（additionalContext・警告のみ） |
| WF006 | チケット作業中のプランモード使用 | PreToolUse（exit 2） |
| WF007 | 作業タイプ定義（workflow-types.json）が読めない | PreToolUse（exit 2。設定ファイル自身の Edit は可） |
| WF008 | doing チケットの type 書き換え | PreToolUse（exit 2）／PostToolUse（警告） |
| WF009 | 未記載（想定外）パスへの書き込み / git add | PreToolUse（ユーザー確認） |
| WF010 | ask_paths への書き込み | PreToolUse（ユーザー確認・毎回） |
| WF-DIFF | deny または未承認パスの差分検出 | PostToolUse（additionalContext・警告のみ） |

## ガード条件（フック共通）

1. `WORKFLOW_ENFORCE=0` → 全チェック無効（緊急脱出用。ユーザーの明示的な指示があるときのみ使用）
2. `wip/10_tickets/10_doing/` にチケットが無い → 何もしない（通常セッションに影響なし。全体計画のプランモードもこの状態で使う）
3. doing に 2 枚以上 → WF001 でブロック
4. 作業タイプ定義が読めない → WF007 でブロック（設定ファイルと `wip/10_tickets/` への Edit は復旧用に許可）
5. フロントマターの `type` が定義に無い → WF004 でブロック（`wip/10_tickets/` への Edit だけは復旧用に許可）
