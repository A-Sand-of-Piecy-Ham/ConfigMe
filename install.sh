#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------- platform ---
# Config paths diverge sharply by OS (macOS buries them in ~/Library, Linux
# follows XDG, Git Bash uses the Windows profile), so detect once up front and
# branch on OS rather than sprinkling uname checks through the script.
case "$(uname -s)" in
    Darwin)          OS=darwin ;;
    Linux)           OS=linux ;;
    MINGW*|MSYS*)    OS=windows ;;
    *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

IS_WSL=0
if [ "$OS" = linux ] && grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
fi

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> platform: $OS$([ "$IS_WSL" = 1 ] && echo ' (WSL)')"
echo

link() {
    local src="$1" dst="$2"
    if [ ! -e "$src" ]; then
        echo "  skip $dst (no $src)"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    # Only back up real files. An existing symlink is assumed to be ours (or
    # stale) and is replaced silently; backing those up just accumulates
    # .bak symlinks pointing at whatever the previous checkout was.
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  backing up $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    # -n is required for directories: without it, `ln -sf dir existing-symlink`
    # creates the link *inside* the target rather than replacing it.
    ln -sfn "$src" "$dst"
    echo "  linked $dst"
}

echo "==> nvim"
link "$DOTFILES/nvim" "$XDG/nvim"

echo "==> bash"
# One shared file plus a per-OS bashrc; see bash/common.sh for the split.
link "$DOTFILES/bash/common.sh" "$XDG/dotfiles/common.sh"
link "$DOTFILES/bash/bashrc.$OS" "$HOME/.bashrc"
link "$DOTFILES/bash/bash_profile.$OS" "$HOME/.bash_profile"

echo "==> git"
link "$DOTFILES/git/config" "$HOME/.gitconfig"
link "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"

if [ "$OS" != windows ]; then
    echo "==> tmux"
    link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "  installing tpm..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
else
    echo "==> tmux (skipped — no tmux under Git Bash)"
fi

echo "==> ghostty"
case "$OS" in
    darwin)  link "$DOTFILES/ghostty/config.ghostty" \
                  "$HOME/Library/Application Support/com.mitchellh.ghostty/config" ;;
    linux)   link "$DOTFILES/ghostty/config.ghostty" "$XDG/ghostty/config" ;;
    windows) echo "  skipped — Ghostty is macOS/Linux only" ;;
esac

echo "==> wezterm"
if [ "$IS_WSL" = 1 ]; then
    # WezTerm is a Windows application here; its config belongs in the Windows
    # profile and is installed by install.ps1. A copy inside the WSL home would
    # never be read.
    echo "  skipped — installed on the Windows side by install.ps1"
else
    # WezTerm reads ~/.wezterm.lua on every platform, and that is the only path
    # that works unchanged from Git Bash, so use it rather than $XDG/wezterm.
    link "$DOTFILES/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
fi

echo "==> ccache"
case "$OS" in
    darwin)  link "$DOTFILES/ccache/ccache.conf" "$HOME/Library/Preferences/ccache/ccache.conf" ;;
    *)       link "$DOTFILES/ccache/ccache.conf" "$XDG/ccache/ccache.conf" ;;
esac

echo "==> claude"
link "$DOTFILES/claude/skills"   "$HOME/.claude/skills"
link "$DOTFILES/claude/memory"   "$HOME/.claude/memory"
link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo
echo "Done."
if [ "$IS_WSL" = 1 ]; then
    echo "WSL is the source of truth. To refresh the Windows mirror, run"
    echo "install.ps1 from the Windows clone after pulling."
fi
