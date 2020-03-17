#!/bin/zsh
cd $(dirname $0)
DOTFILES_DIR=$(pwd)
HOME="${ZDOTFILE:-$HOME}"

git submodule update --init --recursive

# install prezto.
ln -snf $DOTFILES_DIR/prezto $HOME/.zprezto
setopt extended_glob
for rcfile in $DOTFILES_DIR/prezto/runcoms/^README.md(.N); do
  ln -snf "$rcfile" "$HOME/.${rcfile:t}"
done

# remove or replace some runcoms to get the desired behavior.
ln -snf $DOTFILES_DIR/prezto-override/zpreztorc $HOME/.zpreztorc
ln -snf $DOTFILES_DIR/prezto-override/zprofile $HOME/.zprofile
ln -snf $DOTFILES_DIR/prezto-override/zshenv $HOME/.zshenv
rm -f $HOME/.zlogout
rm -f $HOME/.zshrc
cp -f $DOTFILES_DIR/prezto/runcoms/zshrc $HOME/.zshrc
cat $DOTFILES_DIR/prezto-override/zshrc >> $HOME/.zshrc

# vim
mkdir -pv $HOME/.vim/colors
ln -snf $DOTFILES_DIR/iceberg.vim/colors/iceberg.vim $HOME/.vim/colors/iceberg.vim
ln -snf $DOTFILES_DIR/vimrc $HOME/.vimrc

# git
cp -f $DOTFILES_DIR/gitconfig $HOME/.gitconfig
cp -f $DOTFILES_DIR/gitignore_global $HOME/.gitignore_global

# editorconfig
ln -snf $DOTFILES_DIR/editorconfig $HOME/.editorconfig

# brew
if (type brew > /dev/null 2>&1); then
  ln -snf $DOTFILES_DIR/Brewfile $HOME/Brewfile
fi
