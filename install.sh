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
for rcfile in $DOTFILES_DIR/prezto/runcoms/^README.md(.N); do
  ln -snf "$rcfile" "$ZDOTFILE/.${rcfile:t}"
done

# remove or replace some runcoms to get the desired behavior.
ln -snf $DOTFILES_DIR/prezto-override/zpreztorc $ZDOTFILE/.zpreztorc
ln -snf $DOTFILES_DIR/prezto-override/zprofile $ZDOTFILE/.zprofile
ln -snf $DOTFILES_DIR/prezto-override/zshenv $ZDOTFILE/.zshenv
rm -f $ZDOTFILE/.zlogout
rm -f $ZDOTFILE/.zshrc
cp -f $DOTFILES_DIR/prezto/runcoms/zshrc $ZDOTFILE/.zshrc
cat $DOTFILES_DIR/prezto-override/zshrc >> $ZDOTFILE/.zshrc

# vim
mkdir -pv $HOME/.vim/colors
ln -snf $DOTFILES_DIR/iceberg.vim/colors/iceberg.vim $HOME/.vim/colors/iceberg.vim
ln -snf $DOTFILES_DIR/vimrc $HOME/.vimrc

# git
cp -f $DOTFILES_DIR/gitconfig $HOME/.gitconfig
mkdir -p $HOME/.config/git
cp -f $DOTFILES_DIR/gitignore $HOME/.config/git/ignore

# editorconfig
ln -snf $DOTFILES_DIR/editorconfig $HOME/.editorconfig

# brew
if (type brew > /dev/null 2>&1); then
  ln -snf $DOTFILES_DIR/Brewfile $HOME/Brewfile
fi

# tmux
ln -snf $DOTFILES_DIR/tmux.conf $HOME/.tmux.conf
