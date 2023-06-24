#!/usr/bin/env zsh

set -ue

function helpmsg() {
    echo "Usage: $0 [--help | -h | -H]" 0>&2
    echo ""
}

function check_pkg_manager() {
    if command -v apt >/dev/null 2>&1; then
        apt --version
        echo -e "\e[36mVerified package manager: apt\e[m\n"
    elif command -v brew >/dev/null 2>&1; then
        brew --version
        echo -e "\e[36mVerified package manager: homebrew\e[m\n"
    else
        echo -e "\e[31m No supported package manager found. Please install apt or brew. \e[0m"
        exit 1
    fi
}

function install_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        rustup self update
        rustup update
        echo -e "\e[36mInstalled rustup, rustc, cargo\e[m\n"
    fi
}

function install_wget() {
    if ! command -v wget >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            apt install -y wget
        elif command -v brew >/dev/null 2>&1; then
            brew install wget
        fi
        echo -e "\e[36mInstalled wget\e[m\n"
    fi
}

function install_zip() {
    if ! command -v zip >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            apt install -y zip
        elif command -v brew >/dev/null 2>&1; then
            brew install zip
        fi
        echo -e "\e[36mInstalled zip\e[m\n"
    fi
}

function install_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            apt install -y jq
        elif command -v brew >/dev/null 2>&1; then
            brew install jq
        fi
        echo -e "\e[36mInstalled jquery\e[m\n"
    fi
}

function install_fonts() {
    if [[ -z $HOME/.fonts/UDEVGothic35NFLG-Regular.ttf ]]; then
        local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"
        mkdir -p $HOME/.fonts
        mkdir -p $dotfiles_dir/.tmp_fonts
        cd $dotfiles_dir/.tmp_fonts
        wget "https://github.com/yuru7/udev-gothic/releases/download/v1.3.0/UDEVGothic_NF_v1.3.0.zip"
        unzip UDEVGothic_NF_v1.3.0
        mv UDEVGothic_NF_v1.3.0/*.ttf $HOME/.fonts/
        cd $dotfiles_dir
        rm -rf $dotfiles_dir/.tmp_fonts
        fc-cache -fv
        echo -e "\e[36mInstalled a font-family, UDEVGothic\e[m\n"
    fi
}

function install_starship() {
    if ! command -v starship >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://starship.rs/install.sh | sh -s -- -y
        # curl -sS https://starship.rs/install.sh | sh
        echo -e "\e[36mInstalled starship\e[m\n"
    fi
}

function install_sheldon() {
    if ! command -v sheldon >/dev/null 2>&1; then
        cargo install --locked sheldon
        echo -e "\e[36mInstalled sheldon\e[m\n"
    fi
}

function setup() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"

    # Update package manager
    check_pkg_manager

    # Install rustup, cargo, and rustc
    install_rust

    # Install wget
    install_wget

    # Install zip
    install_zip

    # Install jq
    install_jq

    # Install fonts
    install_fonts

    # Install starship
    install_starship

    # Install sheldon
    install_sheldon
}

function generate_links2home() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"
    backup_dir="$dotfiles_dir/.dotbackup.$(date +%Y%m%d%H%M%S)"
    echo "backup old dotfiles into $backup_dir"
    if [ ! -d "$backup_dir" ]; then
        mkdir "$backup_dir"
    fi

    dotfile_mapping="$dotfiles_dir/link_mapper.json"
    if [ ! -f "$dotfile_mapping" ]; then
        echo -e "\e[31m $dotfile_mapping not found. \e[0m"
        exit 1
    fi
    if [[ "$HOME" == "$dotfiles_dir" ]]; then
        echo -e "\e[31m dotfiles_dir is equal to HOME \e[0m"
        exit 1
    fi

    # Generate links & backup old dotfiles

    jq -c '.src2dst[]' < $dotfile_mapping |
    while read src2dst; do
        link_src=$(echo "${src2dst}" | jq -r '.src')
        link_dst=$(echo "${src2dst}" | jq -r '.dst')
        echo -e "\e[36m try to generate symbolic link: \n  $link_src -> $link_dst \e[m\n"

        if [[ -z "$link_src" || -z "$link_dst" ]]; then
            continue
        fi

        # Remove old links
        if [[ -L "$HOME/$link_dst" ]]; then
            rm -f "$HOME/$link_dst"
        fi

        # Backup old dotfiles
        if [[ -e "$HOME/$link_dst" ]]; then
            mkdir -p "$(dirname "$backup_dir/$link_dst")"
            mv "$HOME/$link_dst" "$backup_dir/$link_dst"
        fi
        ln -snf "$dotfiles_dir/$link_src" "$HOME/$link_dst"
    done
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
    echo -e "\n\e[1;36mCastling completed😎\e[m\n"
}

main "$@"
