# bail out on errors
set -ue

function helpmsg() {
  command echo "Usage: $0 [--help | -h | -H]" 0>&2
  command echo ""
}

function update_pkg_manager() {
    if command -v apt >/dev/null 2>&1; then
        command apt update
    elif command -v brew >/dev/null 2>&1; then
        command brew update
    else
        command echo -e "\e[31m No supported package manager found. Please install apt or brew. \e[0m"
        command exit 1
    fi
}

function install_zsh() {
    if [ ! -f /bin/zsh ]; then
        if command -v apt >/dev/null 2>&1; then
            apt install -y zsh
        elif command -v brew >/dev/null 2>&1; then
            brew install zsh
        fi
        command chsh -s $(which zsh)
        command echo -e "\e[32m Zsh was set as default shell. \e[0m"
        command echo -e "\e[1;33m Please restart your terminal & run this script again. \e[0m"
        command exit 0
    fi
}

function install_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        command curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    fi
}

function setup() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"

    # Update package manager
    update_pkg_manager

    # If zsh is not installed, install it
    install_zsh

    # Install rustup, cargo, and rustc
    install_rust

    # Install sheldon
    command cargo install sheldon --locked

}

function generate_links2home() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"
    command echo "backup old dotfiles into $dotfiles_dir/.dotbackup"
    if [ ! -d "$dotfiles_dir/.dotbackup" ]; then
        command mkdir "$dotfiles_dir/.dotbackup"
    fi
    backup_dir="$dotfiles_dir/.dotbackup"

    if [[ "$HOME" != "$dotfiles_dir" ]]; then
        for f in $dotfiles_dir/.config/.??*; do
            [[ `basename $f` == "__ignore__" ]] && continue
            if [[ -L "$HOME/`basename $f`" ]]; then
                command rm -f "$HOME/`basename $f`"
            fi
            if [[ -e "$HOME/`basename $f`" ]]; then
                command mv "$HOME/`basename $f`" "$backup_dir"
            fi
            command ln -snf $f $HOME
        done
    else
        command echo -e "\e[31m src == dest \e[0m"
        command exit 1
    fi
}

function main() {
	while [ $# -gt 0 ]; do
		case ${1} in
			--debug | -d)
				set -uex
				;;
			--help | -h)
				helpmsg
				exit 1
				;;
		esac
		shift
	done

    setup
    generate_links2home
    echo -e "\e[1;36m Castling completed. \e[m"
}

main "$@"
