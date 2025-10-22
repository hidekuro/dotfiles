#!/bin/zsh
# Antidote setup script
# This script sets up Antidote-based zsh configuration

cd "$(dirname "$0")" || exit 1
DOTFILES_DIR=$(pwd)
ZDOTFILE="${ZDOTFILE:-${HOME}}"

setopt extended_glob
setopt clobber
unalias -m '*'

echo "Setting up Antidote-based zsh configuration..."

# Install Antidote if not present
ANTIDOTE_HOME="${ZDOTFILE}/.antidote"
if [[ ! -d "$ANTIDOTE_HOME" ]]; then
  echo "Installing Antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
else
  echo "Antidote already installed at $ANTIDOTE_HOME"
fi

# Create symlink to dotfiles directory for plugin list access
ln -snf "${DOTFILES_DIR}" "${ZDOTFILE}/.dotfiles"

# Link zsh configuration files from zsh directory
for rcfile in "${DOTFILES_DIR}"/zsh/(zshenv|zprofile|zshrc|zlogin|zlogout)(.N); do
  ln -snf "${rcfile}" "${ZDOTFILE}/.${rcfile:t}"
done

echo "Antidote setup complete!"
echo ""
echo "The following files have been linked:"
echo "  ~/.zshenv  -> ${DOTFILES_DIR}/zsh/zshenv"
echo "  ~/.zprofile -> ${DOTFILES_DIR}/zsh/zprofile"
echo "  ~/.zshrc   -> ${DOTFILES_DIR}/zsh/zshrc"
echo "  ~/.zlogin  -> ${DOTFILES_DIR}/zsh/zlogin"
echo "  ~/.zlogout -> ${DOTFILES_DIR}/zsh/zlogout"
echo ""
echo "Please restart your shell or run 'exec zsh' to load the new configuration."
