# Ensure standard system paths are present
typeset -U path
path=(
    /usr/local/sbin
    /usr/local/bin
    $HOME/.local/bin
    /usr/sbin
    /usr/bin
    /sbin
    /bin
    $path
)

. "$HOME/.cargo/env"
