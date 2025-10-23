#!/bin/zsh
# EditorConfig Setup Script
# Sets up EditorConfig configuration

set -e

cd "$(dirname "$0")/.." || exit 1
DOTFILES_DIR=$(pwd)

echo "Setting up EditorConfig..."

ln -snf "${DOTFILES_DIR}/editorconfig" "${HOME}/.editorconfig"

echo "✓ EditorConfig setup complete!"
