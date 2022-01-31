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
GIT_USER_SIGNINGKEY=$(git config --global user.signingKey)
GIT_COMMIT_GPGSIGN=$(git config --global commit.gpgSign)
GIT_TAG_GPGSIGN=$(git config --global tag.gpgSign)
cp -f $DOTFILES_DIR/gitconfig $HOME/.gitconfig
[ ! -z "$GIT_USER_NAME" ] && git config --global user.name "${GIT_USER_NAME}"
[ ! -z "$GIT_USER_EMAIL" ] && git config --global user.email "${GIT_USER_EMAIL}"
[ ! -z "${GIT_USER_SIGNINGKEY}" ] && git config --global user.signingKey "${GIT_USER_SIGNINGKEY}"
[ ! -z "${GIT_COMMIT_GPGSIGN}" ] && git config --global commit.gpgSign "${GIT_COMMIT_GPGSIGN}"
[ ! -z "${GIT_TAG_GPGSIGN}" ] && git config --global tag.gpgSign "${GIT_TAG_GPGSIGN}"
mkdir -p $HOME/.config/git
ln -snf $DOTFILES_DIR/gitignore $HOME/.config/git/ignore
unset GIT_USER_NAME GIT_USER_MAIL GIT_USER_SIGNINGKEY GIT_COMMIT_GPGSIGN

# editorconfig
ln -snf $DOTFILES_DIR/editorconfig $HOME/.editorconfig

# brew
if (type brew > /dev/null 2>&1); then
  if [[ "$OS_TYPE" == "darwin*" ]]; then
    ln -snf $DOTFILES_DIR/Brewfile $HOME/.Brewfile
  elif [[ ! -z "$WSL_DISTRO_NAME" ]]; then
    ln -snf $DOTFILES_DIR/Brewfile-wsl2 $HOME/.Brewfile
  fi
fi

# tmux
mkdir -p $HOME/.tmux
ln -snf $DOTFILES_DIR/tmux/tmux.conf $HOME/.tmux.conf
ln -snf $DOTFILES_DIR/tmux/theme-iceberg-dark $HOME/.tmux/theme-iceberg-dark

# direnv
ln -snf $DOTFILES_DIR/direnvrc $HOME/.direnvrc
