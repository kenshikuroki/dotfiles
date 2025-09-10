#!/usr/bin/env bash
set -euo pipefail

# --- サーバー判定関数 ---
is_special_server() {
  if [[ "${HOSTNAME:-}" == "noether" || "${HOSTNAME:-}" == "bessel" ]]; then
    return 0
  fi
  local hname
  hname=$(hostname)
  if [[ "$hname" == "neumann" || "$hname" == "landau" ]]; then
    return 0
  fi
  return 1
}

# --- 基本設定 ---
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$BIN_DIR/backup"
TMP_DIR="$(mktemp -d)"
ARCHIVE_DIR="$TMP_DIR/archive"
UNPACK_DIR="$TMP_DIR/unpack"
ARCH="x86_64-unknown-linux-musl"
OS="linux"
LOG_FILE="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S)_update.log"

mkdir -p "$BACKUP_DIR" "$ARCHIVE_DIR" "$UNPACK_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# --- 引数処理 ---
SELECTED_TOOLS=()
UPDATE_APT=true
UPDATE_NPM=true
UPDATE_BINARIES=true
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)
      SELECTED_TOOLS+=("$2")
      UPDATE_APT=false
      UPDATE_NPM=false
      shift 2
      ;;
    --apt-only)
      UPDATE_APT=true
      UPDATE_NPM=false
      UPDATE_BINARIES=false
      shift
      ;;
    --npm-only)
      UPDATE_APT=false
      UPDATE_NPM=true
      UPDATE_BINARIES=false
      shift
      ;;
    --binaries-only)
      UPDATE_APT=false
      UPDATE_NPM=false
      UPDATE_BINARIES=true
      shift
      ;;
    --skip-apt)
      UPDATE_APT=false
      shift
      ;;
    --skip-npm)
      UPDATE_NPM=false
      shift
      ;;
    --skip-binaries)
      UPDATE_BINARIES=false
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --tool TOOL_NAME      Update specific binary tool only"
      echo "  --apt-only            Update only apt packages"
      echo "  --npm-only            Update only npm packages"
      echo "  --binaries-only       Update only binary tools"
      echo "  --skip-apt            Skip apt package updates"
      echo "  --skip-npm            Skip npm package updates"
      echo "  --skip-binaries       Skip binary tool updates"
      echo "  --verbose, -v         Enable verbose output"
      echo "  --help, -h            Show this help message"
      echo ""
      echo "Available binary tools:"
      echo "  bat, bottom, delta, duf, dust, eza, fastfetch, fd, fzf,"
      echo "  glow, hgrep, lazygit, procs, ripgrep, rip, starship, zoxide"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# --- バイナリツール情報 ---
declare -A TOOL_INFO
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

# --- ログ関数 ---
log_message() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp="[$(date "+%Y-%m-%d %H:%M:%S")]"
  case "$level" in
    "SUCCESS") echo "✅ $message" ;;
    "ERROR")   echo "❌ ERROR: $message" ;;
    "WARN")    echo "⚠️ WARN: $message" ;;
    "INFO")    echo "ℹ️ $message" ;;
    "DEBUG")   echo "🔍 DEBUG: $message" ;;
    *) echo "$message" ;;
  esac
  echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

error() {
  log_message "ERROR" "$1"
  exit 1
}
success() {
  log_message "SUCCESS" "$1"
}
info() {
  log_message "INFO" "$1"
}
warn() {
  log_message "WARN" "$1"
}
debug() {
  [[ "$VERBOSE" == "true" ]] && log_message "DEBUG" "$1"
}

# --- APTパッケージ更新 ---
update_apt_packages() {
  info "Starting apt package updates..."
  if ! sudo apt update; then
    error "Failed to update apt package lists"
  fi
  if ! sudo apt upgrade -y; then
    error "Failed to upgrade apt packages"
  else
    success "Apt packages updated"
  fi
}

# --- NPMパッケージ更新 ---
update_npm_packages() {
  info "Starting npm package updates..."
  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not found, skipping npm updates"
    return 0
  fi
  # グローバルパッケージの更新
  if ! sudo npm update -g; then
    warn "Failed to update global npm packages"
  else
    success "Global npm packages updated"
  fi
}

# --- GitHub最新版バージョン取得 ---
get_latest_version() {
  local repo="$1"
  local retries=3
  local version=""
  for ((i=1; i<=retries; i++)); do
    local response
    response=$(curl -sL --connect-timeout 10 "https://api.github.com/repos/$repo/releases/latest")
    if echo "$response" | jq -e '.message | test("API rate limit exceeded")' &>/dev/null; then
      error "GitHub API rate limit exceeded. Please try again after 1 hour."
    fi
    version=$(echo "$response" | jq -r .tag_name | sed 's/^v//')
    if [[ "$version" != "null" && -n "$version" ]]; then
      echo "$version"
      return 0
    fi
    debug "Failed to fetch version for $repo (attempt $i/$retries)"
    sleep 2
  done
  error "Could not get latest version for $repo after $retries attempts"
}

# --- 現在のバージョン取得 ---
extract_current_version() {
  local cmd="$1"
  local output
  output=$($cmd 2>/dev/null || echo "0.0.0")
  echo "$output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || echo "0.0.0"
}

# --- バイナリ展開・設置 ---
extract_and_install() {
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

# --- バイナリツール処理 ---
process_binary_tool() {
  local name="$1"
  if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
    local found=false
    for tool in "${SELECTED_TOOLS[@]}"; do
      [[ "$tool" == "$name" ]] && found=true && break
    done
    ! $found && return 0
  fi
  local repo="${TOOL_INFO["$name.repo"]}"
  local ver_cmd="${TOOL_INFO["$name.cmd"]}"
  local filename="${TOOL_INFO["$name.filename"]}"
  local file_pattern="${TOOL_INFO["$name.pattern"]}"
  local uses_v_prefix="${TOOL_INFO["$name.uses_v_prefix"]}"
  debug "Checking $name..."
  local current_ver latest_ver
  current_ver=$(extract_current_version "$ver_cmd")
  latest_ver=$(get_latest_version "$repo") || return 1
  if [[ "$name" == "rip" ]]; then latest_ver="0.11.4"; fi
  if [[ "$current_ver" == "$latest_ver" ]]; then
    info "$name is up-to-date ($current_ver)"
    return 0
  fi
  info "Updating $name: $current_ver → $latest_ver"
  local file="${file_pattern/\{VERSION\}/$latest_ver}"
  local vprefix=""
  [[ "$uses_v_prefix" == "true" ]] && vprefix="v"
  # rip の特別処理
  if [[ "$name" == "rip" ]]; then
    latest_ver="0.11.4"
  fi
  local url="https://github.com/$repo/releases/download/${vprefix}${latest_ver}/$file"
  local archive="$ARCHIVE_DIR/$file"
  debug "Downloading from: $url"
  if ! curl -L --connect-timeout 30 --retry 3 "$url" -o "$archive"; then
    error "Failed to download $name"
  fi
  if extract_and_install "$name" "$archive" "$filename" "$BIN_DIR"; then
    if "$BIN_DIR/$filename" --version &>/dev/null; then
      success "$name updated successfully."
    else
      error "$name failed after update. Rolling back..."
      local latest_backup
      latest_backup=$(ls -t "$BACKUP_DIR/${filename}.bak."* 2>/dev/null | head -n1)
      [[ -n "$latest_backup" ]] && \cp -f "$latest_backup" "$BIN_DIR/$filename" && info "Rolled back $name"
    fi
  fi
}

# --- バイナリツール更新 ---
update_binary_tools() {
  info "Starting binary tools update..."
  for entry in "${TOOLS[@]}"; do
    IFS="|" read -r name _ _ _ <<< "$entry"
    process_binary_tool "$name"
  done
  success "Binary tools updated"
}

# --- クリーンアップ ---
cleanup() {
  \rm -rf "$TMP_DIR"
}

# --- メイン処理 ---
main() {
  echo "========== Update started at $(date) ==========" | tee -a "$LOG_FILE"
  info "Dotfiles update script"
  info "Log file: $LOG_FILE"
  # 更新対象の確認
  local updates=()
  [[ "$UPDATE_APT" == "true" ]] && updates+=("apt packages")
  [[ "$UPDATE_NPM" == "true" ]] && updates+=("npm packages")
  [[ "$UPDATE_BINARIES" == "true" ]] && updates+=("binary tools")
  if [[ ${#updates[@]} -eq 0 ]]; then
    warn "No updates selected. Use --help for usage information."
    exit 0
  fi
  info "Updates planned: ${updates[*]}"
  # 特定ツールの場合は警告表示
  if [[ ${#SELECTED_TOOLS[@]} -gt 0 ]]; then
    info "Selected tools only: ${SELECTED_TOOLS[*]}"
  fi
  # 実際の更新処理
  if [[ "$UPDATE_APT" == "true" ]]; then
    update_apt_packages
  fi
  if [[ "$UPDATE_NPM" == "true" ]]; then
    update_npm_packages
  fi
  if [[ "$UPDATE_BINARIES" == "true" ]]; then
    update_binary_tools
  fi
  cleanup
  success "All updates completed successfully!"
  echo "========== Update finished at $(date) ==========" >> "$LOG_FILE"
}

# --- エラーハンドリング ---
trap cleanup EXIT
trap 'error "Script interrupted"' INT TERM

# --- スクリプト実行 ---
main "$@"
