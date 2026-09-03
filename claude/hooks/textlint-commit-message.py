#!/usr/bin/env python3
"""AI が git commit するときにコミットメッセージのスペース規則を textlint で検査する PreToolUse フック。

違反があれば修正済みの文面を理由に添えてコミットを止め、モデルにその文面で再実行させる。
人間のコミットには効かせない (Claude Code の Bash ツール経由のコミットだけを対象にする) ため、git の commit-msg hook ではなくここに置く。
読み取れる形式は -m "$(cat <<'EOF' ... EOF)"、-m "..." / -m '...'、-F <file> の 3 つ。それ以外はメッセージを特定できないので検査せず通す。
textlint は ~/.claude/textlint に npm でインストールされている前提 (setup/claude.sh が用意する)。無ければ何もしない。
"""
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

TEXTLINT_DIR = os.path.expanduser("~/.claude/textlint")
TEXTLINT_BIN = os.path.join(TEXTLINT_DIR, "node_modules", ".bin", "textlint")
CONFIG = os.path.join(TEXTLINT_DIR, ".textlintrc.json")


def env_with_node():
    """hook は非ログインシェルで動くことがあり、asdf の shim も asdf 本体が PATH に無いと動かないので、node の実体ディレクトリを直接足す。"""
    env = os.environ.copy()
    extra = sorted(glob.glob(os.path.expanduser("~/.asdf/installs/nodejs/*/bin")), reverse=True)
    extra += [os.path.expanduser("~/.asdf/shims"), "/opt/homebrew/bin", "/usr/local/bin"]
    env["PATH"] = os.pathsep.join(extra + [env.get("PATH", "")])
    return env

GIT_COMMIT = re.compile(r"(?:^|[;&|]\s*)git\s+(?:-C\s+\S+\s+)?commit\b")
HEREDOC = re.compile(r"<<-?\s*'?(\w+)'?\s*\n(.*?)\n\1(?:\s|$)", re.S)
DASH_M_DQ = re.compile(r"(?:^|\s)-m\s+\"((?:[^\"\\]|\\.)*)\"")
DASH_M_SQ = re.compile(r"(?:^|\s)-m\s+'([^']*)'")
DASH_F = re.compile(r"(?:^|\s)(?:-F|--file)[\s=]+(\S+)")


def extract_messages(command, cwd):
    messages = []
    for m in HEREDOC.finditer(command):
        messages.append(m.group(2))
    if not messages:
        messages.extend(m.group(1) for m in DASH_M_DQ.finditer(command))
        messages.extend(m.group(1) for m in DASH_M_SQ.finditer(command))
    for m in DASH_F.finditer(command):
        path = os.path.expanduser(m.group(1).strip("'\""))
        if not os.path.isabs(path):
            path = os.path.join(cwd, path)
        try:
            with open(path, encoding="utf-8") as f:
                messages.append(f.read())
        except OSError:
            pass
    return messages


def fix(text):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "message.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        subprocess.run(
            [TEXTLINT_BIN, "--config", CONFIG, "--fix", path],
            cwd=TEXTLINT_DIR, env=env_with_node(), capture_output=True, timeout=30,
        )
        with open(path, encoding="utf-8") as f:
            return f.read()


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if data.get("tool_name") != "Bash":
        return 0
    command = (data.get("tool_input") or {}).get("command", "")
    if not GIT_COMMIT.search(command):
        return 0
    if not (os.path.exists(TEXTLINT_BIN) and os.path.exists(CONFIG)):
        return 0

    cwd = data.get("cwd") or os.getcwd()
    diffs = []
    for message in extract_messages(command, cwd):
        try:
            fixed = fix(message)
        except (OSError, subprocess.SubprocessError):
            return 0
        if fixed != message:
            diffs.append(fixed)
    if not diffs:
        return 0

    reason = (
        "[textlint] コミットメッセージの日本語と英数字の間のスペースが規則と異なります。"
        "次の修正済みメッセージに置き換えて再実行してください。\n\n" + "\n---\n".join(diffs)
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
