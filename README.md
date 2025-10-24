# Dotfiles

軽量なプラグインマネージャー [Antidote](https://github.com/mattmc3/antidote) を使用したzsh設定です。

## 必要環境

- git
- homebrew
- zsh

## 導入

### インストール手順

```bash
# 1. dotfilesをクローン
git clone https://github.com/hidekuro/dotfiles.git ~/.dotfiles

# 2. インストールスクリプトを実行
zsh ~/.dotfiles/install.sh
```

インストールスクリプトは以下を実行します：

- Antidoteのインストール（未インストールの場合）
- zsh設定ファイルのシンボリックリンク作成
- vim、git、その他の設定ファイルのセットアップ
- テンプレートファイルからローカル設定ファイルの作成

初回起動時、プラグインが自動的にダウンロードされます。

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

詳細は `zsh/templates/zshrc.post` のテンプレートを参照してください。

## プラグインのカスタマイズ

### プラグインの追加・削除

プラグインは `zsh/zsh_plugins.txt` で管理されています。
このファイルを編集してプラグインを追加・削除できます。

```bash
# 例：プラグインの追加
echo "zsh-users/zsh-completions" >> ~/dotfiles/zsh/zsh_plugins.txt

# 変更を反映（静的プラグインファイルの再生成）
rm ~/.zsh_plugins.zsh
exec zsh
```

### プラグインリストの書式

```txt
# Oh My Zshプラグイン
ohmyzsh/ohmyzsh path:plugins/git

# GitHubリポジトリ
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-autosuggestions

# 遅延読み込み
olets/zsh-abbr kind:defer

# プロンプトテーマ
sindresorhus/pure kind:fpath
```

詳しくは [Antidote公式ドキュメント](https://getantidote.github.io/) を参照してください。

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
