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
