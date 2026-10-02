#!/usr/bin/env python3
"""~/.claude/settings.json の hooks が dotfiles の claude/settings-hooks.json とずれていたら知らせる SessionStart フック。

setup/claude.sh は settings.json の hooks を dotfiles の内容で丸ごと置き換えるので、/hooks 画面などで settings.json だけを編集すると次の setup で消える。
ずれた時点で気づけるよう起動のたびに比較し、AI ではなくユーザーに見える systemMessage で知らせる。
dotfiles が ~/.dotfiles に clone されている前提。どちらかのファイルが読めなければ何もしない。
"""
import json
import os
import sys

SETTINGS = os.path.expanduser("~/.claude/settings.json")
DOTFILES_HOOKS = os.path.expanduser("~/.dotfiles/claude/settings-hooks.json")


def load_hooks(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f).get("hooks")


def main():
    try:
        current = load_hooks(SETTINGS)
        expected = load_hooks(DOTFILES_HOOKS)
    except (OSError, json.JSONDecodeError):
        return 0
    if current == expected:
        return 0

    print(json.dumps({
        "systemMessage": (
            "[check-hooks-drift] ~/.claude/settings.json の hooks が ~/.dotfiles/claude/settings-hooks.json と一致しません。"
            "settings.json 側を変更したなら dotfiles に反映し、dotfiles 側を更新したなら setup/claude.sh を実行してください。"
        )
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
