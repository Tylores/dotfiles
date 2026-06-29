#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# Treat unset variables as an error, and catch pipeline failures.
set -euo pipefail

# Define text modifiers for clean logging output
BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

info() { echo -e "${BOLD}${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }

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

check_dep "git" "git" "git" "git"
check_dep "tmux" "tmux" "tmux" "tmux"
check_dep "nvim" "neovim" "neovim" "neovim"
check_dep "stow" "stow" "stow" "stow"
check_dep "curl" "curl" "curl" "curl"
check_dep "make" "make" "make" "make"
check_dep "unzip" "unzip" "unzip" "unzip"
check_dep "gcc" "gcc" "build-essential" "gcc"
check_dep "rg" "ripgrep" "ripgrep" "ripgrep"

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

# 3. Create Necessary Target Directories
info "Preparing config directory targets..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.gemini/config/skills"

# 4. Execute GNU Stow Mapping
# Navigates to script directory to ensure stow operates on the correct relative path
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

info "Applying symlink trees via GNU Stow..."
STOW_PACKAGES=(git tmux nvim botfiles)

for package in "${STOW_PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        info "Stowing config layer: [$package]"
        # --target tells Stow where to install symlinks, preventing issues when cloned to non-standard paths
        stow --target="$HOME" --restow "$package"
    else
        echo "  Warning: Package folder '$package' not found in repository root, skipping."
    fi
done

info "Environment bootstrapping complete! Restart your shell session."
