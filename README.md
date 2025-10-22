# Dotfiles

軽量なプラグインマネージャー [Antidote](https://github.com/mattmc3/antidote) を使用したzsh設定です。

## 必要環境

- git
- homebrew
- zsh

## 導入

```bash
git clone https://github.com/hidekuro/dotfiles.git ~/dotfiles
zsh ~/dotfiles/install.sh
```

初回起動時、Antidoteが自動的にインストールされ、プラグインがダウンロードされます。

## マシン固有の追加設定

環境ごとの設定は、ホームディレクトリに特定の名前のファイルを作成することで追加できます。
これらのファイルは `dotfiles` の管理対象外で、各マシン固有の設定を記述するために使用します。

`zsh` の起動時には、以下のファイルが特定の順序で読み込まれます。

| ローカルファイル    | 用途                              | 読み込みタイミング                              |
| :------------------ | :-------------------------------- | :---------------------------------------------- |
| `~/.zshenv.local`   | すべてのシェルで必要な環境変数    | すべてのシェル起動時                            |
| `~/.zprofile.local` | ログインシェル用の設定            | ログインシェル起動時（`zshrc` の前）            |
| `~/.zshrc.path`     | `path`, `fpath` の設定            | インタラクティブシェル起動時（`compinit` の前） |
| `~/.zshrc.local`    | `export`, `alias` などの基本設定  | インタラクティブシェル起動時（`compinit` の前） |
| `~/.zshrc.post`     | ツールの初期化 (`eval`, `source`) | インタラクティブシェル起動時（`compinit` の後） |
| `~/.zlogin.local`   | ログインシェル用の設定            | ログインシェル起動時（`zshrc` の後）            |
| `~/.zlogout.local`  | ログアウト時の処理                | ログインシェル終了時                            |

### ~/.zshrc.post の推奨記法

`~/.zshrc.post` は補完システム（compinit）の後に読み込まれるため、ツールの初期化に適しています。
ただし、コマンドが存在しない場合のエラーを避けるため、必ず存在確認を行ってください：

```zsh
# 良い例：コマンドの存在を確認
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

# 悪い例：コマンドが存在しない場合エラーになる
eval "$(direnv hook zsh)"  # NG: direnvがない場合エラー
```

詳細は `local-templates/zshrc.post` のテンプレートを参照してください。

## トラブルシューティング

### "command not found: compdef" エラー

補完システムのキャッシュを削除して再起動：

```bash
rm -f ~/.zcompdump* ~/.zsh_plugins.zsh
exec zsh
```

### プラグインが読み込まれない

Antidoteを再インストール：

```bash
rm -rf ~/.antidote ~/.zsh_plugins.zsh
exec zsh
```

### "command not found: direnv" (またはその他のツール)

`~/.zshrc.post` でコマンドの存在確認を追加：

```zsh
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi
```

## ライセンス

[CC0](https://creativecommons.org/publicdomain/zero/1.0/)
