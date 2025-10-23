#!/bin/zsh
# Homebrew Setup Script
# Sets up Homebrew Brewfile symlink

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

if ! (type brew >/dev/null 2>&1); then
  echo "⊘ Homebrew not found, skipping setup"
  exit 0
fi

echo "Setting up Homebrew configuration..."

case "${OSTYPE}" in
darwin*)
  ln -snf "${REPO_ROOT}/Brewfile-macos" "${HOME}/.Brewfile"
  echo "  Linked Brewfile-macos"
  ;;
*)
  ln -snf "${REPO_ROOT}/Brewfile-linux" "${HOME}/.Brewfile"
  echo "  Linked Brewfile-linux"
  ;;
esac

echo "✓ Homebrew setup complete!"
