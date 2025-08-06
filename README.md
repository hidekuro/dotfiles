# Dotfiles

## 必要環境

- git
- homebrew
- zsh

## 導入

```bash
git clone https://github.com/hidekuro/dotfiles.git ~/dotfiles
zsh ~/dotfiles/install.sh
```

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

## ライセンス

[CC0](https://creativecommons.org/publicdomain/zero/1.0/)
