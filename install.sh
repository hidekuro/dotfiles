if [[ ! -d ~/.dotfiles ]]; then
  git clone --recurse-submodules https://github.com/hidekuro/dotfiles.git ~/.dotfiles
fi

# vim
mkdir -p ~/.vim/colors
ln -snf ~/.dotfiles/iceberg.vim/colors/iceberg.vim ~/.vim/colors/iceberg.vim
ln -snf ~/.dotfiles/.vimrc ~/.vimrc

# bashrc
ln -snf ~/.dotfiles/.bashrc ~/.bashrc
touch ~/.bashrc.local

# aliases
if [[ -e ~/.aliases && ! -e ~/.aliases.local ]]; then
  cat ~/.aliases >> ~/.aliases.local
fi
ln -snf ~/.dotfiles/.aliases ~/.aliases

# git
cp -n ~/.dotfiles/.gitconfig ~/.gitconfig
cp -n ~/.dotfiles/.gitignore_global ~/.gitignore_global

# brew
if (type brew > /dev/null 2>&1); then
  ln -snf ~/.dotfiles/Brewfile ~/Brewfile
fi

# zsh
if (type zsh > /dev/null 2>&1); then
  ln -snf ~/.dotfiles/.zshrc ~/.zshrc
  touch ~/.zshenv
  touch ~/.zshrc.local

  # zsh-completions
  if [[ "${OSTYPE}" = darwin* ]]; then
    brew install zsh zsh-completions
  elif [[ "${OSTYPE}" = linux* ]]; then
    sudo git clone https://github.com/zsh-users/zsh-completions /usr/local/share/zsh-completions
  elif [[ "${OSTYPE}" = msys ]]; then
    mkdir -p /usr/local/share
    git clone https://github.com/zsh-users/zsh-completions /usr/local/share/zsh-completions
  fi
fi
