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
check_dep "luarocks" "luarocks" "luarocks" "luarocks"
check_dep "fzf" "fzf" "fzf" "fzf"
check_dep "pkg-config" "pkg-config" "pkg-config" "pkg-config"
check_dep "gh" "gh" "gh" "github-cli"

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
mkdir -p "$HOME/.gemini/config/skills"

# 4. Execute GNU Stow Mapping
# Navigates to script directory to ensure stow operates on the correct relative path
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

info "Applying symlink trees via GNU Stow..."
STOW_PACKAGES=(git tmux nvim botfiles gh)

for package in "${STOW_PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        info "Stowing config layer: [$package]"
        stow --target="$HOME" --restow "$package"
    else
        echo "  Warning: Package folder '$package' not found in repository root, skipping."
    fi
done

# 5. Install Development Runtimes and Tools
install_fonts() {
    info "Installing JetBrainsMono Nerd Font..."
    local font_dir=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
    fi
    mkdir -p "$font_dir"

    if [ -f "$font_dir/JetBrainsMonoNerdFont-Regular.ttf" ] || [ -f "$font_dir/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
        echo "  - JetBrainsMono Nerd Font is already installed"
        return 0
    fi

    local temp_dir
    temp_dir="$(mktemp -d)"
    if curl -fLo "$temp_dir/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"; then
        unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir"
        find "$temp_dir" -name "*.ttf" -exec cp {} "$font_dir/" \;
        rm -rf "$temp_dir"
        
        if [[ "$OSTYPE" != "darwin"* ]]; then
            fc-cache -fv >/dev/null 2>&1 || true
        fi
        info "JetBrainsMono Nerd Font installed successfully."
    else
        echo "  Warning: Failed to download JetBrainsMono Nerd Font, skipping."
        rm -rf "$temp_dir"
    fi
}

setup_go() {
    info "Setting up Go..."
    if command -v go >/dev/null 2>&1; then
        echo "  - Go is already installed ($(go version))"
        return 0
    fi

    if command -v brew >/dev/null 2>&1; then
        brew install go
    else
        local go_version="1.25.6"
        info "Downloading and installing Go v${go_version}..."
        local temp_tar
        temp_tar="$(mktemp)"
        if curl -fLo "$temp_tar" "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"; then
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "$temp_tar"
            rm -f "$temp_tar"
            
            local shell_rc=""
            if [[ "${SHELL:-}" == *"zsh"* ]]; then
                shell_rc="$HOME/.zshrc"
            else
                shell_rc="$HOME/.bashrc"
            fi
            
            if [ -f "$shell_rc" ]; then
                if ! grep -q "/usr/local/go/bin" "$shell_rc"; then
                    echo 'export PATH="$PATH:/usr/local/go/bin"' >> "$shell_rc"
                    info "Added /usr/local/go/bin to $shell_rc."
                fi
            fi
        else
            echo "  Warning: Failed to download Go, skipping."
            rm -f "$temp_tar"
        fi
    fi
}

setup_python_tools() {
    info "Setting up Python tools (Poetry & uv)..."
    
    if ! command -v poetry >/dev/null 2>&1; then
        info "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 - || true
    else
        info "  - Poetry is already installed"
    fi
    
    if ! command -v uv >/dev/null 2>&1; then
        info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh || true
    else
        info "  - uv is already installed"
    fi
    
    local shell_rc=""
    if [[ "${SHELL:-}" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if [ -f "$shell_rc" ]; then
        if ! grep -q ".local/bin" "$shell_rc"; then
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$shell_rc"
            info "Added ~/.local/bin to $shell_rc."
        fi
    fi
}

setup_rust() {
    info "Setting up Rust..."
    if command -v rustc >/dev/null 2>&1; then
        echo "  - Rust is already installed ($(rustc --version))"
        return 0
    fi
    
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    local shell_rc=""
    if [[ "${SHELL:-}" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if [ -f "$shell_rc" ]; then
        if ! grep -q "cargo/env" "$shell_rc"; then
            echo 'source "$HOME/.cargo/env"' >> "$shell_rc"
            info "Added cargo env source to $shell_rc."
        fi
    fi
}

install_fonts
setup_go
setup_python_tools
setup_rust

info "Environment bootstrapping complete! Restart your shell session."
