# Core Architecture & Development Workflows

This repository manages a terminal-centric engineering environment. The architecture deliberately avoids heavy, background-orchestrated abstraction layers in favor of explicit, file-based configurations and crisp tool boundaries.

## System Ecosystem & Package Layout
The workspace is fully modularized and symlinked to the `$HOME` root using **GNU Stow**. 

```text
~/dotfiles/
├── bootstrap.sh       # Central dependency installer & stow loop
├── git/               # Git configs, aliases, and global ignores
├── nvim/              # Neovim lua configuration (IDE layer)
├── tmux/              # Tmux session management and window rules
├── shell/             # Zsh core profile configurations
├── bin/               # Custom local scripts (stowed to ~/.local/bin)
└── botfiles/          # AI Agent operational skill playbooks
```

## Bootstrap

```shell
git clone git@github.com:Tylores/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

## Safety & Conflict Handling

The `bootstrap.sh` script runs non-destructive safety checks before stowing packages:
* **Safe Backups**: If a target file or leaf configuration directory already exists at `$HOME` as a regular file/directory (and is not a symlink), it is moved to `<path>.bak`.
* **Symlink Tree Safety**: If a parent directory is already stowed, files under it are skipped to prevent modifying files within the dotfiles repository itself.
* **Shared Folder Protection**: Shared parent directories (e.g. `.config`, `.local/bin`) are never backed up, only their package-specific contents.
