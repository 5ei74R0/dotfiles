# Completion for `git wt`.
# Loaded by sheldon because this file lives under `.config/zsh/defer/*.zsh`.

_git_wt_worktree_names() {
  local repo worktree branch common_dir main_root default_root root_relative
  local -a items
  local base

  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return
  main_root="$(cd "${common_dir:h}" 2>/dev/null && pwd -P)" || return
  repo="${main_root:t}"
  default_root="$main_root/.git-wt"
  worktree=''
  branch=''
  items=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      if [[ -n "$worktree" ]]; then
        if [[ -n "$branch" ]]; then
          items+=("$branch:$worktree")
          items+=("${branch:t}:$worktree")
        fi

        root_relative=''
        if [[ "$worktree" == "$default_root"/* ]]; then
          root_relative="${worktree#$default_root/}"
          items+=("$root_relative:$worktree")
        fi

        base="${worktree:t}"
        items+=("$base:$worktree")
        if [[ "$base" == "$repo" ]]; then
          items+=("main:$worktree")
        elif [[ "$base" == ${repo}-* ]]; then
          items+=("${base#$repo-}:$worktree")
        fi
      fi
      worktree=''
      branch=''
      continue
    fi

    case "$line" in
      'worktree '*)
        worktree="${line#worktree }"
        ;;
      'branch refs/heads/'*)
        branch="${line#branch refs/heads/}"
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null; printf '\n')

  _describe -t worktrees 'worktrees' items
}

_git_wt() {
  local curcontext="$curcontext" state
  typeset -A opt_args
  local -a commands

  commands=(
    'new:create a worktree for a task'
    'ls:list worktrees'
    'path:print a worktree path'
    'shell:open a shell in a worktree'
    'agent:launch codex or claude in a worktree'
    'rm:remove a linked worktree'
    'prune:prune stale worktree metadata'
    'help:show help'
  )

  if (( CURRENT == 3 )); then
    _describe -t commands 'git wt commands' commands
    return
  fi

  case "${words[3]}" in
    new)
      _arguments -C \
        '--from[base commit or branch]:base ref:_git_revisions' \
        '--branch[explicit branch name]:branch:_git_branch_names' \
        '--path[explicit worktree path]:path:_files -/' \
        '--agent[launch agent after creation]:agent:(codex claude)' \
        '--detach[create a detached worktree]' \
        '--lock[lock the new worktree]' \
        '--no-launch[skip launching the selected agent]' \
        '*::task name:'
      ;;
    path|shell)
      _arguments '1:worktree:_git_wt_worktree_names'
      ;;
    agent)
      if (( CURRENT == 4 )); then
        _values 'agent' codex claude
        return
      fi
      _arguments -C \
        '1:agent:(codex claude)' \
        '2:worktree:_git_wt_worktree_names' \
        '*::agent args:_files'
      ;;
    rm)
      _arguments -C \
        '--force[remove even when dirty]' \
        '--branch[also delete the branch]' \
        '1:worktree:_git_wt_worktree_names'
      ;;
    ls|list|prune|help)
      ;;
  esac
}

zstyle ':completion:*:*:git:*' user-commands wt:'worktree workflow helper'
