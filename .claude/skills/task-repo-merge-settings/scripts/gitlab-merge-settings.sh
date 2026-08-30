#!/usr/bin/env bash
# GitLabプロジェクトのマージ関連設定を glab CLI (glab api) 経由で確認・変更する。
# glab に gh repo edit 相当の専用サブコマンドが無いため、プロジェクト設定APIを直接叩く。
# AI が自由にコマンドを組み立てるのではなく、明示的な --flag=value だけを受け付ける。
set -euo pipefail

usage() {
  cat <<'USAGE'
使い方:
  gitlab-merge-settings.sh --project=GROUP/PROJECT --show
  gitlab-merge-settings.sh --project=GROUP/PROJECT [--squash-option=never|always|default_on|default_off] \
      [--remove-source-branch-after-merge=true|false]

オプション:
  --project=GROUP/PROJECT              対象プロジェクト（必須。パスまたは数値ID）
  --show                                現在の設定値を表示するだけで変更しない
  --squash-option=VALUE                MR作成時の「Squash commits」の既定値
                                        （never / always / default_on / default_off）
  --remove-source-branch-after-merge=BOOL  MR作成時の「Delete source branch」の既定値

指定したフラグの設定のみを変更する。未指定の設定は変更しない。
USAGE
}

project=""
show_only=0
squash_option=""
remove_source_branch=""

for arg in "$@"; do
  case "$arg" in
    --project=*)
      project="${arg#--project=}"
      ;;
    --show)
      show_only=1
      ;;
    --squash-option=*)
      squash_option="${arg#--squash-option=}"
      ;;
    --remove-source-branch-after-merge=*)
      remove_source_branch="${arg#--remove-source-branch-after-merge=}"
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

if [ -z "$project" ]; then
  echo "エラー: --project=GROUP/PROJECT は必須です" >&2
  usage >&2
  exit 1
fi

if [ -n "$squash_option" ]; then
  case "$squash_option" in
    never|always|default_on|default_off) ;;
    *)
      echo "エラー: --squash-option は never/always/default_on/default_off のいずれかで指定してください" >&2
      exit 1
      ;;
  esac
fi

if ! command -v glab >/dev/null 2>&1; then
  echo "エラー: glab CLI が見つかりません。公式手順でインストールしてください（https://gitlab.com/gitlab-org/cli#installation）。" >&2
  exit 1
fi

if ! glab auth status >/dev/null 2>&1; then
  echo "エラー: glab が未認証です。'glab auth login' を実行してください。" >&2
  exit 1
fi

# glab api はパスの "/" をそのまま渡すとプロジェクトパスの区切りと衝突するため %2F にエンコードする
encoded_project="${project//\//%2F}"

print_json() {
  if command -v jq >/dev/null 2>&1; then
    jq '{squash_option, remove_source_branch_after_merge}'
  else
    cat
  fi
}

show_current() {
  echo "# ${project} の現在のマージ関連設定"
  glab api "projects/${encoded_project}" | print_json
}

if [ "$show_only" -eq 1 ] || { [ -z "$squash_option" ] && [ -z "$remove_source_branch" ]; }; then
  show_current
  exit 0
fi

declare -a fields=()
if [ -n "$squash_option" ]; then
  fields+=(-f "squash_option=${squash_option}")
fi
if [ -n "$remove_source_branch" ]; then
  fields+=(-f "remove_source_branch_after_merge=${remove_source_branch}")
fi

glab api "projects/${encoded_project}" -X PUT "${fields[@]}" >/dev/null

echo "# 変更後の ${project} のマージ関連設定"
show_current
