#!/usr/bin/env python3
"""Block Bash commands that redundantly target the current working directory.

CLAUDE.md の「Bash コマンド実行ルール」を強制するための PreToolUse フック。
`cd <cwd> &&` プレフィックスと `git -C <cwd>` を検出して deny する。
permissions.allow のパターンマッチが壊れて毎回プロンプトが出るのを防ぐ。
"""
import json
import os
import re
import sys


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    if data.get("tool_name") != "Bash":
        return 0

    command = data.get("tool_input", {}).get("command", "")
    if not command:
        return 0

    cwd = data.get("cwd") or os.getcwd()
    cwd = cwd.rstrip("/")
    if not cwd:
        return 0

    escaped = re.escape(cwd)
    violations = []

    cd_pattern = rf'^\s*cd\s+["\']?{escaped}/?["\']?\s*&&'
    if re.match(cd_pattern, command):
        violations.append(
            f"先頭の `cd {cwd} &&` は不要です。現在の作業ディレクトリと同じなので削除してください。"
        )

    git_c_pattern = rf'(?:^|[\s;&|])git\s+-C\s+["\']?{escaped}/?["\']?(?:\s|$)'
    if re.search(git_c_pattern, command):
        violations.append(
            f"`git -C {cwd}` は不要です。現在の作業ディレクトリと同じなので `-C` オプションを削除してください。"
        )

    if violations:
        reason = "\n".join(violations) + (
            "\n\n(理由: permissions.allow のパターンマッチが壊れ、許可済みコマンドでも毎回プロンプトが発生するため。"
            "CLAUDE.md の「Bash コマンド実行ルール」を参照)"
        )
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }
        print(json.dumps(output, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    sys.exit(main())
