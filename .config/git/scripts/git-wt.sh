#!/usr/bin/env bash
#
# git wt - opinionated Git worktree helper for coding-agent workflows.
#
# This script is designed to pair with `git step`:
# - `git step` for branch switching inside one worktree
# - `git wt`   for spawning / entering / removing task worktrees
#
# The defaults are intentionally lightweight:
# - worktrees live under the main worktree's `.git-wt` unless `wt.rootDir` is set
# - branches default to `<task-path>` unless `wt.branchPrefix` is set
# - `git wt new <task> --agent codex|claude` can immediately launch an agent
#
set -euo pipefail

main() {
  ensure_git_repo

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    new)
      cmd_new "$@"
      ;;
    ls|list)
      cmd_list "$@"
      ;;
    path)
      cmd_path "$@"
      ;;
    shell)
      cmd_shell "$@"
      ;;
    agent)
      cmd_agent "$@"
      ;;
    rm|remove)
      cmd_remove "$@"
      ;;
    prune)
      cmd_prune "$@"
      ;;
    help|-h|--help)
      print_help
      ;;
    *)
      die "unknown subcommand: $cmd"
      ;;
  esac
}

die() {
  printf '[git wt] %s\n' "$*" >&2
  exit 1
}

note() {
  printf '[git wt] %s\n' "$*"
}

ensure_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die 'not a git repository'
  git worktree list >/dev/null 2>&1 || die 'git worktree is unavailable in this Git build'
}

expand_home() {
  case "$1" in
    '~')
      printf '%s\n' "$HOME"
      ;;
    '~/'*)
      printf '%s/%s\n' "$HOME" "${1#~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

current_worktree_path() {
  local top
  top="$(git rev-parse --show-toplevel)"
  (cd "$top" && pwd -P)
}

git_common_dir_path() {
  local common
  common="$(git rev-parse --git-common-dir)"
  (cd "$common" && pwd -P)
}

main_worktree_path() {
  local common_dir
  common_dir="$(git_common_dir_path)"
  (cd "$(dirname "$common_dir")" && pwd -P)
}

repo_name() {
  basename "$(main_worktree_path)"
}

configured_worktree_root() {
  local configured main_path parent
  configured="$(git config --get wt.rootDir 2>/dev/null || true)"
  [ -n "$configured" ] || return 1

  main_path="$(main_worktree_path)"
  parent="$(dirname "$main_path")"

  configured="$(expand_home "$configured")"
  case "$configured" in
    /*)
      printf '%s\n' "$configured"
      ;;
    *)
      printf '%s/%s\n' "$parent" "$configured"
      ;;
  esac
}

default_worktree_root() {
  printf '%s/.git-wt\n' "$(main_worktree_path)"
}

ensure_default_worktree_root() {
  local root ignore_file
  root="$1"
  ignore_file="$root/.gitignore"

  mkdir -p "$root"

  if [ ! -e "$ignore_file" ]; then
    printf '*\n' > "$ignore_file"
  fi
}

default_branch_prefix() {
  local prefix
  prefix="$(git config --get wt.branchPrefix 2>/dev/null || true)"
  prefix="${prefix%/}"
  printf '%s\n' "$prefix"
}

default_base_ref() {
  local base
  base="$(git config --get wt.defaultBase 2>/dev/null || true)"
  if [ -z "$base" ]; then
    base='HEAD'
  fi
  printf '%s\n' "$base"
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's#[[:space:]/]#-#g' \
          -e 's#[^a-z0-9._-]#-#g' \
          -e 's#-\{2,\}#-#g' \
          -e 's#^[-.]##' \
          -e 's#[-.]$##'
}

path_slugify() {
  local input component result='' slug
  input="$1"

  while [ -n "$input" ]; do
    component="${input%%/*}"
    if [ "$component" = "$input" ]; then
      input=''
    else
      input="${input#*/}"
    fi

    slug="$(slugify "$component")"
    [ -n "$slug" ] || continue

    if [ -n "$result" ]; then
      result="$result/$slug"
    else
      result="$slug"
    fi
  done

  printf '%s\n' "$result"
}

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

is_main_worktree() {
  [ "$1" = "$(main_worktree_path)" ]
}

branch_for_worktree() {
  local target normalized worktree='' branch=''
  target="$1"
  normalized="$(cd "$target" && pwd -P)"

  while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$line" ]; then
      if [ -n "$worktree" ] && [ "$worktree" = "$normalized" ]; then
        printf '%s\n' "$branch"
        return 0
      fi
      worktree=''
      branch=''
      continue
    fi

    case "$line" in
      worktree\ *)
        worktree="${line#worktree }"
        ;;
      branch\ refs/heads/*)
        branch="${line#branch refs/heads/}"
        ;;
    esac
  done < <(git worktree list --porcelain; printf '\n')

  return 1
}

worktree_matches_target() {
  local target worktree branch default_root root_relative=''
  target="$1"
  worktree="$2"
  branch="$3"
  default_root="${4:-}"

  [ "$target" = "$worktree" ] && return 0
  [ -n "$branch" ] && [ "$target" = "$branch" ] && return 0

  if [ -n "$default_root" ]; then
    case "$worktree" in
      "$default_root"/*)
        root_relative="${worktree#"$default_root"/}"
        ;;
    esac
  fi

  [ -n "$root_relative" ] && [ "$target" = "$root_relative" ] && return 0

  return 1
}

find_worktree_path() {
  local target normalized_target default_root main_path matches=0 found='' worktree='' branch=''
  target="${1:-}"
  default_root="$(default_worktree_root)"
  main_path="$(main_worktree_path)"

  if [ -z "$target" ]; then
    current_worktree_path
    return 0
  fi

  target="$(expand_home "$target")"
  if [ -d "$target" ]; then
    normalized_target="$(cd "$target" && pwd -P)"
  else
    normalized_target="$target"
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$line" ]; then
      if [ -n "$worktree" ] && [ "$worktree" != "$main_path" ] \
        && worktree_matches_target "$normalized_target" "$worktree" "$branch" "$default_root"; then
        matches=$((matches + 1))
        found="$worktree"
      fi
      worktree=''
      branch=''
      continue
    fi

    case "$line" in
      worktree\ *)
        worktree="${line#worktree }"
        ;;
      branch\ refs/heads/*)
        branch="${line#branch refs/heads/}"
        ;;
    esac
  done < <(git worktree list --porcelain; printf '\n')

  if [ "$matches" -eq 0 ]; then
    die "could not find worktree target: $target"
  fi

  if [ "$matches" -gt 1 ]; then
    die "target is ambiguous: $target"
  fi

  printf '%s\n' "$found"
}

print_help() {
  cat <<'EOF'
Usage:
  git wt new <task> [options]
  git wt ls
  git wt path [target]
  git wt shell [target]
  git wt agent <codex|claude> [target] [-- <agent args...>]
  git wt rm <target> [--force] [--branch]
  git wt prune

Subcommands:
  new     Create a worktree for a task.
  ls      Show known worktrees in a compact view.
  path    Print the resolved worktree path.
  shell   Open an interactive shell inside a worktree.
  agent   Launch Codex CLI or Claude Code CLI inside a worktree.
  rm      Remove a linked worktree.
  prune   Prune stale worktree metadata.

Examples:
  git wt new login-fix
  git wt new login-fix --from main --agent codex
  git wt agent claude login-fix
  git wt shell login-fix
  cd "$(git wt path login-fix)"
  git wt rm login-fix --branch

Config (optional):
  git config --global wt.rootDir ~/worktrees
  git config --global wt.branchPrefix agent
  git config --global wt.defaultBase main
  git config --global wt.agent.codexCommand codex
  git config --global wt.agent.claudeCommand claude
EOF
}

print_new_help() {
  cat <<'EOF'
Usage:
  git wt new <task> [options]

Options:
  --from <ref>      Base commit/branch/tag. Default: wt.defaultBase or HEAD.
  --branch <name>   Explicit branch name. Default: <task-path>.
  --path <path>     Explicit worktree path.
  --agent <name>    Launch an agent after creation: codex | claude.
  --detach          Create a detached worktree instead of a branch.
  --lock            Lock the newly-created worktree.
  --no-launch       Do not launch the agent even when --agent is set.
  -h, --help        Show this help.

Anything after `--` is forwarded to the launched agent.
EOF
}

cmd_new() {
  local name='' from='' branch='' path='' agent=''
  local slug path_slug root repo lock='false' detach='false' no_launch='false'
  local default_root='false'
  local -a agent_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --from)
        [ $# -ge 2 ] || die '--from requires a value'
        from="$2"
        shift 2
        ;;
      --branch)
        [ $# -ge 2 ] || die '--branch requires a value'
        branch="$2"
        shift 2
        ;;
      --path)
        [ $# -ge 2 ] || die '--path requires a value'
        path="$2"
        shift 2
        ;;
      --agent)
        [ $# -ge 2 ] || die '--agent requires a value'
        agent="$2"
        shift 2
        ;;
      --detach)
        detach='true'
        shift
        ;;
      --lock)
        lock='true'
        shift
        ;;
      --no-launch)
        no_launch='true'
        shift
        ;;
      -h|--help)
        print_new_help
        return 0
        ;;
      --)
        shift
        agent_args=("$@")
        break
        ;;
      -*)
        die "unknown option for new: $1"
        ;;
      *)
        if [ -z "$name" ]; then
          name="$1"
        else
          die "unexpected argument: $1"
        fi
        shift
        ;;
    esac
  done

  [ -n "$name" ] || die 'new requires <task>'

  slug="$(slugify "$name")"
  [ -n "$slug" ] || die 'failed to derive task slug'
  path_slug="$(path_slugify "$name")"
  [ -n "$path_slug" ] || die 'failed to derive task path'

  if [ -z "$from" ]; then
    from="$(default_base_ref)"
  fi

  repo="$(repo_name)"

  if [ -z "$path" ]; then
    if root="$(configured_worktree_root)"; then
      path="$root/$repo-$slug"
    else
      root="$(default_worktree_root)"
      default_root='true'
      path="$root/$path_slug"
    fi
  else
    path="$(expand_home "$path")"
  fi

  if [ -e "$path" ]; then
    die "path already exists: $path"
  fi

  if [ "$default_root" = 'true' ]; then
    ensure_default_worktree_root "$root"
  fi
  mkdir -p "$(dirname "$path")"

  if [ "$detach" = 'true' ]; then
    git worktree add --detach "$path" "$from"
  else
    if [ -z "$branch" ]; then
      local prefix
      prefix="$(default_branch_prefix)"
      if [ -n "$prefix" ]; then
        branch="$prefix/$path_slug"
      else
        branch="$path_slug"
      fi
    fi

    git check-ref-format --branch "$branch" >/dev/null 2>&1 \
      || die "invalid branch name: $branch"

    if branch_exists "$branch"; then
      git worktree add "$path" "$branch"
    else
      git worktree add -b "$branch" "$path" "$from"
    fi
  fi

  if [ "$lock" = 'true' ]; then
    git worktree lock "$path"
  fi

  note "created: $path"
  if [ "$detach" = 'true' ]; then
    note "branch : detached @ $from"
  else
    note "branch : $branch"
  fi

  note "enter  : cd \"$path\""
  note "shell  : git wt shell $path_slug"
  if [ -n "$agent" ]; then
    note "agent  : git wt agent $agent $path_slug"
  fi

  if [ -n "$agent" ] && [ "$no_launch" != 'true' ]; then
    if [ "${#agent_args[@]}" -gt 0 ]; then
      launch_agent "$agent" "$path" "${agent_args[@]}"
    else
      launch_agent "$agent" "$path"
    fi
  fi
}

cmd_list() {
  local current worktree='' branch='' label=''
  current="$(current_worktree_path)"

  printf '%-2s %-28s %s\n' '' 'BRANCH' 'PATH'

  while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$line" ]; then
      if [ -n "$worktree" ]; then
        if [ -n "$branch" ]; then
          label="$branch"
        else
          label='detached'
        fi

        if [ "$worktree" = "$current" ]; then
          printf '%-2s %-28s %s\n' '*' "$label" "$worktree"
        else
          printf '%-2s %-28s %s\n' ' ' "$label" "$worktree"
        fi
      fi
      worktree=''
      branch=''
      continue
    fi

    case "$line" in
      worktree\ *)
        worktree="${line#worktree }"
        ;;
      branch\ refs/heads/*)
        branch="${line#branch refs/heads/}"
        ;;
    esac
  done < <(git worktree list --porcelain; printf '\n')
}

cmd_path() {
  local path
  path="$(find_worktree_path "${1:-}")"
  printf '%s\n' "$path"
}

cmd_shell() {
  local path shell_bin
  path="$(find_worktree_path "${1:-}")"
  shell_bin="${SHELL:-/bin/bash}"

  note "shell in: $path"
  (
    cd "$path"
    exec "$shell_bin" -l
  )
}

agent_command() {
  local agent configured
  agent="$1"

  case "$agent" in
    codex)
      configured="$(git config --get wt.agent.codexCommand 2>/dev/null || true)"
      if [ -n "$configured" ]; then
        printf '%s\n' "$configured"
      else
        printf '%s\n' 'codex'
      fi
      ;;
    claude)
      configured="$(git config --get wt.agent.claudeCommand 2>/dev/null || true)"
      if [ -n "$configured" ]; then
        printf '%s\n' "$configured"
      elif command -v claude >/dev/null 2>&1; then
        printf '%s\n' 'claude'
      elif command -v claude-code >/dev/null 2>&1; then
        printf '%s\n' 'claude-code'
      else
        printf '%s\n' 'claude'
      fi
      ;;
    *)
      die "unsupported agent: $agent"
      ;;
  esac
}

launch_agent() {
  local agent path cmd
  agent="$1"
  path="$2"
  shift 2
  cmd="$(agent_command "$agent")"

  note "launching $agent in: $path"

  (
    cd "$path"
    WT_AGENT_CMD="$cmd" bash -lc '
      if [ "$#" -gt 0 ]; then
        eval "exec $WT_AGENT_CMD \"\$@\""
      else
        eval "exec $WT_AGENT_CMD"
      fi
    ' _ "$@"
  )
}

cmd_agent() {
  local agent target=''

  agent="${1:-}"
  [ -n "$agent" ] || die 'agent requires <codex|claude>'
  shift || true

  if [ $# -gt 0 ] && [ "$1" != '--' ]; then
    target="$1"
    shift
  fi

  if [ $# -gt 0 ] && [ "$1" = '--' ]; then
    shift
  fi

  launch_agent "$agent" "$(find_worktree_path "$target")" "$@"
}

cmd_remove() {
  local target='' force='false' delete_branch='false' path branch=''

  while [ $# -gt 0 ]; do
    case "$1" in
      --force|-f)
        force='true'
        shift
        ;;
      --branch)
        delete_branch='true'
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage:
  git wt rm <target> [--force] [--branch]

Options:
  --force   Remove even when the worktree has local changes.
  --branch  Also delete the branch after removing the worktree.
EOF
        return 0
        ;;
      -*)
        die "unknown option for rm: $1"
        ;;
      *)
        if [ -z "$target" ]; then
          target="$1"
        else
          die "unexpected argument: $1"
        fi
        shift
        ;;
    esac
  done

  [ -n "$target" ] || die 'rm requires <target>'

  path="$(find_worktree_path "$target")"
  is_main_worktree "$path" && die 'refusing to remove the main worktree'

  branch="$(branch_for_worktree "$path" || true)"

  if [ "$force" = 'true' ]; then
    git worktree remove --force "$path"
  else
    git worktree remove "$path"
  fi
  git worktree prune

  note "removed: $path"

  if [ "$delete_branch" = 'true' ] && [ -n "$branch" ]; then
    git branch -D "$branch"
    note "deleted branch: $branch"
  fi
}

cmd_prune() {
  git worktree prune "$@"
}

main "$@"
