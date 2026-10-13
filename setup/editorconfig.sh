#!/bin/zsh

set -e

cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

echo "Setting up EditorConfig..."

ln -snf "${REPO_ROOT}/editorconfig" "${HOME}/.editorconfig"

echo "✓ EditorConfig setup complete!"
