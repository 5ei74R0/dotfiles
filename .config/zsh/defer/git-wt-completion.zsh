# Completion for `git wt`.
# Loaded by sheldon because this file lives under `.config/zsh/defer/*.zsh`.

_git_wt_worktree_names() {
  emulate -L zsh

  local worktree branch common_dir main_root default_root root_relative
  local -a items

  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return
  main_root="$(cd "${common_dir:h}" 2>/dev/null && pwd -P)" || return
  default_root="$main_root/.git-wt"
  worktree=''
  branch=''
  items=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      if [[ -n "$worktree" && "$worktree" != "$main_root" ]]; then
        if [[ -n "$branch" ]]; then
          items+=("$branch")
        fi

        root_relative=''
        if [[ "$worktree" == "$default_root"/* ]]; then
          root_relative="${worktree#$default_root/}"
          items+=("$root_relative")
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

  items=("${(@u)items}")
  (( ${#items[@]} )) || return 1
  if (( ${+functions[__gitcomp]} )); then
    __gitcomp "${items[*]}"
  else
    compadd -Q -S ' ' -- "${items[@]}"
  fi
}

_git_wt() {
  local subcmd cur_ prev_ cword_ ret=1

  cur_="${cur-}"
  prev_="${prev-}"
  cword_="${cword:-$((CURRENT - 1))}"
  subcmd="${words[2]-}"

  if [[ -z "$subcmd" || "$cword_" -le 2 ]]; then
    _git_wt_commands && ret=0
    [[ "$ret" -eq 0 ]] && _ret=0
    return ret
  fi

  case "$subcmd" in
    new)
      case "$prev_" in
        --from)
          __git_complete_refs && ret=0
          ;;
        --branch)
          __git_complete_refs --mode=heads && ret=0
          ;;
        --path)
          _files -/ && ret=0
          ;;
        --agent)
          _git_wt_agents && ret=0
          ;;
        *)
          if [[ "$cur_" == -* ]]; then
            _git_wt_new_options && ret=0
          else
            ret=0
          fi
          ;;
      esac
      ;;
    path|shell)
      if [[ "$cword_" -eq 3 ]]; then
        _git_wt_worktree_names && ret=0
      else
        ret=0
      fi
      ;;
    agent)
      case "$cword_" in
        3)
          _git_wt_agents && ret=0
          ;;
        4)
          _git_wt_worktree_names && ret=0
          ;;
        *)
          _files && ret=0
          ;;
      esac
      ;;
    rm|remove)
      if [[ "$cur_" == -* ]]; then
        _git_wt_rm_options && ret=0
      elif [[ "$cword_" -eq 3 ]]; then
        _git_wt_worktree_names && ret=0
      else
        ret=0
      fi
      ;;
    prune)
      if [[ "$prev_" == --expire ]]; then
        ret=0
      elif [[ "$cur_" == -* ]]; then
        _git_wt_prune_options && ret=0
      else
        ret=0
      fi
      ;;
    ls|list|help)
      ret=0
      ;;
  esac

  if (( ret == 0 )); then
    _ret=0
  fi
  return ret
}

_git_wt_commands() {
  emulate -L zsh

  local -a commands
  commands=(
    'new:create a worktree for a task'
    'ls:list worktrees'
    'list:list worktrees'
    'path:print a worktree path'
    'shell:open a shell in a worktree'
    'agent:launch codex or claude in a worktree'
    'rm:remove a linked worktree'
    'remove:remove a linked worktree'
    'prune:prune stale worktree metadata'
    'help:show help'
  )
  commands=("${commands[@]%%:*}")
  if (( ${+functions[__gitcomp]} )); then
    __gitcomp "${commands[*]}"
  else
    compadd -Q -S ' ' -- "${commands[@]}"
  fi
}

_git_wt_agents() {
  emulate -L zsh

  local -a agents
  agents=(codex claude)
  if (( ${+functions[__gitcomp]} )); then
    __gitcomp "${agents[*]}"
  else
    compadd -Q -S ' ' -- "${agents[@]}"
  fi
}

_git_wt_new_options() {
  emulate -L zsh

  local -a options
  options=(
    --from
    --branch
    --path
    --agent
    --detach
    --lock
    --no-launch
  )
  if (( ${+functions[__gitcomp]} )); then
    __gitcomp "${options[*]}"
  else
    compadd -Q -S ' ' -- "${options[@]}"
  fi
}

_git_wt_rm_options() {
  emulate -L zsh

  local -a options
  options=(
    --force
    --branch
  )
  if (( ${+functions[__gitcomp]} )); then
    __gitcomp "${options[*]}"
  else
    compadd -Q -S ' ' -- "${options[@]}"
  fi
}

_git_wt_prune_options() {
  emulate -L zsh

  local -a options
  options=(
    -n
    --dry-run
    -v
    --verbose
    --expire
  )
  if (( ${+functions[__gitcomp]} )); then
    __gitcomp "${options[*]}"
  else
    compadd -Q -S ' ' -- "${options[@]}"
  fi
}

_git-wt() {
  _git_wt "$@"
}

_git_wt_register_user_command() {
  emulate -L zsh

  local -a user_commands
  zstyle -a ':completion:*:*:git:*' user-commands user_commands
  user_commands=(${user_commands:#wt:*})
  user_commands+=('wt:worktree workflow helper')
  zstyle ':completion:*:*:git:*' user-commands "${user_commands[@]}"
}

_git_wt_register_user_command
unfunction _git_wt_register_user_command
