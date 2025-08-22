#!/bin/bash

# Run zsh
echo "上智のサーバーはbashでしかログインできないため、.profileからexec zsh --loginを実行してzshに切り替えている。"
echo "bashにログインするには、.profile中のexec zsh --loginをコメントアウトしてからexec bash --loginを実行。"
exec zsh --login

# export PATH
if [[ "$PATH" != *"$HOME/.local/bin"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# pagerをbatで
#export PAGER="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

#==================================================================================
# 日本語化
export LC_ALL=ja_JP.UTF-8

#==================================================================================
# WSL2専用: XLaunch(VcXsrv)
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
#  if ! tasklist.exe | grep -q vcxsrv.exe; then
#    "/mnt/c/Program Files/VcXsrv/xlaunch.exe" -run "$HOME/.VcXsrv/config.xlaunch" \
#      >/dev/null 2>&1 &
#  fi
  export LIBGL_ALWAYS_INDIRECT=1
  export GNUTERM=x11
fi

#==================================================================================
# 対話的ログインシェルなら ~/.bashrc も読む
if [[ $- == *i* ]]; then
  [[ -f $HOME/.bashrc ]] && source $HOME/.bashrc
fi

#==================================================================================
fastfetch
