#!/usr/bin/env bash
# Must be executed, never sourced. Sourced, this runs inside the calling shell:
# `set -euo pipefail` below would switch that shell to exit on its next failing
# command, and the `exit` that ends every mode would exit it outright. Inside
# tmux either one closes the pane, and the terminal window with it when it is
# the last one. `return` only succeeds in a sourced file, which makes it the test.
if (return 0 2>/dev/null); then
    echo "install.sh must be run, not sourced:  ./install.sh $*" >&2
    return 1
fi
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

# AstroNvim v6 refuses to start below Neovim 0.11, and Debian, Ubuntu LTS and
# Raspberry Pi OS all ship well behind that. Rather than fail on those machines,
# install an official build into ~/.local and put it ahead of the system one.
NVIM_MIN="0.11.0"

nvim_version() {
    command -v nvim >/dev/null 2>&1 || return 1
    nvim --version 2>/dev/null | head -1 | sed -E 's/^NVIM v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
}

nvim_new_enough() {
    local cur
    cur="$(nvim_version)" || return 1
    [ -n "$cur" ] || return 1
    # sort -V puts the lower version first; if that is the minimum, cur >= min.
    [ "$(printf '%s\n%s\n' "$NVIM_MIN" "$cur" | sort -V | head -1)" = "$NVIM_MIN" ]
}

# Official release asset for this machine, or empty when none is published.
nvim_asset() {
    case "$OS/$(uname -m)" in
        linux/x86_64|linux/amd64)   echo "nvim-linux-x86_64.tar.gz" ;;
        linux/aarch64|linux/arm64)  echo "nvim-linux-arm64.tar.gz" ;;
        darwin/arm64)               echo "nvim-macos-arm64.tar.gz" ;;
        darwin/x86_64)              echo "nvim-macos-x86_64.tar.gz" ;;
        *)                          echo "" ;;
    esac
}

install_nvim() {
    local asset url tmp
    asset="$(nvim_asset)"
    if [ -z "$asset" ]; then
        echo "  no official Neovim build for $OS/$(uname -m)"
        echo "  32-bit ARM in particular has none; build from source or keep a stock config here"
        return 1
    fi

    url="https://github.com/neovim/neovim/releases/latest/download/$asset"
    tmp="$(mktemp -d)"
    echo "  downloading $asset"
    if ! curl -fsSL -o "$tmp/nvim.tar.gz" "$url"; then
        echo "  download failed: $url"
        rm -rf "$tmp"
        return 1
    fi

    # Replace rather than merge: leftover files from an older tree shadow the
    # new ones and produce failures that look like config bugs.
    rm -rf "$HOME/.local/nvim"
    mkdir -p "$HOME/.local/nvim"
    tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/nvim" --strip-components=1
    rm -rf "$tmp"

    link "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    echo "  installed $("$HOME/.local/nvim/bin/nvim" --version | head -1)"
}

# lazy.nvim regenerates lazy-lock.json from what is actually installed on this
# machine -- install, update and clean all rewrite it. Entries for plugins that
# are not installed here are dropped rather than preserved, so committing the
# lock from a machine where something failed to build silently removes that
# plugin's pin everywhere else. Changed commits are ordinary; deletions are not.
lock_dropped_plugins() {
    local diff removed added
    diff="$(git -C "$DOTFILES" diff -- nvim/lazy-lock.json 2>/dev/null)" || return 0
    [ -n "$diff" ] || return 0
    removed="$(printf '%s\n' "$diff" | sed -nE 's/^-  "([^"]+)".*/\1/p' | sort)"
    added="$(printf '%s\n' "$diff"  | sed -nE 's/^\+  "([^"]+)".*/\1/p' | sort)"
    comm -23 <(printf '%s\n' "$removed") <(printf '%s\n' "$added") | sed '/^$/d'
}

# ------------------------------------------------------------------ modes ---
usage() {
    cat <<USAGE
usage: install.sh [--doctor|--deps|--install-deps|--help]

  (no args)      link configs into place
  --doctor       report what is missing or misconfigured, change nothing
  --deps         list missing system packages and print the install command
  --install-deps install the missing system packages (needs sudo)
USAGE
}

MODE=install
case "${1:-}" in
    --doctor)       MODE=doctor ;;
    --deps)         MODE=deps ;;
    --install-deps) MODE=install-deps ;;
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
# Printed under a failed check only. Naming what is lost without saying how to
# get it back leaves the reader to go hunting through packages/manual.md.
fix()  { printf '      fix: %s\n' "$1"; }
# Continuation line for a multi-step fix, so "fix:" is not repeated.
fix2() { printf '           %s\n' "$1"; }

# A required tool is one a linked config actively depends on. An optional tool
# gates a single feature and is reported as a warning, with the feature named
# so the report says what is lost rather than just what is absent.
check_cmd() {
    local cmd="$1" why="$2" required="${3:-yes}" howto="${4:-}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd"
        return
    fi
    if [ "$required" = yes ]; then
        bad "$cmd missing -- $why"
    else
        warn "$cmd missing -- $why"
    fi
    [ -n "$howto" ] && fix "$howto"
}

doctor() {
    echo "==> commands"
    check_cmd git    "everything" yes "./install.sh --install-deps"
    check_cmd tmux   "tmux/.tmux.conf" yes "./install.sh --install-deps"
    if nvim_new_enough; then
        ok "nvim $(nvim_version)"
    elif command -v nvim >/dev/null 2>&1; then
        bad "nvim $(nvim_version) is below $NVIM_MIN -- AstroNvim v6 will refuse to start"
        fix "./install.sh   (downloads an official build into ~/.local)"
    else
        bad "nvim missing"
        fix "./install.sh   (downloads an official build into ~/.local)"
    fi
    check_cmd fzf    "tmux prefix+s session switcher, tmux-fzf" yes "./install.sh --install-deps"
    check_cmd ccache "ccache/ccache.conf" yes "./install.sh --install-deps"
    # snacks.image shells out to magick, or convert/identify on ImageMagick 6.
    if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
        ok "ImageMagick"
    else
        bad "ImageMagick missing -- snacks.image cannot decode any image"
        fix "./install.sh --install-deps"
    fi
    check_cmd entr      "tmux-autoreload; the plugin loads but does nothing" no "./install.sh --install-deps"
    check_cmd gs        "snacks.image PDF rendering" no "./install.sh --install-deps"
    check_cmd tectonic  "snacks.image LaTeX math rendering" no "static binary from the release page -- see packages/manual.md"
    check_cmd mmdc      "snacks.image Mermaid diagrams" no "PUPPETEER_SKIP_DOWNLOAD=true npm install -g @mermaid-js/mermaid-cli"
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
            fix "install Chrome or Chromium; common.sh sets PUPPETEER_EXECUTABLE_PATH from it"
        fi
        unset _browser _b
    fi

    echo "==> nvim plugins"
    if ! git -C "$DOTFILES" rev-parse --git-dir >/dev/null 2>&1; then
        warn "not a git checkout; cannot check lazy-lock.json"
    elif git -C "$DOTFILES" diff --quiet -- nvim/lazy-lock.json 2>/dev/null; then
        ok "lazy-lock.json clean"
    else
        local dropped
        dropped="$(lock_dropped_plugins)"
        if [ -n "$dropped" ]; then
            bad "lazy-lock.json DROPS $(printf '%s\n' "$dropped" | wc -l) plugin(s): $(printf '%s ' $dropped)"
            bad "  those failed to install here -- committing this removes their pin on every machine"
        else
            warn "lazy-lock.json modified (version bumps only, nothing dropped)"
            warn "  commit deliberately, or: git checkout -- nvim/lazy-lock.json"
        fi
    fi

    echo "==> nvim tooling (mason)"
    # Mason reports only "failed to install" per package; the cause is in
    # :MasonLog. These are the prerequisites whose absence has actually caused
    # that here, so check them directly.
    command -v unzip >/dev/null 2>&1 \
        && ok "unzip" \
        || { bad "unzip missing -- zip-packaged tools like clangd fail to install"; fix "./install.sh --install-deps"; }

    if command -v npm >/dev/null 2>&1; then
        ok "npm ($(command -v npm))"
    else
        bad "npm missing -- every npm-based server fails (typescript, eslint, bash, astro)"
        fix "install node (nvm, or ./install.sh --install-deps for the apt one)"
    fi

    # Mason runs the SYSTEM python, not whatever python3 resolves to on PATH, so
    # a uv- or pyenv-managed interpreter having venv proves nothing.
    if [ -x /usr/bin/python3 ]; then
        if /usr/bin/python3 -c 'import venv, ensurepip' >/dev/null 2>&1; then
            ok "system python venv"
        else
            bad "/usr/bin/python3 lacks venv -- python servers fail (nginx-language-server, ruff)"
            fix "./install.sh --install-deps   (python3-venv)"
        fi
    fi

    echo "==> python lsp"
    # These checks exist to keep the comments in nvim/lua/plugins/astrolsp.lua
    # honest. That file says Python attaches ty and that basedpyright is kept
    # installed-but-disabled as an on-demand second opinion. Both halves are
    # invariants: drop basedpyright from mason.lua and the documented
    # ":LspStart basedpyright" escape hatch silently stops working, with nothing
    # else to catch it.
    _mason_bin="$HOME/.local/share/nvim/mason/bin"
    if [ -x "$_mason_bin/ty" ]; then
        ok "ty ($("$_mason_bin/ty" --version 2>/dev/null || echo unknown))"
    else
        bad "ty missing -- no type checking or completion on Python buffers"
        fix "nvim -c 'MasonInstall ty' -c qa"
    fi
    if [ -x "$_mason_bin/basedpyright-langserver" ]; then
        if grep -q 'basedpyright = false' "$DOTFILES/nvim/lua/plugins/astrolsp.lua" 2>/dev/null; then
            ok "basedpyright installed, not auto-attached (:LspStart basedpyright)"
        else
            warn "basedpyright installed AND auto-attaching -- it and ty will both"
            warn "  report diagnostics, and basedpyright alone costs a few hundred MB"
        fi
    else
        warn "basedpyright absent -- the on-demand strict checker documented in"
        warn "  astrolsp.lua is unavailable; :LspStart basedpyright will fail"
        fix "nvim -c 'MasonInstall basedpyright' -c qa"
    fi
    unset _mason_bin

    echo "==> rust"
    # Optional, but each piece fails silently. Without cargo, rust-analyzer
    # cannot load a project. Without cargo-clippy it checks with plain
    # `cargo check`. Without rust-src there is no std completion, hover or
    # go-to-definition, and no error saying why.
    check_cmd cargo        "rust-analyzer cannot load a Cargo project" no "rustup -- see packages/manual.md"
    if command -v cargo >/dev/null 2>&1; then
        check_cmd cargo-clippy "rust-analyzer checks without clippy lints" no "rustup component add clippy"
        if [ -d "$(rustc --print sysroot 2>/dev/null)/lib/rustlib/src/rust" ]; then
            ok "rust-src"
        else
            warn "rust-src missing -- no std completion, hover or go-to-definition"
            fix "rustup component add rust-src"
        fi
    fi

    echo "==> latex"
    # Optional: nothing else depends on these, but each fails in its own way.
    # Without latexmk, `,ll` errors. Without chktex, texlab simply reports no
    # lint findings. Without zathura, vimtex falls back to xdg-open and loses
    # synctex jumping.
    check_cmd latexmk "vimtex cannot compile (,ll)" no "./install.sh --install-deps"
    check_cmd chktex  "texlab reports no LaTeX lint findings" no "./install.sh --install-deps"
    check_cmd zathura "vimtex views through xdg-open, without synctex" no "./install.sh --install-deps"
    # zathura loads each format from a plugin. Without the PDF one it opens a
    # window and shows nothing, with no error, which reads as a vimtex bug.
    if command -v zathura >/dev/null 2>&1; then
        if ls /usr/lib/*/zathura/libpdf-*.so >/dev/null 2>&1; then
            ok "zathura PDF backend"
        else
            bad "zathura has no PDF backend -- it opens PDFs as blank windows"
            fix "./install.sh --install-deps   (zathura-pdf-poppler)"
        fi
    fi

    echo "==> paste"
    # kitty.conf lists `filter` in paste_actions. If paste-actions.py is not
    # beside it, kitty pastes unfiltered with no visible error and CRLF text
    # from Windows arrives with a ^M on every line again.
    if grep -q '^paste_actions.*filter' "$DOTFILES/kitty/kitty.conf" 2>/dev/null; then
        if [ -r "$XDG/kitty/paste-actions.py" ]; then
            ok "kitty paste filter linked"
        else
            bad "kitty paste filter missing -- pasted Windows text keeps its CRs"
            fix "./install.sh"
        fi
    fi

    echo "==> terminfo"
    for t in tmux-256color xterm-kitty; do
        if infocmp "$t" >/dev/null 2>&1; then
            ok "$t"
        else
            bad "$t missing"
            if [ "$t" = xterm-kitty ]; then
                fix "mkdir -p ~/.terminfo && cp -r ~/.local/kitty.app/share/terminfo/* ~/.terminfo/"
            else
                fix "./install.sh --install-deps   (ncurses-term)"
            fi
        fi
    done

    echo "==> fonts"
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list : family 2>/dev/null | grep -qi 'nerd\|JetBrainsMono NF'; then
            ok "Nerd Font present"
        else
            bad "no Nerd Font -- statusline glyphs render as tofu, not an error"
            fix  "download JetBrainsMono from github.com/ryanoasis/nerd-fonts/releases"
            fix2 "unzip into ~/.local/share/fonts/, then run fc-cache -f"
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
            bad "only $have of $want tmux plugins installed"
            fix "press prefix+I inside tmux (prefix is C-Space)"
        fi
    else
        bad "tpm not installed"
        fix "./install.sh   (clones tpm)"
    fi
    # A running server never re-reads its config, so a correct file on disk
    # says nothing about the server actually using it.
    if tmux info >/dev/null 2>&1; then
        if [ "$(tmux show-options -gv allow-passthrough 2>/dev/null)" = on ]; then
            ok "running server has allow-passthrough on"
        else
            bad "running tmux server has allow-passthrough off -- images will hang"
            fix "press prefix+R to reload, or: tmux source-file ~/.tmux.conf"
        fi
    fi

    if [ "$OS" != windows ]; then
        echo "==> kitty"
        if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
            ok "kitty $("$HOME/.local/kitty.app/bin/kitty" --version 2>/dev/null | awk '{print $2}')"
        else
            warn "kitty not installed"
            fix "curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin"
        fi
        command -v kitty >/dev/null 2>&1 \
            && ok "kitty on PATH" \
            || { warn "kitty not on PATH -- 'kitty @' and kittens will not resolve from a shell"; fix "./install.sh"; }
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
                || { bad "d3d12_dri.so missing -- GL falls back to software rendering"; fix "./install.sh --install-deps   (mesa drivers)"; }
        else
            warn "/dev/dxg absent -- no GPU passthrough"
        fi
        [ -f "$XDG/environment.d/wslg.conf" ] \
            && ok "WSLg env persisted for systemd (dunst)" \
            || { bad "environment.d/wslg.conf missing -- dunst will fail to start"; fix "./install.sh"; }
        command -v wsl-notify-send.exe >/dev/null 2>&1 \
            && ok "wsl-notify-send.exe" \
            || { warn "wsl-notify-send.exe missing -- kitty command-finish notifications disabled"; fix "see packages/manual.md (wsl-notify-send)"; }
        [ -f /usr/share/applications/kitty.desktop ] \
            && ok "kitty Start Menu entry installed" \
            || { warn "kitty.desktop not in /usr/share/applications -- no Start Menu entry"; fix "sudo cp $XDG/kitty/kitty.desktop.staged /usr/share/applications/kitty.desktop"; }
    fi

    echo "==> ssh"
    [ -d "$HOME/.ssh/cm" ] \
        && ok "ControlPath dir present" \
        || { bad "~/.ssh/cm missing -- ssh multiplexing silently falls back to a full connection"; fix "./install.sh"; }
    if [ -L "$HOME/.ssh/config" ]; then
        ssh -G localhost >/dev/null 2>&1 \
            && ok "ssh config parses" \
            || bad "~/.ssh/config does not parse"
    else
        warn "~/.ssh/config not linked"
        fix "./install.sh"
    fi

    echo "==> claude"
    for d in skills rules; do
        if [ -L "$HOME/.claude/$d" ] && [ -d "$HOME/.claude/$d" ]; then
            ok "$d linked ($(find -L "$HOME/.claude/$d" -maxdepth 1 -mindepth 1 | wc -l) entries)"
        else
            bad "~/.claude/$d not linked -- skills or rules will not load"
            fix "./install.sh"
        fi
    done
    [ -L "$HOME/.claude/CLAUDE.md" ] && ok "CLAUDE.md linked" || bad "~/.claude/CLAUDE.md not linked"
    if command -v github-mcp >/dev/null 2>&1; then
        gh auth status >/dev/null 2>&1 && ok "github-mcp (gh authenticated)" \
                                       || bad "github-mcp present but gh not logged in"
    else
        warn "github-mcp missing -- GitHub MCP server unavailable"
        fix "./install.sh   (links bin/github-mcp)"
    fi

    echo
    printf 'ok %s, warnings %s, problems %s\n' "$PASS" "$WARN" "$FAIL"
    [ "$FAIL" -eq 0 ]
}

# Shared by --deps and --install-deps so the two cannot disagree about what is
# missing.
missing_packages() {
    local missing=()
    while read -r pkg; do
        [ -n "$pkg" ] || continue
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done < <(apt_packages)

    # An empty array still prints one blank line through printf, which the
    # callers then count as a missing package with no name.
    [ ${#missing[@]} -eq 0 ] && return 0
    printf '%s\n' "${missing[@]}"
}

deps() {
    local missing
    mapfile -t missing < <(missing_packages)
    if [ ${#missing[@]} -eq 0 ]; then
        echo "all packages in packages/apt.txt are installed"
        return 0
    fi
    echo "missing ${#missing[@]} package(s):"
    printf '  %s\n' "${missing[@]}"
    echo
    echo "sudo apt install ${missing[*]}"
    echo "or: ./install.sh --install-deps"
}

install_deps() {
    local missing
    mapfile -t missing < <(missing_packages)
    if [ ${#missing[@]} -eq 0 ]; then
        echo "all packages in packages/apt.txt are installed"
        return 0
    fi
    echo "installing ${#missing[@]} package(s): ${missing[*]}"
    # Not run under sudo wholesale: only the install needs root, and asking for
    # it here rather than requiring the whole script to be root keeps every
    # other target owned by the user rather than by root.
    sudo apt update && sudo apt install -y "${missing[@]}"
}

case "$MODE" in
    doctor) doctor; exit $? ;;
    deps)
        if [ "$OS" != linux ]; then
            echo "--deps only knows apt; on $OS see packages/manual.md" >&2
            exit 2
        fi
        deps; exit 0 ;;
    install-deps)
        if [ "$OS" != linux ]; then
            echo "--install-deps only knows apt; on $OS see packages/manual.md" >&2
            exit 2
        fi
        install_deps; exit $? ;;
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
if nvim_new_enough; then
    echo "  nvim $(nvim_version) (>= $NVIM_MIN)"
else
    if command -v nvim >/dev/null 2>&1; then
        echo "  nvim $(nvim_version) is below $NVIM_MIN, which AstroNvim v6 requires"
    else
        echo "  nvim not installed"
    fi
    install_nvim || echo "  continuing without a usable nvim"
fi
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

echo "==> ssh"
# ControlPath needs its directory to exist. ssh does not create it, and a
# missing directory makes the multiplex fail silently -- every connection
# quietly pays a full handshake instead.
mkdir -p "$HOME/.ssh/cm"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/cm" 2>/dev/null || true
link "$DOTFILES/ssh/config" "$HOME/.ssh/config"

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
    # kitty looks for the paste filter beside kitty.conf, by fixed name.
    link "$DOTFILES/kitty/paste-actions.py" "$XDG/kitty/paste-actions.py"

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
link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "==> packages"
if [ "$OS" != linux ]; then
    echo "  skipped -- packages/apt.txt is apt-only; see packages/manual.md"
elif ! command -v dpkg >/dev/null 2>&1; then
    echo "  skipped -- no dpkg on this system; see packages/apt.txt for the list"
else
    # Report by default rather than only on request. A dependency nobody is
    # told about is indistinguishable from one that does not exist, which is
    # how a machine ends up without fzf while the repo calls it required.
    _missing=()
    mapfile -t _missing < <(missing_packages)
    if [ ${#_missing[@]} -eq 0 ]; then
        echo "  all packages in packages/apt.txt are installed"
    else
        echo "  missing ${#_missing[@]}: ${_missing[*]}"
        echo "  install with: ./install.sh --install-deps"
    fi
    unset _missing
fi

echo
echo "Done."
echo "Run ./install.sh --doctor for a full check, including things apt cannot"
echo "provide (kitty, the Nerd Font, terminfo, tmux plugins)."
if [ "$IS_WSL" = 1 ]; then
    echo
    echo "WSL is the source of truth. To refresh the Windows mirror, run"
    echo "install.ps1 from the Windows clone after pulling."
fi
