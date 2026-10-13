#!/usr/bin/env python3
"""現在の作業ディレクトリをわざわざ指定した Bash コマンドを、実行前に拒否する PreToolUse フック。

先頭の `cd <cwd> &&` や `git -C <cwd>` があると permissions.allow のパターンに一致しなくなり、許可済みのコマンドでも毎回確認が出るので、拒否して書き直させる。
CLAUDE.md の「Bash コマンド実行ルール」を、モデルの注意に頼らず機械的に守らせるためのもの。
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
