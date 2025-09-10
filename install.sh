#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/packages"
BACKUP_DIR="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DOTFILES_DIR/backup"
mkdir -p "$BACKUP_DIR"
LOG_FILE="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S).log"
# ログ関数
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}
error() {
  log "❌ ERROR: $1"
  exit 1
}
success() {
  log "✅ $1"
}
info() {
  log "ℹ️ $1"
}

#========================================================================
# aptパッケージ導入
apt_install() {
  sudo apt update && sudo apt upgrade -y
  if [[ ! -f "$PACKAGES_DIR/apt.list" ]]; then
    error "apt package list not found: $PACKAGES_DIR/apt.list"
  fi
  local package_array=()
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    local pkg
    pkg=$(echo "$line" | xargs)
    [[ -n "$pkg" ]] && package_array+=("$pkg")
  done < "$PACKAGES_DIR/apt.list"
  if [[ ${#package_array[@]} -gt 0 ]]; then
    for pkg in "${package_array[@]}"; do
      if sudo apt install -y "$pkg"; then
        success "Installed: $pkg"
      else
        error "Failed to install: $pkg"
      fi
    done
  else
    info "No apt packages to install"
  fi
}

# npmパッケージ導入
npm_install() {
  if ! command -v npm >/dev/null 2>&1; then
    error "npm not found. Please install Node.js first."
  fi
  if [[ ! -f "$PACKAGES_DIR/npm.list" ]]; then
    error "npm package list not found: $PACKAGES_DIR/npm.list"
  fi
  local package_array=()
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    local pkg
    pkg=$(echo "$line" | xargs)
    [[ -n "$pkg" ]] && package_array+=("$pkg")
  done < "$PACKAGES_DIR/npm.list"
  if [[ ${#package_array[@]} -gt 0 ]]; then
    for pkg in "${package_array[@]}"; do
      if sudo npm install -g "$pkg"; then
        success "Installed: $pkg"
      else
        error "Failed to install: $pkg"
      fi
    done
  else
    info "No npm packages to install"
  fi
}

#========================================================================
# Additional tools
ARCH="x86_64-unknown-linux-musl"
OS="linux"
BIN_DIR="$HOME/.local/bin"
TMP_DIR="$(mktemp -d)"
ARCHIVE_DIR="$TMP_DIR/archive"
UNPACK_DIR="$TMP_DIR/unpack"
mkdir -p "$BIN_DIR" "$ARCHIVE_DIR" "$UNPACK_DIR"

TOOLS=(
  "bat|sharkdp/bat|bat --version|bat|bat-v{VERSION}-${ARCH}.tar.gz"
  "bottom|ClementTsang/bottom|btm --version|btm|bottom_${ARCH}.tar.gz"
  "delta|dandavison/delta|delta --version|delta|delta-{VERSION}-${ARCH}.tar.gz"
  "duf|muesli/duf|duf --version|duf|duf_{VERSION}_${OS}_x86_64.tar.gz"
  "dust|bootandy/dust|dust --version|dust|dust-v{VERSION}-${ARCH}.tar.gz"
  "eza|eza-community/eza|eza --version|eza|eza_${ARCH}.tar.gz"
  "fastfetch|fastfetch-cli/fastfetch|fastfetch --version|fastfetch|fastfetch-${OS}-amd64.tar.gz"
  "fd|sharkdp/fd|fd --version|fd|fd-v{VERSION}-${ARCH}.tar.gz"
  "fzf|junegunn/fzf|fzf --version|fzf|fzf-{VERSION}-${OS}_amd64.tar.gz"
  "glow|charmbracelet/glow|glow --version|glow|glow_{VERSION}_Linux_x86_64.tar.gz"
  "hgrep|rhysd/hgrep|hgrep --version|hgrep|hgrep-v{VERSION}-${ARCH}.zip"
  "lazygit|jesseduffield/lazygit|lazygit --version|lazygit|lazygit_{VERSION}_Linux_x86_64.tar.gz"
  "procs|dalance/procs|procs --version|procs|procs-v{VERSION}-x86_64-${OS}.zip"
  "ripgrep|BurntSushi/ripgrep|rg --version|rg|ripgrep-{VERSION}-${ARCH}.tar.gz"
  "rip|nivekuil/rip|rip --version|rip|rip-0.11.4-x86_64-unknown-${OS}-gnu.tar.gz"
  "starship|starship/starship|starship --version|starship|starship-${ARCH}.tar.gz"
  "zoxide|ajeetdsouza/zoxide|zoxide --version|zoxide|zoxide-{VERSION}-${ARCH}.tar.gz"
)
declare -A TOOL_INFO
for entry in "${TOOLS[@]}"; do
  IFS="|" read -r name repo cmd filename pattern <<< "$entry"
  TOOL_INFO["$name.repo"]="$repo"
  TOOL_INFO["$name.cmd"]="$cmd"
  TOOL_INFO["$name.filename"]="$filename"
  TOOL_INFO["$name.pattern"]="$pattern"
  TOOL_INFO["$name.uses_v_prefix"]="true"
  [[ "$name" == "bottom" ]] && TOOL_INFO["$name.uses_v_prefix"]="false"
  [[ "$name" == "delta" ]] && TOOL_INFO["$name.uses_v_prefix"]="false"
  [[ "$name" == "fastfetch" ]] && TOOL_INFO["$name.uses_v_prefix"]="false"
  [[ "$name" == "ripgrep" ]] && TOOL_INFO["$name.uses_v_prefix"]="false"
  [[ "$name" == "rip" ]] && TOOL_INFO["$name.uses_v_prefix"]="false"
done

function get_latest_version() {
  local repo="$1"
  local retries=3
  local version=""
  for ((i=1; i<=retries; i++)); do
    local response
    response=$(curl -sL --connect-timeout 10 "https://api.github.com/repos/$repo/releases/latest")
    if echo "$response" | jq -e '.message | test("API rate limit exceeded")' &>/dev/null; then
      exit 1
    fi
    version=$(echo "$response" | jq -r .tag_name | sed 's/^v//')
    if [[ "$version" != "null" && -n "$version" ]]; then
      echo "$version"
      return 0
    fi
    sleep 2
  done
  return 1
}

function extract_and_install() {
  local name="$1"
  local archive="$2"
  local inner_name="$3"
  local dest="$4"
  \rm -rf "${UNPACK_DIR:?}"/*
  if [[ "$archive" == *.tar.gz ]]; then
    tar -xzf "$archive" -C "$UNPACK_DIR" || return 1
  elif [[ "$archive" == *.zip ]]; then
    unzip -q "$archive" -d "$UNPACK_DIR" || return 1
  else
    error "Unknown archive format: $archive"
    return 1
  fi
  local newbin
  newbin=$(find "$UNPACK_DIR" -type f -name "$inner_name" | head -n1)
  if [[ ! -x "$newbin" ]]; then
    chmod +x "$newbin" 2>/dev/null || true
    [[ ! -x "$newbin" ]] && error "Failed to find or extract $inner_name" && return 1
  fi
  [[ -f "$dest/$inner_name" ]] && \cp "$dest/$inner_name" "$BACKUP_DIR/${inner_name}.bak.$(date +%s)" || true
  \cp "$newbin" "$dest/$inner_name" && chmod +x "$dest/$inner_name"
}

function process_tool() {
  local repo="${TOOL_INFO["$name.repo"]}"
  local filename="${TOOL_INFO["$name.filename"]}"
  local file_pattern="${TOOL_INFO["$name.pattern"]}"
  local uses_v_prefix="${TOOL_INFO["$name.uses_v_prefix"]}"
  latest_ver=$(get_latest_version "$repo") || return 1
  local file="${file_pattern/\{VERSION\}/$latest_ver}"
  local vprefix=""
  [[ "$uses_v_prefix" == "true" ]] && vprefix="v"
  if [[ "$name" == "rip" ]]; then latest_ver=0.11.4; fi
  local url="https://github.com/$repo/releases/download/${vprefix}${latest_ver}/$file"
  local archive="$ARCHIVE_DIR/$file"
  info "Downloading: $name from $url"
  if ! curl -L --connect-timeout 30 --retry 3 "$url" -o "$archive"; then
    error "Failed to download $name"
    return 1
  fi
  if extract_and_install "$name" "$archive" "$filename" "$BIN_DIR"; then
    if "$BIN_DIR/$filename" --version &>/dev/null; then
      success "Installed: $name"
    else
      error "Failed to install: $name"
    fi
  fi
}
function tools_install() {
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r name _ _ _ <<< "$entry"
    process_tool "$name"
  done
  \rm -rf "$TMP_DIR"
}

#========================================================================
# シンボリックリンク作成
declare -A symlink_targets=(
  [".bashrc"]="$DOTFILES_DIR/shell/.bashrc"
  [".profile"]="$DOTFILES_DIR/shell/.profile"
  [".zshrc"]="$DOTFILES_DIR/shell/.zshrc"
  [".zprofile"]="$DOTFILES_DIR/shell/.zprofile"
  [".gitconfig"]="$DOTFILES_DIR/git/.gitconfig"
  [".gitignore_global"]="$DOTFILES_DIR/git/.gitignore_global"
  [".ssh/config"]="$DOTFILES_DIR/ssh/config"
  [".vscode/settings.json"]="$DOTFILES_DIR/editors/vscode/settings.json"
  [".vscode/extensions.json"]="$DOTFILES_DIR/editors/vscode/extensions.json"
  [".vscode/keybindings.json"]="$DOTFILES_DIR/editors/vscode/keybindings.json"
  [".emacs.d/init.el"]="$DOTFILES_DIR/editors/emacs/init.el"
  [".latexmkrc"]="$DOTFILES_DIR/tex/.latexmkrc"
  [".config/starship.toml"]="$DOTFILES_DIR/config/starship.toml"
  [".config/lazygit/config.yml"]="$DOTFILES_DIR/config/lazygit/config.yml"
)

symlink_backup() {
  for name in "${!symlink_targets[@]}"; do
    local src="$HOME/$name"
    if [[ -L "$src" ]]; then
      continue
    fi
    if [[ -f "$src" ]]; then
      local backup_path="$BACKUP_DIR/$name"
      if ! mkdir -p "$(dirname "$backup_path")"; then
        error "Failed to create directory for backup: $(dirname "$backup_path")"
      fi
      if \cp "$src" "$backup_path"; then
        success "Backed up file: $name"
      else
        error "Failed to backup file: $name"
      fi
    elif [[ -d "$src" ]]; then
      local backup_path="$BACKUP_DIR/$name"
      if ! mkdir -p "$(dirname "$backup_path")"; then
        error "Failed to create directory for backup: $(dirname "$backup_path")"
      fi
      if \cp -r "$src" "$backup_path"; then
        success "Backed up directory: $name"
      else
        error "Failed to backup directory: $name"
      fi
    fi
  done
}

symlink_create() {
  for name in "${!symlink_targets[@]}"; do
    local link_path="$HOME/$name"
    local target_path="${symlink_targets[$name]}"
    # 親ディレクトリが存在しない場合は作成する
    local link_dir
    link_dir="$(dirname "$link_path")"
    if [[ ! -d "$link_dir" ]]; then
      if ! mkdir -p "$link_dir"; then
        error "Failed to create parent directory: $link_dir (required for $link_path)"
      fi
    fi
    if [[ -e "$link_path" || -L "$link_path" ]]; then
      if ! \rm -rf "$link_path"; then
        error "Failed to remove existing: $link_path"
      fi
    fi
    if ln -s "$target_path" "$link_path"; then
      success "Created symlink: $link_path -> $target_path"
    else
      error "Failed to create symlink: $link_path -> $target_path"
    fi
  done
}

#========================================================================
# zsh plugins
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

zshplugins_install() {
  # zsh-completions
  local ZSH_COMPLETIONS_DIR="$ZSH_PLUGIN_DIR/zsh-completions"
  if [ ! -d "$ZSH_COMPLETIONS_DIR" ]; then
    if git clone https://github.com/zsh-users/zsh-completions "$ZSH_COMPLETIONS_DIR"; then
      success "Installed zsh-completions"
    else
      error "Failed to install zsh-completions"
    fi
  fi
  # zsh completion using fzf
  local FZF_TAB_COMPLETION_DIR="$ZSH_PLUGIN_DIR/fzf-tab-completion"
  if [ ! -f "$FZF_TAB_COMPLETION_DIR/zsh/fzf-zsh-completion.sh" ]; then
    if git clone https://github.com/lincheney/fzf-tab-completion.git "$FZF_TAB_COMPLETION_DIR"; then
      success "Installed fzf-tab-completion"
      \rm -rf "$FZF_TAB_COMPLETION_DIR/.git"
    else
      error "Failed to install fzf-tab-completion"
    fi
  fi
  # zsh-ssh
  local ZSH_SSH_DIR="$ZSH_PLUGIN_DIR/zsh-ssh"
  if [ ! -d "$ZSH_SSH_DIR" ]; then
    if git clone https://github.com/sunlei/zsh-ssh "$ZSH_SSH_DIR"; then
      success "Installed zsh-ssh"
    else
      error "Failed to install zsh-ssh"
    fi
  fi
  # zsh-autosuggestions
  local ZSH_AUTOSUGGESTIONS_DIR="$ZSH_PLUGIN_DIR/zsh-autosuggestions"
  if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    if git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"; then
      success "Installed zsh-autosuggestions"
    else
      error "Failed to install zsh-autosuggestions"
    fi
  fi
  # zsh-syntax-highlighting
  #local ZSH_HIGHLIGHT_DIR="$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
  #if [ ! -d "$ZSH_HIGHLIGHT_DIR" ]; then
  #  if git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_HIGHLIGHT_DIR"; then
  #    success "Installed zsh-syntax-highlighting"
  #  else
  #    error "Failed to install zsh-syntax-highlighting"
  #  fi
  #fi
  # fast-syntax-highlighting
  local FAST_HIGHLIGHTING_DIR="$ZSH_PLUGIN_DIR/fast-syntax-highlighting"
  if [ ! -d "$FAST_HIGHLIGHTING_DIR" ]; then
    if git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$FAST_HIGHLIGHTING_DIR"; then
      success "Installed fast-syntax-highlighting"
    else
      error "Failed to install fast-syntax-highlighting"
    fi
  fi
  # print-alias
  local PRINT_ALIAS_DIR="$ZSH_PLUGIN_DIR/print-alias"
  if [ ! -d "$PRINT_ALIAS_DIR" ]; then
    if git clone https://github.com/brymck/print-alias "$PRINT_ALIAS_DIR"; then
      success "Installed print-alias"
    else
      error "Failed to install print-alias"
    fi
  fi
  # dirhistory plugin (Oh My Zsh)
  local DIRHISTORY_PLUGIN_DIR="$ZSH_PLUGIN_DIR/dirhistory"
  if [ ! -d "$DIRHISTORY_PLUGIN_DIR" ]; then
    mkdir -p "$DIRHISTORY_PLUGIN_DIR"
    if curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/dirhistory/dirhistory.plugin.zsh -o "$DIRHISTORY_PLUGIN_DIR/dirhistory.plugin.zsh"; then
      success "Installed dirhistory plugin"
    else
      error "Failed to install dirhistory plugin"
    fi
  fi
}

#========================================================================
# Change default shell to zsh
zsh_default_shell() {
  if [[ "$SHELL" != *"zsh"* ]]; then
    local zsh_path
    if [[ -x "/bin/zsh" ]]; then
      zsh_path="/bin/zsh"
    elif [[ -x "$HOME/.local/bin/zsh" ]]; then
      zsh_path="$HOME/.local/bin/zsh"
    elif [[ -x "/usr/bin/zsh" ]]; then
      zsh_path="/usr/bin/zsh"
    else
      error "Zsh not found in expected locations"
    fi
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    sudo chsh -s "$zsh_path"
    success "Default shell changed to: $zsh_path"
  else
    info "Zsh is already the default shell"
  fi
}

#========================================================================


# サーバー判定関数
is_special_server() {
  # $HOSTNAMEがnoether/besselならtrue
  if [[ "${HOSTNAME:-}" == "noether" || "${HOSTNAME:-}" == "bessel" ]]; then
    return 0
  fi
  # $HOSTNAMEが未定義または空文字ならhostnameコマンドで判定
  local hname
  hname=$(hostname)
  if [[ "$hname" == "neumann" || "$hname" == "landau" ]]; then
    return 0
  fi
  return 1
}

# main関数
main() {
  echo ""
  echo "This script will:"
  if is_special_server; then
    echo "  - Install custom tools"
    echo "  - Create symbolic links for configuration files (backup included)"
    echo "  - Install Zsh plugins"
  else
    echo "  - Install apt packages from $PACKAGES_DIR/apt.list"
    echo "  - Install npm packages from $PACKAGES_DIR/npm.list"
    echo "  - Install custom tools"
    echo "  - Create symbolic links for configuration files"
    echo "  - Install Zsh plugins"
    echo "  - Change default shell to Zsh"
    echo "  - Start Zsh"
  fi
  echo ""
  read -p "Continue? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Installation cancelled"
    exit 0
  fi
  # サーバーの場合はsudo認証をスキップ
  if ! is_special_server; then
    if sudo -v; then
      success "sudo authentication succeeded"
    fi
  fi
  echo ""
  log "=== dotfiles installation started ==="
  info "Dotfiles directory: $DOTFILES_DIR"
  if is_special_server; then
    log "=== Installing useful tools ==="
    tools_install
    log "=== Creating symlinks (special server mode) ==="
    symlink_backup
    symlink_create
    log "=== Installing zsh plugins (special server mode) ==="
    zshplugins_install
    log "=== dotfiles installation completed (special server mode) ==="
    info "Backup created at: $BACKUP_DIR"
    info "Log file: $LOG_FILE"
    echo ""
    return 0
  fi
  # 通常モード
  log "=== Installing packages ==="
  apt_install
  npm_install
  log "=== Installing additional tools ==="
  tools_install
  log "=== Creating symlinks ==="
  symlink_backup
  symlink_create
  log "=== Installing zsh plugins ==="
  zshplugins_install
  log "=== Change default shell to Zsh ==="
  zsh_default_shell
  log "=== dotfiles installation completed ==="
  info "Backup created at: $BACKUP_DIR"
  info "Log file: $LOG_FILE"
  echo ""
  if [[ $SHELL != *zsh* ]]; then
    exec zsh --login
  else
    source "$HOME/.zprofile"
  fi
}

# スクリプト実行
main "$@"
