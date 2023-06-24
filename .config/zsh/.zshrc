dotfiles_dir="$(pwd)/dotfiles"

if test -n "$(git -C ${dotfiles_dir} status --porcelain)" ||
   ! git -C ${dotfiles_dir} diff --exit-code --stat --cached origin/main > /dev/null ; then
  echo -e "\e[1;31m[warn] DIRTY DOTFILES\e[m"
  echo ""
  echo -e "\e[31m -> Update configs in $dotfiles_dir\e[m"
  echo ""
fi

eval "$(sheldon source)"