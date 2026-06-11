# Copilot Instructions

## Repository Overview

Personal dotfiles for WSL2 Ubuntu. Config files live under topic directories (`shell/`, `editors/`, `git/`, `ssh/`, `tmux/`, `config/`, `tex/`) and are deployed as symlinks into `$HOME` by `install.sh`.

## Scripts

```bash
bash install.sh   # Fresh setup: packages, binaries, symlinks, zsh plugins, default shell
bash update.sh    # Update packages and binaries
bash update.sh --tool <name>   # Update a single binary (e.g. bat, fzf, lazygit)
bash update.sh --help          # Full options list
```

There are no tests or linters.

## Architecture

### Symlink map (`install.sh`)
All config files are deployed as symlinks: `$HOME/<name>` → `$DOTFILES_DIR/<path>`. The full mapping is defined in the `symlink_targets` associative array in `install.sh`. Notably, `~/.copilot/instructions/copilot-instructions.md` is symlinked to `copilot/instructions/copilot-instructions.md` (global personal AI instructions — separate from this repo-scoped file).

### Binary tool registry
Both scripts share an identical `TOOLS` array. Each entry is a `|`-delimited string:
```
"name|owner/repo|version-cmd|binary-filename|archive-pattern"
```
The `{VERSION}` placeholder in the archive pattern is substituted at runtime. A separate `TOOL_INFO["$name.uses_v_prefix"]` flag controls whether `v` is prepended to the tag in the download URL.

### `is_special_server()` mode
When the hostname is `noether`, `bessel`, `neumann`, or `landau`, apt/npm installs are skipped and only binaries + symlinks are updated.

### Backups and logs
- `install.sh` creates `backup/YYYYMMDD_HHMMSS/` with both config backups and a log.
- `update.sh` writes logs to `backup/YYYYMMDD_HHMMSS_update.log` and binary backups to `~/.local/bin/backup/`.

## Key Conventions

- All scripts use `set -euo pipefail`.
- Code identifiers and comments are in **English**; inline script comments and log messages are in **Japanese**.
- Responses and explanations to the user should be in **Japanese** (see `copilot/instructions/copilot-instructions.md`).
- Binaries are installed to `~/.local/bin/`.
- Packages are listed one per line in `packages/apt.list` and `packages/npm.list`; lines starting with `#` or blank lines are ignored.

## Commit Convention

Commits use the format `{emoji}{type}: {subject}` (max 50 chars), managed by `changelog.config.js`. Types: `feat 🎸`, `fix 🐛`, `perf ⚡️`, `refactor 💡`, `style 💄`, `chore 🤖`, `docs ✏️`, `test 💍`.
