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

# Phase 1: Core tools (order matters)
echo "==> Phase 1: Setting up core tools"
zsh setup/zsh.sh
echo ""
zsh setup/git.sh
echo ""

# Phase 2: Other tools (order doesn't matter)
echo "==> Phase 2: Setting up other tools"
for script in setup/*.sh; do
  case "${script##*/}" in
    zsh.sh|git.sh) continue ;;  # Already executed in Phase 1
    *) zsh "${script}"; echo "" ;;
  esac
done

echo "==> All setup tasks complete!"
echo ""
echo "Dotfiles installation finished successfully."
