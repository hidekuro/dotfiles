#!/bin/zsh
# direnv Setup Script
# Sets up direnv configuration

set -e

cd "$(dirname "$0")/.." || exit 1
DOTFILES_DIR=$(pwd)

echo "Setting up direnv configuration..."

ln -snf "${DOTFILES_DIR}/direnvrc" "${HOME}/.direnvrc"

echo "✓ direnv setup complete!"
