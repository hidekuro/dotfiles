#!/bin/bash
# Claude Code のプラグインと、Skills CLI (npx skills) で入れたスキルをまとめて最新化する
set -euo pipefail

installed="${HOME}/.claude/plugins/installed_plugins.json"

claude plugin marketplace update

for plugin in $(jq -r '.plugins | to_entries[] | select(any(.value[]; .scope == "user")) | .key' "${installed}"); do
  claude plugin update --scope user "${plugin}"
done

npx --yes skills update --global
