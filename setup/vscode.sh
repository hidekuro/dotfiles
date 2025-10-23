#!/bin/zsh
# VSCode Setup Script
# Configures VSCode integrated terminal for DevContainer environments

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

setopt extended_glob
setopt clobber
unalias -m '*' 2>/dev/null || true

echo "Setting up VSCode configuration..."

# VSCode Remote Container user settings location
VSCODE_SETTINGS_DIR="${HOME}/.vscode-server/data/Machine"
VSCODE_SETTINGS_FILE="${VSCODE_SETTINGS_DIR}/settings.json"

# Check if running in a DevContainer by checking for .vscode-server directory
if [[ ! -d "${HOME}/.vscode-server" ]]; then
  echo "  Not in a DevContainer environment (no .vscode-server directory found)"
  echo "  Skipping VSCode terminal configuration"
  echo ""
  echo "✓ VSCode setup complete (skipped)"
  exit 0
fi

echo "  DevContainer environment detected"
echo "  Configuring VSCode integrated terminal to use zsh..."

# Create settings directory if it doesn't exist
mkdir -p "$VSCODE_SETTINGS_DIR"

# Create settings.json if it doesn't exist
if [[ ! -f "$VSCODE_SETTINGS_FILE" ]]; then
  echo '{}' > "$VSCODE_SETTINGS_FILE"
  echo "    Created ${VSCODE_SETTINGS_FILE}"
fi

# Update settings.json to use zsh as default terminal
if command -v jq &> /dev/null; then
  TMP_FILE=$(mktemp)
  jq '. + {"terminal.integrated.defaultProfile.linux": "zsh"}' "$VSCODE_SETTINGS_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$VSCODE_SETTINGS_FILE"
  echo "    Updated terminal.integrated.defaultProfile.linux to zsh"
else
  # Fallback: manual update using sed if jq is not available
  # Check if the setting already exists
  if grep -q "terminal.integrated.defaultProfile.linux" "$VSCODE_SETTINGS_FILE"; then
    # Update existing setting
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS sed (but unlikely in DevContainer)
      sed -i '' 's/"terminal.integrated.defaultProfile.linux"[[:space:]]*:[[:space:]]*"[^"]*"/"terminal.integrated.defaultProfile.linux": "zsh"/g' "$VSCODE_SETTINGS_FILE"
    else
      # Linux sed
      sed -i 's/"terminal.integrated.defaultProfile.linux"[[:space:]]*:[[:space:]]*"[^"]*"/"terminal.integrated.defaultProfile.linux": "zsh"/g' "$VSCODE_SETTINGS_FILE"
    fi
    echo "    Updated terminal.integrated.defaultProfile.linux to zsh (using sed)"
  else
    # Add new setting (simple approach - may need manual formatting)
    echo ""
    echo "⚠️  jq not found and setting doesn't exist."
    echo "    Please manually add the following to your VSCode User Settings (Remote):"
    echo '    "terminal.integrated.defaultProfile.linux": "zsh"'
    echo ""
  fi
fi

echo ""
echo "✓ VSCode setup complete!"
echo ""
echo "Changes applied:"
echo "  - VSCode integrated terminal configured to use zsh"
echo ""
echo "Note:"
echo "  You may need to reload VSCode or open a new terminal for changes to take effect."
