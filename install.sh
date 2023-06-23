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
            command apt install -y zsh
        elif command -v brew >/dev/null 2>&1; then
            command brew install zsh
        fi
        command chsh -s $(which zsh)
        command echo -e "\e[32m Zsh was set as default shell. \e[0m"
        command echo -e "\e[1;33m Please restart your terminal & run this script again. \e[0m"
        command exit 0
    fi
}

function install_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        command curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
}

function install_wget() {
    if ! command -v wget >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            command apt install -y wget
        elif command -v brew >/dev/null 2>&1; then
            command brew install wget
        fi
    fi
}

function install_zip() {
    if ! command -v zip >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            command apt install -y zip
        elif command -v brew >/dev/null 2>&1; then
            command brew install zip
        fi
    fi
}

function install_fonts() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"
    command mkdir -p "$HOME/.fonts"
    command mkdir -p "$dotfiles_dir/.tmp_fonts"
    command cd "$dotfiles_dir/.tmp_fonts"
    command wget "https://github.com/yuru7/udev-gothic/releases/download/v1.3.0/UDEVGothic_NF_v1.3.0.zip"
    command unzip UDEVGothic_NF_v1.3.0
    command mv UDEVGothic_NF_v1.3.0/*.ttf ./$HOME/.fonts
    command cd "$dotfiles_dir"
    command rm -rf "$dotfiles_dir/.tmp_fonts"
    command fc-cache -fv
}

function setup() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"

    # Update package manager
    update_pkg_manager

    # If zsh is not installed, install it
    install_zsh

    # Install rustup, cargo, and rustc
    install_rust

    # Install wget
    install_wget

    # Install zip
    install_zip

    # Install fonts
    install_fonts

    # Install starship
    curl -sS https://starship.rs/install.sh | sh

    # Install sheldon
    command cargo install --locked sheldon
}

function generate_links2home() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"
    backup_dir="$dotfiles_dir/.dotbackup.$(date +%Y%m%d%H%M%S)"
    command echo "backup old dotfiles into $backup_dir"
    if [ ! -d "$backup_dir" ]; then
        command mkdir "$backup_dir"
    fi

    dotfile_mapping="$dotfiles_dir/dotfile_mapping.txt"
    if [ ! -f "$dotfile_mapping" ]; then
        command echo -e "\e[31m $dotfile_mapping not found. \e[0m"
        command exit 1
    fi
    if [[ "$HOME" == "$dotfiles_dir" ]]; then
        command echo -e "\e[31m dotfiles_dir is equal to HOME \e[0m"
        command exit 1
    fi

    # Generate links & backup old dotfiles
    while read -r line; do
        if [[ "$line" =~ ^\s*# ]]; then
            continue
        fi
        link_src=(${(s: :)line}})[1]
        link_dst=(${(s: :)line}})[2]
        if [[ -z "$link_src" || -z "$link_dst" ]]; then
            continue
        fi

        if [[ -L "$HOME/$link_dst" ]]; then
            command rm -f "$HOME/$link_dst"
        fi
        if [[ -e "$HOME/$link_dst" ]]; then
            mkdir -p "$(dirname "$backup_dir/$link_dst")"
            command mv "$HOME/$link_dst" "$backup_dir/$link_dst"
        fi
        command ln -snf "$dotfiles_dir/$link_src" "$HOME/$link_dst"
    done < $dotfile_mapping
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
