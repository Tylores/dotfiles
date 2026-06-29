# dotfiles
Dead-Simple Machine Provisioning

## Structure
The standard config structure and bonus `botfiles` that include agent skill and config information.

```text
~/dotfiles/
├── git/
│   └── .gitconfig
├── tmux/
│   └── .tmux.conf
├── nvim/
│   └── .config/
│       └── nvim/
│           └── init.lua
└── botfiles/
    └── .gemini/
        └── config/
            └── skills/
                ├── triage.md
                └── helics-core.md
```

## Bootstrap

```shell
git clone git@github.com:Tylores/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```
