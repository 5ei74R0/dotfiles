#!/usr/bin/env zsh

set -ue

function helpmsg() {
    # echo "Usage: $0 [--help | -h | -H]" 0>&2
    echo "See README.md ↓"
    echo -e "\e[36mhttps://github.com/5ei74R0/dotfiles\e[m"
    echo ""
}

function check_pkg_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo -e "\e[36mVerified package manager: $(brew --version)\e[m\n"
    elif command -v apt >/dev/null 2>&1; then
        echo -e "\e[36mVerified package manager: $(apt --version)\e[m\n"
    else
        echo -e "\e[31m No supported package manager found. Please install apt or brew. \e[0m"
        exit 1
    fi
}

function install_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install curl
        elif command -v apt >/dev/null 2>&1; then
            apt install -y curl
        fi
        echo -e "\e[36mInstalled curl\e[m\n"
    fi
}

function install_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        rustup self update
        rustup update
        echo -e "\e[36mInstalled rustup, rustc, cargo\e[m\n"
    fi
}

function install_zip() {
    if ! command -v zip >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install zip
        elif command -v apt >/dev/null 2>&1; then
            apt install -y zip
        fi
        echo -e "\e[36mInstalled zip\e[m\n"
    fi
}

function install_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install jq
        elif command -v apt >/dev/null 2>&1; then
            apt install -y jq
        fi
        echo -e "\e[36mInstalled jquery\e[m\n"
    fi
}

function install_fonts() {
    if ! command -v fc-cache >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install fontconfig
        elif command -v apt >/dev/null 2>&1; then
            apt install -y fontconfig
        fi
        echo -e "\e[36mInstalled fontconfig\e[m\n"
    fi
    if [[ ! -e "$HOME/.fonts/UDEVGothic35NFLG-Regular.ttf" ]]; then
        local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"
        mkdir -p $HOME/.fonts
        mkdir -p $dotfiles_dir/.tmp_fonts
        cd $dotfiles_dir/.tmp_fonts
        curl -LO "https://github.com/yuru7/udev-gothic/releases/download/v1.3.0/UDEVGothic_NF_v1.3.0.zip"
        unzip UDEVGothic_NF_v1.3.0.zip
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
        echo -e "\e[36mInstalled starship\e[m\n"
    fi
}

function install_sheldon() {
    if ! command -v sheldon >/dev/null 2>&1; then
        cargo install sheldon
        echo -e "\e[36mInstalled sheldon\e[m\n"
    fi
}

function install_extra_rust_tools() {
    if ! command -v cargo install-update >/dev/null 2>&1; then
        cargo install cargo-update
        echo -e "\e[36mInstalled cargo-update\e[m\n"
    fi

    if ! command -v bat >/dev/null 2>&1; then
        cargo install bat
        echo -e "\e[36mInstalled bat\e[m\n"
    fi
    if ! command -v eza >/dev/null 2>&1; then
        cargo install eza
        echo -e "\e[36mInstalled eza\e[m\n"
    fi
    if ! command -v fd >/dev/null 2>&1; then
        cargo install fd-find
        echo -e "\e[36mInstalled fd\e[m\n"
    fi
    if ! command -v rg >/dev/null 2>&1; then
        cargo install ripgrep
        echo -e "\e[36mInstalled rg\e[m\n"
    fi
    if ! command -v dust >/dev/null 2>&1; then
        cargo install du-dust
        echo -e "\e[36mInstalled dust\e[m\n"
    fi
}

function install_mise_en_place() {
    if ! command -v mise >/dev/null 2>&1; then
        cargo install mise
        echo -e "\e[36mInstalled mise\e[m\n"
    fi
}

function install_runtimes_via_mise() {
    # Node.js
    if [ ! "$(mise bin-paths | rg node)" ]; then
        mise use --global node@18.16.1  # lts
        echo -e "\e[36mInstalled node via mise\e[m\n"
    fi

    # Python
    if [ ! "$(mise bin-paths | rg python)" ]; then
        mise use --global python@3.8.10
        echo -e "\e[36mInstalled python via mise\e[m\n"
    fi
}

function install_gitmoji() {
    if ! command -v gitmoji >/dev/null 2>&1; then
        if command -v npm >/dev/null 2>&1; then
            npm i -g gitmoji-cli
            echo -e "\e[36mInstalled gitmoji-cli\e[m\n"
        else
            echo -e "\e[33m[warn] npm is not available...\e[m"
            echo -e "\e[33m       Install gitmoji-cli manually, please.\e[m\n"
        fi
    fi
}

function setup() {
    local dotfiles_dir="$(cd "$(dirname "$0")" && pwd -P)"

    # Update package manager
    check_pkg_manager

    # Install  curl
    install_curl

    # Install rustup, cargo, and rustc
    install_rust

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
    backup_dir="$dotfiles_dir/.dotbackup/backup_$(date +%Y%m%d%H%M%S)"
    echo "backup old dotfiles into $backup_dir"
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
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
        echo -e "\e[36mTry to generate symbolic link:\e[m\n\e[36m  $dotfiles_dir/$link_src -> $HOME/$link_dst \e[m\n"

        if [[ -z "$link_src" || -z "$link_dst" ]]; then
            continue
        fi

        # Check directory
        if [[ ! -d "$HOME/$(dirname "$link_dst")" ]]; then
            mkdir -p "$HOME/$(dirname "$link_dst")"
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

    # If there is no change (if backup directory is empty), remove backup directory
    rm -d "$backup_dir" 2>/dev/null
}

function extra_setup() {
    # Install bat eza fd rg...
    install_extra_rust_tools

    # Install mise
    install_mise_en_place

    # Install node python...
    install_runtimes_via_mise

    # Install gitmoji
    install_gitmoji
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
            --link | -l)
                echo -e "\n\e[36mSetup [skipped]\e[m\n"
                generate_links2home
                echo -e "\n\e[36mLinks [ok]\e[m\n"
                echo -e "\e[1;36mCastling completed😎\e[m\n"
                exit 0
                ;;
            --extra | -e)
                setup
                echo -e "\n\e[36mSetup [ok]\e[m\n"
                generate_links2home
                echo -e "\n\e[36mLinks [ok]\e[m\n"
                extra_setup
                echo -e "\n\e[36mExtra [ok]\e[m\n"
                echo -e "\e[1;36mCastling completed😎\e[m\n"
                exit 0
                ;;
		esac
		shift
	done

    setup
    echo -e "\n\e[36mSetup [ok]\e[m\n"
    generate_links2home
    echo -e "\n\e[36mLinks [ok]\e[m\n"
    echo -e "\e[1;36mCastling completed😎\e[m\n"
    exit 0
}

main "$@"
