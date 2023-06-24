# dotfiles
Quick castling w/ `install.sh`

## Requirements
#### default shell: zsh
If your default shell is not zsh, please install zsh first.
1. Install via apt,
    ```sh
    apt install --no-install-recommends -y zsh
    ```
    or via brew
    ```sh
    brew install zsh
    ```
2. Change default shell
    ```sh
    chsh -s $(which zsh)
    ```
3. Logout and login again

## Continuous Integration
We run github actions on Ubuntu20.04 & latest macOS (on github actions) to test whether or not `install.sh` works well.
See [Actions](https://github.com/5ei74R0/dotfiles/actions) for more details.

## Installation
Run `Install.sh`. This installer has following options:
- `--link | -l`: Just create symbolic links. Do not install any packages.
- `--extra | -e`: Install extra packages. (e.g. `ripgrep`, `fd`, `bat`, `exa`, `dust`, `rtx-cli`, `npm`, `python`, `gitmoji-cli`...)


## Usage
#### Add new config
1. Add new config file to [`./config/`](./.config)
2. Record src to dst mapping in [`link_mapper.json`](./link_mapper.json)
3. Run [`install.sh`](./install.sh)
    ```sh
    ./install.sh --link
    ```
    (When `--link` option is specified, `install.sh` only creates symbolic links)
