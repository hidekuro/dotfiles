#!/bin/zsh
# Claude Code Setup Script
# Sets up ~/.claude configuration files (CLAUDE.md and skills/)

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

# Copy each skill directory (replace per-skill if exists)
# マシン固有のスキルを残したまま dotfiles 側のスキルだけ更新できるよう、
# skills/ ディレクトリ全体ではなくスキル単位で置き換える
SKILLS_SRC="${REPO_ROOT}/claude/skills"
SKILLS_DEST="${CLAUDE_DIR}/skills"

mkdir -p "${SKILLS_DEST}"

for skill_path in "${SKILLS_SRC}"/*(N/); do
  skill_name="${skill_path:t}"
  rm -rf "${SKILLS_DEST}/${skill_name}"
  cp -R "${skill_path}" "${SKILLS_DEST}/${skill_name}"
  echo "  Copied skill: ${skill_name}"
done

echo ""
echo "✓ Claude Code setup complete!"
