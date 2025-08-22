
## Dotfiles for WSL2 Ubuntu

This repository contains my personal dotfiles, primarily intended for use on WSL2 Ubuntu environments.

### Features
- Personal configuration files for various tools and editors:
	- Shell:   bash, zsh, starship prompt
	- Editors: VS Code, Emacs
	- Others:  Git, SSH, Other useful CLI tools, etc.
- Package management:
	- List of apt and npm packages for easy setup (`packages/apt.list`, `packages/npm.list`)
- Scripts for automation:
	- `install.sh`: Automated initial setup (package install, config symlinks, backup)
	- `update.sh`:  Update installed packages and binaries, with backup and logging
- Backup and restore:
	- Automatic backup of existing config files before overwriting
	- Log files for tracking changes and updates
- Optimized for WSL2 Ubuntu:
	- Paths, permissions, and tools are tuned for WSL2 environments

### Usage
Clone this repository and use the provided scripts.

```bash
git clone https://github.com/kenshikuroki/dotfiles.git
cd dotfiles
# Run the install script for initial setup
bash install.sh
# For updating packages and configs later
bash update.sh
```

#### install.sh
- Installs packages listed in `packages/apt.list` and `packages/npm.list`
- Installs useful CLI binaries into `.local/bin/`
- Creates symlinks for configuration files
- Backs up existing files before overwriting
- Logs all actions

#### update.sh
- Updates apt and npm packages, and useful CLI binaries
- Supports selective tool updates via command-line options
- Backs up and logs changes automatically

---
