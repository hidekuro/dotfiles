#!/bin/zsh
# Vim Setup Script
# Sets up vim configuration

set -e

cd "$(dirname "$0")/.." || exit 1
DOTFILES_DIR=$(pwd)

echo "Setting up vim configuration..."

mkdir -p "${HOME}/.vim/colors"
ln -snf "${DOTFILES_DIR}/vimrc" "${HOME}/.vimrc"

echo "✓ Vim setup complete!"
