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

# Copy hooks per file. settings.json は dotfiles 管理外なので、hook の登録 (settings.json の hooks 節) は手動
HOOKS_SRC="${REPO_ROOT}/claude/hooks"
HOOKS_DEST="${CLAUDE_DIR}/hooks"

mkdir -p "${HOOKS_DEST}"

for hook_path in "${HOOKS_SRC}"/*(N.); do
  cp "${hook_path}" "${HOOKS_DEST}/${hook_path:t}"
  chmod +x "${HOOKS_DEST}/${hook_path:t}"
  echo "  Copied hook: ${hook_path:t}"
done

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
