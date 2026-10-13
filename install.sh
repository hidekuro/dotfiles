#!/bin/bash
cd "$(dirname "$0")" || exit 1

if ! (type git >/dev/null 2>&1); then
  echo "git is required." >&2
  exit 1
fi

if ! (type zsh >/dev/null 2>&1); then
  echo "zsh is required." >&2
  exit 1
fi

echo "Starting dotfiles setup..."
echo ""

# zsh と git の設定は、ほかの設定より先に行う
echo "==> Phase 1: Setting up core tools"
zsh setup/zsh.sh
echo ""
zsh setup/git.sh
echo ""

# 残りの設定は互いに依存しないので、順序を気にせず setup/ に追加してよい
echo "==> Phase 2: Setting up other tools"
for script in setup/*.sh; do
  case "${script##*/}" in
    zsh.sh|git.sh) continue ;;  # 先に実行済み
    *) zsh "${script}"; echo "" ;;
  esac
done

echo "==> All setup tasks complete!"
echo ""
echo "Dotfiles installation finished successfully."
