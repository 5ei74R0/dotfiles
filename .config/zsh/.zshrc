dotfiles_dir=~/dotfiles

function is_dirty() {
  test -n "$(git -C ${dotfiles_dir} status --porcelain)" ||
    ! git -C ${dotfiles_dir} diff --exit-code --stat --cached origin/main > /dev/null
}

function auto_sync() {
  echo -e "\e[1;36m[[dotfiles]]\e[m"
  echo -en "\e[1;36mTry auto sync...\e[m"
  if (cd $dotfiles_dir && git pull && cd $HOME) > /dev/null 2>&1; then
    if is_dirty $? ; then
      echo -e "\e[1;31m [failed]\e[m"
      echo -e "\e[1;33m[warn] DIRTY DOTFILES\e[m"
      echo -e "\e[1;33m    -> Push your local changes in $dotfiles_dir\e[m"
    else
      echo -e "\e[1;32m [ok]\e[m"
    fi
  else
    echo -e "\e[1;31m [failed]\e[m"
    echo -e "\e[1;33m[warn] Coud not pull remote changes.\e[m"
  fi
}

auto_sync
eval "$(sheldon source)"
