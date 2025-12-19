# HISTORY
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=10000  # history size in memory
export SAVEHIST=10000  # history size on disk
setopt share_history          # share history across all sessions
setopt append_history         # append to the history file, don't overwrite it
setopt inc_append_history     # write to the history file immediately, not when the shell exits
setopt hist_ignore_all_dups   # remove older duplicates from the history list
setopt hist_reduce_blanks     # remove superfluous blanks from each command line
