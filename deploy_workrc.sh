#!/bin/bash

remote="$1"

rcs=(
    .bash_profile
    .bashrc
    .config/fish/
    .config/nvim/
    scripts/name2color.py
    .tmux.conf
    .tmux/
    .gitconfig
    .vim/
    .vimrc
    .dircolors
)
ssh "$remote" "mkdir -p ~/scripts"
for rc in "${rcs[@]}"; do
    rsync -avPR --no-times "$HOME/$rc" "$remote:/"
done

echo "Done."
