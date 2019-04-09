if (type zsh > /dev/null 2>&1); then
  if [[ "${OSTYPE}" = darwin* ]]; then
    brew install zsh zsh-completions
  elif [[ "${OSTYPE}" = linux* ]]; then
    sudo git clone https://github.com/zsh-users/zsh-completions /usr/local/share/zsh-completions
  elif [[ "${OSTYPE}" = msys ]]; then
    mkdir -p /usr/local/share
    git clone https://github.com/zsh-users/zsh-completions /usr/local/share/zsh-completions
  fi
fi

git clone --recurse-submodules https://github.com/hidekuro/dotfiles.git ~/.dotfiles

mkdir -p ~/.vim/colors
ln -snf ~/.dotfiles/iceberg.vim/colors/iceberg.vim ~/.vim/colors/iceberg.vim
ln -snf ~/.dotfiles/.vimrc ~/.vimrc

cat ~/.dotfiles/.bashrc >> ~/.bashrc
cp -n ~/.dotfiles/.aliases ~/.aliases

cp -n ~/.dotfiles/.gitconfig ~/.gitconfig
cp -n ~/.dotfiles/.gitignore_global ~/.gitignore_global

if (type zsh > /dev/null 2>&1); then
  ln -snf ~/.dotfiles/.zshrc ~/.zshrc
  touch ~/.zshenv
fi
