#!/bin/bash
cd "$(dirname $0)" || exit 1
DOTFILES_DIR=$(pwd)

if ! (type git >/dev/null 2>&1); then
  echo "git is required." >&2
  exit 1
fi

# zsh with Antidote
if (type zsh >/dev/null 2>&1); then
  zsh setup-zsh.sh
fi

# vim
mkdir -pv "${HOME}/.vim/colors"
ln -snf "${DOTFILES_DIR}/vimrc" "${HOME}/.vimrc"

# git
if (type zsh >/dev/null 2>&1); then
  zsh setup-git.sh
fi

# editorconfig
ln -snf "${DOTFILES_DIR}/editorconfig" "${HOME}/.editorconfig"

# brew
if (type brew >/dev/null 2>&1); then
  case "${OSTYPE}" in
  darwin*)
    ln -snf "${DOTFILES_DIR}/Brewfile-macos" "${HOME}/.Brewfile"
    ;;
  *)
    ln -snf "${DOTFILES_DIR}/Brewfile-linux" "${HOME}/.Brewfile"
    ;;
  esac
fi

# direnv
ln -snf "${DOTFILES_DIR}/direnvrc" "${HOME}/.direnvrc"
