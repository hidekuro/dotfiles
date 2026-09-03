#!/usr/bin/env python3
"""Markdown を編集した直後に textlint --fix を当て、日本語と英数字の間のスペースを規則に揃える PostToolUse フック。

モデルに毎回スペース規則を意識させるより、ツールで機械的に直す方が確実で安い。
修正が入ったときだけ additionalContext で知らせる。Edit ツールは読み込み後にファイルが変わっていると失敗するので、再読込を促すため。
textlint は ~/.claude/textlint に npm でインストールされている前提 (setup/claude.sh が用意する)。無ければ何もしない。
"""
import glob
import json
import os
import subprocess
import sys

TEXTLINT_DIR = os.path.expanduser("~/.claude/textlint")
TEXTLINT_BIN = os.path.join(TEXTLINT_DIR, "node_modules", ".bin", "textlint")
CONFIG = os.path.join(TEXTLINT_DIR, ".textlintrc.json")
TARGET_EXT = (".md", ".markdown")


def env_with_node():
    """hook は非ログインシェルで動くことがあり、asdf の shim も asdf 本体が PATH に無いと動かないので、node の実体ディレクトリを直接足す。"""
    env = os.environ.copy()
    extra = sorted(glob.glob(os.path.expanduser("~/.asdf/installs/nodejs/*/bin")), reverse=True)
    extra += [os.path.expanduser("~/.asdf/shims"), "/opt/homebrew/bin", "/usr/local/bin"]
    env["PATH"] = os.pathsep.join(extra + [env.get("PATH", "")])
    return env


def read(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if data.get("tool_name") not in ("Edit", "Write", "MultiEdit"):
        return 0
    path = (data.get("tool_input") or {}).get("file_path", "")
    if not path.endswith(TARGET_EXT) or not os.path.isfile(path):
        return 0
    if not (os.path.exists(TEXTLINT_BIN) and os.path.exists(CONFIG)):
        return 0

    before = read(path)
    try:
        subprocess.run(
            [TEXTLINT_BIN, "--config", CONFIG, "--fix", path],
            cwd=TEXTLINT_DIR, env=env_with_node(), capture_output=True, timeout=30,
        )
    except (OSError, subprocess.SubprocessError):
        return 0
    if read(path) == before:
        return 0

    cwd = data.get("cwd") or os.getcwd()
    rel = os.path.relpath(path, cwd) if path.startswith(cwd) else path
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": f"[textlint] {rel} の日本語と英数字の間のスペースを自動修正しました。",
        }
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
