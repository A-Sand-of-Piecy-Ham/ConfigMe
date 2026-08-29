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

# ------------------------------------------------------------------ modes ---
usage() {
    cat <<USAGE
usage: install.sh [--doctor|--deps|--help]

  (no args)  link configs into place
  --doctor   report what is missing or misconfigured, change nothing
  --deps     print the package-manager command for missing system packages
USAGE
}

MODE=install
case "${1:-}" in
    --doctor) MODE=doctor ;;
    --deps)   MODE=deps ;;
    -h|--help) usage; exit 0 ;;
    "") ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

# Package names in packages/apt.txt are followed by a `# reason` comment.
apt_packages() {
    sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' \
        "$DOTFILES/packages/apt.txt"
}

PASS=0; WARN=0; FAIL=0
ok()   { printf '  \033[32m*\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; WARN=$((WARN+1)); }
bad()  { printf '  \033[31mx\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

# A required tool is one a linked config actively depends on. An optional tool
# gates a single feature and is reported as a warning, with the feature named
# so the report says what is lost rather than just what is absent.
check_cmd() {
    local cmd="$1" why="$2" required="${3:-yes}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd"
    elif [ "$required" = yes ]; then
        bad "$cmd missing -- $why"
    else
        warn "$cmd missing -- $why"
    fi
}

doctor() {
    echo "==> commands"
    check_cmd git    "everything"
    check_cmd tmux   "tmux/.tmux.conf"
    check_cmd nvim   "nvim/"
    check_cmd fzf    "tmux prefix+s session switcher, tmux-fzf"
    check_cmd ccache "ccache/ccache.conf"
    # snacks.image shells out to magick, or convert/identify on ImageMagick 6.
    if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
        ok "ImageMagick"
    else
        bad "ImageMagick missing -- snacks.image cannot decode any image"
    fi
    check_cmd entr      "tmux-autoreload; the plugin loads but does nothing" no
    check_cmd gs        "snacks.image PDF rendering" no
    check_cmd tectonic  "snacks.image LaTeX math rendering" no
    check_cmd mmdc      "snacks.image Mermaid diagrams" no
    # mmdc without a browser path fails at launch rather than degrading, so a
    # present binary is not on its own enough to call this working. Test for a
    # browser rather than for PUPPETEER_EXECUTABLE_PATH being set: common.sh
    # exports that from an interactive shell, which this script is not, so
    # reading the variable here would report the caller's environment instead
    # of the configuration.
    if command -v mmdc >/dev/null 2>&1; then
        _browser=""
        for _b in /usr/bin/google-chrome /usr/bin/chromium /usr/bin/chromium-browser; do
            [ -x "$_b" ] && { _browser="$_b"; break; }
        done
        if [ -n "$_browser" ]; then
            ok "puppeteer browser ($_browser)"
        else
            bad "mmdc installed but no browser found -- puppeteer will fail at launch"
        fi
        unset _browser _b
    fi

    echo "==> terminfo"
    for t in tmux-256color xterm-kitty; do
        if infocmp "$t" >/dev/null 2>&1; then
            ok "$t"
        else
            bad "$t missing -- see packages/manual.md"
        fi
    done

    echo "==> fonts"
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list : family 2>/dev/null | grep -qi 'nerd\|JetBrainsMono NF'; then
            ok "Nerd Font present"
        else
            bad "no Nerd Font -- statusline glyphs render as tofu, not an error"
        fi
    else
        warn "fontconfig absent; cannot check fonts"
    fi

    echo "==> tmux"
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        # Every @plugin line should have a matching directory under plugins/.
        local want have
        want=$(grep -c "^set -g @plugin" "$DOTFILES/tmux/.tmux.conf" 2>/dev/null || echo 0)
        have=$(find "$HOME/.tmux/plugins" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
        if [ "$have" -ge "$want" ]; then
            ok "plugins installed ($have/$want)"
        else
            bad "only $have of $want tmux plugins installed -- run prefix+I"
        fi
    else
        bad "tpm not installed"
    fi
    # A running server never re-reads its config, so a correct file on disk
    # says nothing about the server actually using it.
    if tmux info >/dev/null 2>&1; then
        if [ "$(tmux show-options -gv allow-passthrough 2>/dev/null)" = on ]; then
            ok "running server has allow-passthrough on"
        else
            bad "running tmux server has allow-passthrough off -- images will hang; press prefix+R"
        fi
    fi

    if [ "$OS" != windows ]; then
        echo "==> kitty"
        if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
            ok "kitty $("$HOME/.local/kitty.app/bin/kitty" --version 2>/dev/null | awk '{print $2}')"
        else
            warn "kitty not installed -- see packages/manual.md"
        fi
        command -v kitty >/dev/null 2>&1 \
            && ok "kitty on PATH" \
            || warn "kitty not on PATH -- 'kitty @' and kittens will not resolve from a shell"
    fi

    if [ "$IS_WSL" = 1 ]; then
        echo "==> wsl"
        # Mesa tries zink first under WSLg and silently falls back to llvmpipe
        # software rendering. There is no error; the only sign is the driver
        # that ends up loaded.
        if [ -e /dev/dxg ]; then
            ok "/dev/dxg present (GPU passthrough)"
            [ -f /usr/lib/x86_64-linux-gnu/dri/d3d12_dri.so ] \
                && ok "d3d12 Mesa driver present" \
                || bad "d3d12_dri.so missing -- GL falls back to software rendering"
        else
            warn "/dev/dxg absent -- no GPU passthrough"
        fi
        [ -f "$XDG/environment.d/wslg.conf" ] \
            && ok "WSLg env persisted for systemd (dunst)" \
            || bad "environment.d/wslg.conf missing -- dunst will fail to start"
        command -v wsl-notify-send.exe >/dev/null 2>&1 \
            && ok "wsl-notify-send.exe" \
            || warn "wsl-notify-send.exe missing -- kitty command-finish notifications disabled"
        [ -f /usr/share/applications/kitty.desktop ] \
            && ok "kitty Start Menu entry installed" \
            || warn "kitty.desktop not in /usr/share/applications -- no Start Menu entry"
    fi

    echo
    printf 'ok %s, warnings %s, problems %s\n' "$PASS" "$WARN" "$FAIL"
    [ "$FAIL" -eq 0 ]
}

deps() {
    local missing=()
    while read -r pkg; do
        [ -n "$pkg" ] || continue
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done < <(apt_packages)

    if [ ${#missing[@]} -eq 0 ]; then
        echo "all packages in packages/apt.txt are installed"
        return 0
    fi
    echo "missing ${#missing[@]} package(s):"
    printf '  %s\n' "${missing[@]}"
    echo
    echo "sudo apt install ${missing[*]}"
}

case "$MODE" in
    doctor) doctor; exit $? ;;
    deps)
        if [ "$OS" != linux ]; then
            echo "--deps only knows apt; on $OS see packages/manual.md" >&2
            exit 2
        fi
        deps; exit 0 ;;
esac

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

echo "==> bin"
# Repo helper scripts on PATH. kitty and other tools reference these by
# absolute path, but they are useful from a shell too.
for script in "$DOTFILES"/bin/*; do
    [ -f "$script" ] || continue
    link "$script" "$HOME/.local/bin/$(basename "$script")"
done

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
        # Windows Start Menu integration.
        #
        # WSLg generates a shortcut for every .desktop entry that is
        # Terminal=false and NoDisplay=false -- but its scanner uses the XDG
        # default data dirs, /usr/local/share:/usr/share, because XDG_DATA_DIRS
        # is unset under WSLg. ~/.local/share/applications is NOT searched, so
        # an entry placed there is silently ignored. It has to go system-wide.
        #
        # WSLg appends " (Ubuntu)" to the name itself, so Name is just "kitty".
        KITTY_BIN="$HOME/.local/kitty.app/bin/kitty"
        if [ -x "$KITTY_BIN" ]; then
            # A wrapper rather than `env ...` directly in Exec: WSLg launches
            # this without a shell, so GALLIUM_DRIVER has to be set here or
            # Mesa falls back to llvmpipe software rendering. Keeping it in a
            # script also gives one place to add future launch environment.
            WRAPPER="$HOME/.local/bin/kitty-wsl"
            mkdir -p "$(dirname "$WRAPPER")"
            cat > "$WRAPPER" <<WRAPEOF
#!/usr/bin/env bash
# Generated by install.sh. Launches kitty with the hardware GL driver forced.
# Under WSLg, Mesa tries zink first, fails to choose a physical device, and
# silently falls back to llvmpipe -- software rendering in a GPU-accelerated
# terminal, with no error shown.
[ -e /dev/dxg ] && export GALLIUM_DRIVER=d3d12
exec "$KITTY_BIN" "\$@"
WRAPEOF
            chmod +x "$WRAPPER"
            echo "  wrote $WRAPPER"

            # kitty and kitten on PATH. The .desktop launcher uses the wrapper
            # above, but `kitty @` remote control and every kitten are invoked
            # from a shell and need the real binaries resolvable by name.
            for b in kitty kitten; do
                link "$HOME/.local/kitty.app/bin/$b" "$HOME/.local/bin/$b"
            done

            KITTY_ICON="$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png"
            STAGED="$XDG/kitty/kitty.desktop.staged"
            cat > "$STAGED" <<DESKTOPEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
GenericName=Terminal emulator
Comment=Fast, feature-rich, GPU based terminal
TryExec=$WRAPPER
Exec=$WRAPPER
Icon=$KITTY_ICON
Categories=System;TerminalEmulator;
Terminal=false
StartupNotify=true
StartupWMClass=kitty
DESKTOPEOF

            SYS_DESKTOP=/usr/share/applications/kitty.desktop
            if cmp -s "$STAGED" "$SYS_DESKTOP" 2>/dev/null; then
                echo "  $SYS_DESKTOP already current"
            elif cp "$STAGED" "$SYS_DESKTOP" 2>/dev/null; then
                echo "  installed $SYS_DESKTOP"
            elif sudo -n cp "$STAGED" "$SYS_DESKTOP" 2>/dev/null; then
                echo "  installed $SYS_DESKTOP (via sudo)"
            else
                echo "  NEEDS ROOT -- WSLg only reads /usr/share/applications:"
                echo "      sudo cp '$STAGED' $SYS_DESKTOP"
            fi

            # A stale entry in the user dir would shadow nothing under WSLg but
            # would duplicate the launcher on a normal Linux desktop.
            rm -f "$HOME/.local/share/applications/kitty.desktop"
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
            cat > "$XDG/kitty/local/wsl.conf" <<KITTYLOCALEOF
# Generated by install.sh -- machine-local, not in the repo.
notify_on_cmd_finish unfocused 15.0 command wsl-notify-send.exe --category kitty

# URLs open in the Windows default browser. wslview comes from wslu. Named
# explicitly with an absolute path because WSLg launches kitty without a shell,
# so PATH is minimal and \$BROWSER from bash/common.sh is not set.
open_url_with $(command -v wslview 2>/dev/null || echo wslview)

# The hints kitten opens matched file:line errors with this. kitty-nvim routes
# into the running tmux session rather than opening a detached kitty window.
editor $DOTFILES/bin/kitty-nvim
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
link "$DOTFILES/claude/rules"    "$HOME/.claude/rules"
link "$DOTFILES/claude/memory"   "$HOME/.claude/memory"
link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo
echo "Done."
if [ "$IS_WSL" = 1 ]; then
    echo "WSL is the source of truth. To refresh the Windows mirror, run"
    echo "install.ps1 from the Windows clone after pulling."
fi
