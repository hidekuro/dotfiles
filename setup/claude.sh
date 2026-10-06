#!/bin/zsh
# Claude Code Setup Script
# Sets up ~/.claude configuration files (CLAUDE.md, skills/, hooks/, textlint/)

set -e

# Always run from repository root
cd "$(dirname "$0")/.." || exit 1
REPO_ROOT=$(pwd)
CLAUDE_DIR="${HOME}/.claude"

echo "Setting up Claude Code configuration..."

mkdir -p "${CLAUDE_DIR}"

# Link CLAUDE.md
ln -snf "${REPO_ROOT}/claude/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"
echo "  Linked ~/.claude/CLAUDE.md"

# Link each skill directory (replace per-skill if exists)
# マシン固有のスキルを残すため、skills/ ディレクトリ全体ではなくスキル単位でリンクする
SKILLS_SRC="${REPO_ROOT}/claude/skills"
SKILLS_DEST="${CLAUDE_DIR}/skills"

mkdir -p "${SKILLS_DEST}"

# 改名・削除したスキルが起動候補に残らないよう、dotfiles を指したままリンク先が無くなったリンクを消す
for link_path in "${SKILLS_DEST}"/*(N@); do
  if [[ "$(readlink "${link_path}")" == "${SKILLS_SRC}/"* && ! -e "${link_path}" ]]; then
    rm "${link_path}"
  fi
done

for skill_path in "${SKILLS_SRC}"/*(N/); do
  skill_name="${skill_path:t}"
  rm -rf "${SKILLS_DEST}/${skill_name}"
  ln -s "${skill_path}" "${SKILLS_DEST}/${skill_name}"
  echo "  Linked skill: ${skill_name}"
done

# Copy hooks per file
HOOKS_SRC="${REPO_ROOT}/claude/hooks"
HOOKS_DEST="${CLAUDE_DIR}/hooks"

mkdir -p "${HOOKS_DEST}"

for hook_path in "${HOOKS_SRC}"/*(N.); do
  cp "${hook_path}" "${HOOKS_DEST}/${hook_path:t}"
  chmod +x "${HOOKS_DEST}/${hook_path:t}"
  echo "  Copied hook: ${hook_path:t}"
done

# settings.json には業務用の permissions やマーケットプレイスも入るので、ファイルごとではなく hooks 節だけを dotfiles の内容で置き換える
# settings.json だけに足した hook も消えるので、置き換える前に差分を表示し、元のファイルを settings.json.bak に残す
SETTINGS="${CLAUDE_DIR}/settings.json"
SETTINGS_HOOKS="${REPO_ROOT}/claude/settings-hooks.json"

if (( $+commands[jq] )); then
  [[ -f "${SETTINGS}" ]] || echo '{}' > "${SETTINGS}"
  if ! diff -u <(jq -S '.hooks' "${SETTINGS}") <(jq -S '.hooks' "${SETTINGS_HOOKS}"); then
    cp "${SETTINGS}" "${SETTINGS}.bak"
    jq --slurpfile src "${SETTINGS_HOOKS}" '.hooks = $src[0].hooks' "${SETTINGS}" > "${SETTINGS}.tmp"
    mv "${SETTINGS}.tmp" "${SETTINGS}"
    echo "  Replaced hooks in ~/.claude/settings.json (previous file: ~/.claude/settings.json.bak)"
  fi
else
  echo "  jq not found; skipped registering hooks in ~/.claude/settings.json"
fi

# textlint は hooks から呼ぶ。node_modules をリポジトリに置かないため、~/.claude/textlint に npm でインストールする
TEXTLINT_SRC="${REPO_ROOT}/claude/textlint"
TEXTLINT_DEST="${CLAUDE_DIR}/textlint"

mkdir -p "${TEXTLINT_DEST}"
cp "${TEXTLINT_SRC}/package.json" "${TEXTLINT_SRC}/package-lock.json" "${TEXTLINT_SRC}/.textlintrc.json" "${TEXTLINT_DEST}/"

if (( $+commands[npm] )); then
  (cd "${TEXTLINT_DEST}" && npm ci --silent --no-audit --no-fund)
  echo "  Installed textlint into ~/.claude/textlint"
else
  echo "  npm not found; skipped textlint install (textlint hooks do nothing until installed)"
fi

echo ""
echo "✓ Claude Code setup complete!"
