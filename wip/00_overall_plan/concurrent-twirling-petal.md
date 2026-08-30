# 全skillに requirements/specs を1:1:1で紐づける（issue #37）

- 対象 issue: #37 https://github.com/yuki-matsu783/agent-workflow/issues/37
- PR: #38 https://github.com/yuki-matsu783/agent-workflow/pull/38

## Context

`.claude/skills/` 配下には現在11スキルあるが、専用の要件定義書（`.claude/docs/00_requirements/`）と仕様書（`.claude/docs/10_spec/`）のペアを持つのは `work-ticket-driven` と `workflow-issue-mr-driven` の2スキルのみ。残り9スキル（`task-*` 系8つ + `workflow-quick-request`）にはrequirements/specsが存在しない。

また既存のrequirements/specsは「issue-PR駆動ワークフロー」のようにトピック単位で作られており、「スキル体系」「用語辞書」「ワークフロー振り分け実施済み判定」は特定の1スキルに紐づかない横断的なメタ文書として存在する。ユーザーの要望は「skillとrequirements/specsが必ず1:1:1で紐づく」体系にすること。現状は不足している9スキル分を新規作成しつつ、横断的な3メタ文書をどう扱うか（1:1:1の例外として明示するか、代表スキルに寄せるか）を整理する必要がある。

## 方針

1. **9スキル全てに専用requirements+specを新設する**（`workflow-quick-request` を含む。既存の「ワークフロー振り分け実施済み判定.md」はWF101フックの仕様であり、`workflow-quick-request` 自身の手順仕様ではないため、別途「軽作業ワークフロー」requirements+specを新設し、両スキルが専用ペアを持つ状態にする）。
2. **横断的メタ文書（スキル体系・用語辞書・ワークフロー振り分け実施済み判定）は1:1:1原則の例外として明示する。** 各文書に「特定の1スキルに1:1で紐づく要件/仕様ではなく、複数スキルが参照する横断的なメタ文書である」旨の一文を追記する。`ワークフロー振り分け実施済み判定.md` は現状specのみでrequirements側が無く非対称なため、requirementsも新設して3文書ともペアを揃える。
3. **SKILL.mdへの参照リンクは既存書式（`- 要件: ...` / `- 仕様: ...`）に揃える。** `workflow-quick-request` は専用ペアに加え、共有メタ文書への参照であることが分かる注記付きの行を追加する（`workflow-issue-mr-driven` にも対称の行を追加し、整合を明示する）。

### 新規ファイルの配置（`.claude/docs/00_requirements/<title>.md` / `.claude/docs/10_spec/<title>.md`）

| skill | title |
|---|---|
| task-gh-feature | featureブランチとPR作成 |
| task-gh-install | CLIインストール |
| task-gh-issue | issue操作 |
| task-repo-merge-settings | マージ設定変更 |
| task-requirements | 要件定義書作成 |
| task-spec | 仕様書作成 |
| task-ai-asset-creator | AIアセット作成 |
| task-investigating-technologies | 技術調査 |
| workflow-quick-request | 軽作業ワークフロー |

既存ファイル名との衝突なしを確認済み。requirementsは `task-requirements/assets/requirements.template.md`、specは `task-spec/assets/spec.template.md` をコピーし、骨格見出しは維持しつつスキルの性質に応じて小節を追加・置換してよい（既存の `issue-PR駆動ワークフロー.md` が実例）。frontmatterは `.claude/rules/markdown-frontmatter.md` に従う（`type: requirements`/`type: spec` 等）。

### SKILL.md参照リンクの書式

H1見出し直後・最初の `##` 節より前に追加（`workflow-issue-mr-driven/SKILL.md` の既存書式に揃える）:

```markdown
- 要件: `.claude/docs/00_requirements/<title>.md`
- 仕様: `.claude/docs/10_spec/<title>.md`
```

`workflow-quick-request` は3行構成:

```markdown
- 要件: `.claude/docs/00_requirements/軽作業ワークフロー.md`
- 仕様: `.claude/docs/10_spec/軽作業ワークフロー.md`
- 振り分け実施済み判定の仕様（WF101 フックの正。`workflow-issue-mr-driven` と共有するメタ文書）: `.claude/docs/10_spec/ワークフロー振り分け実施済み判定.md`
```

SKILL.mdのfrontmatter（OKF: type/title/tags/keywords）付与は本issueのスコープ外（触らない）。

## チケット分割（現状の最終done連番 020 の続き、021から）

`.claude/docs/**` は `ai-asset-design`、`.claude/skills/**` は `ai-asset-implementation` で変更する制約に従い、design → implementation の順。9スキルをドメインでグルーピング。

| # | type | ファイル | 目的 | depends_on |
|---|------|---------|------|-----------|
| 021 | ai-asset-design | gh-glab操作スキル要件仕様 | task-gh-feature/task-gh-install/task-gh-issue/task-repo-merge-settings の4スキル分、req+spec 計8ファイル新設 | なし |
| 022 | ai-asset-design | ドキュメント作成スキル要件仕様 | task-requirements/task-spec の2スキル分、req+spec 計4ファイル新設 | なし |
| 023 | ai-asset-design | アセット作成技術調査スキル要件仕様 | task-ai-asset-creator/task-investigating-technologies の2スキル分、req+spec 計4ファイル新設 | なし |
| 024 | ai-asset-design | 軽作業とメタ文書整理 | workflow-quick-request専用req+spec新設（2ファイル）、ワークフロー振り分け実施済み判定のrequirements新設（1ファイル）、3メタ文書5ファイルへ位置づけ注記追記 | なし |
| 025 | ai-asset-implementation | gh-glab操作スキル参照リンク | 021の4ファイルペアへの参照リンクを対応する4スキルのSKILL.mdに追加 | 021 |
| 026 | ai-asset-implementation | ドキュメント作成スキル参照リンク | 022のペアへの参照リンクをtask-requirements/task-specのSKILL.mdに追加 | 022 |
| 027 | ai-asset-implementation | アセット作成技術調査スキル参照リンク | 023のペアへの参照リンクを対応する2スキルのSKILL.mdに追加 | 023 |
| 028 | ai-asset-implementation | 軽作業スキル参照リンク | workflow-quick-request/SKILL.mdに専用req/spec+共有メタ文書の3行追加。workflow-issue-mr-driven/SKILL.mdに対称の共有メタ文書1行追加 | 024 |
| 029 | retrospective | 振り返り | 全11スキルが1:1:1(専用ペア or 例外明示)を満たすこと、リンク先実在、issue #37受け入れ条件3点の充足を確認しwip/30_reports/に記録 | 025, 026, 027, 028 |

design 4本 → implementation 4本 → retrospective 1本の順で連続実施（type単位でまとめてワーク境界=レビュー往復を最小化）。

## 検証

- 各design完了時: 新設したrequirements/specファイルのfrontmatterと見出し骨格を目視確認
- 各implementation完了時: 追加したSKILL.mdのリンク先パスが実在することを確認（`ls` で対象ファイルの存在確認）
- retrospective: `.claude/skills/*/SKILL.md` 全11件を確認し、それぞれから要件/仕様への参照が辿れることをチェックリストで確認
