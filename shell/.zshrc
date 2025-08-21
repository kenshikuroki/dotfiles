# ~/.zshrc
# シェルガード
[ -n "$ZSH_VERSION" ] || return

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# $SHELLの設定
if [ -x "$HOME/.local/bin/zsh" ]; then
  export SHELL="$HOME/.local/bin/zsh"
else
  export SHELL="/bin/zsh"
fi

# enable color support
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

#=================================================================================
# shell options of zsh
setopt menucomplete # 補完メニューを表示
setopt list_types # 候補にファイルの種別を表示
setopt auto_list # 補完候補を自動的にリスト表示
setopt auto_menu # 補完キー（Tab）連打で補完を順に表示
setopt auto_cd # cdコマンドの保管
setopt cdable_vars # cdコマンドの引数に変数を使えるようにする
setopt auto_pushd # cdコマンドでディレクトリをスタックに追加
setopt pushd_ignore_dups # pushdコマンドの重複を無視
setopt pushd_silent # pushdコマンドの出力を抑制
setopt auto_param_keys # カッコなどを補完
setopt correct_all # typoを検出
setopt extended_history # historyにタイムスタンプも記録する
setopt hist_ignore_dups # historyの連続を削除
setopt hist_save_no_dups # historyの重複を保存しない
setopt hist_reduce_blanks # historyの余分な空白削除
setopt share_history # historyを共有する
setopt extended_glob # 拡張グロブを有効化
setopt no_beep # ビープ音を消す
setopt interactive_comments # 対話モードでもコメントを

#==================================================================================
# prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"
TRAPINT() {
  print -n "\n\033[31m⚠️ Command cancelled by Ctrl-C.\033[0m"
  return 130
}

#===================================================================================
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
source <(fzf --zsh)

#==================================================================================
# プラグインの格納ディレクトリ
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

# zsh-completions
ZSH_COMPLETIONS_DIR="$ZSH_PLUGIN_DIR/zsh-completions"
fpath+="$ZSH_COMPLETIONS_DIR/src"

autoload -Uz compinit
compinit

# zsh completion using fzf
local FZF_TAB_COMPLETION_DIR="$ZSH_PLUGIN_DIR/fzf-tab-completion"
source "$FZF_TAB_COMPLETION_DIR/zsh/fzf-zsh-completion.sh"
export FZF_COMPLETION_AUTO_COMMON_PREFIX=true
export FZF_COMPLETION_AUTO_COMMON_PREFIX_PART=true
bindkey '^I' fzf_completion

# zsh-ssh
ZSH_SSH_DIR="$ZSH_PLUGIN_DIR/zsh-ssh"
source "$ZSH_SSH_DIR/zsh-ssh.zsh"

# zsh-autosuggestions
ZSH_AUTOSUGGESTIONS_DIR="$ZSH_PLUGIN_DIR/zsh-autosuggestions"
source "$ZSH_AUTOSUGGESTIONS_DIR/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# zsh-syntax-highlighting
#ZSH_HIGHLIGHT_DIR="$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
#source "$ZSH_HIGHLIGHT_DIR/zsh-syntax-highlighting.zsh"
#ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets pattern)

# fast-syntax-highlighting
FAST_HIGHLIGHTING_DIR="$ZSH_PLUGIN_DIR/fast-syntax-highlighting"
source "$FAST_HIGHLIGHTING_DIR/fast-syntax-highlighting.plugin.zsh"

# print-alias
PRINT_ALIAS_DIR="$ZSH_PLUGIN_DIR/print-alias"
source "$PRINT_ALIAS_DIR/print-alias.plugin.zsh"
export PRINT_ALIAS_PREFIX=$'\e[1;32m  ╰─> \e[0m'
export PRINT_ALIAS_FORMAT=$'\e[32m'
export PRINT_NON_ALIAS_FORMAT=$'\e[0m'
export PRINT_ALIAS_IGNORE_REDEFINED_COMMANDS=false

# dirhistory plugin (Oh My Zsh)
DIRHISTORY_PLUGIN_DIR="$ZSH_PLUGIN_DIR/dirhistory"
source "$DIRHISTORY_PLUGIN_DIR/dirhistory.plugin.zsh"
# オリジナルの関数をラップして出力と履歴記録を追加
function dirhistory_back_enhanced() {
  zle kill-buffer
  local old_pwd="$PWD"
  dirhistory_back
  if [[ "$PWD" != "$old_pwd" ]]; then
    printf '\n\033[32m❯ cd\033[0m \033[35;4m%s\033[0m\n' "$PWD" >&2
    print -s "cd $PWD"
    zle accept-line
  fi
}
function dirhistory_forward_enhanced() {
  zle kill-buffer
  local old_pwd="$PWD"
  dirhistory_forward
  if [[ "$PWD" != "$old_pwd" ]]; then
    printf '\n\033[32m❯ cd\033[0m \033[35;4m%s\033[0m\n' "$PWD" >&2
    print -s "cd $PWD"
    zle accept-line
  fi
}
function dirhistory_up_enhanced() {
  zle kill-buffer
  local old_pwd="$PWD"
  dirhistory_up
  if [[ "$PWD" != "$old_pwd" ]]; then
    printf '\n\033[32m❯ cd\033[0m \033[35;4m%s\033[0m\n' "$PWD" >&2
    print -s "cd $PWD"
    zle accept-line
  fi
}
function dirhistory_down_disabled() {
  return
}
zle -N dirhistory_back_enhanced
zle -N dirhistory_forward_enhanced
zle -N dirhistory_up_enhanced
zle -N dirhistory_down_disabled
bindkey '^[[1;3D' dirhistory_back_enhanced    # Alt+Left
bindkey '^[[1;3C' dirhistory_forward_enhanced # Alt+Right
bindkey '^[[1;3A' dirhistory_up_enhanced      # Alt+Up
bindkey '^[[1;3B' dirhistory_down_disabled    # Alt+Down (無効化)

#==================================================================================
# history settings for Zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=50000
HISTTIMEFORMAT="%F  %T  "
# 複数条件の履歴無視
function zshaddhistory() {
  emulate -L zsh
  local line=${1%%$'\n'}
  [[ $line =~ ^(exit|clear|reset|pwd|date|whoami|history)$ ]] && return 1
  [[ $line =~ ^(ls|ll|la|lt|eza|tree)(\s.*)?$ ]] && return 1
  [[ $line =~ ^(ps|top|htop|du|df|free|jobs)(\s.*)?$ ]] && return 1
  [[ $line =~ ^(fcd|back|zi|zi_1|l|unrm|fk9|f|fdat|flog|ferr|fpng|fpdf|fga)(\s.*)?$ ]] && return 1
  return 0
}
# fzf-based history search function
function h-widget() {
  local selected cmd
  zle -I
  selected=$(fc -il 1 | fzf --tac --list-label=' History ' --preview-window=right:0%)
  if [[ -n "$selected" ]]; then
    cmd=$(echo "$selected" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}[[:space:]]+//')
    if [[ -n "$cmd" ]]; then
      BUFFER="$cmd"
      CURSOR=${#BUFFER}
    fi
  fi
  zle reset-prompt
}
zle -N h-widget
bindkey '^R' h-widget

#==================================================================================
# Others

if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  alias open='explorer.exe .'
  alias clip='clip.exe'
  alias aptupd='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
fi

function help() {
  if [ "$#" -eq 0 ]; then
    echo -e "\033[31mError: No arguments provided. Please specify a command.\033[0m" >&2
    return 1
  fi
  "$@" --help 2>&1 | bat --plain --language=help
}

alias htop='htop -t -u $USER'
alias top='htop'
alias ps='ps au | (head -n 1 && ps au | tail -n +2 | rg $USER | rg --invert-match "ps au|tail|rg|-bash|zsh|vscode|dbus")'
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

alias cds='dirs -v; echo -n "select number: "; read newdir; cd +"$newdir"'
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
    print -s "cd $selected"
  fi
}
eval "$(zoxide init zsh)"
function zi_1() {
  local selected
  selected=$(zoxide query -l | fzf --reverse --preview "eza -T -L 1 --icons --color=always {}")
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m cd $selected"
    cd "$selected" || return 1
    print -s "cd $selected"
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
      print -s "rip -u $file"
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
    print -s "eza $result"
  elif [ -f "$result" ]; then
    less "$result"
    print -s "less $result"
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
    print -s "less $selected"
  fi
}
function flog() {
  local query="${1:-}"
  local selected
  selected=$(fd -e log --follow -I --exclude .git | fzf --reverse -q "$query" --preview 'bat --color=always --style=header --line-range 0:100 {}')
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m less $selected"
    less "$selected"
    print -s "less $selected"
  fi
}
function ferr() {
  local query="${1:-}"
  local selected
  selected=$(fd -e err --follow -I --exclude .git | fzf --reverse -q "$query" --preview 'bat --color=always --style=header --line-range 0:100 {}')
  if [ -n "$selected" ]; then
    echo -e "\033[32m❯\033[0m less $selected"
    less "$selected"
    print -s "less $selected"
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
      print -s "eog $file &"
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
      print -s "evince $file &"
    done <<<"$selected"
  fi
}

alias grep='rg --color=auto --line-number'
alias fgrep='rg --fixed-strings --color=auto'
alias egrep='rg --extended-regexp --color=auto'
export HGREP_DEFAULT_OPTS='--theme "Visual Studio Dark+"'
alias hrg='hgrep'
function frg() {
  local pattern="${1:-.}"
  local selected prev_filepath filepath line_number line_content
  selected=$(fzf --bind="change:top+reload:rg --smart-case --line-number --color=always --trim {q} || true" \
                  --reverse -m \
                  --ansi --phony \
                  --delimiter=":" \
                  --prompt="RG> ")
  if [[ -n "$selected" ]]; then
    while IFS= read -r item; do
      filepath=${item%%:*}
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
alias g='git'
alias lg='lazygit'
function fga() {
  addfiles=$(git status --short |
    awk '{if (substr($0,2,1) !~ / /) print $2}' |
    fzf --reverse -m --preview 'git diff --color=always {1}')
  if [[ -n "$addfiles" ]]; then
    while IFS= read -r file; do
      echo -e "\033[32m❯\033[0m git add $file"
      git add "$file"
      print -s "git add $file"
    done <<<"$addfiles"
  fi
}
alias proot='cd $(git rev-parse --show-toplevel)'

# ssh
alias neumann='ssh neumann'
alias landau='ssh landau'
alias noether='ssh noether'
alias bessel='ssh bessel'
