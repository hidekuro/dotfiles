########################################
# エイリアス
alias ll='ls -AFhl'
alias sudo='sudo '

case ${OSTYPE} in
  darwin*)
    export CLICOLOR=1
    alias ls='ls -G -F'
    ;;
  linux*)
    alias ls='ls -F --color'
    ;;
esac

# ローカル設定があれば優先
[[ -e ~/.aliases ]] && . ~/.aliases

########################################
# 環境変数
export LESS="-igSNRM"

# ローカル設定があれば優先
[[ -e ~/.bashrc.local ]] && . ~/.bashrc.local
