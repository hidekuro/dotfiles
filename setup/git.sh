#!/bin/zsh
# Git Setup Script
# Sets up git configuration while preserving user-specific settings

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

setopt extended_glob
setopt clobber
unalias -m '*' 2>/dev/null || true

echo "Setting up git configuration..."

# Preserve existing user-specific settings
echo "  Preserving existing user settings..."
GIT_USER_NAME=$(git config --global user.name 2>/dev/null || true)
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || true)
GIT_USER_SIGNINGKEY=$(git config --global user.signingKey 2>/dev/null || true)
GIT_COMMIT_GPGSIGN=$(git config --global commit.gpgSign 2>/dev/null || true)
GIT_TAG_GPGSIGN=$(git config --global tag.gpgSign 2>/dev/null || true)

# Copy main gitconfig
echo "  Copying gitconfig..."
cp -f "${REPO_ROOT}/gitconfig" "${HOME}/.gitconfig"

# Restore user-specific settings
echo "  Restoring user-specific settings..."
[[ -n ${GIT_USER_NAME} ]] && git config --global user.name "${GIT_USER_NAME}"
[[ -n ${GIT_USER_EMAIL} ]] && git config --global user.email "${GIT_USER_EMAIL}"
[[ -n ${GIT_USER_SIGNINGKEY} ]] && git config --global user.signingKey "${GIT_USER_SIGNINGKEY}"
[[ -n ${GIT_COMMIT_GPGSIGN} ]] && git config --global commit.gpgSign "${GIT_COMMIT_GPGSIGN}"
[[ -n ${GIT_TAG_GPGSIGN} ]] && git config --global tag.gpgSign "${GIT_TAG_GPGSIGN}"

# Setup local config include
git config --global include.path "${HOME}/.gitconfig.local"

# Configure SSH signing if Git version supports it (2.34.0+)
echo "  Checking Git version for SSH signing support..."
GIT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
GIT_MAJOR=$(echo "${GIT_VERSION}" | cut -d. -f1)
GIT_MINOR=$(echo "${GIT_VERSION}" | cut -d. -f2)

if [[ ${GIT_MAJOR} -gt 2 ]] || [[ ${GIT_MAJOR} -eq 2 && ${GIT_MINOR} -ge 34 ]]; then
  echo "    Git ${GIT_VERSION} supports SSH signing, enabling..."
  git config --global gpg.format ssh
else
  echo "    Git ${GIT_VERSION} does not support SSH signing (requires 2.34.0+), skipping..."
  git config --global --unset gpg.format 2>/dev/null || true
fi

# Setup gitignore
echo "  Setting up global gitignore..."
mkdir -p "${HOME}/.config/git"
ln -snf "${REPO_ROOT}/gitignore" "${HOME}/.config/git/ignore"

# Create local config file from template if it doesn't exist
echo "  Creating local config file from template..."
if [[ ! -f "${HOME}/.gitconfig.local" ]]; then
  cp "${REPO_ROOT}/templates/gitconfig.local" "${HOME}/.gitconfig.local"
  echo "    Created ~/.gitconfig.local"
fi

# Clean up
unset GIT_USER_NAME GIT_USER_EMAIL GIT_USER_SIGNINGKEY GIT_COMMIT_GPGSIGN GIT_TAG_GPGSIGN

echo ""
echo "✓ Git setup complete!"
echo ""
echo "Configuration files:"
echo "  ~/.gitconfig (main config)"
echo "  ~/.gitconfig.local (local overrides)"
echo "  ~/.config/git/ignore (global gitignore)"
echo ""
echo "Next steps:"
echo "  1. Customize your local settings in ~/.gitconfig.local"
if [[ -z ${GIT_USER_NAME} ]] || [[ -z ${GIT_USER_EMAIL} ]]; then
  echo "  2. Configure your user details:"
  echo "     git config --global user.name 'Your Name'"
  echo "     git config --global user.email 'your.email@example.com'"
fi
echo ""
