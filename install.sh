# bail out on errors
set -ue

function helpmsg() {
  command echo "Usage: $0 [--help | -h | -H]" 0>&2
  command echo ""
}

function update_pkg_manager() {
    if command -v apt >/dev/null 2>&1; then
        apt update
    elif command -v brew >/dev/null 2>&1; then
        brew update
    else
        echo "No supported package manager found. Please install apt or brew."
        exit 1
    fi
}

function install_zsh() {
    if [ ! -f /bin/zsh ]; then
        apt install -y zsh
        chsh -s $(which zsh)
        echo "Zsh was set as default shell. \nPlease restart your terminal & run this script again."
        exit 0
    fi
}

function install_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
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
    cargo install sheldon --locked

}

function generate_symbolic_links() {

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
    generate_symbolic_links
    echo "Castling completed."
}

main "$@"
