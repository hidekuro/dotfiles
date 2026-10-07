---
name: update-addons
description: >
  マーケットプレイスから入れた Claude Code のプラグインと、Skills CLI (npx skills) で入れたスキルをまとめて最新化する。
disable-model-invocation: true
---

# プラグインとスキルの更新

次のスクリプトを Bash ツールで実行する。手順をスクリプトに固定しているので、個々のコマンドを分けて実行したり、内容を書き換えて実行したりしない。

```bash
~/.claude/skills/update-addons/scripts/update.sh
```

実行が終わったら、次のことを報告する。

- 更新したプラグインとスキル、失敗したものがあればそのエラー
- 途中で失敗した場合は、失敗したコマンドをユーザーが端末で実行して確認に答えてから、`/update-addons` をもう一度実行すること (失敗した時点より後の更新は実行されていないため)
- セッションに反映するには `/reload-plugins` を実行すること
