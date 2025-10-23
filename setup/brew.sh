#!/bin/zsh
# Homebrew Setup Script
# Sets up Homebrew Brewfile symlink

set -e

cd "$(dirname "$0")/.." || exit 1
DOTFILES_DIR=$(pwd)

if ! (type brew >/dev/null 2>&1); then
  echo "⊘ Homebrew not found, skipping setup"
  exit 0
fi

echo "Setting up Homebrew configuration..."

case "${OSTYPE}" in
darwin*)
  ln -snf "${DOTFILES_DIR}/Brewfile-macos" "${HOME}/.Brewfile"
  echo "  Linked Brewfile-macos"
  ;;
*)
  ln -snf "${DOTFILES_DIR}/Brewfile-linux" "${HOME}/.Brewfile"
  echo "  Linked Brewfile-linux"
  ;;
esac

echo "✓ Homebrew setup complete!"
