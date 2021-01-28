#!/bin/zsh
ZDOTDIR="${ZDOTDIR:-$HOME}"
cd $ZDOTDIR

DOTFILES_DIR=$(pwd)/.dotfiles
DOTFILES_DIR_REL=$(realpath --relative-to=$ZDOTDIR $DOTFILES_DIR)

setopt extended_glob
setopt clobber
unalias -m '*'

git --git-dir=$DOTFILES_DIR/.git submodule update --init --recursive

# install prezto.
ln -snfv $DOTFILES_DIR_REL/prezto $ZDOTDIR/.zprezto
for rcfile in $DOTFILES_DIR_REL/prezto/runcoms/^README.md(.N); do
  ln -snfv "$rcfile" "$ZDOTDIR/.${rcfile:t}"
done

# remove or replace some runcoms to get the desired behavior.
ln -snfv $DOTFILES_DIR_REL/prezto-override/zpreztorc $ZDOTDIR/.zpreztorc
ln -snfv $DOTFILES_DIR_REL/prezto-override/zprofile $ZDOTDIR/.zprofile
ln -snfv $DOTFILES_DIR_REL/prezto-override/zshenv $ZDOTDIR/.zshenv
rm -fv $ZDOTDIR/.zlogout
rm -fv $ZDOTDIR/.zshrc
cp -fv $DOTFILES_DIR_REL/prezto/runcoms/zshrc $ZDOTDIR/.zshrc
cat $DOTFILES_DIR_REL/prezto-override/zshrc >> $ZDOTDIR/.zshrc

# vim
mkdir -pv $HOME/.vim/colors
ln -snfv $DOTFILES_DIR_REL/iceberg.vim/colors/iceberg.vim $HOME/.vim/colors/iceberg.vim
ln -snfv $DOTFILES_DIR_REL/vimrc $HOME/.vimrc

# git
cp -fv $DOTFILES_DIR_REL/gitconfig $HOME/.gitconfig
mkdir -pv $HOME/.config/git
cp -fv $DOTFILES_DIR_REL/gitignore $HOME/.config/git/ignore

# editorconfig
ln -snfv $DOTFILES_DIR_REL/editorconfig $HOME/.editorconfig

# brew
if (type brew > /dev/null 2>&1); then
  ln -snfv $DOTFILES_DIR_REL/Brewfile $HOME/Brewfile
fi

# tmux
mkdir -p $HOME/.tmux
ln -snfv $DOTFILES_DIR_REL/tmux/tmux.conf $HOME/.tmux.conf
ln -snfv $DOTFILES_DIR_REL/tmux/theme-iceberg-dark $HOME/.tmux/theme-iceberg-dark
