#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable color support
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# pagerをbatで
#export PAGER="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

#==================================================================================
# shell options of bash
shopt -s autocd
shopt -s cdspell
shopt -s histappend
shopt -s expand_aliases

#==================================================================================
# PATHを通す
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
  fi
fi

#==================================================================================
# 日本語化
export LC_ALL=ja_JP.UTF-8

#==================================================================================
# XLaunch(VcXsrv)
if ! tasklist.exe | grep vcxsrv.exe >/dev/null; then
  "/mnt/c/Program Files/VcXsrv/xlaunch.exe" -run "$HOME/.VcXsrv/config.xlaunch" \
    >/dev/null 2>&1 &
fi
#export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
export LIBGL_ALWAYS_INDIRECT=1
export GNUTERM=x11

#==================================================================================
# prompt
eval "$(starship init bash)"

#==================================================================================
# fuzzy finder (fzf)
export FZF_DEFAULT_COMMAND='fd --type f --follow -I --exclude .git'
export FZF_DEFAULT_OPTS="--exit-0 --height 50% --border --preview-window=right:50% \
  --style=full:double --no-header-border \
  --input-label ' Search ' --preview-label ' Preview ' \
  --color 'input-border:#996666,input-label:#ffcccc' \
  --color 'list-border:#669966,list-label:#99cc99,header:#99cc99' \
  --color 'preview-border:#9999cc,preview-label:#ccccff'"
export FZF_ALT_C_OPTS="--preview 'eza -T -L 1 --icons --color=always {}'"
export FZF_COMPLETION_OPTS='--border=none --style=minimal --info=hidden'
eval "$(fzf --bash)"

# bash completion using fzf
if [ ! -f ~/.local/fzf-tab-completion/bash/fzf-bash-completion.sh ]; then
  git clone https://github.com/lincheney/fzf-tab-completion.git ~/.local/fzf-tab-completion
  cd ~/.local/fzf-tab-completion || exit
  rm -f .git
  cd ~ || exit
  echo -e "\033[31mRewrite ~/.local/fzf-tab-completion/bash/fzf-bash-completion.sh : ps -> \ps and cat -> \cat\033[0m"
fi
#shellcheck source=https://github.com/lincheney/fzf-tab-completion/blob/master/bash/fzf-bash-completion.sh
source ~/.local/fzf-tab-completion/bash/fzf-bash-completion.sh
export FZF_COMPLETION_AUTO_COMMON_PREFIX=true
export FZF_COMPLETION_AUTO_COMMON_PREFIX_PART=true
bind -x '"\t": fzf_bash_completion'

#==================================================================================
# history setting
export HISTTIMEFORMAT='%F  %T  '
export HISTSIZE=10000
export HISTFILESIZE=50000
export HISTIGNORE='exit:clear:reset:h:history:fk9:ps:jobs:top:du:df:free:pwd:zi:eza:l:ls:la:ll:lt:tree:f:fcd:fdat:flog:ferr:fpng:fpdf:frg'
export HISTCONTROL=ignoreboth:erasedups:ignoredups:ignorespace
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
function h() {
  local query="${1:-}"
  local selected
  local saved_stty
  saved_stty=$(stty -g)
  selected=$(history | fzf -m --tac --list-label ' History ' --preview-window=right:0% -q "$query")
  if [ -n "$selected" ]; then
    stty sane
    while IFS= read -r line; do
      local cmd
      cmd=$(echo "$line" | awk '{for (i=4; i<=NF; i++) printf "%s ", $i; print ""}')
      echo -e "\033[32m❯\033[0m $cmd"
      if [ -t 1 ]; then
        eval "$cmd" </dev/tty || break
      else
        eval "$cmd" || break
      fi
      history -s "$cmd"
    done <<<"$selected"
  fi
  stty "$saved_stty"
}
bind -x '"\C-r": "h"'

#==================================================================================
# Others

alias open='explorer.exe .'
alias clip='clip.exe'

alias aptupd='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

function help() {
  if [ "$#" -eq 0 ]; then
    echo -e "\033[31mError: No arguments provided. Please specify a command.\033[0m" >&2
    return 1
  fi
  "$@" --help 2>&1 | bat --plain --language=help
}

alias htop='htop -t -u $USER'
alias top='htop'
alias ps='ps au | (head -n 1 && ps au | tail -n +2 | rg $USER | rg --invert-match "ps au|tail|rg|-bash|vscode|dbus")'
alias k9='kill -9'
function fk9() {
  local query="${1:-}"
  local pid
  pid=$(ps | rg --invert-match "fzf|awk" | fzf --tac --header-lines=1 -m -q "$query" | awk '{print $2}')
  if [ -n "$pid" ]; then
    kill -9 $pid
  fi
}

alias du='dust -ri'
alias df='duf'
alias free='free -mh'

alias chmod='chmod -v'
alias chown='chown --verbose'
alias chgrp='chgrp --verbose'

function back(){
  local target
  target=$(cd - || exit)
  if [ -n "$target" ]; then
    echo -e "\033[32m❯\033[0m cd $target"
    cd "$target" || return 1
    history -s "cd $target"
  fi
}
alias ..='cd ..'
alias .1='cd ..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
function fcd() {
  local query="${1:-}"
  local selected
  selected=$(fd -t d --follow -I --exclude .git . $HOME | fzf --reverse --preview 'eza -T -L 1 --icons --color=always {}' -q "$query")
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m cd $selected"
    cd "$selected" || return 1
    history -s "cd $selected"
  fi
}
eval "$(zoxide init bash --hook pwd)"
function zi_1() {
  local selected
  selected=$(zoxide query -l | fzf --reverse --preview "eza -T -L 1 --icons --color=always {}")
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m cd $selected"
    cd "$selected" || return 1
    history -s "cd $selected"
  fi
}
alias zi='zi_1'

alias rip='rip --graveyard ~/.local/share/Trash'
function rm_1() {
  local args=()
  for arg in "$@"; do
    if [ "$arg" != "-f" ]; then
      args+=("$arg")
    fi
  done
  if [[ " $* " == *" -f "* ]]; then
    rip "${args[@]}"
  else
    rip -i "${args[@]}"
  fi
}
alias rm='rm_1'
function unrm() {
  local query="${1:-}"
  local selected
  selected=$(rip -s | fzf --reverse --tac -m -q "$query")
  if [ -n "$selected" ]; then
    while IFS= read -r file; do
      echo -e "\033[32m❯\033[0m rip -u $file"
      rip -u "$file"
      history -s "rip -u $file"
    done <<<"$selected"
  fi
}

alias mv='mv -i'
alias cp='cp -i'
alias mkdir='mkdir -pv'

alias eza='eza --git --time-style long-iso --no-user --icons'
alias ls='eza'
alias la='eza -a'
alias ll='eza -lh'
alias lt='eza -lh -s modified'
alias tree='eza -T'

export BAT_THEME="Visual Studio Dark+"
alias less='bat'
alias cat='bat -pp -f'
alias glow='glow --pager'
alias diff='delta'

function l() {
  if [ $# -eq 0 ] || [ -d "$1" ]; then
    ls "$@"
  else
    less "$@"
  fi
}

function f() {
  local query="${1:-}"
  local result
  result=$(fd --follow -I --exclude .git | fzf --reverse -q "$query")
  [ -z "$result" ] && return
  if [ -d "$result" ]; then
    echo -e "\033[34m$result\033[0m"
    ls "$result"
    history -s "eza $result"
  elif [ -f "$result" ]; then
    less "$result"
    history -s "less $result"
  else
    echo "$result"
  fi
}
function fdat() {
  local query="${1:-}"
  local selected
  selected=$(fd -e dat --follow -I --exclude .git | fzf --reverse -q "$query" --preview 'bat --color=always --style=header --line-range 0:100 {}')
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m less $selected"
    less "$selected"
    history -s "less $selected"
  fi
}
function flog() {
  local query="${1:-}"
  local selected
  selected=$(fd -e log --follow -I --exclude .git | fzf --reverse -q "$query" --preview 'bat --color=always --style=header --line-range 0:100 {}')
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m less $selected"
    less "$selected"
    history -s "less $selected"
  fi
}
function ferr() {
  local query="${1:-}"
  local selected
  selected=$(fd -e err --follow -I --exclude .git | fzf --reverse -q "$query" --preview 'bat --color=always --style=header --line-range 0:100 {}')
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m less $selected"
    less "$selected"
    history -s "less $selected"
  fi
}
alias eog='eog &>/dev/null'
function fpng() {
  local query="${1:-}"
  local selected
  selected=$(fd -e png --follow -I --exclude .git | fzf --reverse -m -q "$query")
  if [ -n "$selected" ]; then
    while IFS= read -r file; do
      echo -e "\033[32m❯\033[0m eog $file &"
      eog "$file" &
      history -s "eog $file &"
    done <<<"$selected"
  fi
}
function fpdf() {
  local query="${1:-}"
  local selected
  selected=$(fd -e pdf --follow -I --exclude .git | fzf --reverse -m -q "$query")
  if [ -n "$selected" ]; then
    while IFS= read -r file; do
      echo -e "\033[32m❯\033[0m evince $file &"
      evince "$file" &
      history -s "evince $file &"
    done <<<"$selected"
  fi
}

alias grep='rg --color=auto --line-number'
alias fgrep='rg --fixed-strings --color=auto'
alias egrep='rg --extended-regexp --color=auto'
export HGREP_DEFAULT_OPTS='--theme "Visual Studio Dark+"'
alias hrg='hgrep'
function frg() {
  local rg_cmd="rg --smart-case --line-number --color=always --trim"
  local pattern="${1:-.}"
  local selected prev_filepath="" filepath line_number line_content
  selected=$($rg_cmd "$pattern" | FZF_DEFAULT_COMMAND=":" \
    fzf --bind="change:top+reload($rg_cmd {q} || true)" \
    --reverse -m \
    --ansi --phony \
    --delimiter=":")
  if [[ -n "$selected" ]]; then
    while IFS= read -r item; do
      filepath=$(echo "$item" | cut -d: -f1)
      line_number=$(echo "$item" | cut -d: -f2)
      line_content=$(echo "$item" | cut -d: -f3-)
      if [[ "$filepath" != "$prev_filepath" ]]; then
        echo -e "\n\033[35m$filepath\033[0m"
        prev_filepath="$filepath"
      fi
      printf '\033[32m%s\033[0m:' "$line_number"
      printf '%s\n' "$line_content"
    done <<<"$selected"
    printf "\n"
  fi
}

# editor
export EDITOR=code
function c() {
  command code "$@" &
}
function e() {
  if [[ "$1" == "-nw" ]]; then
    shift
    command emacs -nw "$@"
  else
    command emacs "$@" &
  fi
}

# git
if [ ! -f ~/.git-completion.sh ]; then
  curl -o .git-completion.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash >/dev/null 2>&1
fi
#shellcheck source=https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
source ~/.git-completion.sh
alias g='git'
alias gs='git status'
alias ga='git add'
function fga() {
  addfiles=$(git status --short |
    awk '{if (substr($0,2,1) !~ / /) print $2}' |
    fzf --reverse -m --preview 'git diff --color=always {1}')
  if [[ -n "$addfiles" ]]; then
    while IFS= read -r file; do
      echo -e "\033[32m❯\033[0m git add $file"
      git add "$file"
      history -s "git add $file"
    done <<<"$addfiles"
  fi
}
alias gc='git commit'
alias gp='git push'
alias gl='git log --decorate --color --graph --all --name-status --date=short \
--pretty=format:"%C(red)%h%C(yellow)%d%n%C(magenta)%ad %C(green)%an%n%C(blue)%s %C(reset)"'
alias gd='git diff'

# ssh & sftp
function ssh_connect() {
  ssh -l kuroki -Y $1.sn.sophia.ac.jp
}
alias neumann='ssh_connect neumann'
alias bessel='ssh_connect bessel'
alias noether='ssh_connect noether'
alias landau='ssh_connect landau'
function sftp() {
  local servers=("landau" "neumann" "bessel" "noether")
  local server_found=false
  for server in "${servers[@]}"; do
    if [[ "$server" == "$1" ]]; then
      server_found=true
      break
    fi
  done
  if [ "$server_found" = true ]; then
    command sftp kuroki@$1.sn.sophia.ac.jp
  else
    command sftp "$@"
  fi
}
