#!/bin/zsh
cd "$(dirname "$0")" || exit 1
DOTFILES_DIR=$(pwd)
ZDOTFILE="${ZDOTFILE:-${HOME}}"

setopt extended_glob
setopt clobber
unalias -m '*'

git submodule update --init --recursive
ln -snf "${DOTFILES_DIR}/prezto" "${ZDOTFILE}/.zprezto"

for rcfile in "${DOTFILES_DIR}"/prezto-override/runcoms/^README.md(.N); do
  ln -snf "${rcfile}" "${ZDOTFILE}/.${rcfile:t}"
done
