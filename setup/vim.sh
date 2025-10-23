#!/bin/zsh
# Vim Setup Script
# Sets up vim configuration

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

echo "Setting up vim configuration..."

mkdir -p "${HOME}/.vim/colors"
ln -snf "${REPO_ROOT}/vimrc" "${HOME}/.vimrc"

echo "✓ Vim setup complete!"
