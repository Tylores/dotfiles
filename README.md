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
└── botfiles/          # AI Agent operational skill playbooks
```

## Bootstrap

```shell
git clone git@github.com:Tylores/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```
