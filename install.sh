#!/bin/zsh
cd $(dirname $0)
DOTFILES_DIR=$(pwd)
ZDOTFILE="${ZDOTFILE:-$HOME}"

setopt extended_glob
setopt clobber
unalias -m '*'

git submodule update --init --recursive

# install prezto.
ln -snf $DOTFILES_DIR/prezto $ZDOTFILE/.zprezto
for rcfile in $DOTFILES_DIR/prezto-override/runcoms/^README.md(.N); do
  ln -snf "$rcfile" "$ZDOTFILE/.${rcfile:t}"
done

# vim
mkdir -pv $HOME/.vim/colors
ln -snf $DOTFILES_DIR/iceberg.vim/colors/iceberg.vim $HOME/.vim/colors/iceberg.vim
ln -snf $DOTFILES_DIR/vimrc $HOME/.vimrc

# git
GIT_USER_NAME=$(git config --global user.name)
GIT_USER_EMAIL=$(git config --global user.email)
cp -f $DOTFILES_DIR/gitconfig $HOME/.gitconfig
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
mkdir -p $HOME/.config/git
ln -snf $DOTFILES_DIR/gitignore $HOME/.config/git/ignore
unset GIT_USER_NAME GIT_USER_MAIL

# editorconfig
ln -snf $DOTFILES_DIR/editorconfig $HOME/.editorconfig

# brew
if (type brew > /dev/null 2>&1); then
  ln -snf $DOTFILES_DIR/Brewfile $HOME/Brewfile
fi

# tmux
mkdir -p $HOME/.tmux
ln -snf $DOTFILES_DIR/tmux/tmux.conf $HOME/.tmux.conf
ln -snf $DOTFILES_DIR/tmux/theme-iceberg-dark $HOME/.tmux/theme-iceberg-dark
