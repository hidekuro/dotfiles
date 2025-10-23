#!/bin/zsh
# direnv Setup Script
# Sets up direnv configuration

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

echo "Setting up direnv configuration..."

ln -snf "${REPO_ROOT}/direnvrc" "${HOME}/.direnvrc"

echo "✓ direnv setup complete!"
