#!/bin/zsh
# Git Setup Script
# Links the shared git configuration and leaves ~/.gitconfig to machine-specific settings

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

echo "Setting up git configuration..."

# git は ~/.config/git/config の後に ~/.gitconfig を読むので、git config --global で書いたマシン固有の値が共有設定より優先される
mkdir -p "${HOME}/.config/git"
ln -snf "${REPO_ROOT}/gitconfig" "${HOME}/.config/git/config"
ln -snf "${REPO_ROOT}/gitignore" "${HOME}/.config/git/ignore"
echo "  Linked ~/.config/git/config and ~/.config/git/ignore"

# ~/.gitconfig が無いと git config --global がリンク先のリポジトリの gitconfig に書き込むので、空でも作っておく
touch "${HOME}/.gitconfig"

if [[ ! -f "${HOME}/.gitconfig.local" ]]; then
  cp "${REPO_ROOT}/templates/gitconfig.local" "${HOME}/.gitconfig.local"
  echo "  Created ~/.gitconfig.local"
fi

echo ""
echo "✓ Git setup complete!"
