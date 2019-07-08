if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

########################################
# エイリアス
alias ll='ls -Ahl'
alias sudo='sudo '

case ${OSTYPE} in
  darwin*)
    export CLICOLOR=1

    if (type gls 2>&1 > /dev/null); then
      alias ls='ls -F --color=auto'
    else
      alias ls='ls -G -F'
    fi
    ;;
  linux*)
    alias ls='ls -F --color'
    ;;
  msys*)
    alias ls='ls -F --color=auto'
    ;;
esac

# ローカル設定があれば優先
[[ -e ~/.aliases.local ]] && . ~/.aliases.local

########################################
# 環境変数
export LESS="-igSRM"

# ローカル設定があれば優先
[[ -e ~/.bashrc.local ]] && . ~/.bashrc.local
