#!/bin/bash
#
# Git Step-away - Branch Switching with Auto-Stash
#
# A Git enhancement that automatically stashes your current work when switching
# branches and restores the stash when returning to a branch. This version acts
# as a transparent wrapper around git switch, supporting ALL git switch options.
#
# FEATURES:
# - Transparent wrapper: supports all git switch options and arguments
# - Automatically stashes uncommitted changes before switching branches
# - Restores branch-specific stashes when switching to a branch
# - Updates existing stashes instead of creating duplicates
# - Distinguishes auto-stashes from manual stashes with clear labeling
# - Hook-style design: pre-switch stashing + post-switch restoration
#
# USAGE:
#   git step [git-switch-options] <branch-name>
#   git step [git-switch-options] <start-point>
#
# SUPPORTED OPTIONS:
#   All git switch options are supported, including:
#   -c, --create <branch>        Create a new branch
#   -C, --force-create <branch>  Force create a new branch
#   -d, --detach                 Switch to a commit for inspection
#   -f, --force                  Force switch (discard local changes)
#   -m, --merge                  Perform a 3-way merge
#   --guess / --no-guess         Control remote branch guessing
#   --track / --no-track         Control branch tracking setup
#   And many more...
#
# INSTALLATION:
#   1. Save this script to ~/.local/bin/git-step-away
#   2. Make it executable: chmod +x ~/.local/bin/git-step-away  
#   3. Add to ~/.gitconfig:
#      [alias]
#          step = !"bash $HOME/.local/bin/git-script/git-step-away.sh"
#
# SET COMPLETION:
#   For Zsh, add to your completion setup (e.g., in .zshrc):
#       ```zsh
#       autoload -Uz compinit && compinit
#       _git_step() {
#           words[2]='switch'  # get completion as if calling git switch
#           __git_zsh_bash_func 'switch'
#       }
#       zstyle ':completion:*:*:git:*' user-commands step:'switch with auto-stash'
#       ```
#
# EXAMPLES:
#   git step feature-branch              # Basic branch switch
#   git step -c new-feature              # Create and switch to new branch
#   git step -c new-feature origin/main  # Create branch from origin/main
#   git step -d HEAD~3                   # Detach to specific commit
#   git step -f main                     # Force switch to main
#   git step -                           # Switch to previous branch
#
# REQUIREMENTS:
# - Git 2.23+ (for git switch command)
# - Bash or Zsh shell


git_step() {
    # Ensure we're in a Git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not a git repository"
        return 1
    fi

    # Handle help/usage display
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ $# -eq 0 ]; then
        echo "Usage: git step [git-switch-options] <branch-name|start-point>"
        echo ""
        echo "Git Step transparently wraps 'git switch' with automatic stashing."
        echo "All git switch options and arguments are supported."
        echo ""
        echo "Common examples:"
        echo "  git step feature-branch              # Switch to existing branch"
        echo "  git step -c new-feature             # Create and switch to new branch"
        echo "  git step -c new-feature origin/main # Create branch from origin/main"
        echo "  git step -d HEAD~3                  # Detach to specific commit"
        echo "  git step -                          # Switch to previous branch"
        echo ""
        echo "For full git switch documentation: git switch --help"
        return 0
    fi

    # PRE-SWITCH HOOK: Store current state and stash if needed
    local current_branch=$(git branch --show-current)
    local had_changes=false

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        had_changes=true

        # Look for existing auto-stash for current branch
        local existing_stash=$(git stash list | grep "\[auto-stash by git step\] WIP on $current_branch" | head -1)
        if [ -n "$existing_stash" ]; then
            local stash_index=$(echo "$existing_stash" | cut -d: -f1)
            git stash drop "$stash_index" > /dev/null 2>&1
            echo "Updated existing auto-stash for branch: $current_branch"
        else
            echo "Auto-stashed changes for branch: $current_branch"
        fi

        # Create new stash with distinctive label
        git stash push -m "[auto-stash by git step] WIP on $current_branch" > /dev/null 2>&1
    fi

    # MAIN OPERATION: Execute git switch with all original arguments
    git switch "$@"
    local switch_exit_code=$?

    # POST-SWITCH HOOK: Restore stash if switch was successful
    if [ $switch_exit_code -eq 0 ]; then
        local new_branch=$(git branch --show-current)

        # Always attempt stash restoration for named branches
        # This handles both branch switches and explicit switches to current branch
        if [ -n "$new_branch" ]; then
            # Look for auto-stash for the target branch
            local target_stash=$(git stash list | grep "\[auto-stash by git step\] WIP on $new_branch" | head -1)
            if [ -n "$target_stash" ]; then
                local stash_index=$(echo "$target_stash" | cut -d: -f1)
                git stash pop "$stash_index" > /dev/null 2>&1
                echo "Restored auto-stash for branch: $new_branch"
            fi
        fi
    else
        # git switch failed
        echo "Error: git switch failed with exit code $switch_exit_code"

        # If we had stashed changes and switch failed, we should restore them
        if [ "$had_changes" = true ]; then
            echo "Restoring your previously stashed changes..."
            local failed_stash=$(git stash list | grep "\[auto-stash by git step\] WIP on $current_branch" | head -1)
            if [ -n "$failed_stash" ]; then
                local stash_index=$(echo "$failed_stash" | cut -d: -f1)
                git stash pop "$stash_index" > /dev/null 2>&1
                echo "Restored your changes to working directory"
            fi
        fi
    fi

    # Return the original git switch exit code
    return $switch_exit_code
}

git_step "$@"
