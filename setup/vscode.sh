#!/bin/zsh

set -e

cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)

setopt extended_glob
setopt clobber
unalias -m '*' 2>/dev/null || true

echo "Setting up VSCode configuration..."

# devcontainer の中で動く VS Code Server の、マシン単位の設定ファイル
VSCODE_SETTINGS_DIR="${HOME}/.vscode-server/data/Machine"
VSCODE_SETTINGS_FILE="${VSCODE_SETTINGS_DIR}/settings.json"

# devcontainer の中かどうかを、VS Code Server のディレクトリがあるかで判断する
if [[ ! -d "${HOME}/.vscode-server" ]]; then
  echo "  Not in a DevContainer environment (no .vscode-server directory found)"
  echo "  Skipping VSCode terminal configuration"
  echo ""
  echo "✓ VSCode setup complete (skipped)"
  exit 0
fi

echo "  DevContainer environment detected"
echo "  Configuring VSCode integrated terminal to use zsh..."

mkdir -p "$VSCODE_SETTINGS_DIR"

if [[ ! -f "$VSCODE_SETTINGS_FILE" ]]; then
  echo '{}' > "$VSCODE_SETTINGS_FILE"
  echo "    Created ${VSCODE_SETTINGS_FILE}"
fi

if command -v jq &> /dev/null; then
  TMP_FILE=$(mktemp)
  jq '. + {"terminal.integrated.defaultProfile.linux": "zsh"}' "$VSCODE_SETTINGS_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$VSCODE_SETTINGS_FILE"
  echo "    Updated terminal.integrated.defaultProfile.linux to zsh"
else
  if grep -q "terminal.integrated.defaultProfile.linux" "$VSCODE_SETTINGS_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS の BSD 版 sed は、-i に空のバックアップ用の拡張子を渡さないと上書きできない
      sed -i '' 's/"terminal.integrated.defaultProfile.linux"[[:space:]]*:[[:space:]]*"[^"]*"/"terminal.integrated.defaultProfile.linux": "zsh"/g' "$VSCODE_SETTINGS_FILE"
    else
      sed -i 's/"terminal.integrated.defaultProfile.linux"[[:space:]]*:[[:space:]]*"[^"]*"/"terminal.integrated.defaultProfile.linux": "zsh"/g' "$VSCODE_SETTINGS_FILE"
    fi
    echo "    Updated terminal.integrated.defaultProfile.linux to zsh (using sed)"
  else
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
