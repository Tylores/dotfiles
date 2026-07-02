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

append_to_rc() {
    local line="$1"
    local desc="$2"
    
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ] || { [ "$(basename "$rc")" = ".zshrc" ] && [ -d "$DOTFILES_DIR/shell" ]; }; then
            touch "$rc"
            if ! grep -Fq "$line" "$rc"; then
                echo "$line" >> "$rc"
                info "Added $desc to $rc."
            fi
        fi
    done
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
            
            append_to_rc 'export PATH="$PATH:/usr/local/go/bin"' "/usr/local/go/bin"
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
    
    append_to_rc 'export PATH="$PATH:$HOME/.local/bin"' "~/.local/bin"
}

setup_rust() {
    info "Setting up Rust..."
    if command -v rustc >/dev/null 2>&1; then
        echo "  - Rust is already installed ($(rustc --version))"
        return 0
    fi
    
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    append_to_rc 'source "$HOME/.cargo/env"' "cargo env source"
}

setup_agent_clis() {
    info "Setting up Agent CLIs (Antigravity, Claude, and Copilot)..."
    
    # 1. Antigravity CLI (agy)
    if ! command -v agy >/dev/null 2>&1; then
        info "Installing Antigravity CLI..."
        curl -fsSL https://antigravity.google/cli/install.sh | bash || true
    else
        echo "  - Antigravity CLI (agy) is already installed ($(agy --version))"
    fi
    
    # 2. Claude Code CLI (claude)
    if ! command -v claude >/dev/null 2>&1; then
        info "Installing Claude Code CLI..."
        curl -fsSL https://claude.ai/install.sh | bash || true
    else
        echo "  - Claude Code CLI (claude) is already installed ($(claude --version 2>/dev/null || echo 'installed'))"
    fi
    
    # 3. GitHub Copilot CLI (copilot)
    if ! command -v copilot >/dev/null 2>&1; then
        info "Installing GitHub Copilot CLI..."
        if command -v npm >/dev/null 2>&1; then
            sudo npm install -g @github/copilot || true
        else
            echo "  Warning: npm is required to install GitHub Copilot CLI, skipping."
        fi
    else
        echo "  - GitHub Copilot CLI (copilot) is already installed ($(copilot --version 2>/dev/null || echo 'installed'))"
    fi
}

setup_starship() {
    info "Setting up Starship..."
    if command -v starship >/dev/null 2>&1; then
        echo "  - Starship is already installed ($(starship --version | head -n 1))"
        return 0
    fi
    
    info "Installing Starship..."
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
}

setup_docker() {
    info "Setting up Docker..."
    
    local needs_install=false
    if ! command -v docker >/dev/null 2>&1; then
        needs_install=true
    elif ! docker compose version >/dev/null 2>&1; then
        needs_install=true
    fi

    if [ "$needs_install" = "true" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install docker docker-compose
        elif command -v apt-get >/dev/null 2>&1; then
            info "Setting up Docker official APT repository..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            
            sudo install -m 0755 -d /etc/apt/keyrings
            local os_id
            os_id=$(. /etc/os-release && echo "${ID:-ubuntu}")
            
            # Force debian or ubuntu as os_id for GPG key download
            if [ "$os_id" != "debian" ] && [ "$os_id" != "ubuntu" ]; then
                if [ -f /etc/debian_version ]; then
                    os_id="debian"
                else
                    os_id="ubuntu"
                fi
            fi

            curl -fsSL "https://download.docker.com/linux/${os_id}/gpg" | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            local codename
            codename=$(. /etc/os-release && echo "${VERSION_CODENAME:-}")
            if [ -z "$codename" ]; then
                codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-}")
            fi
            if [ -z "$codename" ]; then
                codename=$(lsb_release -cs 2>/dev/null || echo "")
            fi
            if [ -z "$codename" ]; then
                if [ "$os_id" = "debian" ]; then
                    codename="bookworm"
                else
                    codename="noble"
                fi
            fi

            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${os_id} \
              ${codename} stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            info "Installing Docker packages..."
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif command -v pacman >/dev/null 2>&1; then
            info "Installing Docker via Pacman..."
            sudo pacman -S --noconfirm docker docker-compose
            sudo systemctl enable --now docker.service
        else
            echo "  Warning: Docker installation is not supported on this platform, skipping package install."
        fi
    else
        echo "  - Docker and Docker Compose are already installed ($(docker --version), $(docker compose version | head -n 1))"
    fi

    # Ensure docker group exists and user is in it (runs regardless of whether docker was already installed)
    if command -v docker >/dev/null 2>&1; then
        if ! getent group docker >/dev/null; then
            sudo groupadd docker || true
        fi
        if ! id -nG "$USER" | grep -qw docker; then
            info "Adding user to the docker group..."
            sudo usermod -aG docker "$USER"
            info "Note: You will need to log out and back in (or run 'newgrp docker') for group changes to take effect."
        fi
    fi

    # Create compatibility symlink for legacy docker-compose command if the plugin is installed
    if [ -f /usr/libexec/docker/cli-plugins/docker-compose ] && [ ! -f "$HOME/.local/bin/docker-compose" ]; then
        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/libexec/docker/cli-plugins/docker-compose "$HOME/.local/bin/docker-compose"
        info "Created legacy docker-compose compatibility symlink in ~/.local/bin/docker-compose"
    fi
}

install_fonts
setup_go
setup_python_tools
setup_rust
setup_agent_clis
setup_starship
setup_docker

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
