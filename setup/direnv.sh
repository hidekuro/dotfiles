#!/bin/zsh

set -e

cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

echo "Setting up direnv configuration..."

ln -snf "${REPO_ROOT}/direnvrc" "${HOME}/.direnvrc"

echo "✓ direnv setup complete!"
