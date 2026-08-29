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

echo "==> kitty"
if [ "$OS" = windows ]; then
    echo "  skipped -- kitty has no Windows build"
else
    link "$DOTFILES/kitty/kitty.conf" "$XDG/kitty/kitty.conf"

    if [ "$IS_WSL" = 1 ]; then
        # WSLg surfaces .desktop entries from here in the Windows Start Menu,
        # so kitty can be pinned and launched like a native Windows app.
        #
        # GALLIUM_DRIVER is set on the Exec line, not in .bashrc: WSLg launches
        # this binary directly, so no shell ever runs to export it. Without it
        # Mesa tries zink, fails to pick a physical device, and silently falls
        # back to llvmpipe -- software rendering in a GPU-accelerated terminal.
        KITTY_BIN="$HOME/.local/kitty.app/bin/kitty"
        if [ -x "$KITTY_BIN" ]; then
            DESKTOP="$HOME/.local/share/applications/kitty.desktop"
            mkdir -p "$(dirname "$DESKTOP")"
            cat > "$DESKTOP" <<DESKTOPEOF
[Desktop Entry]
Type=Application
Name=kitty (WSL)
GenericName=Terminal emulator
Comment=Kitty running under WSLg with GPU acceleration
Exec=env GALLIUM_DRIVER=d3d12 $KITTY_BIN
Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png
Categories=System;TerminalEmulator;
Terminal=false
StartupNotify=true
DESKTOPEOF
            echo "  wrote $DESKTOP"
        else
            echo "  kitty not installed; skipping desktop entry"
            echo "  install with: curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin"
        fi

        # Machine-local kitty settings, picked up by the globinclude at the end
        # of kitty.conf. Kept out of the repo because delivery of a desktop
        # notification is machine-specific.
        #
        # wsl-notify-send.exe produces a real Windows toast -- Action Center,
        # Focus Assist and all -- rather than a Linux popup floating over the
        # desktop. kitty's own notification path speaks D-Bus, so the
        # `command` action is what routes around it.
        if command -v wsl-notify-send.exe >/dev/null 2>&1; then
            mkdir -p "$XDG/kitty/local"
            cat > "$XDG/kitty/local/wsl.conf" <<'KITTYLOCALEOF'
# Generated by install.sh -- machine-local, not in the repo.
notify_on_cmd_finish unfocused 15.0 command wsl-notify-send.exe --category kitty
KITTYLOCALEOF
            echo "  wrote $XDG/kitty/local/wsl.conf (Windows toast notifications)"
        else
            echo "  wsl-notify-send.exe not on PATH; kitty command-finish notifications disabled"
        fi
    fi
fi

if [ "$IS_WSL" = 1 ]; then
    echo "==> wslg environment"
    # systemd's user manager starts without WSLg's DISPLAY/WAYLAND_DISPLAY, so
    # anything it launches that needs a display dies. dunst is the concrete
    # case: D-Bus activates it, it aborts with "Cannot open X11 display", and
    # every notification call then hangs until it times out.
    #
    # environment.d is read by the systemd user manager at startup, which makes
    # this survive a WSL restart -- unlike `systemctl --user import-environment`,
    # which only affects the running manager.
    ENVD="$XDG/environment.d/wslg.conf"
    mkdir -p "$(dirname "$ENVD")"
    cat > "$ENVD" <<'ENVDEOF'
# Generated by install.sh. WSLg's display sockets, so systemd user units
# (notably dunst) can reach a display. Values are fixed by WSLg.
DISPLAY=:0
WAYLAND_DISPLAY=wayland-0
ENVDEOF
    echo "  wrote $ENVD"
    # Also apply to the manager running right now, so no restart is needed.
    systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR 2>/dev/null || true
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
