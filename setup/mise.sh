#!/bin/zsh

set -e

if ! (type mise >/dev/null 2>&1); then
  echo "⊘ mise not found, skipping setup"
  # zshrc はもう asdf の shims を PATH に通さないので、mise を入れて移行するまで asdf で入れたツールが見えない
  if [[ -f "${HOME}/.tool-versions" ]]; then
    echo "  Run 'dot update' to install mise, then 'dot pull' to migrate ~/.tool-versions"
  fi
  exit 0
fi

echo "Setting up mise configuration..."

# asdf の ~/.tool-versions は mise も読むが、~/.config/mise/config.toml より優先されてグローバルの設定を打ち消すので、内容を config.toml に移して退ける
if [[ -f "${HOME}/.tool-versions" ]]; then
  # ツール名の別名 (nodejs → node) や registry と桁数が違うバージョンは mise が解決するので、変換せずに渡す
  mise use --global $(grep -v -e '^#' -e '^$' "${HOME}/.tool-versions" | awk '{ print $1 "@" $2 }')
  mv "${HOME}/.tool-versions" "${HOME}/.tool-versions.bak"
  echo "  Migrated ~/.tool-versions into ~/.config/mise/config.toml (previous file: ~/.tool-versions.bak)"
fi

echo "✓ mise setup complete!"
