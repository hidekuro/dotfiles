#!/bin/zsh

set -e

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

# ~/.gitconfig に ~/.gitconfig.local の読み込みがあるのは共有設定をコピーしていた構成のマシンで、後から読まれるコピーが共有設定の変更を打ち消すので、共有設定にあるキーを消す
if git config --file "${HOME}/.gitconfig" --get-all include.path >/dev/null; then
  for key in $(git config --file "${REPO_ROOT}/gitconfig" --name-only --list); do
    git config --file "${HOME}/.gitconfig" --unset-all "${key}" || true
  done
  echo "  Removed shared settings copied into ~/.gitconfig"
fi

if [[ ! -f "${HOME}/.gitconfig.local" ]]; then
  cp "${REPO_ROOT}/templates/gitconfig.local" "${HOME}/.gitconfig.local"
  echo "  Created ~/.gitconfig.local"
fi

echo ""
echo "✓ Git setup complete!"
