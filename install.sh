#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  backing up $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sf "$src" "$dst"
    echo "  linked $dst"
}

echo "==> nvim"
link "$DOTFILES/nvim" "$HOME/.config/nvim"

echo "==> git"
link "$DOTFILES/git/config" "$HOME/.gitconfig"
link "$DOTFILES/git/ignore" "$HOME/.config/git/ignore"

echo "==> tmux"
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
# Install tpm if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "  installing tpm..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo "==> ghostty"
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_DIR"
link "$DOTFILES/ghostty/config.ghostty" "$GHOSTTY_DIR/config.ghostty"

echo "==> ccache"
CCACHE_DIR="$HOME/Library/Preferences/ccache"
mkdir -p "$CCACHE_DIR"
link "$DOTFILES/ccache/ccache.conf" "$CCACHE_DIR/ccache.conf"

echo ""
echo "Done. Update git/config with your email before committing."
