#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and catch pipeline failures.
set -euo pipefail

# Define text modifiers for clean logging output
BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

info() { echo -e "${BOLD}${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn() { echo -e "${BOLD}${YELLOW}==> WARNING:${RESET} ${BOLD}$*${RESET}"; }

is_under_symlink() {
    local path="$1"
    local parent
    parent="$(dirname "$path")"
    while [ "$parent" != "$HOME" ] && [ "$parent" != "/" ] && [ "$parent" != "." ]; do
        if [ -L "$parent" ]; then
            return 0
        fi
        parent="$(dirname "$parent")"
    done
    return 1
}

safe_backup() {
    local target="$1"

    # If it doesn't exist, nothing to do
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return 0
    fi

    # If it is a symlink, stow --restow will handle it natively
    if [ -L "$target" ]; then
        return 0
    fi

    # If it is under a symlink, do not modify it (already managed/stowed)
    if is_under_symlink "$target"; then
        return 0
    fi

    # Check if it is a shared directory we must not move
    if [ -d "$target" ]; then
        case "$target" in
            "$HOME"|"$HOME/.config"|"$HOME/.local"|"$HOME/.local/bin"|"$HOME/.gemini"|"$HOME/.claude"|"$HOME/.copilot")
                return 0
                ;;
        esac

        # Prevent nested directories if .bak folder already exists
        if [ -e "${target}.bak" ] || [ -L "${target}.bak" ]; then
            rm -rf "${target}.bak"
        fi
        warn "Found existing local directory at $target. Moving to ${target}.bak"
        mv "$target" "${target}.bak"
    elif [ -f "$target" ]; then
        if [ -e "${target}.bak" ] || [ -L "${target}.bak" ]; then
            rm -rf "${target}.bak"
        fi
        warn "Found existing local file at $target. Moving to ${target}.bak"
        mv "$target" "${target}.bak"
    fi
}

# 1. Detect Operating System & Package Manager
info "Detecting system environment..."
if command -v brew >/dev/null 2>&1; then
    INSTALL_CMD="brew install"
    info "Found Homebrew (macOS/Linux)"
elif command -v apt-get >/dev/null 2>&1; then
    INSTALL_CMD="sudo apt-get install -y"
    info "Found APT package manager (Ubuntu/Debian)"
elif command -v pacman >/dev/null 2>&1; then
    INSTALL_CMD="sudo pacman -S --noconfirm"
    info "Found Pacman package manager (Arch)"
else
    echo "Error: Supported package manager not found (Brew, APT, or Pacman required)." >&2
    exit 1
fi

# 2. Declare and Install System Dependencies
info "Verifying core tool installations..."

MISSING_PKGS=()

check_dep() {
    local cmd="$1"
    local brew_pkg="$2"
    local apt_pkg="$3"
    local pacman_pkg="$4"

    local pkg=""
    if command -v brew >/dev/null 2>&1; then
        pkg="$brew_pkg"
    elif command -v apt-get >/dev/null 2>&1; then
        pkg="$apt_pkg"
    elif command -v pacman >/dev/null 2>&1; then
        pkg="$pacman_pkg"
    fi

    if [ -n "$pkg" ]; then
        if ! command -v "$cmd" >/dev/null 2>&1; then
            MISSING_PKGS+=("$pkg")
        else
            echo "  - $cmd is already installed"
        fi
    fi
}

is_plugin_installed() {
    local plugin="$1"
    local paths=(
        "/usr/share/$plugin/$plugin.zsh"
        "/usr/share/zsh/plugins/$plugin/$plugin.zsh"
        "/usr/local/share/$plugin/$plugin.zsh"
        "/opt/homebrew/share/$plugin/$plugin.zsh"
    )
    for p in "${paths[@]}"; do
        if [ -f "$p" ]; then
            return 0
        fi
    done
    return 1
}

check_zsh_plugin() {
    local plugin="$1"
    local brew_pkg="$2"
    local apt_pkg="$3"
    local pacman_pkg="$4"

    local pkg=""
    if command -v brew >/dev/null 2>&1; then
        pkg="$brew_pkg"
    elif command -v apt-get >/dev/null 2>&1; then
        pkg="$apt_pkg"
    elif command -v pacman >/dev/null 2>&1; then
        pkg="$pacman_pkg"
    fi

    if [ -n "$pkg" ]; then
        if ! is_plugin_installed "$plugin"; then
            MISSING_PKGS+=("$pkg")
        else
            echo "  - $plugin is already installed"
        fi
    fi
}

check_dep "git" "git" "git" "git"
check_dep "tmux" "tmux" "tmux" "tmux"
check_dep "nvim" "neovim" "neovim" "neovim"
check_dep "stow" "stow" "stow" "stow"
check_dep "curl" "curl" "curl" "curl"
check_dep "make" "make" "make" "make"
check_dep "unzip" "unzip" "unzip" "unzip"
check_dep "gcc" "gcc" "build-essential" "gcc"
check_dep "rg" "ripgrep" "ripgrep" "ripgrep"
check_dep "luarocks" "luarocks" "luarocks" "luarocks"
check_dep "fzf" "fzf" "fzf" "fzf"
check_dep "pkg-config" "pkg-config" "pkg-config" "pkg-config"
check_dep "gh" "gh" "gh" "github-cli"
check_dep "zsh" "zsh" "zsh" "zsh"
check_zsh_plugin "zsh-autosuggestions" "zsh-autosuggestions" "zsh-autosuggestions" "zsh-autosuggestions"
check_zsh_plugin "zsh-syntax-highlighting" "zsh-syntax-highlighting" "zsh-syntax-highlighting" "zsh-syntax-highlighting"

# Install fd-find / fd
if command -v apt-get >/dev/null 2>&1; then
    # On Debian/Ubuntu, check for either fdfind command or physical ~/.local/bin/fd symlink
    if ! command -v fdfind >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/fd" ]; then
        MISSING_PKGS+=("fd-find")
    else
        echo "  - fd is already installed"
    fi
else
    check_dep "fd" "fd" "fd-find" "fd"
fi

# Ensure node and npm are installed (needed for Mason LSP servers)
check_dep "node" "node" "nodejs" "nodejs"
check_dep "npm" "node" "npm" "npm"

# OS-specific packages
if command -v apt-get >/dev/null 2>&1; then
    check_dep "xclip" "" "xclip" ""
    check_dep "wl-clipboard" "" "wl-clipboard" ""
    check_dep "hunspell" "" "libhunspell-dev" ""
    check_dep "readline" "" "libreadline-dev" ""
elif command -v pacman >/dev/null 2>&1; then
    check_dep "xclip" "" "" "xclip"
    check_dep "wl-clipboard" "" "" "wl-clipboard"
    check_dep "hunspell" "" "" "hunspell"
    check_dep "readline" "" "" "readline"
fi

# De-duplicate missing package list
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    DEDUPED_PKGS=()
    for pkg in "${MISSING_PKGS[@]}"; do
        if [[ ! " ${DEDUPED_PKGS[*]:-} " =~ " ${pkg} " ]]; then
            DEDUPED_PKGS+=("$pkg")
        fi
    done
    MISSING_PKGS=("${DEDUPED_PKGS[@]}")
fi

# Install all gathered missing dependencies in a single run
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    info "Installing missing dependencies: ${MISSING_PKGS[*]}..."
    if command -v apt-get >/dev/null 2>&1; then
        info "Updating APT package lists..."
        sudo apt-get update
    fi
    $INSTALL_CMD "${MISSING_PKGS[@]}"
else
    info "All core system dependencies are satisfied."
fi

# Special post-install handling for fd on Debian/Ubuntu
if command -v apt-get >/dev/null 2>&1; then
    if command -v fdfind >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/fd" ]; then
        info "Creating symlink for fd in ~/.local/bin..."
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
    fi

    # Verify if ~/.local/bin is in PATH, print a warning if not
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "\n${BOLD}Warning:${RESET} '$HOME/.local/bin' is not in your PATH."
        echo "Please add it to your shell configuration (e.g. .bashrc or .zshrc):"
        echo "  export PATH=\"\$PATH:\$HOME/.local/bin\""
    fi
fi

# Install tree-sitter CLI if npm is available
if command -v npm >/dev/null 2>&1 && ! command -v tree-sitter >/dev/null 2>&1; then
    info "Installing tree-sitter-cli globally..."
    sudo npm install -g tree-sitter-cli || true
fi

# 3. Create Necessary Target Directories
info "Preparing config directory targets..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.gemini/antigravity-cli/skills"
mkdir -p "$HOME/.claude/rules"
mkdir -p "$HOME/.copilot/instructions"

# 4. Execute GNU Stow Mapping
# Navigates to script directory to ensure stow operates on the correct relative path
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

info "Applying symlink trees via GNU Stow..."
STOW_PACKAGES=(git tmux nvim botfiles gh bin shell starship)

# Run safety checks on existing configurations before stowing
info "Running safety checks on existing configs..."
for package in "${STOW_PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        (
            cd "$package"
            find . -mindepth 1 | while read -r rel_path; do
                rel_path="${rel_path#./}"
                safe_backup "$HOME/$rel_path"
            done
        )
    fi
done

for package in "${STOW_PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        info "Stowing config layer: [$package]"
        stow --target="$HOME" --restow "$package"
    else
        echo "  Warning: Package folder '$package' not found in repository root, skipping."
    fi
done

# 5. Install Development Runtimes and Tools
"$DOTFILES_DIR/bin/.local/bin/setup-fonts"
"$DOTFILES_DIR/bin/.local/bin/setup-go"
"$DOTFILES_DIR/bin/.local/bin/setup-python"
"$DOTFILES_DIR/bin/.local/bin/setup-rust"
"$DOTFILES_DIR/bin/.local/bin/setup-agents"
"$DOTFILES_DIR/bin/.local/bin/setup-starship"
"$DOTFILES_DIR/bin/.local/bin/setup-docker"

# 6. Suggest changing default shell to zsh if currently on something else
if [[ "${SHELL:-}" != *"zsh"* ]]; then
    if command -v zsh >/dev/null 2>&1; then
        ZSH_PATH="$(command -v zsh)"
        info "Note: Your default shell is not set to zsh (current shell is $SHELL)."
        info "To set zsh as your default shell, run:"
        echo "  chsh -s $ZSH_PATH"
    fi
fi

info "Environment bootstrapping complete! Restart your shell session."
