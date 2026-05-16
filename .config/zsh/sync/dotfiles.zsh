typeset -ga DOTFILES_OPTION_NAMES
typeset -gA DOTFILES_OPTION_DEFAULTS
typeset -gA DOTFILES_OPTION_DESCRIPTIONS

DOTFILES_OPTION_NAMES=(
    autosync
    dirty_warning
)

DOTFILES_OPTION_DEFAULTS=(
    autosync yes
    dirty_warning yes
)

DOTFILES_OPTION_DESCRIPTIONS=(
    autosync "Pull dotfiles and relink configs when a login shell starts."
    dirty_warning "Warn when the dotfiles repository has uncommitted or unpushed changes."
)

function dotfiles_options_state_file() {
    emulate -L zsh
    print -r -- "${DOTFILES_OPTIONS_FILE:-$HOME/.config/dotfiles/options.zsh}"
}

function dotfiles_option_exists() {
    emulate -L zsh
    local name="${1:-}"
    (( ${+DOTFILES_OPTION_DEFAULTS[$name]} ))
}

function dotfiles_option_value() {
    emulate -L zsh
    local name="${1:-}"
    local value

    dotfiles_option_exists "$name" || return 1

    if zstyle -s ':dotfiles:options' "$name" value; then
        print -r -- "$value"
        return 0
    fi

    print -r -- "${DOTFILES_OPTION_DEFAULTS[$name]}"
}

function dotfiles_option_enabled() {
    emulate -L zsh
    local name="${1:-}"
    local value

    value="$(dotfiles_option_value "$name")" || return 1

    case "${value:l}" in
        yes | true | on | 1 | enabled)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

_dotfiles_options_state_file="$(dotfiles_options_state_file)"
if [[ -r "$_dotfiles_options_state_file" ]]; then
    source "$_dotfiles_options_state_file"
fi
unset _dotfiles_options_state_file
