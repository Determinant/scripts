#!/bin/bash

remote="$1"

rcs=(
    .bash_profile
    .bashrc
    .config/fish/
    .config/nvim/
    .tmux.conf
    .gitconfig
    .vim/
    .vimrc
    .dircolors
)

for rc in "${rcs[@]}"; do
    rsync -avPR --no-times "$HOME/$rc" "$remote:/"
done
