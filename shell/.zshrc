# --- Environment Core ---
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="C.UTF-8"

# --- History Configuration ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS       # Do not write duplicate lines to history
setopt HIST_SAVE_NO_DUPS      # Do not write old duplicate lines
setopt INC_APPEND_HISTORY     # Write to history file immediately upon command exit
setopt SHARE_HISTORY          # Share history across active tmux panes

# --- Basic Quality of Life ---
setopt AUTO_CD                # Typing a directory name directly moves you into it
setopt NO_BEEP                # Silence annoying audio alert bell rings
bindkey -v                    # Enforce pure Vim keybindings inside your shell prompt
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shells

# --- Tool Plugins & Sourcing ---
# Sourcing the native installations for maximum execution performance
AUTOSUGGEST_PATHS=(
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
)
for p in "${AUTOSUGGEST_PATHS[@]}"; do
    if [ -f "$p" ]; then
        source "$p"
        break
    fi
done

SYNTAX_PATHS=(
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
)
for p in "${SYNTAX_PATHS[@]}"; do
    if [ -f "$p" ]; then
        source "$p"
        break
    fi
done

# --- Theme Matching Style Variables ---
# This variable sets the color tint of the ghost inline text preview.

# standard 256-color ANSI index or an explicit Hex code.
# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=242" 

# Tokyo Night (Default / Dark Night):
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565f89,italic"

# --- Sourcing Local Overrides ---
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi
export PATH="$PATH:/usr/local/go/bin"

. "$HOME/.local/bin/env"
export PATH="$PATH:$HOME/.local/bin"
source "$HOME/.cargo/env"
