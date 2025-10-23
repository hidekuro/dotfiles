#!/bin/zsh
# Zsh Setup Script
# Sets up zsh configuration with Antidote plugin manager

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)
ZDOTDIR="${ZDOTDIR:-${HOME}}"

setopt extended_glob
setopt clobber
unalias -m '*' 2>/dev/null || true

echo "Setting up zsh configuration..."

# Install Antidote if not present
ANTIDOTE_HOME="${ZDOTDIR}/.antidote"
if [[ ! -d "$ANTIDOTE_HOME" ]]; then
  echo "  Installing Antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
else
  echo "  Antidote already installed"
fi

# Create symlink to dotfiles directory for plugin list access
echo "  Creating dotfiles symlink..."
ln -snf "${REPO_ROOT}" "${ZDOTDIR}/.dotfiles"

# Link zsh configuration files
echo "  Linking zsh configuration files..."
for rcfile in "${REPO_ROOT}"/zsh/(zshenv|zprofile|zshrc|zlogin|zlogout)(.N); do
  target="${ZDOTDIR}/.${rcfile:t}"
  ln -snf "${rcfile}" "${target}"
done

# Create local config files from templates if they don't exist
echo "  Creating local config files from templates..."
for tpl in "${REPO_ROOT}"/zsh/templates/*(.N); do
  filename=$(basename "$tpl")
  target="${ZDOTDIR}/.${filename}"
  # Use -n to prevent overwriting existing files
  if [[ ! -f "$target" ]]; then
    cp "$tpl" "$target"
    echo "    Created ${target}"
  fi
done

echo ""
echo "✓ Zsh setup complete!"
echo ""
echo "Configuration files linked:"
echo "  ~/.zshenv, ~/.zprofile, ~/.zshrc, ~/.zlogin, ~/.zlogout"
echo ""
echo "Next steps:"
echo "  1. Customize your settings in ~/.zshrc.local"
echo "  2. Run 'exec zsh' to reload your shell"
