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

# Link skills directory
ln -snf "${REPO_ROOT}/claude/skills" "${CLAUDE_DIR}/skills"
echo "  Linked ~/.claude/skills"

echo ""
echo "✓ Claude Code setup complete!"
