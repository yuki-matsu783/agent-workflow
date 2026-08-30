#!/usr/bin/env bash
# GitHubリポジトリのマージ関連設定を gh CLI 経由で確認・変更する。
# AI が自由にコマンドを組み立てるのではなく、明示的な --flag=value だけを受け付ける。
set -euo pipefail

usage() {
  cat <<'USAGE'
使い方:
  github-merge-settings.sh --repo=OWNER/REPO --show
  github-merge-settings.sh --repo=OWNER/REPO [--delete-branch-on-merge=true|false] \
      [--allow-squash-merge=true|false] [--allow-merge-commit=true|false] \
      [--allow-rebase-merge=true|false]

オプション:
  --repo=OWNER/REPO             対象リポジトリ（必須）
  --show                        現在の設定値を表示するだけで変更しない
  --delete-branch-on-merge=BOOL  マージ後にsource branchを自動削除するか
  --allow-squash-merge=BOOL      squash mergeを許可するか
  --allow-merge-commit=BOOL      merge commitを許可するか
  --allow-rebase-merge=BOOL      rebase mergeを許可するか

指定したフラグの設定のみを変更する。未指定の設定は変更しない。
USAGE
}

repo=""
show_only=0
declare -a edit_args=()

for arg in "$@"; do
  case "$arg" in
    --repo=*)
      repo="${arg#--repo=}"
      ;;
    --show)
      show_only=1
      ;;
    --delete-branch-on-merge=*)
      edit_args+=("--delete-branch-on-merge" "${arg#--delete-branch-on-merge=}")
      ;;
    --allow-squash-merge=*)
      edit_args+=("--allow-squash-merge" "${arg#--allow-squash-merge=}")
      ;;
    --allow-merge-commit=*)
      edit_args+=("--allow-merge-commit" "${arg#--allow-merge-commit=}")
      ;;
    --allow-rebase-merge=*)
      edit_args+=("--allow-rebase-merge" "${arg#--allow-rebase-merge=}")
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "不明な引数: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$repo" ]; then
  echo "エラー: --repo=OWNER/REPO は必須です" >&2
  usage >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "エラー: gh CLI が見つかりません。task-gh-install スキルでインストールしてください。" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "エラー: gh が未認証です。'gh auth login' を実行してください。" >&2
  exit 1
fi

show_current() {
  echo "# ${repo} の現在のマージ関連設定"
  gh repo view "$repo" \
    --json deleteBranchOnMerge,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed,defaultBranchRef
}

if [ "$show_only" -eq 1 ] || [ "${#edit_args[@]}" -eq 0 ]; then
  show_current
  exit 0
fi

gh repo edit "$repo" "${edit_args[@]}"

echo "# 変更後の ${repo} のマージ関連設定"
show_current
