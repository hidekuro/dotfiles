#!/bin/zsh
# EditorConfig Setup Script
# Sets up EditorConfig configuration

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

echo "Setting up EditorConfig..."

ln -snf "${REPO_ROOT}/editorconfig" "${HOME}/.editorconfig"

echo "✓ EditorConfig setup complete!"
