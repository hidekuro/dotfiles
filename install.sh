#!/bin/bash
cd "$(dirname $0)" || exit 1
DOTFILES_DIR=$(pwd)

if ! (type git >/dev/null 2>&1); then
  echo "git is required." >&2
  exit 1
fi

# bash
ln -snf "${DOTFILES_DIR}/bash/bash_profile" "${HOME}/.bash_profile"
ln -snf "${DOTFILES_DIR}/bash/bashrc" "${HOME}/.bashrc"
ln -snf "${DOTFILES_DIR}/bash/bash_aliases" "${HOME}/.bash_aliases"

# prezto
if (type zsh >/dev/null 2>&1); then
  zsh _prezto.sh
fi

# vim
mkdir -pv "${HOME}/.vim/colors"
ln -snf "${DOTFILES_DIR}/vimrc" "${HOME}/.vimrc"

# git
GIT_USER_NAME=$(git config --global user.name)
GIT_USER_EMAIL=$(git config --global user.email)
GIT_USER_SIGNINGKEY=$(git config --global user.signingKey)
GIT_COMMIT_GPGSIGN=$(git config --global commit.gpgSign)
GIT_TAG_GPGSIGN=$(git config --global tag.gpgSign)
cp -f "${DOTFILES_DIR}/gitconfig" "${HOME}/.gitconfig"
[[ -n ${GIT_USER_NAME} ]] && git config --global user.name "${GIT_USER_NAME}"
[[ -n ${GIT_USER_EMAIL} ]] && git config --global user.email "${GIT_USER_EMAIL}"
[[ -n ${GIT_USER_SIGNINGKEY} ]] && git config --global user.signingKey "${GIT_USER_SIGNINGKEY}"
[[ -n ${GIT_COMMIT_GPGSIGN} ]] && git config --global commit.gpgSign "${GIT_COMMIT_GPGSIGN}"
[[ -n ${GIT_TAG_GPGSIGN} ]] && git config --global tag.gpgSign "${GIT_TAG_GPGSIGN}"
git config --global include.path "${HOME}/.gitconfig.local"
mkdir -p "${HOME}/.config/git"
ln -snf "${DOTFILES_DIR}/gitignore" "${HOME}/.config/git/ignore"
unset GIT_USER_NAME GIT_USER_MAIL GIT_USER_SIGNINGKEY GIT_COMMIT_GPGSIGN

# editorconfig
ln -snf "${DOTFILES_DIR}/editorconfig" "${HOME}/.editorconfig"

# brew
if (type brew >/dev/null 2>&1); then
  case "${OSTYPE}" in
  darwin*)
    ln -snf "${DOTFILES_DIR}/Brewfile-macos" "${HOME}/Brewfile"
    ;;
  *)
    ln -snf "${DOTFILES_DIR}/Brewfile-linux" "${HOME}/Brewfile"
    ;;
  esac
fi

# tmux
mkdir -p "${HOME}/.tmux"
ln -snf "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"

# direnv
ln -snf "${DOTFILES_DIR}/direnvrc" "${HOME}/.direnvrc"
