---
type: plan
title: merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化する実装計画
description: gh の GraphQL 自動解決（gh pr view / gh pr comment / gh issue comment）を gh api（REST）に置き換える
tags: [workflow-issue-mr-driven, work-ticket-driven, plan]
keywords: [merge-prep, work-boundary, gh api, GraphQL, REST, reviewDecision, agent proxy, gh CLI]
---

# merge-prep.sh / work-boundary.sh の PR 特定・コメント投稿を REST 化する実装計画

- 作成元チケット: 001-ai-asset-design-gh-pr-rest化設計.md
- 作成日: 2026-08-30

## 調査サマリ

- `merge-prep.sh` の `mp_pr_number()` と `work-boundary.sh` の `wb_pr_number()` は同一実装（`gh pr view --json number -q .number`）で、現在ブランチから PR を自動解決する GraphQL クエリ `PullRequestForBranch` を使う
- `mp_notify()` の PR 本文取得（`Closes #N` 抽出用）は `gh pr view "${PR}" --json body -q .body`（`PullRequestByNumber` クエリ）
- `wb_complete()` のレビュー判定取得は `gh pr view "${pr}" --json reviewDecision,reviews,comments`（同じく `PullRequestByNumber` クエリ）
- `wb_request()` のレビュー依頼コメント投稿は `gh pr comment`、`mp_notify()` の issue コメント投稿は `gh issue comment` で、いずれも GraphQL の `addComment` mutation 経由（`GH_DEBUG=api` で実測確認済み）
- 一方 `wb_complete()` のインラインコメント取得（`gh api "repos/{owner}/{repo}/pulls/${pr}/comments"`）と `wb_reply()`（`gh api ".../replies"`）は既に REST であり、対象外
- `gh api` の URL 文字列中の `{owner}` / `{repo}` / `{branch}` はローカルの git remote・現在ブランチから解決され、ネットワークに出る前に完了する（`GH_DEBUG=api` で実測済み。この解決自体は GraphQL 制限の影響を受けない）
- REST には GraphQL の `reviewDecision`（ブランチ保護込みの集約判定）に相当するフィールドが無い。`GET .../pulls/{pr}/reviews` の一覧から自前で計算する必要がある

## 変更方針

対象4関数・2箇所のコメント投稿を、すべて `gh api`（REST）呼び出しに置き換える。`reviewDecision` は
reviewer ごとの最新レビュー状態（`COMMENTED` / `PENDING` を除く）から `CHANGES_REQUESTED` /
`APPROVED` / `""` を自前で計算する簡略版とする。GitHub のブランチ保護ルール（必須レビュー人数・
CODEOWNERS 等）は考慮しない。`wb_complete()` が実際に使うのは `decision == "CHANGES_REQUESTED"` の
判定のみであり、この簡略化で既存の合否判定の挙動は変わらない。

代替案として「GraphQL のうち番号解決クエリだけを REST 化し、`reviewDecision` 取得は GraphQL のまま
残す」も検討したが、報告されている環境ではプロキシがクエリ単位で許可制になっており、
`reviewDecision` を含む `PullRequestByNumber` クエリ自体が拒否される（`--json number` のみなら
ネットワークに出ずローカルで完結するため見かけ上動くだけ）。この案では問題が解決しないため採らない。

`gh pr comment` / `gh issue comment` も同じ理由（GraphQL 経由）で REST 化する。PR コメントも GitHub
の内部では issue コメントと同じ名前空間なので、`POST /repos/{owner}/{repo}/issues/{number}/comments`
で両方投稿できる。

## 変更対象ファイル

| ファイル / パス | 変更内容 |
|----------------|---------|
| `.claude/hooks/merge-prep.sh` | `mp_pr_number()`、`mp_notify()` を REST 化 |
| `.claude/hooks/work-boundary.sh` | `wb_pr_number()`、`wb_request()`、`wb_complete()` を REST 化 |
| `.claude/skills/work-ticket-driven/scripts/test-hooks.sh` | `MOCK_BIN/gh` のパターンマッチとフィクスチャを新しい呼び出しに合わせて更新 |

**allowed_paths 案**: 実装チケットは `ai-asset-implementation`（`.claude/hooks/**` / `.claude/skills/**`）の標準範囲内。追加指定は不要。

## 実装ステップ

### 1. `merge-prep.sh` の `mp_pr_number()`

変更前:
```bash
mp_pr_number() {
    gh pr view --json number -q .number 2>/dev/null | tr -d '\r'
}
```

変更後:
```bash
mp_pr_number() {
    gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open" --jq '.[0].number // empty' 2>/dev/null | tr -d '\r'
}
```

`.[0].number` は PR が無ければ `.[0]` が `null` になり `// empty` で空文字列を返す（既存の「PR が無ければ空文字列」という契約を維持）。

### 2. `merge-prep.sh` の `mp_notify()`（PR 本文取得）

変更前（307-309行目付近）:
```bash
    if [ -n "${PR}" ]; then
        targets=$(gh pr view "${PR}" --json body -q .body 2>/dev/null | tr -d '\r' \
            | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)[[:space:]]+#[0-9]+' | grep -oE '[0-9]+$' || true)
    fi
```

変更後:
```bash
    if [ -n "${PR}" ]; then
        targets=$(gh api "repos/{owner}/{repo}/pulls/${PR}" --jq '.body // empty' 2>/dev/null | tr -d '\r' \
            | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)[[:space:]]+#[0-9]+' | grep -oE '[0-9]+$' || true)
    fi
```

### 3. `merge-prep.sh` の `mp_notify()`（issue コメント投稿）

変更前（329行目付近）:
```bash
        url=$(gh issue comment "${n}" --body-file "${tmp}" 2>&1 | tr -d '\r' | tail -1)
```

変更後:
```bash
        url=$(gh api "repos/{owner}/{repo}/issues/${n}/comments" -f body="@${tmp}" --jq '.html_url' 2>&1 | tr -d '\r' | tail -1)
```

`-f body="@${tmp}"` は `gh api` の仕様で `@` 始まりの値をファイルから読み込む（`--body-file` と等価）。エラー時の分岐（`case "${url}" in http*issuecomment-*) ... ; *) ... mp_die ...`）はそのまま維持できる（REST のエラーレスポンスは JSON で stdout に出るため `2>&1` 経由で `posted`/エラーメッセージに含められる挙動は変わらない）。

### 4. `work-boundary.sh` の `wb_pr_number()`

変更前:
```bash
wb_pr_number() {
    gh pr view --json number -q .number 2>/dev/null | tr -d '\r'
}
```

変更後（`mp_pr_number()` と同一）:
```bash
wb_pr_number() {
    gh api "repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open" --jq '.[0].number // empty' 2>/dev/null | tr -d '\r'
}
```

### 5. `work-boundary.sh` の `wb_request()`（レビュー依頼コメント投稿）

変更前（182行目付近）:
```bash
        comment_url=$(gh pr comment "${pr}" --body-file "${tmp}" 2>&1 | tr -d '\r' | tail -1)
```

変更後:
```bash
        comment_url=$(gh api "repos/{owner}/{repo}/issues/${pr}/comments" -f body="@${tmp}" --jq '.html_url' 2>&1 | tr -d '\r' | tail -1)
```

### 6. `work-boundary.sh` の `wb_complete()`（レビュー判定・コメント取得）

変更前（227-249行目）:
```bash
    local decision="" comment_ids="[]" inline_ids="[]" new_comments="[]" new_reviews="[]" new_inline="[]"
    if [ "${local_mode}" = false ]; then
        local prv inl
        prv=$(gh pr view "${pr}" --json reviewDecision,reviews,comments 2>/dev/null | tr -d '\r')
        [ -n "${prv}" ] || wb_die WF014 "レビュー完了の前提未充足: gh pr view に失敗しました" "PR #${pr} の情報を取得できません" "gh の認証・PR の状態を確認してから再実行してください。"
        inl=$(gh api "repos/{owner}/{repo}/pulls/${pr}/comments" 2>/dev/null | tr -d '\r')
        [ -n "${inl}" ] || inl="[]"
        decision=$(printf '%s' "${prv}" | wf_jq -r '.reviewDecision // ""')
        local unreplied
        unreplied=$(printf '%s' "${inl}" | wf_jq -r '. as $all | [.[] | select(.in_reply_to_id == null) | select(.id as $id | any($all[]; .in_reply_to_id == $id) | not)] | .[] | "\(.id) \(.path):\(.line // .original_line // "-")"')
        [ "${decision}" = "CHANGES_REQUESTED" ] && fails+="reviewDecision が CHANGES_REQUESTED です"$'\n'
        [ -n "${unreplied}" ] && fails+="返信の無いインラインスレッドがあります: $(printf '%s' "${unreplied}" | paste -sd ',' -)"$'\n'
        [ -n "${fails}" ] && wb_die WF014 "レビュー完了の前提未充足: complete を実行できません" "${fails%$'\n'}" \
            "CHANGES_REQUESTED なら指摘を同じ type の追加チケットで対応し、push 後に再度 request してください（または対応不要と合意できたらレビュアーに approve / dismiss を依頼してください）。未返信スレッドは bash .claude/hooks/work-boundary.sh reply <id> \"<対応内容>\" で返信してから再実行してください。"
        comment_ids=$(printf '%s' "${prv}" | wf_jq -c '[.comments[]?.id]')
        inline_ids=$(printf '%s' "${inl}" | wf_jq -c '[.[]?.id]')
        new_comments=$(printf '%s' "${prv}" | wf_jq -c --arg p "${WB_PREFIX}" --arg at "${req_at}" \
            '[.comments[]? | select((.body | startswith($p)) | not) | select(.createdAt >= $at) | {id, author: .author.login, createdAt, url, body}]')
        new_reviews=$(printf '%s' "${prv}" | wf_jq -c --arg at "${req_at}" \
            '[.reviews[]? | select(.submittedAt >= $at) | {author: .author.login, state, submittedAt, body}]')
        new_inline=$(printf '%s' "${inl}" | wf_jq -c --arg p "${WB_PREFIX}" --arg at "${req_at}" \
            '[.[]? | select((.body | startswith($p)) | not) | select(.created_at >= $at) | {id, path, line, in_reply_to_id, user: .user.login, url: .html_url, body}]')
    fi
```

変更後:
```bash
    local decision="" comment_ids="[]" inline_ids="[]" new_comments="[]" new_reviews="[]" new_inline="[]"
    if [ "${local_mode}" = false ]; then
        local reviews comments inl
        reviews=$(gh api "repos/{owner}/{repo}/pulls/${pr}/reviews" 2>/dev/null | tr -d '\r')
        [ -n "${reviews}" ] || wb_die WF014 "レビュー完了の前提未充足: gh api pulls/reviews に失敗しました" "PR #${pr} のレビュー情報を取得できません" "gh の認証・PR の状態を確認してから再実行してください。"
        comments=$(gh api "repos/{owner}/{repo}/issues/${pr}/comments" 2>/dev/null | tr -d '\r')
        [ -n "${comments}" ] || comments="[]"
        inl=$(gh api "repos/{owner}/{repo}/pulls/${pr}/comments" 2>/dev/null | tr -d '\r')
        [ -n "${inl}" ] || inl="[]"
        # reviewDecision 相当: reviewer ごとの最新レビュー（COMMENTED/PENDING を除く）から算出する簡略版。
        # ブランチ保護（必須レビュー人数・CODEOWNERS 等）は考慮しない。CHANGES_REQUESTED 判定にのみ使う
        decision=$(printf '%s' "${reviews}" | wf_jq -r '
            [.[] | select(.state != "COMMENTED" and .state != "PENDING")]
            | group_by(.user.login) | map(max_by(.submitted_at))
            | if any(.state == "CHANGES_REQUESTED") then "CHANGES_REQUESTED"
              elif any(.state == "APPROVED") then "APPROVED"
              else "" end')
        local unreplied
        unreplied=$(printf '%s' "${inl}" | wf_jq -r '. as $all | [.[] | select(.in_reply_to_id == null) | select(.id as $id | any($all[]; .in_reply_to_id == $id) | not)] | .[] | "\(.id) \(.path):\(.line // .original_line // "-")"')
        [ "${decision}" = "CHANGES_REQUESTED" ] && fails+="reviewDecision が CHANGES_REQUESTED です"$'\n'
        [ -n "${unreplied}" ] && fails+="返信の無いインラインスレッドがあります: $(printf '%s' "${unreplied}" | paste -sd ',' -)"$'\n'
        [ -n "${fails}" ] && wb_die WF014 "レビュー完了の前提未充足: complete を実行できません" "${fails%$'\n'}" \
            "CHANGES_REQUESTED なら指摘を同じ type の追加チケットで対応し、push 後に再度 request してください（または対応不要と合意できたらレビュアーに approve / dismiss を依頼してください）。未返信スレッドは bash .claude/hooks/work-boundary.sh reply <id> \"<対応内容>\" で返信してから再実行してください。"
        comment_ids=$(printf '%s' "${comments}" | wf_jq -c '[.[]?.id]')
        inline_ids=$(printf '%s' "${inl}" | wf_jq -c '[.[]?.id]')
        new_comments=$(printf '%s' "${comments}" | wf_jq -c --arg p "${WB_PREFIX}" --arg at "${req_at}" \
            '[.[]? | select((.body | startswith($p)) | not) | select(.created_at >= $at) | {id, author: .user.login, createdAt: .created_at, url: .html_url, body}]')
        new_reviews=$(printf '%s' "${reviews}" | wf_jq -c --arg at "${req_at}" \
            '[.[]? | select(.state != "PENDING") | select(.submitted_at >= $at) | {author: .user.login, state, submittedAt: .submitted_at, body}]')
        new_inline=$(printf '%s' "${inl}" | wf_jq -c --arg p "${WB_PREFIX}" --arg at "${req_at}" \
            '[.[]? | select((.body | startswith($p)) | not) | select(.created_at >= $at) | {id, path, line, in_reply_to_id, user: .user.login, url: .html_url, body}]')
    fi
```

`inl`（インラインコメント取得）と `wb_reply()` は無変更。

### フィールド名の対応（REST への移行に伴う変更）

| 用途 | GraphQL（旧） | REST（新） |
|------|--------------|------------|
| 会話コメント投稿者 | `.comments[].author.login` | `.[].user.login` |
| 会話コメント投稿日時 | `.comments[].createdAt` | `.[].created_at` |
| 会話コメント URL | `.comments[].url` | `.[].html_url` |
| 会話コメント id | `.comments[].id`（GraphQL Node ID 文字列） | `.[].id`（REST 数値 id） |
| レビュー投稿者 | `.reviews[].author.login` | `.[].user.login` |
| レビュー投稿日時 | `.reviews[].submittedAt` | `.[].submitted_at` |

出力 JSON（`new_comments` / `new_reviews` 等、`complete` の stdout）のキー名（`author` / `createdAt` /
`url` / `submittedAt`）自体は変更しない。値の取得元だけが REST フィールドに変わる。`comment_ids` は
型が文字列（Node ID）から数値（REST id）に変わる。これは返信 id（`wb_reply` が使う id）と同じ体系に
なるため、証跡としての一貫性はむしろ上がる。

### 7. `test-hooks.sh` のモック更新（実装チケットで対応。ここでは要点のみ記す）

`MOCK_BIN/gh` の `case "$*" in ... esac` を、`gh pr view` / `gh pr comment` / `gh issue comment` 系の
パターンから `gh api` の呼び出しパターンに置き換える。新しい呼び出しは以下の4系統に分類でき、
`case` の順序は**具体的なものを先に**書く必要がある（bash の `case` は最初にマッチしたものを採用する）。

1. `*"pulls?head="*` → PR 番号（`GH_MOCK_PR` の値をそのまま返す。従来の `pr view --json number` と同じ役割）
2. `*"pulls/"*"/reviews"*` → レビュー一覧 JSON（従来 `GH_MOCK_PRVIEW` の `.reviews` 相当。フィールド名を REST 形式に変更したフィクスチャに更新する）
3. `*"pulls/"*"/comments/"*"/replies"*`（既存）→ 返信 URL。**`/comments"*` より前に置く**
4. `*"pulls/"*"/comments"*`（既存、GET）→ インラインコメント JSON（`GH_MOCK_INLINE`。変更なし）
5. `*"pulls/"*"-f body="*` は無いが、PR 本文取得は `*"pulls/"*` の単独マッチ（`--jq '.body // empty'` 付き。上記 2〜4 のいずれにも一致しない `pulls/<N>` 単体）→ `GH_MOCK_PRBODY` を返す
6. `*"issues/"*"/comments"*"-f body="*` → コメント投稿（`wb_request` の PR コメント・`mp_notify` の issue コメント、両方がこのパターンになる）→ `issuecomment-` を含む URL
7. `*"issues/"*"/comments"*`（`-f` なし、GET）→ 会話コメント一覧 JSON（従来 `GH_MOCK_PRVIEW` の `.comments` 相当。REST 形式のフィクスチャに変更）

既存フィクスチャ変数（`GH_MOCK_PRVIEW`）は 1 つで `reviewDecision`/`reviews`/`comments` を兼ねていたが、
新実装ではレビュー一覧と会話コメント一覧が別リクエストになるため、`GH_MOCK_PRVIEW` を
`GH_MOCK_REVIEWS`（レビュー一覧、REST 形式）と `GH_MOCK_COMMENTS`（会話コメント一覧、REST 形式）に
分割する。既存テストケース（TC028c 系）のフィクスチャ値をこの2変数に書き換える。

## 検証方法

- `bash .claude/skills/work-ticket-driven/scripts/test-hooks.sh` を実行し、TC024〜TC031 を含む全件が PASS すること
- `grep -n "gh pr view\|gh pr comment\|gh issue comment" .claude/hooks/merge-prep.sh .claude/hooks/work-boundary.sh` がヒットしないこと
- 実装後、`GH_DEBUG=api` を付けて `mp_pr_number` / `wb_pr_number` 相当のコマンドを単体実行し、
  `Request to https://api.github.com/repos/...`（REST）に到達し `api.github.com/graphql` に到達しないことを目視確認する

## リスク・未解決事項

- **`{branch}` プレースホルダの最小 `gh` バージョン**: 明確な最小バージョンの公式記載は確認できなかったが、このセッションの `gh 2.45.0` で動作を実測確認済み。既存コードも `gh` のバージョンを一切ガードしていない（`gh pr view` 等も同様に無条件で使っている）ため、本変更でも `gh` バージョンのガードは追加しない。仕様書には「`gh` の `{owner}`/`{repo}`/`{branch}` プレースホルダ機能を利用する」とだけ明記し、個別のバージョン要件は記載しない
- フォーク経由の PR（head が別リポジトリ）は REST の `head=owner:branch` フィルタでは考慮しない。既存の GraphQL 実装（`gh pr view` の内部解決）もこの点を特別扱いしていた保証はなく、扱いは変えない
- `reviewDecision` の自前計算はブランチ保護ルール（必須レビュー人数・CODEOWNERS）を考慮しない簡略版。`wb_complete()` が使うのは `CHANGES_REQUESTED` の検知のみのため実害は無いが、将来 `APPROVED` の値自体を条件分岐に使う変更が入る場合は注意が必要（仕様書に明記する）
