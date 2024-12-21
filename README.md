# Simple, Rust-Centric `dotfiles`
Quick castling w/ `install.sh`

<p align="center">
  <img src="https://res.cloudinary.com/zenn/image/fetch/s--QXp-o4ub--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_1200/https://storage.googleapis.com/zenn-user-upload/deployed-images/ce6f97bbd960d167bb536ddd.png%3Fsha%3D691458ee2c7b66c62ab1a135b0de945d46543aaf" alt="top" width="70%">
</p>


### Features
- Shell plugin management w/ [sheldon](https://sheldon.cli.rs/)
- Runtime management w/ [mise (rtx-cli)](https://mise.jdx.dev/)
- Dress up w/ [Starship](https://starship.rs/) + [UDEV Gothic](https://github.com/yuru7/udev-gothic)
- Autosync
- one-step installer, [`install.sh`](https://github.com/5ei74R0/dotfiles/blob/main/install.sh#L248-L285)
- Test w/ [Github Actions](https://github.com/5ei74R0/dotfiles/actions)

## Installation
Run `install.sh`.

This installer has following options:
- `--link | -l`: Just create symbolic links. Do not install any packages.
- `--extra | -e`: Install extra packages. (e.g. `ripgrep`, `fd`, `bat`, `eza`, `dust`, `mise` (`rtx-cli`), `npm`, `python`, `gitmoji-cli`...)

## Usage
#### Add new config
1. Add new config file to [`./config/`](./.config)
2. Record src (under this directory) to dst (under $HOME directory) mapping in [`link_mapper.json`](./link_mapper.json)
3. Run [`install.sh`](./install.sh)
    ```sh
    ./install.sh --link
    ```
    (When `--link` option is specified, `install.sh` only creates symbolic links)

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

