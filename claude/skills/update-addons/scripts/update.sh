#!/bin/bash
set -euo pipefail

installed="${HOME}/.claude/plugins/installed_plugins.json"

claude plugin marketplace update

for plugin in $(jq -r '.plugins | to_entries[] | select(any(.value[]; .scope == "user")) | .key' "${installed}"); do
  claude plugin update --scope user "${plugin}"
done

npx --yes skills update --global
