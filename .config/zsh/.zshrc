function dotfiles_dir() {
    local command_path

    if [[ -n "$DOTFILES_DIR" ]]; then
        print -r -- "$DOTFILES_DIR"
        return 0
    fi

    command_path="${commands[dotfiles]:-}"
    if [[ -n "$command_path" ]]; then
        command_path="${command_path:A}"
        if [[ -r "${command_path:h:h}/.config/zsh/sync/dotfiles.zsh" ]]; then
            print -r -- "${command_path:h:h}"
            return 0
        fi
    fi

    print -r -- "$HOME/dotfiles"
}

_dotfiles_options_file="$(dotfiles_dir)/.config/zsh/sync/dotfiles.zsh"
if [[ -r "$_dotfiles_options_file" ]]; then
    source "$_dotfiles_options_file"
else
    function dotfiles_option_enabled() {
        return 0
    }
fi
unset _dotfiles_options_file

function is_dirty() {
    local dotfiles_dir="$(dotfiles_dir)"
    test -n "$(git -C "$dotfiles_dir" status --porcelain)" ||
        ! git -C "$dotfiles_dir" diff --exit-code --stat --cached origin/main > /dev/null
}

function warn_dirty() {
    local dotfiles_dir="$(dotfiles_dir)"
    if is_dirty ; then
        echo -e "\e[1;36m[[dotfiles]]\e[m"
        echo -e "\e[1;33m[warn] DIRTY DOTFILES\e[m"
        echo -e "\e[1;33m    -> Push your local changes in $dotfiles_dir\e[m"
    fi
}

if [[ ! -o login ]] && dotfiles_option_enabled dirty_warning; then
    # Avoid duplicate warning (See .config/zsh/.zprofile)
    warn_dirty
fi

eval "$(sheldon source)"
