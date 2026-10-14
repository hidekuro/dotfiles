# Dotfiles

軽量なプラグインマネージャー [Antidote](https://github.com/mattmc3/antidote) を使用した zsh 設定です。

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

- Antidote のインストール（未インストールの場合）
- zsh 設定ファイルのシンボリックリンク作成
- vim、git、その他の設定ファイルのセットアップ
- テンプレートファイルからローカル設定ファイルの作成

初回起動時、プラグインが自動的にダウンロードされます。

### 日々の運用

インストール後は `dot` コマンドが使えます。

```bash
# リポジトリの変更を取り込み、install.sh を再実行する
dot pull

# zsh のプラグインと Brewfile のパッケージを更新する
dot update

# このマシンにインストールされているパッケージを Brewfile に書き出し、差分を表示する
dot dump
```

手元の変更をほかのマシンに渡すときは、通常どおり `git push` します。

## マシン固有の追加設定

環境ごとの設定は、ホームディレクトリに特定の名前のファイルを作成することで追加できます。
これらのファイルは `dotfiles` の管理対象外で、各マシン固有の設定を記述するために使用します。

`zsh` の起動時には、以下のファイルが特定の順序で読み込まれます。

| ローカルファイル    | 用途                              | 読み込みタイミング                              |
| :------------------ | :-------------------------------- | :---------------------------------------------- |
| `~/.zshenv.local`   | すべてのシェルで必要な環境変数    | すべてのシェル起動時                            |
| `~/.zprofile.local` | ログインシェル用の設定            | ログインシェル起動時（`zshrc` の前）            |
| `~/.zshrc.path`     | `path`, `fpath` の設定            | インタラクティブシェル起動時（`compinit` の前） |
| `~/.zshrc.local`    | `export`, `alias`, ツールの初期化 | インタラクティブシェル起動時（`zshrc` の最後）  |
| `~/.zlogin.local`   | ログインシェル用の設定            | ログインシェル起動時（`zshrc` の後）            |
| `~/.zlogout.local`  | ログアウト時の処理                | ログインシェル終了時                            |

### ~/.zshrc.local の推奨記法

`~/.zshrc.local` は補完システム（compinit）の後に読み込まれるため、ツールの初期化に適しています。
ただし、コマンドが存在しない場合のエラーを避けるため、必ず存在確認を行ってください：

```zsh
# 良い例：コマンドの存在を確認
if (( $+commands[pipx] )); then
  eval "$(register-python-argcomplete pipx)"
fi

# 悪い例：コマンドが存在しない場合エラーになる
eval "$(register-python-argcomplete pipx)"  # NG: pipxがない場合エラー
```

補完関数のディレクトリを `fpath` に足すときは、`compinit` の前に読み込まれる `~/.zshrc.path` に書いてください。
詳細は `zsh/templates/zshrc.local` と `zsh/templates/zshrc.path` のテンプレートを参照してください。

## プラグインのカスタマイズ

### プラグインの追加・削除

プラグインは `zsh/zsh_plugins.txt` で管理されています。
このファイルを編集してプラグインを追加・削除できます。

```bash
# 例：プラグインの追加
echo "zsh-users/zsh-completions" >> ~/.dotfiles/zsh/zsh_plugins.txt

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

詳しくは [Antidote 公式ドキュメント](https://getantidote.github.io/) を参照してください。

## トラブルシューティング

### "command not found: compdef" エラー

補完システムのキャッシュを削除して再起動：

```bash
rm -f ~/.zcompdump* ~/.zsh_plugins.zsh
exec zsh
```

### プラグインが読み込まれない

Antidote を再インストール：

```bash
rm -rf ~/.antidote ~/.zsh_plugins.zsh
exec zsh
```

### "command not found: pipx" (またはその他のツール)

`~/.zshrc.local` でコマンドの存在確認を追加：

```zsh
if (( $+commands[pipx] )); then
  eval "$(register-python-argcomplete pipx)"
fi
```

## ライセンス

[CC0](https://creativecommons.org/publicdomain/zero/1.0/)
