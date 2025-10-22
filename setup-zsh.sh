#!/bin/zsh
# Zsh Setup Script
# Sets up zsh configuration with Antidote plugin manager

set -e

cd "$(dirname "$0")" || exit 1
DOTFILES_DIR=$(pwd)
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
ln -snf "${DOTFILES_DIR}" "${ZDOTDIR}/.dotfiles"

# Link zsh configuration files
echo "  Linking zsh configuration files..."
for rcfile in "${DOTFILES_DIR}"/zsh/(zshenv|zprofile|zshrc|zlogin|zlogout)(.N); do
  target="${ZDOTDIR}/.${rcfile:t}"
  ln -snf "${rcfile}" "${target}"
done

echo ""
echo "✓ Zsh setup complete!"
echo ""
echo "Configuration files linked:"
echo "  ~/.zshenv, ~/.zprofile, ~/.zshrc, ~/.zlogin, ~/.zlogout"
echo ""
echo "Next steps:"
echo "  1. Customize your settings in ~/.zshrc.path, ~/.zshrc.local, ~/.zshrc.post"
echo "  2. Run 'exec zsh' to reload your shell"
